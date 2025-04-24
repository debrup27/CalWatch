from rest_framework import serializers
from .models import ImageUpload, PredictionFeedback

class ImageUploadSerializer(serializers.ModelSerializer):
    image_url = serializers.SerializerMethodField()
    
    class Meta:
        model = ImageUpload
        fields = ['id', 'image', 'image_url', 'timestamp', 'prediction', 'prediction_id']
        read_only_fields = ['timestamp', 'prediction', 'prediction_id', 'image_url']
    
    def get_image_url(self, obj):
        request = self.context.get('request')
        if obj.image and hasattr(obj.image, 'url') and request:
            return request.build_absolute_uri(obj.image.url)
        return None

class PredictionFeedbackSerializer(serializers.ModelSerializer):
    class Meta:
        model = PredictionFeedback
        fields = ['id', 'feedback_data', 'timestamp']
        read_only_fields = ['timestamp']