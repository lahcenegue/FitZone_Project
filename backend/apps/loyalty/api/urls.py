from django.urls import path
from . import views

app_name = 'loyalty_api'

urlpatterns = [
    # Data Retrieval Endpoints
    path('packages/', views.PointPackageListAPIView.as_view(), name='packages-list'),
    path('milestones/', views.MilestoneRoadmapAPIView.as_view(), name='milestones-roadmap'),
    
    # User Specific Endpoints
    path('wallet/', views.WalletSummaryAPIView.as_view(), name='wallet-summary'),
    path('my-milestones/', views.UserMilestonesAPIView.as_view(), name='my-milestones'),
    
    # Action Endpoints
    path('purchase/', views.PurchasePointsAPIView.as_view(), name='purchase-points'),
    path('milestones/consume/', views.ConsumeMilestoneAPIView.as_view(), name='consume-milestone'),
]