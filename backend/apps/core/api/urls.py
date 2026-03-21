# apps/core/api/urls.py
from django.urls import path
from .views import InitAPIView, CityListAPIView

app_name = "core_api"

urlpatterns = [
    path("init/", InitAPIView.as_view(), name="init"),
    path("cities/", CityListAPIView.as_view(), name="cities"),
]