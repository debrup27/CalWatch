from django.db import models
from django.contrib.auth.models import User

class DataEntry(models.Model):
    """Model for storing JSON data with timestamp"""
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='data_entries')
    timestamp = models.DateTimeField(auto_now_add=True)
    protein = models.DecimalField(max_digits=7, decimal_places=3)
    carbs = models.DecimalField(max_digits=7, decimal_places=3)
    fat = models.DecimalField(max_digits=7, decimal_places=3)
    vitamins = models.DecimalField(max_digits=7, decimal_places=3)
    minerals = models.DecimalField(max_digits=7, decimal_places=3)

    def __str__(self):
        return f"DataEntry {self.id} - {self.timestamp}"

# Create your models here.
