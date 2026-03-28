import logging
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from django.core.paginator import Paginator, EmptyPage

from apps.providers.services.search_service import UnifiedSearchService
from apps.gyms.api.serializers import GymBranchSearchSerializer
from apps.core.constants import PAGE_SIZE_DEFAULT

logger = logging.getLogger(__name__)

class UnifiedSearchAPIView(APIView):
    """
    GET /api/v1/providers/discover/
    Unified endpoint to search and filter providers explicitly governed by 'type'.
    """
    authentication_classes = [] 
    permission_classes = []

    def get(self, request, *args, **kwargs):
        try:
            params = request.query_params
            service_type = params.get('type', 'gym').lower()
            page_number = params.get('page', 1)

            # 1. Fetch data through the service layer routing
            try:
                queryset = UnifiedSearchService.search_providers(params)
            except ValueError as ve:
                return Response({"error": str(ve)}, status=status.HTTP_400_BAD_REQUEST)

            # 2. Assign the correct Serializer based on service type
            if service_type == 'gym':
                serializer_class = GymBranchSearchSerializer
            else:
                return Response(
                    {"error": f"Serializer for type '{service_type}' is not implemented yet."}, 
                    status=status.HTTP_501_NOT_IMPLEMENTED
                )

            # 3. Handle Pagination
            paginator = Paginator(queryset, PAGE_SIZE_DEFAULT)
            try:
                page_obj = paginator.page(page_number)
            except EmptyPage:
                return Response({
                    "results": [],
                    "meta": {
                        "total_items": paginator.count,
                        "total_pages": paginator.num_pages,
                        "current_page": int(page_number)
                    }
                }, status=status.HTTP_200_OK)

            # 4. Serialize Data
            serializer = serializer_class(page_obj.object_list, many=True, context={'request': request})

            return Response({
                "results": serializer.data,
                "meta": {
                    "total_items": paginator.count,
                    "total_pages": paginator.num_pages,
                    "current_page": page_obj.number,
                    "has_next": page_obj.has_next(),
                    "has_previous": page_obj.has_previous(),
                }
            }, status=status.HTTP_200_OK)

        except Exception as e:
            logger.error(f"Error in UnifiedSearchAPIView: {str(e)}", exc_info=True)
            return Response(
                {"error": "An internal server error occurred during search."}, 
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )