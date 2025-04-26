# data_api/views.py

from rest_framework import status, generics
from rest_framework.response import Response
from .models import DataEntry
from .serializers import DataEntrySerializer
from django.utils.dateparse import parse_datetime
from django.utils import timezone
from rest_framework.exceptions import ValidationError

class DataEntryCreateView(generics.CreateAPIView):
    """API endpoint for creating a new data entry"""
    queryset = DataEntry.objects.all()
    serializer_class = DataEntrySerializer
    
    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        self.perform_create(serializer)
        headers = self.get_success_headers(serializer.data)
        return Response(serializer.data, status=status.HTTP_201_CREATED, headers=headers)

class DataEntryListByDateView(generics.ListAPIView):
    """API endpoint to fetch data entries within a date range"""
    serializer_class = DataEntrySerializer
    
    def get_queryset(self):
        start_date = self.request.query_params.get('start_date')
        end_date = self.request.query_params.get('end_date')
        
        if not start_date or not end_date:
            raise ValidationError("Both start_date and end_date are required query parameters")
        
        # Parse the date strings to datetime objects
        try:
            start_datetime = parse_datetime(start_date)
            end_datetime = parse_datetime(end_date)
            
            if not start_datetime:
                start_datetime = timezone.make_aware(timezone.datetime.strptime(start_date, "%Y-%m-%d"))
            if not end_datetime:
                # Add one day to end_date to include the whole day
                end_datetime = timezone.make_aware(timezone.datetime.strptime(end_date, "%Y-%m-%d"))
                end_datetime = end_datetime.replace(hour=23, minute=59, second=59)
        
        except (ValueError, TypeError):
            raise ValidationError("Invalid date format. Use YYYY-MM-DD or YYYY-MM-DDThh:mm:ss format")
        
        # Filter queryset based on the date range
        return DataEntry.objects.filter(timestamp__gte=start_datetime, timestamp__lte=end_datetime)