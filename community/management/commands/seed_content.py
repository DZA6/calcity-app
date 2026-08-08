"""Management command: python manage.py seed_content — populates empty models."""
from datetime import datetime
from django.core.management.base import BaseCommand
from community.models import Event, School, Alert, WeatherInfo


class Command(BaseCommand):
    help = "Seed empty content models with default data"

    def handle(self, *args, **options):
        created = {"events": 0, "schools": 0, "alerts": 0, "weather": 0}

        # Weather (static fallback — live fetch not available on PA free tier)
        if WeatherInfo.objects.count() == 0:
            WeatherInfo.objects.create(
                headline="Sunny, high of 97F",
                detail="Stay hydrated. Limit outdoor activity during peak heat hours (12-4 PM).",
                temperature_high=97, temperature_low=66,
                humidity="14%", wind="SW 12 mph", fire_risk="Moderate",
                sunrise="6:12 AM", sunset="7:50 PM", is_active=True,
            )
            created["weather"] = 1

        # Events
        if Event.objects.count() == 0:
            Event.objects.bulk_create([
                Event(title="City Council Meeting", description="Regular meeting of the California City Council. Public attendance welcome.", location="California City Hall", start_date=datetime(2026, 8, 12, 18, 0), end_date=datetime(2026, 8, 12, 20, 0), category="government", is_approved=True),
                Event(title="Farmers Market Saturday", description="Fresh local produce, baked goods, and artisan crafts. Every Saturday morning.", location="Community Center, California City", start_date=datetime(2026, 8, 9, 8, 0), end_date=datetime(2026, 8, 9, 12, 0), category="community", is_approved=True),
                Event(title="Back to School Night", description="Meet teachers, tour classrooms, get schedules. Cal City High School.", location="California City High School, 8567 Raven Way", start_date=datetime(2026, 8, 14, 17, 30), end_date=datetime(2026, 8, 14, 19, 30), category="school", is_approved=True),
                Event(title="Community Clean-Up Day", description="Volunteers needed! Meet at Central Park. Gloves and bags provided.", location="Central Park", start_date=datetime(2026, 8, 16, 7, 0), end_date=datetime(2026, 8, 16, 11, 0), category="community", is_approved=True),
                Event(title="Youth Soccer Registration", description="Cal City Youth Soccer fall season. Ages 5-14.", location="Parks and Recreation Office", start_date=datetime(2026, 8, 9, 9, 0), end_date=datetime(2026, 8, 9, 14, 0), category="sports", is_approved=True),
                Event(title="Desert Song Church BBQ", description="Community BBQ — all welcome! Games, live music, free.", location="Desert Song Foursquare Church, 20849 Hacienda Blvd", start_date=datetime(2026, 8, 10, 17, 0), end_date=datetime(2026, 8, 10, 20, 0), category="church", is_approved=True),
                Event(title="First Baptist Food Pantry", description="Monthly food distribution for families in need. Bring ID.", location="First Baptist Church, California City", start_date=datetime(2026, 8, 9, 9, 0), end_date=datetime(2026, 8, 9, 12, 0), category="community", is_approved=True),
            ])
            created["events"] = 7

        # Schools
        if School.objects.count() == 0:
            School.objects.bulk_create([
                School(name="California City High School", address="8567 Raven Way, California City, CA 93505", type="high", phone="(760) 373-5263", website="mojave.k12.ca.us/cchs", description="Home of the Ravens. Grades 9-12.", is_approved=True),
                School(name="California City Middle School", address="California City, CA 93505", type="middle", phone="(661) 824-4001", website="mojave.k12.ca.us", description="Grades 6-8. Approximately 300 students.", is_approved=True),
                School(name="Hacienda Elementary School", address="California City, CA 93505", type="elementary", phone="(661) 824-4001", website="mojave.k12.ca.us", description="Grades K-5.", is_approved=True),
                School(name="Robert P. Ulrich Elementary", address="California City, CA 93505", type="elementary", phone="(661) 824-4001", website="mojave.k12.ca.us", description="Grades K-5.", is_approved=True),
            ])
            created["schools"] = 4

        # Alerts
        if Alert.objects.count() == 0:
            Alert.objects.bulk_create([
                Alert(title="Heat Advisory", message="Temperatures expected to reach 97F. Stay indoors 12-4 PM. Drink water. Check on elderly neighbors.", severity="warning", is_active=True),
                Alert(title="Water Conservation Active", message="Outdoor watering restricted to designated days. Visit californiacity-ca.gov for your schedule.", severity="info", is_active=True),
                Alert(title="All Clear — No Active Emergencies", message="No active emergency alerts for California City at this time.", severity="info", is_active=True),
            ])
            created["alerts"] = 3

        self.stdout.write(self.style.SUCCESS(
            f"Seeded: {created['weather']} weather, {created['events']} events, "
            f"{created['schools']} schools, {created['alerts']} alerts"
        ))
