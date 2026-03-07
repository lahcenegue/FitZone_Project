from django.views import View
from django.http import HttpResponse

class ProductListView(View):
    def get(self, request): return HttpResponse('')

class ProductAddView(View):
    def get(self, request): return HttpResponse('')

class ProductEditView(View):
    def get(self, request, product_id): return HttpResponse('')

class ProductDeleteView(View):
    def post(self, request, product_id): return HttpResponse('')

class OrderListView(View):
    def get(self, request): return HttpResponse('')
