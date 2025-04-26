'''from rest_framework import status, generics, permissions
from rest_framework.response import Response
from rest_framework.parsers import MultiPartParser, FormParser
from .models import ImageUpload, PredictionFeedback
from .serializers import ImageUploadSerializer, PredictionFeedbackSerializer
from .prediction import predict_image_content, get_nutrition_by_dish
from .searchNutrients import get_row_as_json

class ImageUploadView(generics.CreateAPIView):
    """API endpoint for uploading and processing images"""
    serializer_class = ImageUploadSerializer
    parser_classes = (MultiPartParser, FormParser)
    permission_classes = [permissions.IsAuthenticated]
    
    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        
        # Save the image upload with the authenticated user
        instance = serializer.save(user=request.user)
        
        # Get the path to the saved image
        image_path = instance.image.path
        
        # Use the prediction service to analyze the image
        prediction_result = predict_image_content(image_path)
        
        # Update the instance with the prediction
        instance.prediction = prediction_result['class']
        instance.save()
        
        # Return the updated instance data
        response_serializer = self.get_serializer(instance)
        response_data = response_serializer.data
        response_data.update({
            'prediction_detail': prediction_result
        })
        
        return Response(response_data, status=status.HTTP_201_CREATED)

class PredictionFeedbackView(generics.CreateAPIView):
    """API endpoint for submitting feedback on predictions"""
    serializer_class = PredictionFeedbackSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    # def perform_create(self, request):
    def create(self, request):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        
        # Associate the feedback with the authenticated user
        instance = serializer.save(user=self.request.user)
        response_data = get_nutrition_by_dish(instance.feedback_data)
        return Response(response_data, status=status.HTTP_201_CREATED)


class UserImageListView(generics.ListAPIView):
    """API endpoint to fetch all images uploaded by the current user"""
    serializer_class = ImageUploadSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def get_queryset(self):
        return ImageUpload.objects.filter(user=self.request.user).order_by('-timestamp')
        '''