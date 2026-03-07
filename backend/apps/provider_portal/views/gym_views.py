from django.views import View
from django.http import HttpResponse

class BranchListView(View):
    def get(self, request): return HttpResponse('')

class BranchAddView(View):
    def get(self, request): return HttpResponse('')

class BranchEditView(View):
    def get(self, request, branch_id): return HttpResponse('')

class BranchDeleteView(View):
    def post(self, request, branch_id): return HttpResponse('')

class BranchPhotosView(View):
    def get(self, request, branch_id): return HttpResponse('')

class PlanListView(View):
    def get(self, request): return HttpResponse('')

class PlanAddView(View):
    def get(self, request): return HttpResponse('')

class PlanEditView(View):
    def get(self, request, plan_id): return HttpResponse('')

class PlanToggleView(View):
    def post(self, request, plan_id): return HttpResponse('')

class SubscriberListView(View):
    def get(self, request): return HttpResponse('')
