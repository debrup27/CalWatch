
from django.urls import path
from .views import DataEntryCreateView, DataEntryListByDateView

urlpatterns = [
    path('submit/', DataEntryCreateView.as_view(), name='data-submit'),
    path('list/', DataEntryListByDateView.as_view(), name='data-list'),
]