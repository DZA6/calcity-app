"""URLs for the CalCity management dashboard at /manage/."""
from django.urls import path

from . import management_views as views

app_name = "manage"

urlpatterns = [
    # Dashboard
    path("", views.dashboard, name="dashboard"),

    # News / Articles
    path("news/", views.news_list, name="news_list"),
    path("news/bulk-delete/", views.news_bulk_delete, name="news_bulk_delete"),
    path("news/new/", views.news_edit, name="news_edit"),
    path("news/<int:pk>/", views.news_edit, name="news_edit"),
    path("news/<int:pk>/delete/", views.news_delete, name="news_delete"),
    path("news/<int:pk>/toggle/<str:field>/", views.news_toggle, name="news_toggle"),

    # Weather
    path("weather/", views.weather_panel, name="weather"),
    path("weather/activate/<int:pk>/", views.weather_activate, name="weather_activate"),

    # Alerts
    path("alerts/", views.alerts_panel, name="alerts"),
    path("alerts/new/", views.alert_edit, name="alert_edit"),
    path("alerts/<int:pk>/", views.alert_edit, name="alert_edit"),
    path("alerts/<int:pk>/toggle/", views.alert_toggle, name="alert_toggle"),
    path("alerts/<int:pk>/push/", views.alert_push, name="alert_push"),
    path("alerts/<int:pk>/delete/", views.alert_delete, name="alert_delete"),

    # Events
    path("events/", views.events_list, name="events_list"),
    path("events/new/", views.event_edit, name="event_edit"),
    path("events/<int:pk>/", views.event_edit, name="event_edit"),
    path("events/<int:pk>/delete/", views.event_delete, name="event_delete"),
    path("events/<int:pk>/toggle/", views.event_toggle, name="event_toggle"),

    # Businesses
    path("businesses/", views.businesses_list, name="businesses_list"),
    path("businesses/new/", views.business_edit, name="business_edit"),
    path("businesses/<int:pk>/", views.business_edit, name="business_edit"),
    path("businesses/<int:pk>/delete/", views.business_delete, name="business_delete"),
    path("businesses/<int:pk>/toggle/<str:field>/", views.business_toggle, name="business_toggle"),

    # Schools
    path("schools/", views.schools_list, name="schools_list"),
    path("schools/new/", views.school_edit, name="school_edit"),
    path("schools/<int:pk>/", views.school_edit, name="school_edit"),
    path("schools/<int:pk>/delete/", views.school_delete, name="school_delete"),

    # Council Agendas
    path("council/", views.council_list, name="council_list"),
    path("council/<int:pk>/delete/", views.council_delete, name="council_delete"),
    path("council/<int:pk>/toggle/", views.council_toggle, name="council_toggle"),

    # Deals
    path("deals/", views.deals_list, name="deals_list"),
    path("deals/new/", views.deal_edit, name="deal_edit"),
    path("deals/<int:pk>/", views.deal_edit, name="deal_edit"),
    path("deals/<int:pk>/delete/", views.deal_delete, name="deal_delete"),
    path("deals/<int:pk>/toggle/", views.deal_toggle, name="deal_toggle"),

    # Featured Placements
    path("featured/", views.featured_list, name="featured_list"),
    path("featured/new/", views.featured_edit, name="featured_edit"),
    path("featured/<int:pk>/", views.featured_edit, name="featured_edit"),
    path("featured/<int:pk>/delete/", views.featured_delete, name="featured_delete"),

    # Community & Moderation
    path("moderation/", views.moderation_panel, name="moderation"),
    path("moderation/tips/<int:pk>/<str:action>/", views.tip_moderate, name="tip_moderate"),
    path("moderation/topics/<int:pk>/toggle/<str:field>/", views.topic_toggle, name="topic_toggle"),
    path("moderation/topics/<int:pk>/delete/", views.topic_delete, name="topic_delete"),
    path("moderation/comments/<int:pk>/toggle/", views.comment_toggle, name="comment_toggle"),
    path("moderation/comments/<int:pk>/delete/", views.comment_delete, name="comment_delete"),
    path("weather/delete/<int:pk>/", views.weather_delete, name="weather_delete"),

    # Council Agendas (manual add/edit)
    path("council/new/", views.council_edit, name="council_edit"),
    path("council/<int:pk>/edit/", views.council_edit, name="council_edit"),

    # Topics / Comments (moderation edit)
    path("moderation/topics/new/", views.topic_edit, name="topic_edit"),
    path("moderation/topics/<int:pk>/edit/", views.topic_edit, name="topic_edit"),
    path("moderation/comments/<int:pk>/edit/", views.comment_edit, name="comment_edit"),
]
