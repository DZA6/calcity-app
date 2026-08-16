from rest_framework import viewsets
from rest_framework.generics import CreateAPIView
from rest_framework.permissions import AllowAny, IsAuthenticatedOrReadOnly
from rest_framework.authtoken.models import Token
from rest_framework.response import Response
from rest_framework import status
from rest_framework.pagination import PageNumberPagination
from rest_framework.views import APIView
from django.utils.decorators import method_decorator
from django_ratelimit.decorators import ratelimit

from .models import (
    Alert,
    Business,
    Church,
    Comment,
    CommunityTip,
    CouncilAgenda,
    Deal,
    DiscussionTopic,
    Event,
    FeaturedPlacement,
    NewsItem,
    NewsletterSubscriber,
    Reaction,
    School,
    WeatherInfo,
)
from .serializers import (
    AlertSerializer,
    BusinessSerializer,
    ChurchSerializer,
    ClassifiedCreateSerializer,
    CommentSerializer,
    CommunityTipSerializer,
    CouncilAgendaSerializer,
    DealSerializer,
    DiscussionTopicSerializer,
    EventSerializer,
    FeaturedPlacementSerializer,
    NewsletterEmailSerializer,
    NewsItemSerializer,
    ReactionInputSerializer,
    SchoolSerializer,
    WeatherInfoSerializer,
    resolve_content_type,
    reaction_summary,
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
    """Public submission endpoint — no auth required, rate-limited to
    10 submissions per hour per IP to stop spam flooding the queue."""

    queryset = CommunityTip.objects.all()
    serializer_class = CommunityTipSerializer

    @method_decorator(ratelimit(key="ip", rate="10/h", method="POST", block=False))
    def post(self, request, *args, **kwargs):
        if getattr(request, "limited", False):
            return Response(
                {"error": "Too many submissions. Please try again later."},
                status=status.HTTP_429_TOO_MANY_REQUESTS,
            )
        return super().post(request, *args, **kwargs)


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


class ChurchViewSet(viewsets.ReadOnlyModelViewSet):
    """Public API — only returns approved churches, alphabetical by name."""

    queryset = Church.objects.filter(is_approved=True)
    serializer_class = ChurchSerializer
    pagination_class = None
    ordering = ["name"]


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
    """Create a new user account. Returns an auth token.
    NOTE: legacy endpoint used by the current Flutter app. Rate-limited
    to 3 registrations per hour per IP (mirrors /api/auth/register/).
    Prefer /api/auth/register/ (email-verified flow) for new clients.
    """
    permission_classes = [AllowAny]

    @method_decorator(ratelimit(key="ip", rate="3/h", method="POST", block=False))
    def create(self, request, *args, **kwargs):
        if getattr(request, "limited", False):
            return Response(
                {"error": "Too many registration attempts. Please try again later."},
                status=status.HTTP_429_TOO_MANY_REQUESTS,
            )
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


# ── Social: discussions, comments, reactions ─────────────────────────

class TopicViewSet(viewsets.ModelViewSet):
    """Discussion threads. Anyone can read; logged-in users can post."""

    queryset = DiscussionTopic.objects.select_related("author")
    serializer_class = DiscussionTopicSerializer
    permission_classes = [IsAuthenticatedOrReadOnly]

    @method_decorator(ratelimit(key="ip", rate="30/h", method="POST", block=False))
    def create(self, request, *args, **kwargs):
        if getattr(request, "limited", False):
            return Response(
                {"error": "Too many posts. Please try again later."},
                status=status.HTTP_429_TOO_MANY_REQUESTS,
            )
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        serializer.save(author=request.user)
        return Response(
            serializer.data, status=status.HTTP_201_CREATED,
            headers=self.get_success_headers(serializer.data),
        )

    def update(self, request, *args, **kwargs):
        obj = self.get_object()
        if request.user != obj.author and not request.user.is_staff:
            return Response(
                {"error": "You can only edit your own posts."},
                status=status.HTTP_403_FORBIDDEN,
            )
        return super().update(request, *args, **kwargs)

    def destroy(self, request, *args, **kwargs):
        obj = self.get_object()
        if request.user != obj.author and not request.user.is_staff:
            return Response(
                {"error": "You can only delete your own posts."},
                status=status.HTTP_403_FORBIDDEN,
            )
        return super().destroy(request, *args, **kwargs)


class CommentViewSet(viewsets.ModelViewSet):
    """Comments on any content. Read via ?content_type=&object_id=."""

    serializer_class = CommentSerializer
    permission_classes = [IsAuthenticatedOrReadOnly]

    def get_queryset(self):
        qs = Comment.objects.select_related("author").filter(is_hidden=False)
        ct_key = self.request.query_params.get("content_type")
        object_id = self.request.query_params.get("object_id")
        if ct_key and object_id:
            try:
                ct, _ = resolve_content_type(ct_key)
                qs = qs.filter(content_type=ct, object_id=object_id)
            except Exception:
                return Comment.objects.none()
        return qs

    @method_decorator(ratelimit(key="ip", rate="60/h", method="POST", block=False))
    def create(self, request, *args, **kwargs):
        if getattr(request, "limited", False):
            return Response(
                {"error": "Too many comments. Please slow down."},
                status=status.HTTP_429_TOO_MANY_REQUESTS,
            )
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        serializer.save()  # author comes from request.user in the serializer
        return Response(
            serializer.data, status=status.HTTP_201_CREATED,
            headers=self.get_success_headers(serializer.data),
        )

    def update(self, request, *args, **kwargs):
        obj = self.get_object()
        if request.user != obj.author and not request.user.is_staff:
            return Response(
                {"error": "You can only edit your own comments."},
                status=status.HTTP_403_FORBIDDEN,
            )
        return super().update(request, *args, **kwargs)

    def destroy(self, request, *args, **kwargs):
        obj = self.get_object()
        if request.user != obj.author and not request.user.is_staff:
            return Response(
                {"error": "You can only delete your own comments."},
                status=status.HTTP_403_FORBIDDEN,
            )
        return super().destroy(request, *args, **kwargs)


class ReactionToggleView(APIView):
    """POST {content_type, object_id, value} — toggles like/dislike.

    Same value twice removes the reaction; a different value switches it.
    Returns the fresh {likes, dislikes, my_value} summary.
    """

    permission_classes = [IsAuthenticatedOrReadOnly]

    @method_decorator(ratelimit(key="ip", rate="120/h", method="POST", block=False))
    def post(self, request):
        if getattr(request, "limited", False):
            return Response(
                {"error": "Too many reactions. Please slow down."},
                status=status.HTTP_429_TOO_MANY_REQUESTS,
            )
        serializer = ReactionInputSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        ct = serializer.validated_data["_ct"]
        object_id = serializer.validated_data["object_id"]
        value = serializer.validated_data["value"]

        reaction, created = Reaction.objects.get_or_create(
            content_type=ct,
            object_id=object_id,
            user=request.user,
            defaults={"value": value},
        )
        if not created:
            if reaction.value == value:
                reaction.delete()  # toggle off
            else:
                reaction.value = value  # switch like <-> dislike
                reaction.save(update_fields=["value"])

        return Response(reaction_summary(ct, object_id, request.user))


class ReactionSummaryView(APIView):
    """GET ?content_type=&object_id= -> {likes, dislikes, my_value}."""

    permission_classes = [AllowAny]

    def get(self, request):
        try:
            ct, _ = resolve_content_type(request.query_params.get("content_type"))
            object_id = int(request.query_params.get("object_id"))
        except Exception:
            return Response(
                {"error": "content_type and object_id are required."},
                status=status.HTTP_400_BAD_REQUEST,
            )
        return Response(reaction_summary(ct, object_id, request.user))


class ReactionBulkView(APIView):
    """GET ?targets=news:5,event:2 -> {"news:5": {summary}, ...}.

    Batch summary for list screens so one request covers many items.
    """

    permission_classes = [AllowAny]

    def get(self, request):
        targets = request.query_params.get("targets", "")
        out = {}
        for chunk in targets.split(","):
            chunk = chunk.strip()
            if ":" not in chunk:
                continue
            key, _, raw_id = chunk.partition(":")
            try:
                ct, _ = resolve_content_type(key)
                object_id = int(raw_id)
            except Exception:
                continue
            out[f"{key}:{object_id}"] = reaction_summary(ct, object_id, request.user)
        return Response(out)


# ── Classifieds & newsletter ─────────────────────────────────────────


class ClassifiedCreateView(CreateAPIView):
    """Public endpoint — submit a classified / announcement.

    Creates an unapproved NewsItem (hidden until staff approves).
    Rate-limited to 10/hour/IP to deter spam.
    """

    serializer_class = ClassifiedCreateSerializer

    @method_decorator(ratelimit(key="ip", rate="10/h", method="POST", block=False))
    def post(self, request, *args, **kwargs):
        if getattr(request, "limited", False):
            return Response(
                {"error": "Too many posts. Please try again later."},
                status=status.HTTP_429_TOO_MANY_REQUESTS,
            )
        return super().post(request, *args, **kwargs)


class NewsletterSubscribeView(APIView):
    """POST {email} — opt in to the community digest."""

    permission_classes = [AllowAny]

    @method_decorator(ratelimit(key="ip", rate="20/h", method="POST", block=False))
    def post(self, request):
        if getattr(request, "limited", False):
            return Response(
                {"error": "Too many requests. Please try again later."},
                status=status.HTTP_429_TOO_MANY_REQUESTS,
            )
        serializer = NewsletterEmailSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        email = serializer.validated_data["email"].lower()
        sub, created = NewsletterSubscriber.objects.get_or_create(
            email=email, defaults={"is_active": True}
        )
        if not created and not sub.is_active:
            sub.is_active = True
            sub.save(update_fields=["is_active"])
        return Response(
            {"ok": True, "email": email},
            status=status.HTTP_201_CREATED if created else status.HTTP_200_OK,
        )


class NewsletterUnsubscribeView(APIView):
    """POST {email} — opt out of the community digest."""

    permission_classes = [AllowAny]

    def post(self, request):
        serializer = NewsletterEmailSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        email = serializer.validated_data["email"].lower()
        NewsletterSubscriber.objects.filter(email=email).update(is_active=False)
        return Response({"ok": True})
