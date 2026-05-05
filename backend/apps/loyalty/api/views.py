import logging
from decimal import Decimal
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
from apps.loyalty.models import PointPackage, Milestone, UserMilestone, WalletTransaction, TransactionStatus, TransactionType
from .serializers import (
    PurchasePointsSerializer, MilestoneUsageSerializer, MilestoneClaimSerializer,
    PointPackageSerializer, MilestoneSerializer, UserMilestoneSerializer,
    WalletTransactionSerializer, PointsHistorySerializer, UserBankAccountSerializer, WithdrawalRequestSerializer
)

logger = logging.getLogger(__name__)

class StandardResultsSetPagination(PageNumberPagination):
    page_size = 20
    page_size_query_param = 'limit'
    max_page_size = 100

class PointPackageListAPIView(ListAPIView):
    permission_classes = [AllowAny]
    queryset = PointPackage.objects.filter(is_active=True)
    serializer_class = PointPackageSerializer
    pagination_class = None

class MilestoneRoadmapAPIView(ListAPIView):
    permission_classes = [AllowAny] # Safe because serializer handles context
    queryset = Milestone.objects.filter(is_active=True).order_by('required_lifetime_points')
    serializer_class = MilestoneSerializer
    pagination_class = None

class UserMilestonesAPIView(ListAPIView):
    """
    Inventory of user rewards. ONLY shows Claimed rewards.
    """
    permission_classes = [IsAuthenticated]
    serializer_class = UserMilestoneSerializer
    pagination_class = StandardResultsSetPagination

    def get_queryset(self):
        # STRICT: Must be claimed to show in inventory
        queryset = UserMilestone.objects.filter(
            user=self.request.user, 
            is_claimed=True
        ).select_related('milestone__reward').order_by('-claimed_at')
        
        status_filter = self.request.query_params.get('status')
        if status_filter == 'consumed':
            queryset = queryset.filter(is_consumed=True)
        elif status_filter == 'active': # Not consumed yet (Ready to use)
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
    permission_classes = [IsAuthenticated]
    serializer_class = WalletTransactionSerializer
    pagination_class = StandardResultsSetPagination

    def get_queryset(self):
        queryset = WalletTransaction.objects.exclude(fiat_amount=0).filter(
            wallet__user=self.request.user
        ).order_by('-created_at')

        status_filter = self.request.query_params.get('status')
        type_filter = self.request.query_params.get('type')

        if status_filter:
            queryset = queryset.filter(status=status_filter)

        if type_filter:
            if type_filter == 'deposit':
                queryset = queryset.filter(transaction_type__in=['sell_sub', 'refund'])
            elif type_filter == 'withdrawal':
                queryset = queryset.filter(transaction_type='withdraw_fiat')

        return queryset

class TransactionsSummaryAPIView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        transactions = WalletTransaction.objects.filter(wallet__user=request.user)

        fiat_earned = transactions.filter(
            transaction_type__in=[TransactionType.SELL_SUBSCRIPTION, TransactionType.REFUND],
            status=TransactionStatus.COMPLETED
        ).aggregate(total=Sum('fiat_amount'))['total'] or Decimal('0.00')

        fiat_spent = transactions.filter(
            transaction_type__in=[TransactionType.WITHDRAW_FIAT],
            status=TransactionStatus.COMPLETED
        ).aggregate(total=Sum('fiat_amount'))['total'] or Decimal('0.00')

        pending_withdrawals = transactions.filter(
            transaction_type=TransactionType.WITHDRAW_FIAT,
            status=TransactionStatus.PENDING
        ).aggregate(total=Sum('fiat_amount'))['total'] or Decimal('0.00')

        completed_withdrawals = transactions.filter(
            transaction_type=TransactionType.WITHDRAW_FIAT,
            status=TransactionStatus.COMPLETED
        ).aggregate(total=Sum('fiat_amount'))['total'] or Decimal('0.00')

        response_data = {
            "total_earned": float(fiat_earned),
            "total_spent": abs(float(fiat_spent)),
            "pending_withdrawals": abs(float(pending_withdrawals)),
            "completed_withdrawals": abs(float(completed_withdrawals))
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
            if summary.get('next_milestone') and summary['next_milestone']['title'] != "MAX":
                summary['next_milestone']['title'] = str(_(summary['next_milestone']['title']))
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
            # Capturing payload at Claim time
            payload = LoyaltyService.claim_milestone_reward(
                user=request.user,
                user_milestone_id=serializer.validated_data['user_milestone_id']
            )
            return Response({
                "message": str(_("Milestone reward claimed and generated successfully.")),
                "reward_payload": payload
            }, status=status.HTTP_200_OK)
        except ValidationError as e:
            return Response({"detail": list(e)}, status=status.HTTP_400_BAD_REQUEST)
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
    """Endpoint for user to select which subscription to extend using their reward."""
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
    """Endpoint for Gym/Store Staff to scan physical gifts and hand them over."""
    permission_classes = [IsAuthenticated] # Needs to be updated to IsStaff in future if required

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