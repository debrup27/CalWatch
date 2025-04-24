from django.db import models

# Create your models here.
class DataEntry(models.Model):
    """Model for storing JSON data with timestamp"""
    data = models.JSONField()
    timestamp = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"DataEntry {self.id} - {self.timestamp}"