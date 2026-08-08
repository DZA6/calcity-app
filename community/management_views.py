"""
CalCity Management Dashboard — custom admin views.

Simple, modern UI for daily content management:
- Dashboard with stats and quick actions
- Article editor with image/video preview
- Weather panel
- Alerts panel
- Events panel

Access at /manage/ (requires Django admin login).
"""
import json

from django.contrib.admin.views.decorators import staff_member_required
from django.core.paginator import Paginator
from django.http import JsonResponse
from django.shortcuts import get_object_or_404, redirect, render
from django.urls import reverse
from django.utils import timezone
from django.views.decorators.http import require_http_methods

from .models import Alert, Business, CommunityTip, Event, NewsItem, School, WeatherInfo

# ── Dashboard ──────────────────────────────────────────────────────────────


@staff_member_required
def dashboard(request):
    """Main management dashboard with stats and quick actions."""
    ctx = {
        "news_count": NewsItem.objects.count(),
        "news_approved": NewsItem.objects.filter(is_approved=True).count(),
        "active_alerts": Alert.objects.filter(is_active=True).count(),
        "upcoming_events": Event.objects.filter(
            is_approved=True, start_date__gte=timezone.now()
        ).count(),
        "weather_count": WeatherInfo.objects.count(),
        "latest_weather": WeatherInfo.objects.filter(is_active=True).first(),
        "recent_news": NewsItem.objects.order_by("-created_at")[:8],
        "recent_alerts": Alert.objects.order_by("-created_at")[:5],
        "recent_events": Event.objects.filter(is_approved=True).order_by("start_date")[:5],
        "pending_tips": CommunityTip.objects.filter(is_approved=False).count(),
    }
    return render(request, "manage/dashboard.html", ctx)


# ── News / Articles ────────────────────────────────────────────────────────


@staff_member_required
def news_list(request):
    """List all news articles with filters."""
    category = request.GET.get("category", "")
    status = request.GET.get("status", "all")  # all, approved, pending
    page_num = request.GET.get("page", 1)

    qs = NewsItem.objects.all()
    if category:
        qs = qs.filter(category=category)
    if status == "approved":
        qs = qs.filter(is_approved=True)
    elif status == "pending":
        qs = qs.filter(is_approved=False)

    paginator = Paginator(qs.order_by("-created_at"), 20)
    page = paginator.get_page(page_num)

    ctx = {
        "articles": page,
        "categories": NewsItem.CATEGORY_CHOICES,
        "current_category": category,
        "current_status": status,
    }
    return render(request, "manage/news_list.html", ctx)


@staff_member_required
def news_edit(request, pk=None):
    """Create or edit a news article."""
    article = None
    if pk:
        article = get_object_or_404(NewsItem, pk=pk)

    if request.method == "POST":
        title = request.POST.get("title", "").strip()
        content = request.POST.get("content", "").strip()
        category = request.POST.get("category", "general")
        source_url = request.POST.get("source_url", "").strip()
        is_approved = request.POST.get("is_approved") == "on"
        featured = request.POST.get("featured") == "on"

        if not title or not content:
            ctx = _news_form_context(article, request)
            ctx["error"] = "Title and content are required."
            return render(request, "manage/news_edit.html", ctx)

        if article:
            article.title = title
            article.content = content
            article.category = category
            article.source_url = source_url
            article.is_approved = is_approved
            article.featured = featured
        else:
            article = NewsItem(
                title=title,
                content=content,
                category=category,
                source_url=source_url,
                is_approved=is_approved,
                featured=featured,
            )

        # Handle image upload
        if request.FILES.get("image"):
            article.image = request.FILES["image"]

        # Handle video upload
        if request.FILES.get("video"):
            article.video = request.FILES["video"]

        article.save()
        return redirect("manage:news_list")

    ctx = _news_form_context(article, request)
    return render(request, "manage/news_edit.html", ctx)


def _news_form_context(article, request):
    """Build context for the news edit form."""
    ctx = {
        "article": article,
        "categories": NewsItem.CATEGORY_CHOICES,
        "preview_image_url": article.image.url if article and article.image else None,
        "preview_video_url": article.video.url if article and article.video else None,
    }
    if article:
        ctx["preview_json"] = json.dumps({
            "title": article.title,
            "category": article.category,
            "is_approved": article.is_approved,
            "featured": article.featured,
        })
    return ctx


@staff_member_required
def news_delete(request, pk):
    """Delete a news article."""
    article = get_object_or_404(NewsItem, pk=pk)
    if request.method == "POST":
        article.delete()
        return redirect("manage:news_list")
    return render(request, "manage/confirm_delete.html", {
        "obj": article,
        "type_name": "News Article",
        "cancel_url": reverse("manage:news_list"),
    })


@staff_member_required
def news_toggle(request, pk, field):
    """AJAX: toggle is_approved or featured on a news item."""
    article = get_object_or_404(NewsItem, pk=pk)
    if field == "approve":
        article.is_approved = not article.is_approved
    elif field == "feature":
        article.featured = not article.featured
    article.save()
    return JsonResponse({"ok": True, "is_approved": article.is_approved, "featured": article.featured})


# ── Weather ─────────────────────────────────────────────────────────────────


@staff_member_required
def weather_panel(request):
    """Manage weather updates — edit the latest or create new."""
    latest = WeatherInfo.objects.filter(is_active=True).first()
    all_weather = WeatherInfo.objects.order_by("-created_at")[:10]

    if request.method == "POST":
        headline = request.POST.get("headline", "").strip()
        detail = request.POST.get("detail", "").strip()
        temp_high = request.POST.get("temperature_high", "")
        temp_low = request.POST.get("temperature_low", "")
        humidity = request.POST.get("humidity", "").strip()
        wind = request.POST.get("wind", "").strip()
        fire_risk = request.POST.get("fire_risk", "").strip()
        sunrise = request.POST.get("sunrise", "").strip()
        sunset = request.POST.get("sunset", "").strip()
        is_active = request.POST.get("is_active") == "on"

        if not headline:
            ctx = _weather_context(latest, all_weather)
            ctx["error"] = "Headline is required."
            return render(request, "manage/weather.html", ctx)

        # If updating the latest and it's active, deactivate old ones
        if is_active and latest:
            WeatherInfo.objects.filter(is_active=True).exclude(pk=latest.pk).update(is_active=False)

        w = WeatherInfo(
            headline=headline,
            detail=detail,
            temperature_high=int(temp_high) if temp_high else None,
            temperature_low=int(temp_low) if temp_low else None,
            humidity=humidity,
            wind=wind,
            fire_risk=fire_risk,
            sunrise=sunrise,
            sunset=sunset,
            is_active=is_active,
        )
        w.save()
        return redirect("manage:weather")

    ctx = _weather_context(latest, all_weather)
    return render(request, "manage/weather.html", ctx)


def _weather_context(latest, all_weather):
    return {
        "weather": latest,
        "all_weather": all_weather,
    }


@staff_member_required
def weather_activate(request, pk):
    """Activate a specific weather update (deactivates others)."""
    w = get_object_or_404(WeatherInfo, pk=pk)
    WeatherInfo.objects.filter(is_active=True).update(is_active=False)
    w.is_active = True
    w.save()
    return redirect("manage:weather")


# ── Alerts ──────────────────────────────────────────────────────────────────


@staff_member_required
def alerts_panel(request):
    """Manage community alerts."""
    alerts = Alert.objects.order_by("-created_at")
    ctx = {"alerts": alerts, "severities": Alert.SEVERITY_CHOICES}
    return render(request, "manage/alerts.html", ctx)


@staff_member_required
def alert_edit(request, pk=None):
    """Create or edit an alert."""
    alert = None
    if pk:
        alert = get_object_or_404(Alert, pk=pk)

    if request.method == "POST":
        title = request.POST.get("title", "").strip()
        message = request.POST.get("message", "").strip()
        severity = request.POST.get("severity", "info")
        is_active = request.POST.get("is_active") == "on"

        if not title or not message:
            ctx = _alert_form_context(alert)
            ctx["error"] = "Title and message are required."
            return render(request, "manage/alert_edit.html", ctx)

        if alert:
            alert.title = title
            alert.message = message
            alert.severity = severity
            alert.is_active = is_active
        else:
            alert = Alert(
                title=title, message=message, severity=severity, is_active=is_active
            )

        if request.FILES.get("image"):
            alert.image = request.FILES["image"]

        alert.save()
        return redirect("manage:alerts")

    ctx = _alert_form_context(alert)
    return render(request, "manage/alert_edit.html", ctx)


def _alert_form_context(alert):
    ctx = {"alert": alert, "severities": Alert.SEVERITY_CHOICES}
    if alert and alert.image:
        ctx["preview_image_url"] = alert.image.url
    return ctx


@staff_member_required
def alert_toggle(request, pk):
    """AJAX: toggle alert active status."""
    alert = get_object_or_404(Alert, pk=pk)
    alert.is_active = not alert.is_active
    alert.save()
    return JsonResponse({"ok": True, "is_active": alert.is_active})


@staff_member_required
def alert_push(request, pk):
    """AJAX: send this alert as an FCM push to the 'alerts' topic.

    Returns {"ok": false, "detail": "FCM not configured"} when no Firebase
    service account is set up yet — the button is safe to click anytime.
    """
    alert = get_object_or_404(Alert, pk=pk)
    if request.method != "POST":
        return JsonResponse({"error": "POST required"}, status=405)

    from .firebase_messaging import send_topic_message

    ok, result = send_topic_message(
        title=alert.title[:100],
        body=alert.message[:180],
        topic="alerts",
        data={"type": "alert", "id": str(alert.pk), "severity": alert.severity},
    )
    return JsonResponse({"ok": ok, "detail": result})


@staff_member_required
def alert_delete(request, pk):
    """Delete an alert."""
    alert = get_object_or_404(Alert, pk=pk)
    if request.method == "POST":
        alert.delete()
        return redirect("manage:alerts")
    return render(request, "manage/confirm_delete.html", {
        "obj": alert,
        "type_name": "Alert",
        "cancel_url": reverse("manage:alerts"),
    })


# ── Events ──────────────────────────────────────────────────────────────────


@staff_member_required
def events_list(request):
    """List community events."""
    status = request.GET.get("status", "all")
    qs = Event.objects.all()
    if status == "approved":
        qs = qs.filter(is_approved=True)
    elif status == "pending":
        qs = qs.filter(is_approved=False)

    paginator = Paginator(qs.order_by("start_date"), 20)
    page_num = request.GET.get("page", 1)
    page = paginator.get_page(page_num)

    ctx = {"events": page, "current_status": status}
    return render(request, "manage/events_list.html", ctx)


@staff_member_required
def event_edit(request, pk=None):
    """Create or edit an event."""
    event = None
    if pk:
        event = get_object_or_404(Event, pk=pk)

    if request.method == "POST":
        title = request.POST.get("title", "").strip()
        description = request.POST.get("description", "").strip()
        location = request.POST.get("location", "").strip()
        category = request.POST.get("category", "community")
        start_date = request.POST.get("start_date", "")
        end_date = request.POST.get("end_date", "")
        is_approved = request.POST.get("is_approved") == "on"

        if not title or not start_date:
            ctx = {"event": event, "categories": Event.CATEGORY_CHOICES, "error": "Title and start date are required."}
            if event:
                ctx["preview_image_url"] = event.image.url if event.image else None
            return render(request, "manage/event_edit.html", ctx)

        try:
            from django.utils.dateparse import parse_datetime
            start_dt = parse_datetime(start_date)
            end_dt = parse_datetime(end_date) if end_date else None
        except Exception:
            start_dt = None
            end_dt = None

        if not start_dt:
            ctx = {"event": event, "categories": Event.CATEGORY_CHOICES, "error": "Invalid start date."}
            return render(request, "manage/event_edit.html", ctx)

        if event:
            event.title = title
            event.description = description
            event.location = location
            event.category = category
            event.start_date = start_dt
            event.end_date = end_dt
            event.is_approved = is_approved
        else:
            event = Event(
                title=title, description=description, location=location,
                category=category, start_date=start_dt, end_date=end_dt,
                is_approved=is_approved,
            )

        if request.FILES.get("image"):
            event.image = request.FILES["image"]

        event.save()
        return redirect("manage:events_list")

    ctx = {"event": event, "categories": Event.CATEGORY_CHOICES}
    if event and event.image:
        ctx["preview_image_url"] = event.image.url
    return render(request, "manage/event_edit.html", ctx)


@staff_member_required
def event_delete(request, pk):
    """Delete an event."""
    event = get_object_or_404(Event, pk=pk)
    if request.method == "POST":
        event.delete()
        return redirect("manage:events_list")
    return render(request, "manage/confirm_delete.html", {
        "obj": event, "type_name": "Event",
        "cancel_url": reverse("manage:events_list"),
    })


@staff_member_required
def event_toggle(request, pk):
    """AJAX: toggle event approval."""
    event = get_object_or_404(Event, pk=pk)
    event.is_approved = not event.is_approved
    event.save()
    return JsonResponse({"ok": True, "is_approved": event.is_approved})


# ── Businesses ──────────────────────────────────────────────────────────────


@staff_member_required
def businesses_list(request):
    """List all businesses with filters."""
    category = request.GET.get("category", "")
    status = request.GET.get("status", "all")
    page_num = request.GET.get("page", 1)

    qs = Business.objects.all()
    if category:
        qs = qs.filter(category=category)
    if status == "approved":
        qs = qs.filter(is_approved=True)
    elif status == "pending":
        qs = qs.filter(is_approved=False)

    paginator = Paginator(qs.order_by("name"), 30)
    page = paginator.get_page(page_num)

    ctx = {
        "businesses": page,
        "categories": Business.CATEGORY_CHOICES,
        "current_category": category,
        "current_status": status,
    }
    return render(request, "manage/businesses_list.html", ctx)


@staff_member_required
def business_edit(request, pk=None):
    """Create or edit a business."""
    biz = None
    if pk:
        biz = get_object_or_404(Business, pk=pk)

    if request.method == "POST":
        name = request.POST.get("name", "").strip()
        description = request.POST.get("description", "").strip()
        category = request.POST.get("category", "local_shop")
        contact_phone = request.POST.get("contact_phone", "").strip()
        contact_email = request.POST.get("contact_email", "").strip()
        website = request.POST.get("website", "").strip()
        address = request.POST.get("address", "").strip()
        is_home_based = request.POST.get("is_home_based") == "on"
        is_featured = request.POST.get("is_featured") == "on"
        is_approved = request.POST.get("is_approved") == "on"

        if not name:
            ctx = _biz_form_context(biz)
            ctx["error"] = "Business name is required."
            return render(request, "manage/business_edit.html", ctx)

        if biz:
            biz.name = name
            biz.description = description
            biz.category = category
            biz.contact_phone = contact_phone
            biz.contact_email = contact_email
            biz.website = website
            biz.address = address
            biz.is_home_based = is_home_based
            biz.is_featured = is_featured
            biz.is_approved = is_approved
        else:
            biz = Business(
                name=name, description=description, category=category,
                contact_phone=contact_phone, contact_email=contact_email,
                website=website, address=address,
                is_home_based=is_home_based, is_featured=is_featured,
                is_approved=is_approved,
            )

        if request.FILES.get("image"):
            biz.image = request.FILES["image"]

        biz.save()
        return redirect("manage:businesses_list")

    ctx = _biz_form_context(biz)
    return render(request, "manage/business_edit.html", ctx)


def _biz_form_context(biz):
    ctx = {"biz": biz, "categories": Business.CATEGORY_CHOICES}
    if biz and biz.image:
        ctx["preview_image_url"] = biz.image.url
    return ctx


@staff_member_required
def business_delete(request, pk):
    """Delete a business."""
    biz = get_object_or_404(Business, pk=pk)
    if request.method == "POST":
        biz.delete()
        return redirect("manage:businesses_list")
    return render(request, "manage/confirm_delete.html", {
        "obj": biz, "type_name": "Business",
        "cancel_url": reverse("manage:businesses_list"),
    })


@staff_member_required
def business_toggle(request, pk, field):
    """AJAX: toggle is_approved, is_featured, or is_home_based."""
    biz = get_object_or_404(Business, pk=pk)
    if field == "approve":
        biz.is_approved = not biz.is_approved
    elif field == "feature":
        biz.is_featured = not biz.is_featured
    elif field == "home":
        biz.is_home_based = not biz.is_home_based
    biz.save()
    return JsonResponse({
        "ok": True, "is_approved": biz.is_approved,
        "is_featured": biz.is_featured, "is_home_based": biz.is_home_based,
    })
