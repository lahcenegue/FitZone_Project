from django.urls import path
from . import views

app_name = 'resale_api'

urlpatterns = [
    path('discover/', views.MarketplaceListView.as_view(), name='marketplace-list'),
    path('list/', views.CreateListingAPIView.as_view(), name='create-listing'),
    path('cancel/', views.CancelListingAPIView.as_view(), name='cancel-listing'),
    path('purchase/', views.PurchaseListingAPIView.as_view(), name='purchase-listing'),
]