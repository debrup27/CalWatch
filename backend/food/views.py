from django.shortcuts import render
from rest_framework import generics, permissions, status
from rest_framework.response import Response
from django.http import Http404, JsonResponse
from .models import DailyGoal, WaterIntake, FoodConsumption
from .serializers import DailyGoalSerializer, WaterIntakeSerializer, FoodConsumptionSerializer
from .food_data import search_food, get_food_by_index, get_food_by_id
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated

# Create your views here.

class DailyGoalView(generics.RetrieveAPIView):
    """API endpoint to get user's daily goals"""
    serializer_class = DailyGoalSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def get_object(self):
        try:
            return DailyGoal.objects.get(user=self.request.user)
        except DailyGoal.DoesNotExist:
            raise Http404("Daily goals not found")

class WaterIntakeView(generics.ListCreateAPIView):
    """API endpoint to list and create water intake records"""
    serializer_class = WaterIntakeSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def get_queryset(self):
        return WaterIntake.objects.filter(user=self.request.user).order_by('-timestamp')
    
    def perform_create(self, serializer):
        serializer.save(user=self.request.user)

@api_view(['GET'])
def food_autocomplete(request):
    """
    API endpoint for food autocomplete search
    
    URL Parameters:
    - q: Search query
    
    Returns:
    - List of food items matching the query
    """
    query = request.GET.get('q', '')
    
    if not query:
        return Response({'results': []})
    
    results = search_food(query)
    return Response({'results': results})

@api_view(['GET'])
def get_food(request):
    """
    API endpoint to get food details by ID or index
    
    URL Parameters:
    - id: Food ID
    - index: Food index (alternative to ID)
    
    Returns:
    - Food details or error message
    """
    food_id = request.GET.get('id')
    food_index = request.GET.get('index')
    
    # Check if neither id nor index is provided
    if not food_id and not food_index:
        return Response(
            {'error': 'Missing required parameter: either id or index must be provided'},
            status=status.HTTP_400_BAD_REQUEST
        )
    
    # If index is provided, try to convert it to integer
    if food_index:
        try:
            food_index = int(food_index)
            food = get_food_by_index(food_index)
        except ValueError:
            return Response(
                {'error': 'Invalid index format'},
                status=status.HTTP_400_BAD_REQUEST
            )
    else:
        # Otherwise, use the ID
        food = get_food_by_id(food_id)
    
    # Check if food was found
    if not food:
        return Response(
            {'error': 'Food not found'},
            status=status.HTTP_404_NOT_FOUND
        )
    
    return Response(food)

class AddFoodView(generics.CreateAPIView):
    """API endpoint to add food consumption"""
    serializer_class = FoodConsumptionSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def create(self, request, *args, **kwargs):
        try:
            # Handle food lookup by ID (preferred) or by index
            food_id = request.data.get('food_id', None)
            food_index = int(request.data.get('food_index', 0))
            
            food_details = None
            if food_id:
                food_details = get_food_by_id(food_id)
            elif food_index > 0:
                food_details = get_food_by_index(food_index)
            
            if not food_details:
                return Response({"detail": "Food not found"}, status=status.HTTP_404_NOT_FOUND)
            
            # Create food consumption entry
            consumption_data = {
                'food_index': food_index if food_index > 0 else 0,
                'food_id': food_id if food_id else food_details.get('food_code', ''),
                'food_name': food_details.get('food_name', 'Unknown Food'),
                'calories': float(food_details.get('nutrients', {}).get('calories', 0)),
                'protein': float(food_details.get('nutrients', {}).get('protein', 0)),
                'carbohydrates': float(food_details.get('nutrients', {}).get('carbs', 0)),
                'fat': float(food_details.get('nutrients', {}).get('fat', 0))
            }
            
            serializer = self.get_serializer(data=consumption_data)
            serializer.is_valid(raise_exception=True)
            serializer.save(user=request.user)
            
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        except ValueError:
            return Response({"detail": "Invalid data format"}, status=status.HTTP_400_BAD_REQUEST)
