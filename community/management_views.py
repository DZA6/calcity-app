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

from .services.weather_service import get_live_weather
from .models import (
    Alert,
    Business,
    Comment,
    CommunityTip,
    CouncilAgenda,
    Deal,
    DiscussionTopic,
    Event,
    FeaturedPlacement,
    NewsItem,
    School,
    WeatherInfo,
)

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
        "live_weather": get_live_weather(),
        "recent_news": NewsItem.objects.order_by("-created_at")[:8],
        "recent_alerts": Alert.objects.order_by("-created_at")[:5],
        "recent_events": Event.objects.filter(is_approved=True).order_by("start_date")[:5],
        "pending_tips": CommunityTip.objects.filter(is_approved=False).count(),
        "school_count": School.objects.count(),
        "business_count": Business.objects.count(),
        "deal_count": Deal.objects.filter(is_active=True).count(),
        "featured_count": FeaturedPlacement.objects.filter(is_active=True, is_paid=True).count(),
        "topic_count": DiscussionTopic.objects.count(),
        "comment_count": Comment.objects.count(),
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
    """Manage weather updates — live conditions + manual advisory posts."""
    latest = WeatherInfo.objects.filter(is_active=True).first()
    all_weather = WeatherInfo.objects.order_by("-created_at")[:10]

    # ?refresh=1 bypasses the cache and pulls fresh live conditions
    live = get_live_weather(force=request.GET.get("refresh") == "1")

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
            ctx = _weather_context(latest, all_weather, live)
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

    ctx = _weather_context(latest, all_weather, live)
    return render(request, "manage/weather.html", ctx)


def _weather_context(latest, all_weather, live=None):
    return {
        "weather": latest,
        "all_weather": all_weather,
        "live_weather": live,
    }


@staff_member_required
def weather_delete(request, pk):
    """Delete a weather update."""
    w = get_object_or_404(WeatherInfo, pk=pk)
    if request.method == "POST":
        w.delete()
        return redirect("manage:weather")
    return render(request, "manage/confirm_delete.html", {
        "object_type": "weather update",
        "object_name": w.headline,
        "cancel_url": "manage:weather",
    })


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
    if request.GET.get("demo") == "1":
        qs = qs.filter(is_demo=True)
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
        "current_demo": request.GET.get("demo", ""),
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
        is_demo = request.POST.get("is_demo") == "on"
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
            biz.is_demo = is_demo
            biz.is_approved = is_approved
        else:
            biz = Business(
                name=name, description=description, category=category,
                contact_phone=contact_phone, contact_email=contact_email,
                website=website, address=address,
                is_home_based=is_home_based, is_featured=is_featured,
                is_demo=is_demo, is_approved=is_approved,
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


# ── Schools ────────────────────────────────────────────────────────────────


@staff_member_required
def schools_list(request):
    """List all schools with add/edit/delete."""
    q = request.GET.get("q", "").strip()
    schools = School.objects.all().order_by("name")
    if q:
        schools = schools.filter(name__icontains=q)
    paginator = Paginator(schools, 25)
    page = paginator.get_page(request.GET.get("page"))
    return render(request, "manage/schools_list.html", {
        "schools": page, "q": q, "total": paginator.count,
    })


@staff_member_required
def school_edit(request, pk=None):
    """Add or edit a school."""
    school = get_object_or_404(School, pk=pk) if pk else None
    if request.method == "POST":
        fields = {
            "name": request.POST.get("name", "").strip(),
            "address": request.POST.get("address", "").strip(),
            "type": request.POST.get("type", "elementary"),
            "phone": request.POST.get("phone", "").strip(),
            "website": request.POST.get("website", "").strip(),
            "description": request.POST.get("description", "").strip(),
            "is_approved": "is_approved" in request.POST,
        }
        if not fields["name"]:
            return render(request, "manage/school_edit.html", {
                "school": school, "error": "Name is required.",
            })
        if school:
            for k, v in fields.items():
                setattr(school, k, v)
            school.save()
        else:
            school = School.objects.create(**fields)
        return redirect("manage:schools_list")
    return render(request, "manage/school_edit.html", {"school": school})


@staff_member_required
def school_delete(request, pk):
    """Delete a school."""
    school = get_object_or_404(School, pk=pk)
    if request.method == "POST":
        school.delete()
        return redirect("manage:schools_list")
    return render(request, "manage/confirm_delete.html", {
        "obj": school, "type_name": "School",
        "cancel_url": reverse("manage:schools_list"),
    })


# ── Council Agendas ─────────────────────────────────────────────────────────


@staff_member_required
def council_list(request):
    """List council agendas with delete + toggle approve."""
    agendas = CouncilAgenda.objects.all().order_by("-meeting_date")
    paginator = Paginator(agendas, 25)
    page = paginator.get_page(request.GET.get("page"))
    return render(request, "manage/council_list.html", {
        "agendas": page, "total": paginator.count,
    })


@staff_member_required
def council_delete(request, pk):
    """Delete a council agenda."""
    agenda = get_object_or_404(CouncilAgenda, pk=pk)
    if request.method == "POST":
        agenda.delete()
        return redirect("manage:council_list")
    return render(request, "manage/confirm_delete.html", {
        "obj": agenda, "type_name": "Council Agenda",
        "cancel_url": reverse("manage:council_list"),
    })


@staff_member_required
def council_toggle(request, pk):
    """AJAX: toggle is_approved."""
    agenda = get_object_or_404(CouncilAgenda, pk=pk)
    agenda.is_approved = not agenda.is_approved
    agenda.save()
    return JsonResponse({"ok": True, "is_approved": agenda.is_approved})


# ── Deals ───────────────────────────────────────────────────────────────────


@staff_member_required
def deals_list(request):
    """List all deals with add/edit/delete."""
    q = request.GET.get("q", "").strip()
    deals = Deal.objects.select_related("business").all().order_by("-created_at")
    if q:
        deals = deals.filter(title__icontains=q)
    paginator = Paginator(deals, 25)
    page = paginator.get_page(request.GET.get("page"))
    return render(request, "manage/deals_list.html", {
        "deals": page, "q": q, "total": paginator.count,
        "businesses": Business.objects.filter(is_approved=True).order_by("name"),
    })


@staff_member_required
def deal_edit(request, pk=None):
    """Add or edit a deal."""
    deal = get_object_or_404(Deal, pk=pk) if pk else None
    if request.method == "POST":
        biz_id = request.POST.get("business")
        fields = {
            "business": get_object_or_404(Business, pk=biz_id) if biz_id else None,
            "title": request.POST.get("title", "").strip(),
            "description": request.POST.get("description", "").strip(),
            "discount": request.POST.get("discount", "").strip(),
            "is_active": "is_active" in request.POST,
        }
        if not fields["business"] or not fields["title"]:
            return render(request, "manage/deal_edit.html", {
                "deal": deal,
                "businesses": Business.objects.filter(is_approved=True).order_by("name"),
                "error": "Business and title are required.",
            })
        if deal:
            for k, v in fields.items():
                setattr(deal, k, v)
            deal.save()
        else:
            deal = Deal.objects.create(**fields)
        return redirect("manage:deals_list")
    return render(request, "manage/deal_edit.html", {
        "deal": deal,
        "businesses": Business.objects.filter(is_approved=True).order_by("name"),
    })


@staff_member_required
def deal_delete(request, pk):
    """Delete a deal."""
    deal = get_object_or_404(Deal, pk=pk)
    if request.method == "POST":
        deal.delete()
        return redirect("manage:deals_list")
    return render(request, "manage/confirm_delete.html", {
        "obj": deal, "type_name": "Deal",
        "cancel_url": reverse("manage:deals_list"),
    })


@staff_member_required
def deal_toggle(request, pk):
    """AJAX: toggle is_active."""
    deal = get_object_or_404(Deal, pk=pk)
    deal.is_active = not deal.is_active
    deal.save()
    return JsonResponse({"ok": True, "is_active": deal.is_active})


# ── Featured Placements ─────────────────────────────────────────────────────


@staff_member_required
def featured_list(request):
    """List paid promotions with add/edit/delete."""
    featured = FeaturedPlacement.objects.select_related("business").all().order_by("-created_at")
    paginator = Paginator(featured, 25)
    page = paginator.get_page(request.GET.get("page"))
    return render(request, "manage/featured_list.html", {
        "featured": page, "total": paginator.count,
        "businesses": Business.objects.filter(is_approved=True).order_by("name"),
    })


@staff_member_required
def featured_edit(request, pk=None):
    """Add or edit a featured placement."""
    placement = get_object_or_404(FeaturedPlacement, pk=pk) if pk else None
    if request.method == "POST":
        biz_id = request.POST.get("business")
        fields = {
            "business": get_object_or_404(Business, pk=biz_id) if biz_id else None,
            "headline": request.POST.get("headline", "").strip(),
            "start_date": request.POST.get("start_date") or None,
            "end_date": request.POST.get("end_date") or None,
            "is_active": "is_active" in request.POST,
            "is_paid": "is_paid" in request.POST,
        }
        if not fields["business"] or not fields["headline"]:
            return render(request, "manage/featured_edit.html", {
                "placement": placement,
                "businesses": Business.objects.filter(is_approved=True).order_by("name"),
                "error": "Business and headline are required.",
            })
        if placement:
            for k, v in fields.items():
                setattr(placement, k, v)
            placement.save()
        else:
            placement = FeaturedPlacement.objects.create(**fields)
        return redirect("manage:featured_list")
    return render(request, "manage/featured_edit.html", {
        "placement": placement,
        "businesses": Business.objects.filter(is_approved=True).order_by("name"),
    })


@staff_member_required
def featured_delete(request, pk):
    """Delete a featured placement."""
    placement = get_object_or_404(FeaturedPlacement, pk=pk)
    if request.method == "POST":
        placement.delete()
        return redirect("manage:featured_list")
    return render(request, "manage/confirm_delete.html", {
        "obj": placement, "type_name": "Featured Placement",
        "cancel_url": reverse("manage:featured_list"),
    })


# ── Community & Moderation ──────────────────────────────────────────────────


@staff_member_required
def moderation_panel(request):
    """Moderation hub: tips, topics, comments."""
    tips = CommunityTip.objects.filter(is_approved=False).order_by("-created_at")[:15]
    recent_tips = CommunityTip.objects.filter(is_approved=True).order_by("-created_at")[:10]
    topics = DiscussionTopic.objects.select_related("author").all().order_by("-created_at")[:20]
    comments = Comment.objects.select_related("author").filter(is_hidden=False).order_by("-created_at")[:20]
    return render(request, "manage/moderation.html", {
        "pending_tips": tips,
        "recent_tips": recent_tips,
        "topics": topics,
        "comments": comments,
        "pending_count": tips.count(),
        "topic_count": DiscussionTopic.objects.count(),
        "comment_count": Comment.objects.count(),
        "tip_total": CommunityTip.objects.count(),
    })


@staff_member_required
def tip_moderate(request, pk, action):
    """Approve, reject, or delete a community tip."""
    tip = get_object_or_404(CommunityTip, pk=pk)
    if action == "approve":
        tip.is_approved = True
        tip.save()
    elif action == "reject":
        tip.is_approved = False
        tip.save()
    elif action == "delete" and request.method == "POST":
        tip.delete()
        return redirect("manage:moderation")
    return redirect("manage:moderation")


@staff_member_required
def topic_toggle(request, pk, field):
    """AJAX: toggle is_pinned or is_closed on a topic."""
    topic = get_object_or_404(DiscussionTopic, pk=pk)
    if field == "pin":
        topic.is_pinned = not topic.is_pinned
    elif field == "close":
        topic.is_closed = not topic.is_closed
    topic.save()
    return JsonResponse({"ok": True, "is_pinned": topic.is_pinned, "is_closed": topic.is_closed})


@staff_member_required
def topic_delete(request, pk):
    """Delete a discussion topic."""
    topic = get_object_or_404(DiscussionTopic, pk=pk)
    if request.method == "POST":
        topic.delete()
        return redirect("manage:moderation")
    return render(request, "manage/confirm_delete.html", {
        "obj": topic, "type_name": "Discussion Topic",
        "cancel_url": reverse("manage:moderation"),
    })


@staff_member_required
def comment_toggle(request, pk):
    """AJAX: hide/show a comment."""
    comment = get_object_or_404(Comment, pk=pk)
    comment.is_hidden = not comment.is_hidden
    comment.save()
    return JsonResponse({"ok": True, "is_hidden": comment.is_hidden})


@staff_member_required
def comment_delete(request, pk):
    """Delete a comment."""
    comment = get_object_or_404(Comment, pk=pk)
    if request.method == "POST":
        comment.delete()
        return redirect("manage:moderation")
    return render(request, "manage/confirm_delete.html", {
        "obj": comment, "type_name": "Comment",
        "cancel_url": reverse("manage:moderation"),
    })


@staff_member_required
def topic_edit(request, pk=None):
    """Create or edit a discussion topic (Seddit post)."""
    topic = None
    if pk:
        topic = get_object_or_404(DiscussionTopic, pk=pk)

    if request.method == "POST":
        title = request.POST.get("title", "").strip()
        body = request.POST.get("body", "").strip()
        category = request.POST.get("category", "general")
        is_pinned = request.POST.get("is_pinned") == "on"
        is_closed = request.POST.get("is_closed") == "on"

        if not title or not body:
            return render(request, "manage/topic_edit.html", {
                "topic": topic,
                "categories": DiscussionTopic.CATEGORY_CHOICES,
                "error": "Title and body are required.",
            })

        if topic is None:
            topic = DiscussionTopic(author=request.user)
        topic.title = title
        topic.body = body
        topic.category = category
        topic.is_pinned = is_pinned
        topic.is_closed = is_closed
        topic.save()
        return redirect("manage:moderation")

    return render(request, "manage/topic_edit.html", {
        "topic": topic,
        "categories": DiscussionTopic.CATEGORY_CHOICES,
    })


@staff_member_required
def comment_edit(request, pk):
    """Edit a comment body from moderation."""
    comment = get_object_or_404(Comment, pk=pk)
    if request.method == "POST":
        body = request.POST.get("body", "").strip()
        if not body:
            return render(request, "manage/comment_edit.html", {
                "comment": comment, "error": "Comment body is required.",
            })
        comment.body = body[:2000]
        comment.save()
        return redirect("manage:moderation")
    return render(request, "manage/comment_edit.html", {"comment": comment})


@staff_member_required
def council_edit(request, pk=None):
    """Create or edit a council agenda entry."""
    agenda = None
    if pk:
        agenda = get_object_or_404(CouncilAgenda, pk=pk)

    if request.method == "POST":
        title = request.POST.get("title", "").strip()
        description = request.POST.get("description", "").strip()
        meeting_date = request.POST.get("meeting_date", "").strip()
        pdf_url = request.POST.get("pdf_url", "").strip()
        is_approved = request.POST.get("is_approved") == "on"

        if not title:
            return render(request, "manage/council_edit.html", {
                "agenda": agenda, "error": "Title is required.",
            })

        from django.utils.dateparse import parse_datetime
        dt = parse_datetime(meeting_date) if meeting_date else None
        if meeting_date and dt is None:
            return render(request, "manage/council_edit.html", {
                "agenda": agenda, "error": "Enter a valid meeting date (YYYY-MM-DD HH:MM).",
            })

        if agenda is None:
            agenda = CouncilAgenda()
        agenda.title = title
        agenda.description = description
        agenda.pdf_url = pdf_url
        agenda.is_approved = is_approved
        if dt:
            if timezone.is_naive(dt):
                dt = timezone.make_aware(dt)
            agenda.meeting_date = dt
        agenda.save()
        return redirect("manage:council_list")

    return render(request, "manage/council_edit.html", {"agenda": agenda})
