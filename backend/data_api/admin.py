from django.contrib import admin
from .models import DataEntry

@admin.register(DataEntry)
class DataEntryAdmin(admin.ModelAdmin):
    list_display = ('id', 'user', 'timestamp')
    list_filter = ('user',)
    search_fields = ('id', 'user__username')
    readonly_fields = ('timestamp',)