"""
API views for Gym access and management operations.
"""

import logging
from rest_framework import status
from rest_framework.generics import ListAPIView
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView
from django.shortcuts import get_object_or_404
from django.db.models import Prefetch
from django.utils import timezone
from django.urls import reverse

from apps.gyms.models import GymBranch, SubscriptionPlan, GymSport, GymAmenity, GymVisit, GymSubscription, RoamingPass
from apps.gyms.api.serializers import (
    GymSportSerializer, GymAmenitySerializer, GymBranchDetailSerializer, 
    GymCheckoutSerializer, GymSubscriptionSerializer, RoamingCheckoutSerializer,
    RoamingPassSerializer, QRScanSerializer
)
from ..services import GymSubscriptionService, GymAccessService
from apps.users.services.user_service import UserDashboardService
from apps.users.api.serializers import AggregatedSubscriptionSerializer


logger = logging.getLogger(__name__)


class GymBranchDetailView(APIView):
    permission_classes = [AllowAny]

    def get(self, request, branch_id):
        branch = get_object_or_404(
            GymBranch.objects.select_related('tier').prefetch_related(
                'images',
                'amenities',
                'sports',
                'schedules',
                'reviews__user',
                'visits',
                Prefetch(
                    'available_plans', 
                    queryset=SubscriptionPlan.objects.filter(is_active=True)
                )
            ),
            id=branch_id,
            is_active=True
        )

        from apps.gyms.models import GymGlobalSetting
        gym_setting = GymGlobalSetting.load()
        
        serializer = GymBranchDetailSerializer(
            branch, 
            context={'request': request, 'gym_setting': gym_setting}
        )
        return Response(serializer.data, status=status.HTTP_200_OK)
    
class GymSportListAPIView(ListAPIView):
    queryset = GymSport.objects.all().order_by('name')
    serializer_class = GymSportSerializer
    authentication_classes = []  
    permission_classes = []
    pagination_class = None

class GymAmenityListAPIView(ListAPIView):
    queryset = GymAmenity.objects.all().order_by('name')
    serializer_class = GymAmenitySerializer
    authentication_classes = [] 
    permission_classes = []
    pagination_class = None

class GymCheckoutAPIView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request, *args, **kwargs):
        serializer = GymCheckoutSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        try:
            subscription = GymSubscriptionService.checkout_subscription(
                user=request.user,
                plan_id=serializer.validated_data['plan_id'],
                gateway_name=serializer.validated_data['gateway'],
                points_to_use=serializer.validated_data.get('points_to_use', 0)
            )
            
            subs_data = UserDashboardService.get_all_subscriptions(request.user, request=request)
            new_sub_data = next((s for s in subs_data if s["id"] == subscription.id and s["type"] == "regular"), None)
            
            return Response({
                "message": "Payment successful. Subscription activated.",
                "subscription": AggregatedSubscriptionSerializer(new_sub_data).data if new_sub_data else GymSubscriptionSerializer(subscription).data
            }, status=status.HTTP_201_CREATED)
            
        except ValueError as e:
            return Response({"detail": str(e)}, status=status.HTTP_400_BAD_REQUEST)
        except Exception as e:
            logger.error(f"Checkout error for user {request.user.email}: {str(e)}", exc_info=True)
            return Response(
                {"detail": "An internal error occurred during checkout."}, 
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

class RoamingCheckoutAPIView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request, *args, **kwargs):
        serializer = RoamingCheckoutSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        try:
            roaming_pass = GymSubscriptionService.checkout_roaming_pass(
                user=request.user,
                branch_id=serializer.validated_data['branch_id'],
                payment_method=serializer.validated_data['payment_method'],
                gateway_name=serializer.validated_data.get('gateway')
            )
            
            subs_data = UserDashboardService.get_all_subscriptions(request.user, request=request)
            new_rp_data = next((s for s in subs_data if s["id"] == roaming_pass.id and s["type"] == "roaming"), None)
            
            return Response({
                "message": "Roaming Pass purchased successfully.",
                "roaming_pass": AggregatedSubscriptionSerializer(new_rp_data).data if new_rp_data else RoamingPassSerializer(roaming_pass).data
            }, status=status.HTTP_201_CREATED)
            
        except ValueError as e:
            return Response({"detail": str(e)}, status=status.HTTP_400_BAD_REQUEST)
        except Exception as e:
            logger.error(f"Roaming checkout error for user {request.user.email}: {str(e)}", exc_info=True)
            return Response(
                {"detail": "An internal error occurred during roaming checkout."}, 
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

class QRScanView(APIView):
    """
    POST /api/v1/gyms/scan-qr/
    Process a user's QR code for gym check-in and builds a rich UI response.
    """
    permission_classes = [IsAuthenticated]

    def post(self, request):
        serializer = QRScanSerializer(data=request.data)
        if not serializer.is_valid():
            return Response({
                "status_color": "error",
                "title": "Invalid QR Format",
                "message": "The scanned code is invalid or tampered."
            }, status=status.HTTP_400_BAD_REQUEST)

        try:
            qr_uuid = str(serializer.validated_data["qr_code_id"])
            branch_id = serializer.validated_data["branch_id"]
            
            scan_result = GymAccessService.process_qr_scan(
                qr_code_id=qr_uuid,
                branch_id=branch_id
            )
            
            visit = GymVisit.objects.select_related(
                'subscription__user', 'subscription__plan', 
                'roaming_pass__user', 'branch'
            ).get(id=scan_result["visit_id"])
            
            user = visit.subscription.user if visit.subscription else visit.roaming_pass.user
            branch = visit.branch
            
            if visit.subscription:
                recent_visits = GymVisit.objects.filter(subscription__user=user).select_related('branch').order_by('-check_in_time')[:5]
            else:
                recent_visits = GymVisit.objects.filter(roaming_pass__user=user).select_related('branch').order_by('-check_in_time')[:5]
                
            logs = [
                {
                    "time": timezone.localtime(v.check_in_time).strftime("%I:%M %p"),
                    "date": timezone.localtime(v.check_in_time).strftime("%Y-%m-%d"),
                    "branch_name": v.branch.name
                } for v in recent_visits
            ]
            
            is_roaming = scan_result.get("is_roaming", False)
            plan_price = visit.subscription.plan.price if visit.subscription else visit.roaming_pass.fiat_paid
            total_days = scan_result.get("total_days", 1)
            days_left = scan_result.get("days_remaining", 0)
            subscription_id = scan_result.get("subscription_id")
            
            response_data = {
                "status_color": "success",
                "title": "Access Granted",
                "message": "Check-in successful" if not is_roaming else "Roaming Pass Consumed",
                "member_name": getattr(user, 'full_name', getattr(user, 'email', 'Unknown')),
                "member_id": str(user.id),
                "gender": getattr(user, 'gender', 'Unknown'),
                "phone_number": getattr(user, 'phone_number', '-'),
                "city": getattr(user, 'city', '-'),
                "address": getattr(user, 'address', '-'),
                "avatar_url": request.build_absolute_uri(user.real_face_image.url) if getattr(user, 'real_face_image', None) else None,
                "id_card_url": request.build_absolute_uri(user.id_card_image.url) if getattr(user, 'id_card_image', None) else None,
                "allowed_branches": branch.name,
                "branch_address": branch.address,
                "branch_logo_url": request.build_absolute_uri(branch.branch_logo.url) if getattr(branch, 'branch_logo', None) else None,
                "plan_name": scan_result.get("plan_name", "-"),
                "plan_price": str(plan_price),
                "days_left": days_left,
                "total_days": total_days,
                "current_capacity": GymAccessService.get_live_occupancy(branch.id),
                "latest_logs": logs,
                "is_roaming": is_roaming,
                "visit_type": scan_result.get("visit_type", "Regular"),
                "redirect_url": reverse('provider_portal:gym_subscriber_detail', args=[subscription_id]) if subscription_id else ""
            }
            return Response(response_data, status=status.HTTP_200_OK)
            
        except ValueError as exc:
            sub_id = None
            user = None
            branch = None
            plan_name = "-"
            is_roaming = False
            
            try:
                subscription = GymSubscription.objects.filter(qr_code_id=qr_uuid).first()
                if subscription:
                    user = subscription.user
                    sub_id = subscription.id
                    plan_name = subscription.plan.name
                else:
                    roaming = RoamingPass.objects.filter(qr_code_id=qr_uuid).first()
                    if roaming:
                        user = roaming.user
                        branch = roaming.branch
                        plan_name = "One-Time Roaming Pass"
                        is_roaming = True
            except Exception:
                pass

            response_error = {
                'status_color': 'error',
                'title': str(_("Access Denied")),
                'message': str(exc),
                'redirect_url': reverse('provider_portal:gym_subscriber_detail', args=[sub_id]) if sub_id else "",
                "member_name": getattr(user, 'full_name', getattr(user, 'email', 'Unknown')) if user else 'Unknown',
                "member_id": str(user.id) if user else "-",
                "gender": user.get_gender_display() if hasattr(user, 'get_gender_display') else getattr(user, 'gender', '-') if user else '-',
                "phone_number": getattr(user, 'phone_number', '-') if user else '-',
                "city": getattr(user, 'city', '-') if user else '-',
                "address": getattr(user, 'address', '-') if user else '-',
                "avatar_url": request.build_absolute_uri(user.real_face_image.url) if user and getattr(user, 'real_face_image', None) else None,
                "id_card_url": request.build_absolute_uri(user.id_card_image.url) if user and getattr(user, 'id_card_image', None) else None,
                "allowed_branches": branch.name if branch else "-",
                "branch_address": branch.address if branch else "-",
                "branch_logo_url": request.build_absolute_uri(branch.branch_logo.url) if branch and getattr(branch, 'branch_logo', None) else None,
                "plan_name": plan_name,
                "plan_price": "-",
                "days_left": 0,
                "total_days": 1,
                "current_capacity": 0,
                "latest_logs": [],
                "is_roaming": is_roaming,
                "visit_type": "Roaming" if is_roaming else "Regular"
            }
            return Response(response_error, status=status.HTTP_400_BAD_REQUEST)

        except Exception as exc:
            logger.error("QR Scan failed: %s", exc)
            return Response({
                "status_color": "error",
                "title": "System Error",
                "message": "An internal server error occurred."
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


class LiveOccupancyView(APIView):
    authentication_classes = [] 
    permission_classes = [AllowAny]

    def get(self, request, branch_id):
        try:
            count = GymAccessService.get_live_occupancy(branch_id=branch_id)
            return Response(
                {
                    "branch_id": branch_id,
                    "current_occupancy": count
                },
                status=status.HTTP_200_OK
            )
        except Exception as exc:
            logger.error("Failed to get occupancy for branch %s: %s", branch_id, exc)
            return Response(
                {"detail": "Failed to retrieve live occupancy."},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )