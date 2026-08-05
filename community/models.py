from django.db import models


class NewsItem(models.Model):
    title = models.CharField(max_length=200)
    content = models.TextField()
    source_url = models.CharField(max_length=500, blank=True)
    image = models.ImageField(upload_to="news/", blank=True, null=True,
                              help_text="Optional: photo for this news item (JPEG/PNG)")
    video = models.FileField(upload_to="news/videos/", blank=True, null=True,
                             help_text="Optional: video clip for this news item (MP4)")
    is_approved = models.BooleanField(default=False)
    featured = models.BooleanField(default=False)
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
