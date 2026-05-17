import logging
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from rest_framework import status
from django.core.exceptions import ValidationError

from apps.payments.services.checkout_service import CheckoutService

logger = logging.getLogger(__name__)

class CheckoutPreviewAPIView(APIView):
    """
    POST /api/v1/checkout/preview/
    Calculates the final invoice for an item considering coupons, points, and wallet balance.
    """
    permission_classes = [IsAuthenticated]

    def post(self, request, *args, **kwargs):
        try:
            # Pass the entire request object to allow building absolute image URLs
            preview_data = CheckoutService.preview_checkout(request, request.data)
            return Response(preview_data, status=status.HTTP_200_OK)
            
        except ValidationError as e:
            # Extract standard message and custom code injected by the service
            error_msg = e.message if hasattr(e, 'message') else (e.messages[0] if hasattr(e, 'messages') else str(e))
            error_code = getattr(e, 'code', 'validation_error')
            
            # Normalization fallback
            if error_code in [None, 'invalid']:
                error_code = "validation_error"
                
            return Response({"code": error_code, "message": error_msg}, status=status.HTTP_400_BAD_REQUEST)
            
        except Exception as e:
            logger.error(f"Critical Checkout Preview Error: {e}")
            return Response(
                {"code": "internal_error", "message": "An unexpected error occurred while generating the preview."}, 
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )


class CheckoutProcessAPIView(APIView):
    """
    POST /api/v1/checkout/process/
    Executes the checkout, deducts balances, calls payment gateways, and fulfills the purchase.
    """
    permission_classes = [IsAuthenticated]

    def post(self, request, *args, **kwargs):
        try:
            # Pass the entire request object to maintain context consistency
            result = CheckoutService.process_checkout(request, request.data)
            return Response(result, status=status.HTTP_200_OK)
            
        except ValidationError as e:
            error_msg = e.message if hasattr(e, 'message') else (e.messages[0] if hasattr(e, 'messages') else str(e))
            error_code = getattr(e, 'code', 'validation_error')
            
            if error_code in [None, 'invalid']:
                error_code = "validation_error"
                
            return Response({"code": error_code, "message": error_msg}, status=status.HTTP_400_BAD_REQUEST)
            
        except ValueError as e:
            # Raised by Payment Gateway if a card is declined, etc.
            return Response({"code": "payment_declined", "message": str(e)}, status=status.HTTP_402_PAYMENT_REQUIRED)
            
        except Exception as e:
            logger.error(f"Critical Checkout Process Error: {e}")
            return Response(
                {"code": "internal_error", "message": "An unexpected error occurred while processing the payment."}, 
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )