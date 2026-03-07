from django.views import View
from django.http import HttpResponse

class ProfileView(View):
    def get(self, request): return HttpResponse('')

class SecurityView(View):
    def get(self, request): return HttpResponse('')

class FinancialView(View):
    def get(self, request): return HttpResponse('')
