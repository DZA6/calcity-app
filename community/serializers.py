from django.contrib.contenttypes.models import ContentType
from rest_framework import serializers

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
    rating = serializers.SerializerMethodField()
    review_count = serializers.SerializerMethodField()

    class Meta:
        model = Business
        fields = "__all__"
        read_only_fields = ["id", "name", "description", "category", "image",
                            "contact_phone", "contact_email", "website", "address",
                            "is_home_based", "is_featured", "is_demo",
                            "is_approved", "created_at"]

    def get_image_url(self, obj):
        return self._abs("image")

    def _visible_reviews(self, obj):
        return [r for r in obj.reviews.all() if not r.is_hidden]

    def get_rating(self, obj):
        reviews = self._visible_reviews(obj)
        if not reviews:
            return None
        return round(sum(r.rating for r in reviews) / len(reviews), 1)

    def get_review_count(self, obj):
        return len(self._visible_reviews(obj))


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


class ChurchSerializer(serializers.ModelSerializer, MediaUrlMixin):
    image_url = serializers.SerializerMethodField()

    class Meta:
        model = Church
        fields = "__all__"
        read_only_fields = ["id", "created_at", "updated_at"]

    def get_image_url(self, obj):
        return self._abs("image")


class WeatherInfoSerializer(serializers.ModelSerializer):
    class Meta:
        model = WeatherInfo
        fields = "__all__"
        read_only_fields = ["id", "created_at"]


class FeaturedPlacementSerializer(serializers.ModelSerializer):
    business_name = serializers.CharField(source="business.name", read_only=True)
    business_category = serializers.CharField(source="business.category", read_only=True)
    business_image = serializers.SerializerMethodField()

    class Meta:
        model = FeaturedPlacement
        fields = ["id", "business", "business_name", "business_category", "business_image",
                  "headline", "start_date", "end_date", "is_active", "is_paid", "created_at"]
        read_only_fields = ["id", "created_at"]

    def get_business_image(self, obj):
        if obj.business.image:
            request = self.context.get("request")
            return request.build_absolute_uri(obj.business.image.url) if request else obj.business.image.url
        return None


class DealSerializer(serializers.ModelSerializer):
    business_name = serializers.CharField(source="business.name", read_only=True)
    business_category = serializers.CharField(source="business.category", read_only=True)
    image_url = serializers.SerializerMethodField()

    class Meta:
        model = Deal
        fields = ["id", "business", "business_name", "business_category", "image_url",
                  "title", "description", "discount", "expiry_date", "is_active", "created_at"]
        read_only_fields = ["id", "created_at"]

    def get_image_url(self, obj):
        if obj.image:
            request = self.context.get("request")
            return request.build_absolute_uri(obj.image.url) if request else obj.image.url
        return None


# ── Social: content refs, discussions, comments, reactions ───────────

# Short keys used by the app ↔ API for generic content targets
# (comments/reactions can attach to any of these).
CONTENT_MODELS = {
    "news": NewsItem,
    "event": Event,
    "business": Business,
    "school": School,
    "topic": DiscussionTopic,
}
MODEL_TO_KEY = {model: key for key, model in CONTENT_MODELS.items()}


def resolve_content_type(key):
    """Return (ContentType, model) for a short key like 'news'."""
    model = CONTENT_MODELS.get(key)
    if model is None:
        raise serializers.ValidationError(f"Unknown content type '{key}'")
    return ContentType.objects.get_for_model(model), model


def content_key(obj):
    """Short key for a model instance, e.g. NewsItem -> 'news'."""
    for key, model in CONTENT_MODELS.items():
        if isinstance(obj, model):
            return key
    return None


def reaction_summary(content_type, object_id, user=None):
    """{likes, dislikes, my_value} for one target."""
    qs = Reaction.objects.filter(content_type=content_type, object_id=object_id)
    my_value = None
    if user is not None and user.is_authenticated:
        mine = qs.filter(user=user).first()
        my_value = mine.value if mine else None
    return {
        "likes": qs.filter(value=Reaction.LIKE).count(),
        "dislikes": qs.filter(value=Reaction.DISLIKE).count(),
        "my_value": my_value,
    }


class DiscussionTopicSerializer(serializers.ModelSerializer):
    author = serializers.CharField(source="author.username", read_only=True)
    author_id = serializers.IntegerField(source="author.id", read_only=True)
    comment_count = serializers.SerializerMethodField()
    likes = serializers.SerializerMethodField()
    dislikes = serializers.SerializerMethodField()
    my_value = serializers.SerializerMethodField()

    def get_comment_count(self, obj):
        ct = ContentType.objects.get_for_model(obj)
        return Comment.objects.filter(
            content_type=ct, object_id=obj.id, is_hidden=False
        ).count()

    def _reactions(self, obj):
        ct = ContentType.objects.get_for_model(obj)
        request = self.context.get("request")
        user = request.user if request else None
        return reaction_summary(ct, obj.id, user)

    def get_likes(self, obj):
        return self._reactions(obj)["likes"]

    def get_dislikes(self, obj):
        return self._reactions(obj)["dislikes"]

    def get_my_value(self, obj):
        return self._reactions(obj)["my_value"]

    class Meta:
        model = DiscussionTopic
        fields = [
            "id",
            "title",
            "body",
            "author",
            "author_id",
            "category",
            "is_pinned",
            "is_closed",
            "created_at",
            "updated_at",
            "comment_count",
            "likes",
            "dislikes",
            "my_value",
        ]
        read_only_fields = [
            "author",
            "author_id",
            "is_pinned",
            "is_closed",
            "created_at",
            "updated_at",
            "comment_count",
            "likes",
            "dislikes",
            "my_value",
        ]


class CommentSerializer(serializers.ModelSerializer):
    author = serializers.CharField(source="author.username", read_only=True)
    author_id = serializers.IntegerField(source="author.id", read_only=True)
    content_type = serializers.SerializerMethodField()

    def get_content_type(self, obj):
        return content_key(obj.content_object) or (
            f"{obj.content_type.app_label}:{obj.content_type.model}"
        )

    def validate(self, data):
        raw_ct = self.initial_data.get("content_type")
        object_id = data.get("object_id")
        ct, model = resolve_content_type(raw_ct)
        if not model.objects.filter(pk=object_id).exists():
            raise serializers.ValidationError(
                {"object_id": "The target item does not exist."}
            )
        parent = data.get("parent")
        if parent is not None and (
            parent.content_type_id != ct.id or parent.object_id != object_id
        ):
            raise serializers.ValidationError(
                {"parent": "Reply must belong to the same item."}
            )
        data["_ct"] = ct
        return data

    def create(self, validated_data):
        ct = validated_data.pop("_ct")
        request = self.context.get("request")
        return Comment.objects.create(
            content_type=ct,
            object_id=validated_data["object_id"],
            body=validated_data["body"],
            parent=validated_data.get("parent"),
            author=request.user if request else validated_data["author"],
        )

    class Meta:
        model = Comment
        fields = [
            "id",
            "content_type",
            "object_id",
            "author",
            "author_id",
            "body",
            "parent",
            "is_hidden",
            "created_at",
        ]
        read_only_fields = ["author", "author_id", "is_hidden", "created_at"]


class ReactionInputSerializer(serializers.Serializer):
    """POST body for toggling a like/dislike."""

    content_type = serializers.CharField()
    object_id = serializers.IntegerField()
    value = serializers.ChoiceField(choices=Reaction.VALUE_CHOICES)

    def validate(self, data):
        ct, model = resolve_content_type(data["content_type"])
        if not model.objects.filter(pk=data["object_id"]).exists():
            raise serializers.ValidationError(
                {"object_id": "The target item does not exist."}
            )
        data["_ct"] = ct
        return data


# ── Classifieds & newsletter ────────────────────────────────────────


class ClassifiedCreateSerializer(serializers.ModelSerializer):
    """Public submission of a classified / announcement.

    Always creates an unapproved NewsItem (pending staff review) so user
    submissions stay hidden until approved in the dashboard.
    """

    class Meta:
        model = NewsItem
        fields = ["id", "title", "content", "category", "source_url", "is_approved", "created_at"]
        read_only_fields = ["id", "is_approved", "created_at"]
        extra_kwargs = {
            "source_url": {"required": False, "allow_blank": True},
        }

    def validate_category(self, value):
        if value not in ("for_sale", "announcements"):
            raise serializers.ValidationError(
                "Category must be 'for_sale' or 'announcements'."
            )
        return value

    def create(self, validated_data):
        validated_data["is_approved"] = False
        return NewsItem.objects.create(**validated_data)


class NewsletterEmailSerializer(serializers.Serializer):
    email = serializers.EmailField()


class BusinessReviewSerializer(serializers.ModelSerializer):
    author = serializers.CharField(source="author.username", read_only=True)

    class Meta:
        model = BusinessReview
        fields = ["id", "business", "author", "rating", "body", "created_at"]
        read_only_fields = ["id", "business", "author", "created_at"]

    def validate_rating(self, value):
        if not (1 <= value <= 5):
            raise serializers.ValidationError("Rating must be between 1 and 5.")
        return value
