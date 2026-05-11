import logging
from decimal import Decimal
from datetime import timedelta
from django.db.models import Sum
from rest_framework.views import APIView
from rest_framework.generics import ListAPIView
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated, AllowAny
from rest_framework import status
from rest_framework.pagination import PageNumberPagination
from django.core.exceptions import ValidationError
from django.utils.translation import gettext as _

from apps.loyalty.services import LoyaltyService
from apps.loyalty.models import PointPackage, Milestone, UserMilestone, WalletTransaction, TransactionStatus, TransactionType, CustomerWallet
from apps.resale.models import ResaleTransaction, ResaleGlobalSetting
from .serializers import (
    PurchasePointsSerializer, MilestoneClaimSerializer,
    PointPackageSerializer, MilestoneSerializer, UserMilestoneSerializer,
    WalletTransactionSerializer, PointsHistorySerializer, UserBankAccountSerializer, 
    WithdrawalRequestSerializer, AggregatedFiatTransactionSerializer
)

logger = logging.getLogger(__name__)

class StandardResultsSetPagination(PageNumberPagination):
    page_size = 20
    page_size_query_param = 'limit'
    max_page_size = 100

class PointPackageListAPIView(ListAPIView):
    permission_classes = [AllowAny]
    queryset = PointPackage.objects.filter(is_active=True).order_by('price')
    serializer_class = PointPackageSerializer
    pagination_class = None

class MilestoneRoadmapAPIView(ListAPIView):
    permission_classes = [AllowAny]
    queryset = Milestone.objects.filter(is_active=True).order_by('required_lifetime_points')
    serializer_class = MilestoneSerializer
    pagination_class = None

    def list(self, request, *args, **kwargs):
        queryset = self.get_queryset()
        serializer = self.get_serializer(queryset, many=True)

        if request.user and request.user.is_authenticated:
            meta_progress = LoyaltyService.calculate_milestone_progress(request.user)
            return Response({
                "meta_progress": meta_progress,
                "milestones": serializer.data
            }, status=status.HTTP_200_OK)

        return Response(serializer.data, status=status.HTTP_200_OK)

class UserMilestonesAPIView(ListAPIView):
    permission_classes = [IsAuthenticated]
    serializer_class = UserMilestoneSerializer
    pagination_class = StandardResultsSetPagination

    def get_queryset(self):
        queryset = UserMilestone.objects.filter(
            user=self.request.user, 
            is_claimed=True
        ).select_related('milestone__reward').order_by('-claimed_at')
        
        status_filter = self.request.query_params.get('status')
        if status_filter == 'consumed':
            queryset = queryset.filter(is_consumed=True)
        elif status_filter == 'active': 
            queryset = queryset.filter(is_consumed=False)
            
        return queryset

class UserMilestonesSummaryAPIView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        milestones = UserMilestone.objects.filter(user=request.user)
        total_available = milestones.filter(is_claimed=True, is_consumed=False).count()
        total_consumed = milestones.filter(is_consumed=True).count()

        response_data = {
            "total_available": total_available,
            "total_consumed": total_consumed
        }
        return Response(response_data, status=status.HTTP_200_OK)

class WalletTransactionsAPIView(ListAPIView):
    """
    Aggregates completed/pending Wallet transactions AND 
    pending ESCROW Resale transactions with proper filtering and UI mapping.
    Filters supported: all, income, withdrawals, consumed.
    """
    permission_classes = [IsAuthenticated]
    serializer_class = AggregatedFiatTransactionSerializer
    pagination_class = StandardResultsSetPagination

    def _get_status_label(self, status_val: str) -> str:
        mapping = {
            'completed': str(_("Completed")),
            'pending': str(_("Processing")),
            'failed': str(_("Failed")),
            'escrow': str(_("Escrow Hold")),
            'refunded': str(_("Refunded"))
        }
        return mapping.get(status_val, str(_(status_val.title())))

    def list(self, request, *args, **kwargs):
        filter_type = request.query_params.get('filter', 'all').lower()
        combined_transactions = []
        
        # 1. Fetch Wallet Transactions
        wt_qs = WalletTransaction.objects.exclude(fiat_amount=0).filter(wallet__user=request.user)
        
        if filter_type == 'income':
            wt_qs = wt_qs.filter(fiat_amount__gt=0)
        elif filter_type == 'withdrawals':
            wt_qs = wt_qs.filter(transaction_type=TransactionType.WITHDRAW_FIAT)
        elif filter_type == 'consumed':
            wt_qs = wt_qs.filter(fiat_amount__lt=0).exclude(transaction_type=TransactionType.WITHDRAW_FIAT)
                
        for wt in wt_qs:
            t_type = wt.transaction_type
            
            # Map type, title, and impact based on business logic
            if t_type == TransactionType.WITHDRAW_FIAT:
                title = str(_("Bank Withdrawal Request"))
                trans_type = "withdrawal"
                impact = "out"
            elif t_type == TransactionType.SELL_SUBSCRIPTION:
                title = str(_("Subscription Resale Revenue"))
                trans_type = "deposit"
                impact = "in"
            elif t_type == TransactionType.REFUND:
                title = str(_("Refunded Amount"))
                trans_type = "refund"
                impact = "in"
            else:
                if wt.fiat_amount < 0:
                    title = str(_("In-App Purchase"))
                    trans_type = "purchase"
                    impact = "out"
                else:
                    title = str(_(wt.get_transaction_type_display()))
                    trans_type = "deposit"
                    impact = "in"
            
            combined_transactions.append({
                "id": wt.id,
                "title": title,
                "amount": abs(wt.fiat_amount),
                "type": trans_type,
                "status": wt.status,
                "status_label": self._get_status_label(wt.status),
                "created_at": wt.created_at,
                "expected_release_date": None,
                "impact": impact
            })
            
        # 2. Fetch Pending Resale Transactions (Escrow)
        if filter_type in ['all', 'income']:
            rt_qs = ResaleTransaction.objects.filter(listing__seller=request.user, status='escrow')
            resale_settings = ResaleGlobalSetting.load()
            hold_hours = resale_settings.escrow_hold_hours
            
            for rt in rt_qs:
                expected_release = rt.purchased_at + timedelta(hours=hold_hours)
                combined_transactions.append({
                    "id": rt.id,
                    "title": str(_("Pending Resale Funds")),
                    "amount": abs(rt.seller_earnings),
                    "type": "deposit",
                    "status": "escrow",
                    "status_label": self._get_status_label("escrow"),
                    "created_at": rt.purchased_at,
                    "expected_release_date": expected_release,
                    "impact": "in"
                })
                    
        # Sort combined list by date descending
        combined_transactions.sort(key=lambda x: x['created_at'], reverse=True)
        
        page = self.paginate_queryset(combined_transactions)
        if page is not None:
            serializer = self.get_serializer(page, many=True)
            return self.get_paginated_response(serializer.data)

        serializer = self.get_serializer(combined_transactions, many=True)
        return Response(serializer.data)

class TransactionsSummaryAPIView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        wallet, _ = CustomerWallet.objects.get_or_create(user=request.user)
        
        # 1. Total pending escrow from active resales
        pending_escrow = ResaleTransaction.objects.filter(
            listing__seller=request.user,
            status='escrow'
        ).aggregate(total=Sum('seller_earnings'))['total'] or Decimal('0.00')

        # 2. Total actually earned & deposited into the wallet
        completed_earnings = WalletTransaction.objects.filter(
            wallet__user=request.user,
            transaction_type__in=[TransactionType.SELL_SUBSCRIPTION, TransactionType.REFUND],
            status=TransactionStatus.COMPLETED
        ).aggregate(total=Sum('fiat_amount'))['total'] or Decimal('0.00')

        gross_earnings = completed_earnings + pending_escrow

        # 3. Total consumed inside app (negative fiat amounts excluding withdrawals)
        total_consumed = WalletTransaction.objects.filter(
            wallet__user=request.user,
            fiat_amount__lt=0,
            status=TransactionStatus.COMPLETED
        ).exclude(transaction_type=TransactionType.WITHDRAW_FIAT).aggregate(total=Sum('fiat_amount'))['total'] or Decimal('0.00')

        # 4. Total withdrawn
        total_withdrawn = WalletTransaction.objects.filter(
            wallet__user=request.user,
            transaction_type=TransactionType.WITHDRAW_FIAT,
            status=TransactionStatus.COMPLETED
        ).aggregate(total=Sum('fiat_amount'))['total'] or Decimal('0.00')

        response_data = {
            "gross_earnings": float(gross_earnings),
            "available_funds": float(wallet.fiat_balance),
            "pending_escrow": float(pending_escrow),
            "total_consumed": abs(float(total_consumed)),
            "total_withdrawn": abs(float(total_withdrawn))
        }

        return Response(response_data, status=status.HTTP_200_OK)

class PointsHistoryAPIView(ListAPIView):
    permission_classes = [IsAuthenticated]
    serializer_class = PointsHistorySerializer
    pagination_class = StandardResultsSetPagination

    def get_queryset(self):
        queryset = WalletTransaction.objects.exclude(points_amount=0).filter(
            wallet__user=self.request.user
        ).order_by('-created_at')

        type_filter = self.request.query_params.get('type')
        if type_filter == 'earn':
            queryset = queryset.filter(points_amount__gt=0)
        elif type_filter == 'redeem':
            queryset = queryset.filter(points_amount__lt=0)

        return queryset

class PointsHistorySummaryAPIView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        transactions = WalletTransaction.objects.filter(wallet__user=request.user)

        points_earned = transactions.filter(
            transaction_type__in=[TransactionType.EARN_PURCHASE, TransactionType.BUY_POINTS],
            status=TransactionStatus.COMPLETED
        ).aggregate(total=Sum('points_amount'))['total'] or 0

        points_spent = transactions.filter(
            transaction_type__in=[TransactionType.SPEND_ROAMING, TransactionType.SPEND_DISCOUNT],
            status=TransactionStatus.COMPLETED
        ).aggregate(total=Sum('points_amount'))['total'] or 0

        response_data = {
            "total_earned": int(points_earned),
            "total_redeemed": abs(int(points_spent))
        }

        return Response(response_data, status=status.HTTP_200_OK)

class WalletSummaryAPIView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        try:
            summary = LoyaltyService.get_wallet_summary(request.user)
            return Response(summary, status=status.HTTP_200_OK)
        except Exception as e:
            logger.error(f"Error fetching wallet summary for user {request.user.id}: {str(e)}")
            return Response(
                {"detail": "Failed to retrieve wallet summary."}, 
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

class PurchasePointsAPIView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        serializer = PurchasePointsSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
        
        try:
            LoyaltyService.purchase_points(
                user=request.user,
                package_id=serializer.validated_data['package_id'],
                gateway_name=serializer.validated_data['gateway']
            )
            return Response({"message": str(_("Points purchased successfully."))}, status=status.HTTP_200_OK)
        except ValueError as e:
            return Response({"detail": str(e)}, status=status.HTTP_400_BAD_REQUEST)
        except Exception as e:
            logger.error(f"Points purchase error for user {request.user.id}: {str(e)}")
            return Response(
                {"detail": str(_("An internal error occurred during the transaction."))}, 
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

class ClaimMilestoneAPIView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        serializer = MilestoneClaimSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
        
        try:
            payload = LoyaltyService.claim_milestone_reward(
                user=request.user,
                user_milestone_id=serializer.validated_data['user_milestone_id']
            )
            return Response({
                "message": str(_("Milestone reward claimed and generated successfully.")),
                "reward_payload": payload
            }, status=status.HTTP_200_OK)
        except ValidationError as e:
            return Response({"detail": list(e) if hasattr(e, 'messages') else str(e)}, status=status.HTTP_400_BAD_REQUEST)
        except Exception as e:
            logger.error(f"Error claiming milestone for user {request.user.id}: {str(e)}")
            return Response({"detail": str(_("Failed to claim milestone reward."))}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

class BankAccountAPIView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        serializer = UserBankAccountSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
        
        bank_account = LoyaltyService.save_bank_account(request.user, serializer.validated_data)
        response_serializer = UserBankAccountSerializer(bank_account)
        
        return Response({
            "message": str(_("Bank account saved successfully.")),
            "bank_account": response_serializer.data
        }, status=status.HTTP_200_OK)

class WithdrawalAPIView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        serializer = WithdrawalRequestSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
        
        try:
            transaction_obj, new_balance = LoyaltyService.request_withdrawal(
                user=request.user,
                amount=serializer.validated_data['amount']
            )
            return Response({
                "message": str(_("Withdrawal request submitted successfully.")),
                "transaction_id": transaction_obj.id,
                "new_fiat_balance": new_balance
            }, status=status.HTTP_200_OK)
            
        except ValidationError as e:
            return Response({"detail": e.messages[0] if hasattr(e, 'messages') else str(e)}, status=status.HTTP_400_BAD_REQUEST)
        except Exception as e:
            logger.error(f"Withdrawal error for user {request.user.id}: {str(e)}")
            return Response(
                {"detail": str(_("An internal error occurred while processing your withdrawal."))}, 
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

class ExtendSubscriptionAPIView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        user_milestone_id = request.data.get('user_milestone_id')
        subscription_id = request.data.get('subscription_id')

        if not user_milestone_id or not subscription_id:
            return Response({"detail": "Missing parameters."}, status=status.HTTP_400_BAD_REQUEST)

        try:
            new_end_date = LoyaltyService.apply_subscription_extension(
                user=request.user,
                user_milestone_id=user_milestone_id,
                subscription_id=subscription_id
            )
            return Response({
                "message": str(_("Subscription extended successfully.")),
                "new_end_date": new_end_date
            }, status=status.HTTP_200_OK)
        except ValidationError as e:
            return Response({"detail": list(e) if hasattr(e, 'messages') else str(e)}, status=status.HTTP_400_BAD_REQUEST)
        except Exception as e:
            logger.error(f"Extension error for user {request.user.id}: {str(e)}")
            return Response({"detail": str(_("An internal server error occurred."))}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

class ScanGiftQRAPIView(APIView):
    permission_classes = [IsAuthenticated] 

    def post(self, request):
        qr_code_data = request.data.get('qr_code_data')
        if not qr_code_data:
            return Response({"detail": "QR code is required."}, status=status.HTTP_400_BAD_REQUEST)

        try:
            result = LoyaltyService.process_gift_qr_scan(
                staff_user=request.user, 
                qr_code_data=qr_code_data
            )
            return Response({
                "message": str(_("Gift consumed successfully. You can hand over the item.")),
                "details": result
            }, status=status.HTTP_200_OK)
        except ValidationError as e:
            return Response({"detail": list(e) if hasattr(e, 'messages') else str(e)}, status=status.HTTP_400_BAD_REQUEST)
        except Exception as e:
            logger.error(f"Gift scan error by staff {request.user.id}: {str(e)}")
            return Response({"detail": str(_("An internal server error occurred."))}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)