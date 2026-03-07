from django.views import View
from django.http import HttpResponse

class DashboardView(View):
    def get(self, request): return HttpResponse('')

class NotificationsView(View):
    def get(self, request): return HttpResponse('')

class MarkNotificationReadView(View):
    def post(self, request, notification_id): return HttpResponse('')
