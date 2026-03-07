from django.views import View
from django.http import HttpResponse

class TrainerProfileView(View):
    def get(self, request): return HttpResponse('')

class AvailabilityView(View):
    def get(self, request): return HttpResponse('')

class BookingListView(View):
    def get(self, request): return HttpResponse('')

class BookingAcceptView(View):
    def post(self, request, booking_id): return HttpResponse('')

class BookingRejectView(View):
    def post(self, request, booking_id): return HttpResponse('')
