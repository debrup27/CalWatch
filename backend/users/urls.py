from django.urls import path, re_path
from .views import UserDetailView, UserProfileView, UserDetailsView

urlpatterns = [
    path('me/', UserDetailView.as_view(), name='user-detail'),
    path('profile/', UserProfileView.as_view(), name='user-profile'),
    re_path(r'^userDetails/?$', UserDetailsView.as_view(), name='user-details'),
]