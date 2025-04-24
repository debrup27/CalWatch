from django.urls import path
from .views import (
    DailyGoalView, WaterIntakeView, food_autocomplete, get_food, AddFoodView
)

app_name = 'food'

urlpatterns = [
    path('dailyGoal/', DailyGoalView.as_view(), name='daily-goal'),
    path('waterIntake/', WaterIntakeView.as_view(), name='water-intake'),
    path('foodAutocomplete/', food_autocomplete, name='food-autocomplete'),
    path('getFood/', get_food, name='get-food'),
    path('addFood/', AddFoodView.as_view(), name='add-food'),
] 