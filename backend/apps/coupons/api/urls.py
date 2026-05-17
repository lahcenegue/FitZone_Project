from django.urls import path
from . import views

app_name = 'coupons_api'

urlpatterns = [
    path('validate/', views.ValidateCouponAPIView.as_view(), name='validate-coupon'),
]