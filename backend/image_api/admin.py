from django.contrib import admin
from .models import ImageUpload, PredictionFeedback

@admin.register(ImageUpload)
class ImageUploadAdmin(admin.ModelAdmin):
    list_display = ('id', 'user', 'prediction', 'timestamp')
    list_filter = ('user', 'prediction')
    search_fields = ('id', 'user__username', 'prediction')
    readonly_fields = ('timestamp', 'prediction_id')

@admin.register(PredictionFeedback)
class PredictionFeedbackAdmin(admin.ModelAdmin):
    list_display = ('id', 'user', 'timestamp')
    list_filter = ('user',)
    search_fields = ('id', 'user__username',)
    readonly_fields = ('timestamp',)