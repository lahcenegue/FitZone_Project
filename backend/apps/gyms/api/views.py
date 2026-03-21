"""
API views for Gym access and management operations.
"""

import logging
from rest_framework import status
from rest_framework.generics import ListAPIView
from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from rest_framework.views import APIView
from django.shortcuts import get_object_or_404
from django.db.models import Prefetch

from apps.gyms.models import GymBranch, SubscriptionPlan, GymSport, GymAmenity
from apps.gyms.api.serializers import GymSportSerializer, GymAmenitySerializer
from .serializers import GymBranchDetailSerializer

logger = logging.getLogger(__name__)


class GymBranchDetailView(APIView):
    """
    GET /api/v1/gyms/branches/<int:branch_id>/
    
    Retrieves full details of a specific gym branch including 
    its amenities, image gallery, weekly schedule, reviews, and plans.
    """
    permission_classes = [AllowAny]

    def get(self, request, branch_id):
        # Prefetch optimizations drastically reduce database hits for nested JSON
        branch = get_object_or_404(
            GymBranch.objects.prefetch_related(
                'images',
                'amenities',
                'sports',
                'schedules',
                'reviews__user',
                'visits',  # FIXED: using correct related_name
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
    """
    GET /api/v1/gyms/sports/
    Returns the full list of available sports for caching in the app.
    """
    queryset = GymSport.objects.all().order_by('name')
    serializer_class = GymSportSerializer
    authentication_classes = []  # Public endpoint
    permission_classes = []
    pagination_class = None  # Return all records at once for caching

class GymAmenityListAPIView(ListAPIView):
    """
    GET /api/v1/gyms/amenities/
    Returns the full list of available amenities for caching in the app.
    """
    queryset = GymAmenity.objects.all().order_by('name')
    serializer_class = GymAmenitySerializer
    authentication_classes = []  # Public endpoint
    permission_classes = []
    pagination_class = None  # Return all records at once for caching