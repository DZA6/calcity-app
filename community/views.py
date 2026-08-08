from rest_framework import viewsets
from rest_framework.generics import CreateAPIView
from rest_framework.permissions import AllowAny
from rest_framework.authtoken.models import Token
from rest_framework.response import Response
from rest_framework import status
from rest_framework.pagination import PageNumberPagination

from .models import Alert, Business, CommunityTip, CouncilAgenda, Deal, Event, FeaturedPlacement, NewsItem, School, WeatherInfo
from .serializers import (
    AlertSerializer,
    BusinessSerializer,
    CommunityTipSerializer,
    CouncilAgendaSerializer,
    DealSerializer,
    EventSerializer,
    FeaturedPlacementSerializer,
    NewsItemSerializer,
    SchoolSerializer,
    WeatherInfoSerializer,
)


class NewsItemViewSet(viewsets.ReadOnlyModelViewSet):
    """Public API — only returns approved news items, newest first."""

    queryset = NewsItem.objects.filter(is_approved=True)
    serializer_class = NewsItemSerializer
    pagination_class = None
    ordering = ["-created_at"]


class EventViewSet(viewsets.ReadOnlyModelViewSet):
    """Public API — only returns approved events, ordered by start date."""

    queryset = Event.objects.filter(is_approved=True)
    serializer_class = EventSerializer
    pagination_class = None
    ordering = ["start_date"]


class BusinessViewSet(viewsets.ReadOnlyModelViewSet):
    """Public API — only returns approved businesses."""

    queryset = Business.objects.filter(is_approved=True)
    serializer_class = BusinessSerializer
    pagination_class = None
    ordering = ["name"]


class TipCreateView(CreateAPIView):
    """Public submission endpoint — no auth required."""

    queryset = CommunityTip.objects.all()
    serializer_class = CommunityTipSerializer


class AlertViewSet(viewsets.ReadOnlyModelViewSet):
    """Public API — only returns active alerts, newest first."""

    queryset = Alert.objects.filter(is_active=True)
    serializer_class = AlertSerializer
    pagination_class = None
    ordering = ["-created_at"]


class CouncilAgendaViewSet(viewsets.ReadOnlyModelViewSet):
    """Public API — only returns approved agendas, newest meeting first."""

    queryset = CouncilAgenda.objects.filter(is_approved=True)
    serializer_class = CouncilAgendaSerializer
    pagination_class = None
    ordering = ["-meeting_date"]


class CategoryNewsViewSet(viewsets.ReadOnlyModelViewSet):
    """News filtered by category slug: /api/news/?category=church or /api/category/church/."""

    serializer_class = NewsItemSerializer
    pagination_class = None
    ordering = ["-created_at"]

    def get_queryset(self):
        qs = NewsItem.objects.filter(is_approved=True)
        cat = self.request.query_params.get("category")
        if cat:
            qs = qs.filter(category=cat)
        return qs


class SchoolViewSet(viewsets.ReadOnlyModelViewSet):
    """Public API — only returns approved schools."""

    queryset = School.objects.filter(is_approved=True)
    serializer_class = SchoolSerializer
    pagination_class = None
    ordering = ["type", "name"]


class WeatherInfoViewSet(viewsets.ReadOnlyModelViewSet):
    """Latest weather update — only the most recent active one."""

    queryset = WeatherInfo.objects.filter(is_active=True)[:1]
    serializer_class = WeatherInfoSerializer
    pagination_class = None
    ordering = ["-created_at"]


class RegisterView(CreateAPIView):
    """Create a new user account. Returns an auth token."""
    permission_classes = [AllowAny]

    def create(self, request, *args, **kwargs):
        from django.contrib.auth.models import User
        username = request.data.get("username", "").strip()
        email = request.data.get("email", "").strip()
        password = request.data.get("password", "")

        if not username or not password:
            return Response(
                {"error": "Username and password are required."},
                status=status.HTTP_400_BAD_REQUEST,
            )
        if User.objects.filter(username=username).exists():
            return Response(
                {"error": "That username is already taken."},
                status=status.HTTP_409_CONFLICT,
            )
        if email and User.objects.filter(email=email).exists():
            return Response(
                {"error": "An account with that email already exists."},
                status=status.HTTP_409_CONFLICT,
            )

        user = User.objects.create_user(username=username, email=email, password=password)
        token, _ = Token.objects.get_or_create(user=user)
        return Response(
            {"token": token.key, "username": user.username, "email": user.email},
            status=status.HTTP_201_CREATED,
        )


class FeaturedPlacementViewSet(viewsets.ReadOnlyModelViewSet):
    """Active paid promotions — latest first."""
    queryset = FeaturedPlacement.objects.filter(is_active=True, is_paid=True).select_related("business")
    serializer_class = FeaturedPlacementSerializer
    pagination_class = None


class DealViewSet(viewsets.ReadOnlyModelViewSet):
    """Active deals — latest first."""
    queryset = Deal.objects.filter(is_active=True).select_related("business")
    serializer_class = DealSerializer
    pagination_class = PageNumberPagination
