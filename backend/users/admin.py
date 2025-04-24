from django.contrib import admin
from .models import UserProfile, UserDetails

admin.site.register(UserProfile)
admin.site.register(UserDetails)
