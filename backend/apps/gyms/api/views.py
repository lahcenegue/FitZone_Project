from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from rest_framework.permissions import AllowAny
from django.shortcuts import get_object_or_404

from apps.gyms.models import GymBranch
from .serializers import GymBranchDetailSerializer

class GymBranchDetailView(APIView):
    """
    GET /api/v1/gyms/branches/<int:branch_id>/
    
    Retrieves full details of a specific gym branch including 
    its amenities, image gallery, and available subscription plans.
    """
    permission_classes = [AllowAny]

    def get(self, request, branch_id):
        branch = get_object_or_404(GymBranch, id=branch_id, is_active=True)
        serializer = GymBranchDetailSerializer(branch, context={'request': request})
        return Response(serializer.data, status=status.HTTP_200_OK)