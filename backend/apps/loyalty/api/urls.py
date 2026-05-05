from django.urls import path
from . import views

app_name = 'loyalty_api'

urlpatterns = [
    path('packages/', views.PointPackageListAPIView.as_view(), name='packages-list'),
    path('milestones/', views.MilestoneRoadmapAPIView.as_view(), name='milestones-roadmap'),
    
    path('wallet/', views.WalletSummaryAPIView.as_view(), name='wallet-summary'),
    
    path('transactions/summary/', views.TransactionsSummaryAPIView.as_view(), name='transactions-summary'),
    path('transactions/', views.WalletTransactionsAPIView.as_view(), name='wallet-transactions'),
    
    path('points-history/summary/', views.PointsHistorySummaryAPIView.as_view(), name='points-history-summary'),
    path('points-history/', views.PointsHistoryAPIView.as_view(), name='points-history'),
    
    path('my-milestones/summary/', views.UserMilestonesSummaryAPIView.as_view(), name='my-milestones-summary'),
    path('my-milestones/', views.UserMilestonesAPIView.as_view(), name='my-milestones'),
    
    path('bank-account/', views.BankAccountAPIView.as_view(), name='bank-account'),
    
    path('purchase/', views.PurchasePointsAPIView.as_view(), name='purchase-points'),
    path('milestones/claim/', views.ClaimMilestoneAPIView.as_view(), name='claim-milestone'),
    
    path('extend-subscription/', views.ExtendSubscriptionAPIView.as_view(), name='extend-subscription'),
    path('scan-gift/', views.ScanGiftQRAPIView.as_view(), name='scan-gift'),
    
    path('withdraw/', views.WithdrawalAPIView.as_view(), name='withdraw'),
]