import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/content.dart';
import '../services/api_service.dart';
import '../services/reminder_service.dart';
import 'category_screen.dart';
import 'church_screen.dart';
import 'freelancers_screen.dart';

/// Explore tab: category grid + a full month calendar with per-date events
/// and the ability to set on-device reminders for any event.
class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});
  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  List<EventItem> _events = [];
  bool _loaded = false;
  DateTime _currentMonth =
      DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _selectedDate =
      DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);

  static const _categories = <Map<String, dynamic>>[
    {
      'slug': 'city_works',
      'label': 'City Works',
      'icon': Icons.engineering_outlined,
      'color': Color(0xFF5F6B41)
    },
    {
      'slug': 'church',
      'label': 'Church/Faith',
      'icon': Icons.church_outlined,
      'color': Color(0xFF8B5A3C)
    },
    {
      'slug': 'recreation',
      'label': 'Recreation',
      'icon': Icons.park_outlined,
      'color': Color(0xFF4A7C59)
    },
    {
      'slug': 'law_enforcement',
      'label': 'Law Enforcement',
      'icon': Icons.local_police_outlined,
      'color': Color(0xFF3A4B6D)
    },
    {
      'slug': 'health',
      'label': 'Health',
      'icon': Icons.health_and_safety_outlined,
      'color': Color(0xFF4D8C7A)
    },
    {
      'slug': 'education',
      'label': 'Education',
      'icon': Icons.school_outlined,
      'color': Color(0xFF6B5B95)
    },
    {
      'slug': 'business',
      'label': 'Business',
      'icon': Icons.store_outlined,
      'color': Color(0xFFB8573E)
    },
    {
      'slug': 'traffic',
      'label': 'Traffic',
      'icon': Icons.traffic_outlined,
      'color': Color(0xFF8B6B3A)
    },
    {
      'slug': 'community',
      'label': 'Community',
      'icon': Icons.celebration_outlined,
      'color': Color(0xFF9B5E3A)
    },
    {
      'slug': 'lost_pets',
      'label': 'Lost Pets',
      'icon': Icons.pets_outlined,
      'color': Color(0xFF7A4E8C)
    },
    {
      'slug': 'gigs',
      'label': 'Gigs & Services',
      'icon': Icons.handyman_outlined,
      'color': Color(0xFF3E6B8C)
    },
    {
      'slug': 'neighbor',
      'label': 'Neighbor Love',
      'icon': Icons.favorite_outline,
      'color': Color(0xFFC0455A)
    },
  ];

  static const _categoryColors = <String, Color>{
    'community': Color(0xFF5B9BD5),
    'school': Color(0xFFE8A838),
    'sports': Color(0xFF28A745),
    'city': Color(0xFFC67B5C),
  };

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    final events = await ApiService().fetchEvents();
    if (mounted)
      setState(() {
        _events = events;
        _loaded = true;
      });
  }

  // ---- date helpers ----
  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  List<EventItem> get _selectedDayEvents => _events
      .where(
          (e) => e.startDate != null && _sameDay(e.startDate!, _selectedDate))
      .toList();

  Set<int> get _eventDays {
    final s = <int>{};
    for (final e in _events) {
      if (e.startDate != null &&
          e.startDate!.year == _currentMonth.year &&
          e.startDate!.month == _currentMonth.month) {
        s.add(e.startDate!.day);
      }
    }
    return s;
  }

  void _changeMonth(int delta) {
    setState(() {
      _currentMonth =
          DateTime(_currentMonth.year, _currentMonth.month + delta, 1);
    });
  }

  Future<void> _setReminder(EventItem e) async {
    final start = e.startDate;
    if (start == null) return;
    final remindAt = start.subtract(const Duration(minutes: 30));
    final now = DateTime.now();
    if (remindAt.isBefore(now)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('This event already started — no reminder set.'),
      ));
      return;
    }
    final ok = await ReminderService.instance.requestPermissions();
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Notification permission is needed to set reminders.'),
      ));
      return;
    }
    await ReminderService.instance.scheduleReminder(
      id: e.id,
      title: 'Reminder: ${e.title}',
      body: '${DateFormat('h:mm a').format(start)}'
          '${e.location != null ? ' · ${e.location}' : ''}',
      when: remindAt,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content:
          Text('Reminder set for ${DateFormat('EEE h:mm a').format(remindAt)}'),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Image.asset('assets/images/calcity_logo.png', height: 36),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _categoryGrid(cs),
            _calendar(cs),
            const SizedBox(height: 8),
            _dayEvents(cs),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ---- category grid ----
  Widget _categoryGrid(ColorScheme cs) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.0,
      ),
      itemCount: _categories.length + 1,
      itemBuilder: (ctx, i) {
        if (i == _categories.length) {
          return GestureDetector(
            onTap: () => Navigator.push(
                ctx,
                MaterialPageRoute(
                  builder: (_) => const FreelancersScreen(),
                )),
            child: _categoryTile(
                cs, Icons.person_outline, 'Freelancers', Colors.blue),
          );
        }
        final cat = _categories[i];
        final slug = cat['slug'] as String;
        return GestureDetector(
          onTap: () {
            Navigator.push(
                ctx,
                MaterialPageRoute(
                  builder: (_) => slug == 'church'
                      ? const ChurchScreen()
                      : CategoryScreen(
                          category: slug, title: cat['label'] as String),
                ));
          },
          child: _categoryTile(
            cs,
            cat['icon'] as IconData,
            cat['label'] as String,
            cat['color'] as Color,
          ),
        );
      },
    );
  }

  Widget _categoryTile(
      ColorScheme cs, IconData icon, String label, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outline.withValues(alpha: 0.4)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 10),
          Text(label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: cs.onSurface,
                height: 1.2,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  // ---- full month calendar ----
  Widget _calendar(ColorScheme cs) {
    final firstDay = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final daysInMonth =
        DateTime(_currentMonth.year, _currentMonth.month + 1, 0).day;
    final leading = firstDay.weekday % 7; // Sunday-first
    final eventDays = _eventDays;
    final today = DateTime.now();
    const weekdays = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: cs.outline.withValues(alpha: 0.4)),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // Month header
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () => _changeMonth(-1),
                ),
                Expanded(
                  child: Text(
                    DateFormat('MMMM yyyy').format(_currentMonth),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () => _changeMonth(1),
                ),
              ],
            ),
            const SizedBox(height: 4),
            // Weekday headers
            Row(
              children: [
                for (final d in weekdays)
                  Expanded(
                    child: Text(d,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: cs.onSurfaceVariant)),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            // Day grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                childAspectRatio: 1.0,
              ),
              itemCount: leading + daysInMonth,
              itemBuilder: (ctx, i) {
                if (i < leading) return const SizedBox.shrink();
                final day = i - leading + 1;
                final date =
                    DateTime(_currentMonth.year, _currentMonth.month, day);
                final isToday = _sameDay(date, today);
                final isSelected = _sameDay(date, _selectedDate);
                final hasEvent = eventDays.contains(day);
                return GestureDetector(
                  onTap: () => setState(() => _selectedDate = date),
                  child: Container(
                    margin: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? cs.primary
                          : (isToday
                              ? cs.primary.withValues(alpha: 0.12)
                              : null),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('$day',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isSelected || isToday
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                              color: isSelected
                                  ? (cs.primary.computeLuminance() > 0.5
                                      ? Colors.black
                                      : Colors.white)
                                  : (isToday ? cs.primary : cs.onSurface),
                            )),
                        if (hasEvent)
                          Container(
                            width: 4,
                            height: 4,
                            margin: const EdgeInsets.only(top: 2),
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.white : cs.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // ---- events for the selected day ----
  Widget _dayEvents(ColorScheme cs) {
    final events = _selectedDayEvents;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Events · ${DateFormat('MMM d').format(_selectedDate)}',
            style: TextStyle(
                fontSize: 15, fontWeight: FontWeight.w700, color: cs.onSurface),
          ),
          const SizedBox(height: 8),
          if (!_loaded)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (events.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text('No events this day.',
                  style: TextStyle(color: cs.onSurfaceVariant)),
            )
          else
            for (final e in events) _eventTile(cs, e),
        ],
      ),
    );
  }

  Widget _eventTile(ColorScheme cs, EventItem e) {
    final catColor = _categoryColors[e.category] ?? cs.primary;
    final timeStr =
        e.startDate != null ? DateFormat('h:mm a').format(e.startDate!) : null;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outline.withValues(alpha: 0.4)),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 4,
            height: 44,
            decoration: BoxDecoration(
                color: catColor, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(e.title,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface)),
                if (timeStr != null) ...[
                  const SizedBox(height: 2),
                  Text(timeStr + (e.location != null ? ' · ${e.location}' : ''),
                      style:
                          TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                ],
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.alarm_add_outlined, size: 20),
            tooltip: 'Remind me',
            color: cs.primary,
            onPressed: () => _setReminder(e),
          ),
        ],
      ),
    );
  }
}
