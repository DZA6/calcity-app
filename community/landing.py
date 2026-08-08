"""Landing page view — serves the public community hub at /."""
from django.shortcuts import render
from django.utils import timezone

from .models import Business, Event, NewsItem


def landing_page(request):
    """Public landing page with news feed, business directory, event calendar."""
    ctx = {
        "news": NewsItem.objects.filter(is_approved=True).order_by("-created_at")[:30],
        "news_count": NewsItem.objects.filter(is_approved=True).count(),
        "businesses": Business.objects.filter(is_approved=True).order_by("name")[:24],
        "businesses_count": Business.objects.filter(is_approved=True).count(),
        "events": Event.objects.filter(
            is_approved=True, start_date__gte=timezone.now()
        ).order_by("start_date")[:20],
        "events_count": Event.objects.filter(
            is_approved=True, start_date__gte=timezone.now()
        ).count(),
    }
    return render(request, "landing.html", ctx)
