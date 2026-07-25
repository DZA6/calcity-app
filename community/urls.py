from django.urls import path
from rest_framework.routers import DefaultRouter

from . import views

router = DefaultRouter()
router.register(r"news", views.NewsItemViewSet, basename="news")
router.register(r"events", views.EventViewSet, basename="event")
router.register(r"businesses", views.BusinessViewSet, basename="business")

urlpatterns = router.urls + [
    path("tips/", views.TipCreateView.as_view(), name="tip-create"),
]
