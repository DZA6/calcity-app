from django.conf import settings
from django.contrib.contenttypes.fields import GenericForeignKey
from django.contrib.contenttypes.models import ContentType
from django.db import models


class NewsItem(models.Model):
    CATEGORY_CHOICES = [
        ("general", "General News"),
        ("city_works", "City Works"),
        ("church", "Church / Faith"),
        ("recreation", "Recreation & Parks"),
        ("law_enforcement", "Law Enforcement"),
        ("health", "Health & Wellness"),
        ("education", "Schools & Education"),
        ("business", "Business & Economy"),
        ("traffic", "Traffic & Roads"),
        ("community", "Community Events"),
        ("lost_pets", "Lost Pets"),
        ("gigs", "Gigs & Services"),
        ("for_sale", "For Sale & Free"),
        ("announcements", "Announcements"),
        ("neighbor", "Neighbor Appreciation"),
    ]

    title = models.CharField(max_length=200)
    content = models.TextField()
    source_url = models.CharField(max_length=500, blank=True)
    category = models.CharField(max_length=50, choices=CATEGORY_CHOICES, default="general",
                                help_text="Which section of the app this appears in")
    image = models.ImageField(upload_to="news/", blank=True, null=True,
                              help_text="Optional: photo for this news item (JPEG/PNG)")
    video = models.FileField(upload_to="news/videos/", blank=True, null=True,
                             help_text="Optional: video clip for this news item (MP4)")
    is_approved = models.BooleanField(default=False)
    featured = models.BooleanField(default=False, help_text="Show on the home page hero")
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return self.title

    class Meta:
        verbose_name = "News Item"
        verbose_name_plural = "News Items"
        ordering = ["-created_at"]


class Event(models.Model):
    CATEGORY_CHOICES = [
        ("community", "Community"),
        ("school", "School"),
        ("sports", "Sports"),
        ("city", "City"),
    ]

    title = models.CharField(max_length=200)
    description = models.TextField()
    location = models.CharField(max_length=300)
    image = models.ImageField(upload_to="events/", blank=True, null=True,
                              help_text="Optional: photo/flyer for this event (JPEG/PNG)")
    start_date = models.DateTimeField()
    end_date = models.DateTimeField(null=True, blank=True)
    category = models.CharField(max_length=50, choices=CATEGORY_CHOICES)
    is_approved = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return self.title

    class Meta:
        ordering = ["start_date"]


class Business(models.Model):
    CATEGORY_CHOICES = [
        ("home_business", "Home Business"),
        ("freelancer", "Freelancer"),
        ("local_shop", "Local Shop"),
        ("service", "Service"),
        ("restaurant", "Restaurant"),
        ("business_support", "Business Support"),
        ("other", "Other"),
    ]

    name = models.CharField(max_length=200)
    description = models.TextField(blank=True)
    category = models.CharField(max_length=50, choices=CATEGORY_CHOICES)
    image = models.ImageField(upload_to="businesses/", blank=True, null=True,
                              help_text="Optional: logo or storefront photo (JPEG/PNG)")
    contact_phone = models.CharField(max_length=20, blank=True)
    contact_email = models.EmailField(blank=True)
    website = models.URLField(blank=True)
    address = models.CharField(max_length=300, blank=True)
    is_home_based = models.BooleanField(default=False)
    is_featured = models.BooleanField(default=False)
    is_demo = models.BooleanField(
        default=False,
        help_text="Fictional example profile — the app shows a DEMO badge on it",
    )
    is_approved = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return self.name

    class Meta:
        verbose_name = "Business"
        verbose_name_plural = "Businesses"
        ordering = ["name"]


class CommunityTip(models.Model):
    CATEGORY_CHOICES = [
        ("news", "News"),
        ("event", "Event"),
        ("business", "Business"),
        ("general", "General"),
        ("bug", "Bug Report"),
        ("info_update", "Info Removal/Update"),
        ("business_promo", "Business Promotion"),
        ("freelancer_promo", "Freelancer Promotion"),
    ]

    submitter_name = models.CharField(max_length=100, blank=True)
    submitter_email = models.EmailField(blank=True)
    content = models.TextField()
    category = models.CharField(max_length=50, choices=CATEGORY_CHOICES)
    is_approved = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return self.content[:50]

    class Meta:
        verbose_name = "Community Tip"
        verbose_name_plural = "Community Tips"
        ordering = ["-created_at"]


class Alert(models.Model):
    SEVERITY_CHOICES = [
        ("info", "Info"),
        ("warning", "Warning"),
        ("emergency", "Emergency"),
    ]

    title = models.CharField(max_length=200)
    message = models.TextField()
    severity = models.CharField(max_length=20, choices=SEVERITY_CHOICES)
    image = models.ImageField(upload_to="alerts/", blank=True, null=True,
                              help_text="Optional: alert graphic (JPEG/PNG)")
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return self.title

    class Meta:
        ordering = ["-created_at"]


class CouncilAgenda(models.Model):
    title = models.CharField(max_length=200)
    description = models.TextField(blank=True)
    meeting_date = models.DateTimeField()
    pdf_url = models.URLField(blank=True)
    is_approved = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return self.title

    class Meta:
        ordering = ["-meeting_date"]


class WeatherInfo(models.Model):
    """A manually-posted weather update (e.g. 'Sunny, 94°F, windy afternoon').
    Admin posts this at any frequency; the Flutter app shows the latest one.
    Also holds sunrise/sunset and static tips (fire risk, heat advisory, etc)."""

    headline = models.CharField(max_length=200, help_text="e.g. Sunny and hot, high of 94°F")
    detail = models.TextField(blank=True, help_text="Extended forecast or advisory text")
    sunrise = models.CharField(max_length=20, blank=True, help_text="e.g. 6:12 AM")
    sunset = models.CharField(max_length=20, blank=True, help_text="e.g. 7:48 PM")
    humidity = models.CharField(max_length=10, blank=True, help_text="e.g. 12%")
    wind = models.CharField(max_length=100, blank=True, help_text="e.g. SW 8-15 mph")
    fire_risk = models.CharField(max_length=50, blank=True, help_text="e.g. Moderate")
    temperature_high = models.IntegerField(null=True, blank=True, help_text="Today's high (°F)")
    temperature_low = models.IntegerField(null=True, blank=True, help_text="Tonight's low (°F)")
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"Weather {self.created_at:%Y-%m-%d %H:%M}: {self.headline}"

    class Meta:
        verbose_name = "Weather Update"
        verbose_name_plural = "Weather Updates"
        ordering = ["-created_at"]


class School(models.Model):
    """Educational institution in the California City / Mojave area."""
    TYPE_CHOICES = [
        ("elementary", "Elementary"),
        ("middle", "Middle School"),
        ("high", "High School"),
        ("other", "Other"),
    ]

    name = models.CharField(max_length=200)
    type = models.CharField(max_length=20, choices=TYPE_CHOICES, default="other")
    address = models.CharField(max_length=300, blank=True)
    phone = models.CharField(max_length=20, blank=True)
    website = models.URLField(blank=True)
    calendar_url = models.URLField(
        blank=True,
        help_text="Link to the school/district calendar (page, PDF, or image)",
    )
    bell_schedule_url = models.URLField(
        blank=True,
        help_text="Link to the school bell schedule document (PDF/DOCX)",
    )
    description = models.TextField(blank=True)
    is_approved = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return self.name

    class Meta:
        verbose_name = "School"
        verbose_name_plural = "Schools"


class Church(models.Model):
    """A church / faith community in the California City area."""

    name = models.CharField(max_length=200)
    denomination = models.CharField(max_length=100, blank=True,
                                    help_text="e.g. Catholic, Baptist, Foursquare")
    description = models.TextField(blank=True)
    address = models.CharField(max_length=300, blank=True)
    phone = models.CharField(max_length=20, blank=True)
    website = models.URLField(blank=True)
    service_times = models.TextField(blank=True,
                                     help_text="Worship/service days and times")
    events = models.TextField(blank=True,
                              help_text="Recurring or upcoming events this church hosts")
    food_giveaway = models.TextField(blank=True,
                                     help_text="Food pantry / giveaway days and times")
    image = models.ImageField(upload_to="churches/", blank=True, null=True)
    is_approved = models.BooleanField(default=False)
    is_demo = models.BooleanField(default=False,
                                  help_text="Fictional example — app shows a DEMO badge")
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return self.name

    class Meta:
        verbose_name = "Church"
        verbose_name_plural = "Churches"
        ordering = ["name"]


class FeaturedPlacement(models.Model):
    """Paid promotion slot — businesses pay to be featured."""
    business = models.ForeignKey(Business, on_delete=models.CASCADE, related_name="promotions")
    headline = models.CharField(max_length=120, help_text="Short promo text (e.g. '20% off this week')")
    start_date = models.DateField()
    end_date = models.DateField()
    is_active = models.BooleanField(default=True)
    is_paid = models.BooleanField(default=False, help_text="Has the business paid for this slot?")
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"Featured: {self.business.name} — {self.headline}"

    class Meta:
        ordering = ["-created_at"]


# ── Social: discussions, comments, reactions ─────────────────────────

class DiscussionTopic(models.Model):
    """User-created discussion thread in the Conversations section."""

    CATEGORY_CHOICES = [
        ("general", "General"),
        ("news", "News"),
        ("events", "Events"),
        ("business", "Business"),
        ("help", "Help & Questions"),
    ]

    title = models.CharField(max_length=200)
    body = models.TextField()
    author = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="topics"
    )
    category = models.CharField(
        max_length=50, choices=CATEGORY_CHOICES, default="general"
    )
    is_pinned = models.BooleanField(default=False, help_text="Staff: pin to the top")
    is_closed = models.BooleanField(
        default=False, help_text="Staff: lock the thread (no new comments)"
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return self.title

    class Meta:
        ordering = ["-is_pinned", "-created_at"]


class Comment(models.Model):
    """A comment on any content (news, event, business, school, topic)."""

    content_type = models.ForeignKey(ContentType, on_delete=models.CASCADE)
    object_id = models.PositiveIntegerField()
    content_object = GenericForeignKey("content_type", "object_id")

    author = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="comments"
    )
    body = models.TextField(max_length=2000)
    parent = models.ForeignKey(
        "self", null=True, blank=True, on_delete=models.CASCADE, related_name="replies"
    )
    is_hidden = models.BooleanField(default=False, help_text="Staff: hide abusive content")
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.author}: {self.body[:50]}"

    class Meta:
        ordering = ["created_at"]
        indexes = [models.Index(fields=["content_type", "object_id"])]


class Reaction(models.Model):
    """Like/dislike on any content. One per user per item (toggle)."""

    LIKE = "like"
    DISLIKE = "dislike"
    VALUE_CHOICES = [(LIKE, "Like"), (DISLIKE, "Dislike")]

    content_type = models.ForeignKey(ContentType, on_delete=models.CASCADE)
    object_id = models.PositiveIntegerField()
    content_object = GenericForeignKey("content_type", "object_id")

    user = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="reactions"
    )
    value = models.CharField(max_length=10, choices=VALUE_CHOICES)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.user} {self.value} {self.content_object}"

    class Meta:
        constraints = [
            models.UniqueConstraint(
                fields=["content_type", "object_id", "user"],
                name="unique_reaction_per_user_per_item",
            )
        ]


class Deal(models.Model):
    """Time-limited deal / coupon from a local business."""
    business = models.ForeignKey(Business, on_delete=models.CASCADE, related_name="deals")
    title = models.CharField(max_length=150)
    description = models.TextField(blank=True)
    discount = models.CharField(max_length=80, blank=True, help_text="e.g. '20% off', 'BOGO free'")
    image = models.ImageField(upload_to="deals/", blank=True, null=True)
    expiry_date = models.DateField(blank=True, null=True)
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.business.name}: {self.title}"

    class Meta:
        ordering = ["-created_at"]


class NewsletterSubscriber(models.Model):
    """Email address opted in to the community digest (news + events)."""

    email = models.EmailField(unique=True)
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return self.email

    class Meta:
        verbose_name = "Newsletter Subscriber"
        verbose_name_plural = "Newsletter Subscribers"
        ordering = ["-created_at"]


class BusinessReview(models.Model):
    """Star rating + written review of a local business (1-5 stars)."""

    business = models.ForeignKey(
        Business, on_delete=models.CASCADE, related_name="reviews"
    )
    author = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.CASCADE,
        related_name="business_reviews",
    )
    rating = models.PositiveSmallIntegerField(default=5)
    body = models.TextField(blank=True)
    is_hidden = models.BooleanField(
        default=False, help_text="Staff: hide this review from the app"
    )
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.business.name}: {self.rating}\u2605 by {self.author}"

    class Meta:
        ordering = ["-created_at"]
        constraints = [
            models.UniqueConstraint(
                fields=["business", "author"],
                name="unique_review_per_business_per_author",
            )
        ]
