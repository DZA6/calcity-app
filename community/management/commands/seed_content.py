"""Management command: python manage.py seed_content — populates empty models."""
from datetime import date, datetime
from django.core.management.base import BaseCommand
from community.models import Alert, Business, Church, Deal, Event, NewsItem, School, WeatherInfo


class Command(BaseCommand):
    help = "Seed empty content models with default data"

    def handle(self, *args, **options):
        created = {"events": 0, "schools": 0, "alerts": 0, "weather": 0,
                   "news": 0, "businesses": 0, "deals": 0, "churches": 0}

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
                Event(title="City Council Meeting", description="Regular meeting of the California City Council. Public attendance welcome.", location="California City Hall", start_date=datetime(2026, 8, 12, 18, 0), end_date=datetime(2026, 8, 12, 20, 0), category="city", is_approved=True),
                Event(title="Farmers Market Saturday", description="Fresh local produce, baked goods, and artisan crafts. Every Saturday morning.", location="Community Center, California City", start_date=datetime(2026, 8, 9, 8, 0), end_date=datetime(2026, 8, 9, 12, 0), category="community", is_approved=True),
                Event(title="Back to School Night", description="Meet teachers, tour classrooms, get schedules. Cal City High School.", location="California City High School, 8567 Raven Way", start_date=datetime(2026, 8, 14, 17, 30), end_date=datetime(2026, 8, 14, 19, 30), category="school", is_approved=True),
                Event(title="Community Clean-Up Day", description="Volunteers needed! Meet at Central Park. Gloves and bags provided.", location="Central Park", start_date=datetime(2026, 8, 16, 7, 0), end_date=datetime(2026, 8, 16, 11, 0), category="community", is_approved=True),
                Event(title="Youth Soccer Registration", description="Cal City Youth Soccer fall season. Ages 5-14.", location="Parks and Recreation Office", start_date=datetime(2026, 8, 9, 9, 0), end_date=datetime(2026, 8, 9, 14, 0), category="sports", is_approved=True),
                Event(title="Desert Song Church BBQ", description="Community BBQ — all welcome! Games, live music, free.", location="Desert Song Foursquare Church, 20849 Hacienda Blvd", start_date=datetime(2026, 8, 10, 17, 0), end_date=datetime(2026, 8, 10, 20, 0), category="community", is_approved=True),
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

        # NewsItem examples — give the Lost Pets + Gigs sections sample content
        if NewsItem.objects.count() == 0:
            NewsItem.objects.bulk_create([
                NewsItem(
                    title="Lost Dog: 'Biscuit' — Tan Chihuahua",
                    content=("Male chihuahua, tan coat, blue collar with a silver tag. "
                             "Last seen near Central Park on the evening of Aug 11. "
                             "Friendly but skittish. If found, please call or text (760) 555-0142."),
                    category="lost_pets", is_approved=True,
                ),
                NewsItem(
                    title="Missing Cat: 'Mittens' — Black & White Tuxedo",
                    content=("Black and white tuxedo cat, green eyes, microchipped. "
                             "Went missing from the 8000 block of Redwood Blvd. "
                             "Please check garages, sheds, and under porches. Reward offered."),
                    category="lost_pets", is_approved=True,
                ),
                NewsItem(
                    title="Yard Cleanup Help Needed — Paid",
                    content=("Need help clearing weeds and brush from a backyard this weekend. "
                             "$25/hr cash, tools provided. Text or call (760) 555-0173."),
                    category="gigs", is_approved=True,
                ),
                NewsItem(
                    title="Handyman Available — Small Repairs",
                    content=("Reliable handyman available for small repairs: drywall, painting, "
                             "fence repair, furniture assembly. Licensed and insured. Free estimates. "
                             "Call (760) 555-0198."),
                    category="gigs", is_approved=True,
                ),
            ])
            created["news"] = 4

        # Demo businesses + non-food deals (deals aren't just restaurants)
        if Business.objects.count() == 0:
            auto = Business.objects.create(
                name="Desert Auto Care", category="service", is_approved=True, is_demo=True,
                description="Oil changes, brakes, tires, and general auto repair.",
                contact_phone="(760) 555-0110", address="California City, CA 93505",
            )
            handyman = Business.objects.create(
                name="High Desert Handyman", category="freelancer", is_approved=True, is_demo=True,
                description="Home repairs, remodels, and routine maintenance.",
                contact_phone="(760) 555-0111", address="California City, CA 93505",
            )
            landscaping = Business.objects.create(
                name="CalCity Landscaping", category="service", is_approved=True, is_demo=True,
                description="Lawn care, sprinkler repair, and tree trimming.",
                contact_phone="(760) 555-0112", address="California City, CA 93505",
            )
            created["businesses"] = 3

            Deal.objects.bulk_create([
                Deal(business=auto, title="Oil Change Special", discount="20% off",
                     description="Full synthetic oil change with filter. Mention the app.",
                     expiry_date=date(2026, 12, 31), is_active=True),
                Deal(business=handyman, title="Free Repair Estimate", discount="Free estimate",
                     description="Free on-site estimate for any home repair job.",
                     expiry_date=date(2026, 12, 31), is_active=True),
                Deal(business=landscaping, title="First Mow Half Price", discount="50% off",
                     description="First lawn mowing service at half price for new customers.",
                     expiry_date=date(2026, 12, 31), is_active=True),
            ])
            created["deals"] = 3

        # Churches (Faith directory)
        if Church.objects.count() == 0:
            Church.objects.bulk_create([
                Church(
                    name="Desert Song Foursquare Church",
                    denomination="Foursquare",
                    address="20849 Hacienda Blvd, California City, CA 93505",
                    phone="(760) 373-2031",
                    description="A welcoming community church in the heart of California City.",
                    service_times="Sunday Worship 9:00 AM & 11:00 AM\nWednesday Bible Study 6:30 PM",
                    events="Monthly Community BBQ (free, all welcome)\nYouth Group Fridays 6:00 PM",
                    food_giveaway="Food pantry 1st & 3rd Saturday 10:00 AM \u2013 12:00 PM",
                    is_approved=True, is_demo=True,
                ),
                Church(
                    name="First Baptist Church of California City",
                    denomination="Baptist",
                    address="California City, CA 93505",
                    phone="(760) 373-1111",
                    description="Bible-based teaching and a monthly food distribution for families in need.",
                    service_times="Sunday School 9:30 AM\nSunday Worship 10:45 AM",
                    events="Women's Fellowship 2nd Tuesday\nMen's Breakfast 1st Saturday",
                    food_giveaway="Food pantry every 2nd Tuesday 9:00 AM \u2013 11:00 AM (bring ID)",
                    is_approved=True, is_demo=True,
                ),
                Church(
                    name="Calvary Chapel California City",
                    denomination="Non-denominational",
                    address="California City, CA 93505",
                    phone="(760) 373-2222",
                    description="Verse-by-verse Bible teaching and community outreach.",
                    service_times="Sunday Service 10:00 AM\nThursday Prayer 7:00 PM",
                    events="Community outreach Saturdays (seasonal)",
                    food_giveaway="",
                    is_approved=True, is_demo=True,
                ),
            ])
            created["churches"] = 3

        self.stdout.write(self.style.SUCCESS(
            f"Seeded: {created['weather']} weather, {created['events']} events, "
            f"{created['schools']} schools, {created['alerts']} alerts, "
            f"{created['news']} news examples, {created['businesses']} demo businesses, "
            f"{created['deals']} deals, {created['churches']} churches"
        ))
