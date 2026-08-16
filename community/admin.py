from django.contrib import admin
from django.utils.html import format_html

from .models import (
    Alert,
    Business,
    BusinessReview,
    Church,
    Comment,
    CommunityTip,
    CouncilAgenda,
    Deal,
    DiscussionTopic,
    Event,
    FeaturedPlacement,
    NewsItem,
    Reaction,
    School,
    WeatherInfo,
)


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
    list_display = ("title", "category", "image_thumb", "video_thumb", "is_approved", "featured", "created_at", "updated_at")
    list_filter = ("is_approved", "featured", "category", "created_at")
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


@admin.register(BusinessReview)
class BusinessReviewAdmin(admin.ModelAdmin):
    list_display = ("business", "author", "rating", "body_short", "is_hidden", "created_at")
    list_filter = ("rating", "is_hidden")
    search_fields = ("business__name", "author__username", "body")
    list_editable = ("is_hidden",)
    raw_id_fields = ("business", "author")

    @admin.display(description="Review")
    def body_short(self, obj):
        return obj.body[:60] + ("\u2026" if len(obj.body) > 60 else "")


@admin.register(CommunityTip)
class TipAdmin(admin.ModelAdmin):
    list_display = ("__str__", "category", "submitter_name", "submitter_email", "is_approved", "created_at")
    list_filter = ("category", "is_approved", "created_at")
    search_fields = ("content", "submitter_name", "submitter_email")
    list_editable = ("is_approved",)


@admin.register(WeatherInfo)
class WeatherInfoAdmin(admin.ModelAdmin):
    list_display = ("headline", "temperature_high", "temperature_low", "humidity", "wind", "is_active", "created_at")
    list_filter = ("is_active",)
    list_editable = ("is_active",)


@admin.register(School)
class SchoolAdmin(admin.ModelAdmin):
    list_display = ("name", "type", "phone", "is_approved", "created_at")
    list_filter = ("type", "is_approved")
    search_fields = ("name", "description", "address")
    list_editable = ("is_approved",)


@admin.register(Church)
class ChurchAdmin(admin.ModelAdmin):
    list_display = ("name", "denomination", "phone", "is_approved", "created_at")
    list_filter = ("denomination", "is_approved")
    search_fields = ("name", "description", "address", "denomination")
    list_editable = ("is_approved",)


@admin.register(FeaturedPlacement)
class FeaturedPlacementAdmin(admin.ModelAdmin):
    list_display = ("business", "headline", "is_active", "is_paid", "start_date", "end_date")
    list_filter = ("is_active", "is_paid")
    list_editable = ("is_active", "is_paid")
    raw_id_fields = ("business",)


@admin.register(Deal)
class DealAdmin(admin.ModelAdmin):
    list_display = ("title", "business", "discount", "is_active", "expiry_date")
    list_filter = ("is_active",)
    list_editable = ("is_active",)
    raw_id_fields = ("business",)


@admin.register(DiscussionTopic)
class DiscussionTopicAdmin(admin.ModelAdmin):
    list_display = ("title", "author", "category", "is_pinned", "is_closed", "created_at")
    list_filter = ("category", "is_pinned", "is_closed", "created_at")
    search_fields = ("title", "body", "author__username")
    list_editable = ("is_pinned", "is_closed")
    raw_id_fields = ("author",)


@admin.register(Comment)
class CommentAdmin(admin.ModelAdmin):
    list_display = ("author", "content_type", "object_id", "body_short", "is_hidden", "created_at")
    list_filter = ("is_hidden", "content_type", "created_at")
    search_fields = ("body", "author__username")
    list_editable = ("is_hidden",)
    raw_id_fields = ("author", "parent")

    @admin.display(description="Comment")
    def body_short(self, obj):
        return obj.body[:60] + ("…" if len(obj.body) > 60 else "")


@admin.register(Reaction)
class ReactionAdmin(admin.ModelAdmin):
    list_display = ("user", "value", "content_type", "object_id", "created_at")
    list_filter = ("value", "content_type")
    search_fields = ("user__username",)
    raw_id_fields = ("user",)
