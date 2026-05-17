import logging
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from rest_framework import status
from django.core.exceptions import ValidationError

from apps.coupons.services import CouponValidationService
from .serializers import CouponValidationRequestSerializer, CouponValidationResponseSerializer

logger = logging.getLogger(__name__)

class ValidateCouponAPIView(APIView):
    """
    API Endpoint for mobile clients to validate a coupon in real-time.
    Optionally accepts a 'subtotal' to calculate the exact expected fiat discount.
    """
    permission_classes = [IsAuthenticated]

    def post(self, request):
        request_serializer = CouponValidationRequestSerializer(data=request.data)
        
        if not request_serializer.is_valid():
            return Response(request_serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        coupon_code = request_serializer.validated_data['coupon_code']
        subtotal = request_serializer.validated_data['subtotal']

        try:
            validation_result = CouponValidationService.validate_and_calculate_discount(
                user=request.user, 
                coupon_code=coupon_code, 
                subtotal=subtotal
            )
            
            response_serializer = CouponValidationResponseSerializer(validation_result)
            return Response(response_serializer.data, status=status.HTTP_200_OK)

        except ValidationError as e:
            error_message = e.messages[0] if hasattr(e, 'messages') else str(e)
            return Response({"detail": error_message}, status=status.HTTP_400_BAD_REQUEST)
            
        except Exception as e:
            logger.error(f"Coupon Validation API error for user {request.user.id}: {str(e)}")
            return Response(
                {"detail": "An internal server error occurred while validating the coupon."}, 
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )