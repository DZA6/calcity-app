from django.contrib import admin

from .models import Business, CommunityTip, Event, NewsItem


@admin.register(NewsItem)
class NewsItemAdmin(admin.ModelAdmin):
    list_display = ("title", "is_approved", "featured", "created_at", "updated_at")
    list_filter = ("is_approved", "featured", "created_at")
    search_fields = ("title", "content")
    list_editable = ("is_approved", "featured")


@admin.register(Event)
class EventAdmin(admin.ModelAdmin):
    list_display = ("title", "category", "start_date", "end_date", "location", "is_approved")
    list_filter = ("category", "is_approved", "start_date")
    search_fields = ("title", "description", "location")
    list_editable = ("is_approved",)


@admin.register(Business)
class BusinessAdmin(admin.ModelAdmin):
    list_display = (
        "name",
        "category",
        "contact_phone",
        "contact_email",
        "is_home_based",
        "is_featured",
        "is_approved",
    )
    list_filter = ("category", "is_home_based", "is_featured", "is_approved")
    search_fields = ("name", "description", "contact_email", "address")
    list_editable = ("is_home_based", "is_featured", "is_approved")


@admin.register(CommunityTip)
class TipAdmin(admin.ModelAdmin):
    list_display = ("__str__", "category", "submitter_name", "submitter_email", "is_approved", "created_at")
    list_filter = ("category", "is_approved", "created_at")
    search_fields = ("content", "submitter_name", "submitter_email")
    list_editable = ("is_approved",)
