from django.urls import path
from rest_framework.routers import DefaultRouter

from . import views

router = DefaultRouter()
router.register(r"news", views.CategoryNewsViewSet, basename="news")
router.register(r"events", views.EventViewSet, basename="event")
router.register(r"businesses", views.BusinessViewSet, basename="business")
router.register(r"schools", views.SchoolViewSet, basename="school")
router.register(r"alerts", views.AlertViewSet, basename="alert")
router.register(r"council-agendas", views.CouncilAgendaViewSet, basename="agenda")
router.register(r"weather", views.WeatherInfoViewSet, basename="weather")

urlpatterns = router.urls + [
    path("tips/", views.TipCreateView.as_view(), name="tip-create"),
]
