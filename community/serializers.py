from rest_framework import serializers

from .models import Business, CommunityTip, Event, NewsItem


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
