from rest_framework import serializers
from .models import DailyGoal, WaterIntake, FoodConsumption

class DailyGoalSerializer(serializers.ModelSerializer):
    class Meta:
        model = DailyGoal
        fields = ('id', 'calories', 'protein', 'carbohydrates', 'fat')
        read_only_fields = ('id',)

class WaterIntakeSerializer(serializers.ModelSerializer):
    class Meta:
        model = WaterIntake
        fields = ('id', 'amount', 'timestamp')
        read_only_fields = ('id', 'timestamp')

class FoodConsumptionSerializer(serializers.ModelSerializer):
    class Meta:
        model = FoodConsumption
        # fields = "__all__"

        fields = ('id', 'food_index', 'food_id', 'food_name', 'calories', 'protein', 'carbohydrates', 'fat', 'timestamp')
        read_only_fields = ('id', 'timestamp') 