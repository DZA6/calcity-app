from django.contrib import admin
from django.utils.html import format_html

from .models import Alert, Business, CommunityTip, CouncilAgenda, Event, NewsItem


def _thumb(obj, field_name, size=60):
    """Render a small preview thumbnail for an ImageField (or '-' if none)."""
    field = getattr(obj, field_name, None)
    if not field:
        return "-"
    try:
        return format_html(
            '<img src="{}" style="max-height:{}px;border-radius:4px;" />',
            field.url,
            size,
        )
    except Exception:
        return "-"


@admin.register(Alert)
class AlertAdmin(admin.ModelAdmin):
    list_display = ("title", "severity", "image_thumb", "is_active", "created_at")
    list_filter = ("severity", "is_active", "created_at")
    search_fields = ("title", "message")
    list_editable = ("is_active",)

    def image_thumb(self, obj):
        return _thumb(obj, "image")

    image_thumb.short_description = "Image"


@admin.register(CouncilAgenda)
class CouncilAgendaAdmin(admin.ModelAdmin):
    list_display = ("title", "meeting_date", "is_approved", "created_at")
    list_filter = ("is_approved", "meeting_date")
    search_fields = ("title", "description")


@admin.register(NewsItem)
class NewsItemAdmin(admin.ModelAdmin):
    list_display = ("title", "image_thumb", "video_thumb", "is_approved", "featured", "created_at", "updated_at")
    list_filter = ("is_approved", "featured", "created_at")
    search_fields = ("title", "content")
    list_editable = ("is_approved", "featured")

    def image_thumb(self, obj):
        return _thumb(obj, "image")

    def video_thumb(self, obj):
        return "🎬" if getattr(obj, "video", None) else "-"

    image_thumb.short_description = "Image"
    video_thumb.short_description = "Video"


@admin.register(Event)
class EventAdmin(admin.ModelAdmin):
    list_display = ("title", "category", "image_thumb", "start_date", "end_date", "location", "is_approved")
    list_filter = ("category", "is_approved", "start_date")
    search_fields = ("title", "description", "location")
    list_editable = ("is_approved",)

    def image_thumb(self, obj):
        return _thumb(obj, "image")

    image_thumb.short_description = "Image"


@admin.register(Business)
class BusinessAdmin(admin.ModelAdmin):
    list_display = (
        "name",
        "category",
        "image_thumb",
        "contact_phone",
        "contact_email",
        "is_home_based",
        "is_featured",
        "is_approved",
    )
    list_filter = ("category", "is_home_based", "is_featured", "is_approved")
    search_fields = ("name", "description", "contact_email", "address")
    list_editable = ("is_home_based", "is_featured", "is_approved")

    def image_thumb(self, obj):
        return _thumb(obj, "image")

    image_thumb.short_description = "Image"


@admin.register(CommunityTip)
class TipAdmin(admin.ModelAdmin):
    list_display = ("__str__", "category", "submitter_name", "submitter_email", "is_approved", "created_at")
    list_filter = ("category", "is_approved", "created_at")
    search_fields = ("content", "submitter_name", "submitter_email")
    list_editable = ("is_approved",)
