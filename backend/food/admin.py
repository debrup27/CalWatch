from django.contrib import admin
from .models import DailyGoal, WaterIntake, FoodConsumption

admin.site.register(DailyGoal)
admin.site.register(WaterIntake)
admin.site.register(FoodConsumption)
