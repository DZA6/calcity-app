from django.urls import path
from rest_framework.routers import DefaultRouter

from . import views

router = DefaultRouter()
router.register(r"news", views.CategoryNewsViewSet, basename="news")
router.register(r"events", views.EventViewSet, basename="event")
router.register(r"businesses", views.BusinessViewSet, basename="business")
router.register(r"schools", views.SchoolViewSet, basename="school")
router.register(r"churches", views.ChurchViewSet, basename="church")
router.register(r"alerts", views.AlertViewSet, basename="alert")
router.register(r"council-agendas", views.CouncilAgendaViewSet, basename="agenda")
router.register(r"weather", views.WeatherInfoViewSet, basename="weather")
router.register(r"featured", views.FeaturedPlacementViewSet, basename="featured")
router.register(r"deals", views.DealViewSet, basename="deal")
router.register(r"topics", views.TopicViewSet, basename="topic")
router.register(r"comments", views.CommentViewSet, basename="comment")

urlpatterns = router.urls + [
    path("tips/", views.TipCreateView.as_view(), name="tip-create"),
    path("classifieds/", views.ClassifiedCreateView.as_view(), name="classified-create"),
    path("businesses/<int:business_id>/reviews/", views.BusinessReviewView.as_view(), name="business-reviews"),
    path("newsletter/subscribe/", views.NewsletterSubscribeView.as_view(), name="newsletter-subscribe"),
    path("newsletter/unsubscribe/", views.NewsletterUnsubscribeView.as_view(), name="newsletter-unsubscribe"),
    path("reactions/toggle/", views.ReactionToggleView.as_view(), name="reaction-toggle"),
    path("reactions/summary/", views.ReactionSummaryView.as_view(), name="reaction-summary"),
    path("reactions/bulk/", views.ReactionBulkView.as_view(), name="reaction-bulk"),
]
