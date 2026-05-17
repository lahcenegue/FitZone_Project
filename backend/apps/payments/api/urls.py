from django.urls import path
from .views import CheckoutPreviewAPIView, CheckoutProcessAPIView

app_name = "payments_api"

urlpatterns = [
    path('checkout/preview/', CheckoutPreviewAPIView.as_view(), name='checkout-preview'),
    path('checkout/process/', CheckoutProcessAPIView.as_view(), name='checkout-process'),
]