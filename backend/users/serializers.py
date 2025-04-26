from rest_framework import serializers
from django.contrib.auth.models import User
from .models import UserProfile, UserDetails

class UserProfileSerializer(serializers.ModelSerializer):
    class Meta:
        model = UserProfile
        fields = ('id', 'bio', 'profile_image', 'date_joined')
        read_only_fields = ('date_joined',)

class UserSerializer(serializers.ModelSerializer):
    profile = UserProfileSerializer(read_only=True)
    
    class Meta:
        model = User
        fields = ('id', 'username', 'email', 'first_name', 'last_name', 'profile')
        read_only_fields = ('email',)

class UserDetailsSerializer(serializers.ModelSerializer):
    class Meta:
        model = UserDetails
        fields = ('id', 'age', 'height', 'current_weight', 'gender', 'activity_level', 'goal_weight')