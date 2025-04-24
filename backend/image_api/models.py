from django.db import models
import uuid
from django.contrib.auth.models import User

def image_upload_path(instance, filename):
    ext = filename.split('.')[-1]
    filename = f"{uuid.uuid4()}.{ext}"
    return f"images/{filename}"

class ImageUpload(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='image_uploads')
    image = models.ImageField(upload_to=image_upload_path)
    timestamp = models.DateTimeField(auto_now_add=True)
    prediction = models.CharField(max_length=255, null=True, blank=True)
    prediction_id = models.UUIDField(default=uuid.uuid4, editable=False)
    
    def __str__(self):
        return f"Image {self.id} - {self.prediction or 'No prediction'}"

class PredictionFeedback(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='prediction_feedbacks')
    # image = models.ForeignKey(ImageUpload, on_delete=models.CASCADE, related_name='feedbacks')
    feedback_data = models.CharField(max_length=255)
    timestamp = models.DateTimeField(auto_now_add=True)
    
    def __str__(self):
        return f"Feedback for Image {self.image.id}"