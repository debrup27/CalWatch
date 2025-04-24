from rest_framework import serializers
from .models import DataEntry

class DataEntrySerializer(serializers.ModelSerializer):
    class Meta:
        model = DataEntry
        fields = ['id', 'data', 'timestamp']
        read_only_fields = ['timestamp']