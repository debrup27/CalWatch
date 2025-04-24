from django.db import models
from django.contrib.auth.models import User
from django.db.models.signals import post_save
from django.dispatch import receiver

class UserProfile(models.Model):
    """Extended user profile with additional information"""
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='profile')
    bio = models.TextField(max_length=500, blank=True)
    profile_image = models.ImageField(upload_to='profile_images/', null=True, blank=True)
    date_joined = models.DateTimeField(auto_now_add=True)
    
    def __str__(self):
        return f"{self.user.username}'s Profile"

class UserDetails(models.Model):
    """User details for calorie calculation"""
    GENDER_CHOICES = [
        ('M', 'Male'),
        ('F', 'Female'),
    ]
    ACTIVITY_CHOICES = [
        ('sedentary', 'Sedentary'),
        ('medium', 'Medium'),
        ('high', 'High'),
    ]
    
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='details')
    age = models.IntegerField()
    height = models.FloatField(help_text="Height in cm")
    current_weight = models.FloatField(help_text="Weight in kg")
    gender = models.CharField(max_length=1, choices=GENDER_CHOICES)
    activity_level = models.CharField(max_length=10, choices=ACTIVITY_CHOICES)
    goal_weight = models.FloatField(help_text="Goal weight in kg")
    
    def __str__(self):
        return f"{self.user.username}'s Details"

# Signal to create a profile when a user is created
@receiver(post_save, sender=User)
def create_user_profile(sender, instance, created, **kwargs):
    if created:
        UserProfile.objects.create(user=instance)

@receiver(post_save, sender=User)
def save_user_profile(sender, instance, **kwargs):
    instance.profile.save()