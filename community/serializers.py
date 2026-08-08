from rest_framework import serializers

from .models import Alert, Business, CommunityTip, CouncilAgenda, Event, NewsItem, School, WeatherInfo


class MediaUrlMixin:
    """Serialize image/video fields as absolute URLs (or None)."""

    def _abs(self, field_name):
        value = getattr(self.instance, field_name, None) if self.instance else None
        if not value:
            return None
        request = self.context.get("request")
        if request is not None:
            return request.build_absolute_uri(value.url)
        return value.url


class NewsItemSerializer(serializers.ModelSerializer, MediaUrlMixin):
    image_url = serializers.SerializerMethodField()
    video_url = serializers.SerializerMethodField()

    class Meta:
        model = NewsItem
        fields = "__all__"
        read_only_fields = ["id", "title", "content", "source_url", "image", "video",
                            "is_approved", "featured", "created_at", "updated_at"]

    def get_image_url(self, obj):
        return self._abs("image")

    def get_video_url(self, obj):
        return self._abs("video")


class EventSerializer(serializers.ModelSerializer, MediaUrlMixin):
    image_url = serializers.SerializerMethodField()

    class Meta:
        model = Event
        fields = "__all__"
        read_only_fields = ["id", "title", "description", "location", "image",
                            "start_date", "end_date", "category", "is_approved", "created_at"]

    def get_image_url(self, obj):
        return self._abs("image")


class BusinessSerializer(serializers.ModelSerializer, MediaUrlMixin):
    image_url = serializers.SerializerMethodField()

    class Meta:
        model = Business
        fields = "__all__"
        read_only_fields = ["id", "name", "description", "category", "image",
                            "contact_phone", "contact_email", "website", "address",
                            "is_home_based", "is_featured", "is_approved", "created_at"]

    def get_image_url(self, obj):
        return self._abs("image")


class CommunityTipSerializer(serializers.ModelSerializer):
    name = serializers.CharField(write_only=True, required=False, allow_blank=True)
    email = serializers.EmailField(write_only=True, required=False, allow_blank=True)

    class Meta:
        model = CommunityTip
        fields = "__all__"
        read_only_fields = ["is_approved", "created_at"]

    def create(self, validated_data):
        if "name" in validated_data:
            validated_data["submitter_name"] = validated_data.pop("name")
        if "email" in validated_data:
            validated_data["submitter_email"] = validated_data.pop("email")
        return super().create(validated_data)


class AlertSerializer(serializers.ModelSerializer, MediaUrlMixin):
    image_url = serializers.SerializerMethodField()

    class Meta:
        model = Alert
        fields = "__all__"
        read_only_fields = ["id", "title", "message", "severity", "image", "is_active", "created_at"]

    def get_image_url(self, obj):
        return self._abs("image")


class CouncilAgendaSerializer(serializers.ModelSerializer):
    class Meta:
        model = CouncilAgenda
        fields = "__all__"
        read_only_fields = ["id", "title", "description", "meeting_date", "pdf_url", "created_at"]


class SchoolSerializer(serializers.ModelSerializer):
    class Meta:
        model = School
        fields = "__all__"
        read_only_fields = ["id", "created_at"]


class WeatherInfoSerializer(serializers.ModelSerializer):
    class Meta:
        model = WeatherInfo
        fields = "__all__"
        read_only_fields = ["id", "created_at"]
