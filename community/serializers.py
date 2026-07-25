from rest_framework import serializers

from .models import Alert, Business, CommunityTip, CouncilAgenda, Event, NewsItem


class NewsItemSerializer(serializers.ModelSerializer):
    class Meta:
        model = NewsItem
        fields = "__all__"
        read_only_fields = fields


class EventSerializer(serializers.ModelSerializer):
    class Meta:
        model = Event
        fields = "__all__"
        read_only_fields = fields


class BusinessSerializer(serializers.ModelSerializer):
    class Meta:
        model = Business
        fields = "__all__"
        read_only_fields = fields


class CommunityTipSerializer(serializers.ModelSerializer):
    class Meta:
        model = CommunityTip
        fields = "__all__"
        read_only_fields = ["is_approved", "created_at"]


class AlertSerializer(serializers.ModelSerializer):
    class Meta:
        model = Alert
        fields = "__all__"
        read_only_fields = ["id", "title", "message", "severity", "is_active", "created_at"]


class CouncilAgendaSerializer(serializers.ModelSerializer):
    class Meta:
        model = CouncilAgenda
        fields = "__all__"
        read_only_fields = ["id", "title", "description", "meeting_date", "pdf_url", "created_at"]
