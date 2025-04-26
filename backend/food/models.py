from django.db import models
from django.contrib.auth.models import User

class DailyGoal(models.Model):
    """Daily nutritional goals for a user"""
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='daily_goal')
    calories = models.IntegerField()
    protein = models.FloatField(help_text="Protein in grams")
    carbohydrates = models.FloatField(help_text="Carbohydrates in grams")
    fat = models.FloatField(help_text="Fat in grams")
    
    def __str__(self):
        return f"{self.user.username}'s Daily Goals"

class WaterIntake(models.Model):
    """Track water intake with timestamp"""
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='water_intake')
    amount = models.FloatField(help_text="Water amount in ml")
    timestamp = models.DateTimeField(auto_now_add=True)
    
    def __str__(self):
        return f"{self.user.username}'s Water Intake on {self.timestamp}"

class FoodConsumption(models.Model):
    """Track food consumption with details"""
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='food_consumption')
    food_index = models.IntegerField(help_text="Index of food in CSV file", default=0)
    food_id = models.CharField(max_length=50, blank=True, help_text="Food code identifier")
    food_name = models.CharField(max_length=255)
    calories = models.FloatField()
    protein = models.FloatField()
    carbohydrates = models.FloatField()
    fat = models.FloatField()
    timestamp = models.DateTimeField(auto_now_add=True)
    
    def __str__(self):
        return f"{self.user.username} consumed {self.food_name} on {self.timestamp}"
