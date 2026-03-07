from django.views import View
from django.http import HttpResponse

class MenuView(View):
    def get(self, request): return HttpResponse('')

class MenuItemAddView(View):
    def get(self, request): return HttpResponse('')

class MenuItemEditView(View):
    def get(self, request, item_id): return HttpResponse('')

class MenuItemDeleteView(View):
    def post(self, request, item_id): return HttpResponse('')

class OrderListView(View):
    def get(self, request): return HttpResponse('')
