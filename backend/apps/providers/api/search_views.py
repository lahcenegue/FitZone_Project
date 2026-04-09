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

            # --- 1. Validate Price Parameters ---
            min_price = params.get('min_price')
            max_price = params.get('max_price')

            if min_price and max_price:
                try:
                    min_p = float(min_price)
                    max_p = float(max_price)
                    if min_p > max_p:
                        return Response(
                            {"detail": "Minimum price cannot be greater than maximum price."},
                            status=status.HTTP_400_BAD_REQUEST
                        )
                except ValueError:
                    return Response(
                        {"detail": "Price values must be valid numbers."},
                        status=status.HTTP_400_BAD_REQUEST
                    )

            # --- 2. Validate Map Bounding Box Parameters ---
            min_lat = params.get('min_lat')
            max_lat = params.get('max_lat')
            min_lng = params.get('min_lng')
            max_lng = params.get('max_lng')

            if min_lat and max_lat:
                try:
                    if float(min_lat) > float(max_lat):
                        return Response(
                            {"detail": "Minimum latitude cannot be greater than maximum latitude."},
                            status=status.HTTP_400_BAD_REQUEST
                        )
                except ValueError:
                    return Response(
                        {"detail": "Latitude values must be valid numbers."}, 
                        status=status.HTTP_400_BAD_REQUEST
                    )
            
            if min_lng and max_lng:
                try:
                    if float(min_lng) > float(max_lng):
                        return Response(
                            {"detail": "Minimum longitude cannot be greater than maximum longitude."},
                            status=status.HTTP_400_BAD_REQUEST
                        )
                except ValueError:
                    return Response(
                        {"detail": "Longitude values must be valid numbers."}, 
                        status=status.HTTP_400_BAD_REQUEST
                    )

            # --- 3. Fetch data through the service layer routing ---
            try:
                queryset = UnifiedSearchService.search_providers(params)
            except ValueError as ve:
                return Response({"detail": str(ve)}, status=status.HTTP_400_BAD_REQUEST)

            # --- 4. Assign the correct Serializer based on service type ---
            if service_type == 'gym':
                serializer_class = GymBranchSearchSerializer
            else:
                return Response(
                    {"detail": f"Serializer for type '{service_type}' is not implemented yet."}, 
                    status=status.HTTP_501_NOT_IMPLEMENTED
                )

            # --- 5. Handle Pagination ---
            paginator = Paginator(queryset, PAGE_SIZE_DEFAULT)
            try:
                page_obj = paginator.page(page_number)
            except EmptyPage:
                return Response({
                    "results": [],
                    "meta": {
                        "total_items": paginator.count,
                        "total_pages": paginator.num_pages,
                        "current_page": int(page_number),
                        "has_next": False,
                        "has_previous": False
                    }
                }, status=status.HTTP_200_OK)

            # --- 6. Serialize Data ---
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
                {"detail": "An internal server error occurred during search."}, 
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )