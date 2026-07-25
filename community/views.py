from rest_framework import viewsets
from rest_framework.generics import CreateAPIView

from .models import Alert, Business, CommunityTip, CouncilAgenda, Event, NewsItem
from .serializers import (
    AlertSerializer,
    BusinessSerializer,
    CommunityTipSerializer,
    CouncilAgendaSerializer,
    EventSerializer,
    NewsItemSerializer,
)


class NewsItemViewSet(viewsets.ReadOnlyModelViewSet):
    """Public API — only returns approved news items, newest first."""

    queryset = NewsItem.objects.filter(is_approved=True)
    serializer_class = NewsItemSerializer
    ordering = ["-created_at"]


class EventViewSet(viewsets.ReadOnlyModelViewSet):
    """Public API — only returns approved events, ordered by start date."""

    queryset = Event.objects.filter(is_approved=True)
    serializer_class = EventSerializer
    ordering = ["start_date"]


class BusinessViewSet(viewsets.ReadOnlyModelViewSet):
    """Public API — only returns approved businesses."""

    queryset = Business.objects.filter(is_approved=True)
    serializer_class = BusinessSerializer
    ordering = ["name"]


class TipCreateView(CreateAPIView):
    """Public submission endpoint — no auth required."""

    queryset = CommunityTip.objects.all()
    serializer_class = CommunityTipSerializer


class AlertViewSet(viewsets.ReadOnlyModelViewSet):
    """Public API — only returns active alerts, newest first."""

    queryset = Alert.objects.filter(is_active=True)
    serializer_class = AlertSerializer
    ordering = ["-created_at"]


class CouncilAgendaViewSet(viewsets.ReadOnlyModelViewSet):
    """Public API — only returns approved agendas, newest meeting first."""

    queryset = CouncilAgenda.objects.filter(is_approved=True)
    serializer_class = CouncilAgendaSerializer
    ordering = ["-meeting_date"]
