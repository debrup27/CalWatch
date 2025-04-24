from rest_framework import generics, permissions, status
from rest_framework.response import Response
from django.contrib.auth.models import User
from django.http import Http404
from .models import UserProfile, UserDetails
from .serializers import UserSerializer, UserProfileSerializer, UserDetailsSerializer
from .caloriecalc import calculate_daily_goals
import sys
from pathlib import Path

# Add the food app to the Python path
BASE_DIR = Path(__file__).resolve().parent.parent
sys.path.append(str(BASE_DIR))
from food.models import DailyGoal
from food.serializers import DailyGoalSerializer

class UserDetailView(generics.RetrieveAPIView):
    """API endpoint to get user details"""
    serializer_class = UserSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def get_object(self):
        return self.request.user

class UserProfileView(generics.RetrieveUpdateAPIView):
    """API endpoint to get and update user profile"""
    serializer_class = UserProfileSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def get_object(self):
        return self.request.user.profile

class UserDetailsView(generics.GenericAPIView):
    """API endpoint to get, create, and update user details"""
    serializer_class = UserDetailsSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def get_object(self):
        try:
            return UserDetails.objects.get(user=self.request.user)
        except UserDetails.DoesNotExist:
            return None
    
    def get(self, request, *args, **kwargs):
        instance = self.get_object()
        if instance:
            serializer = self.get_serializer(instance)
            return Response(serializer.data)
        return Response({"detail": "User details not found"}, status=status.HTTP_404_NOT_FOUND)
    
    def post(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        
        # Use update_or_create instead of save to handle existing records
        user_details, created = UserDetails.objects.update_or_create(
            user=request.user,
            defaults=serializer.validated_data
        )
        
        # Calculate daily goals
        daily_goals = calculate_daily_goals(
            user_details.gender,
            user_details.age,
            user_details.current_weight,
            user_details.height,
            user_details.activity_level,
            user_details.goal_weight
        )
        
        # Create or update the daily goals
        DailyGoal.objects.update_or_create(
            user=request.user,
            defaults={
                'calories': daily_goals['calories'],
                'protein': daily_goals['protein'],
                'carbohydrates': daily_goals['carbohydrates'],
                'fat': daily_goals['fat']
            }
        )
        
        # Return the response
        daily_goal_instance = DailyGoal.objects.get(user=request.user)
        daily_goal_serializer = DailyGoalSerializer(daily_goal_instance)
        
        return Response({
            'user_details': self.get_serializer(user_details).data,
            'daily_goals': daily_goal_serializer.data
        }, status=status.HTTP_201_CREATED)
    
    def patch(self, request, *args, **kwargs):
        instance = self.get_object()
        if not instance:
            return Response({"detail": "User details not found"}, status=status.HTTP_404_NOT_FOUND)
        
        serializer = self.get_serializer(instance, data=request.data, partial=True)
        serializer.is_valid(raise_exception=True)
        self.perform_update(serializer)
        
        # Recalculate daily goals
        user_details = instance
        daily_goals = calculate_daily_goals(
            user_details.gender,
            user_details.age,
            user_details.current_weight,
            user_details.height,
            user_details.activity_level,
            user_details.goal_weight
        )
        
        # Update the daily goals
        DailyGoal.objects.update_or_create(
            user=request.user,
            defaults={
                'calories': daily_goals['calories'],
                'protein': daily_goals['protein'],
                'carbohydrates': daily_goals['carbohydrates'],
                'fat': daily_goals['fat']
            }
        )
        
        # Return the response
        daily_goal_instance = DailyGoal.objects.get(user=request.user)
        daily_goal_serializer = DailyGoalSerializer(daily_goal_instance)
        
        return Response({
            'user_details': serializer.data,
            'daily_goals': daily_goal_serializer.data
        })
        
    def perform_update(self, serializer):
        serializer.save()