from django.views import View
from django.http import HttpResponse

class EarningsView(View):
    def get(self, request): return HttpResponse('')

class WithdrawView(View):
    def get(self, request): return HttpResponse('')
