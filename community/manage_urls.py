"""URLs for the CalCity management dashboard at /manage/."""
from django.urls import path

from . import management_views as views

app_name = "manage"

urlpatterns = [
    # Dashboard
    path("", views.dashboard, name="dashboard"),

    # News / Articles
    path("news/", views.news_list, name="news_list"),
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
]
