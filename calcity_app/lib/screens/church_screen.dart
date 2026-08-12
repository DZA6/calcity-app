import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/content.dart';
import '../services/api_service.dart';

/// Churches & Faith directory — one tab per church, tap a tab for that
/// church's service times, events, food giveaways, and contact info.
class ChurchScreen extends StatefulWidget {
  const ChurchScreen({super.key});
  @override
  State<ChurchScreen> createState() => _ChurchScreenState();
}

class _ChurchScreenState extends State<ChurchScreen> {
  List<ChurchItem> _churches = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await ApiService().fetchChurches();
    if (mounted)
      setState(() {
        _churches = list;
        _loading = false;
      });
  }

  String _shortName(String name) {
    final parts = name.split(' ');
    return parts.length > 2 ? parts.take(2).join(' ') : name;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Churches & Faith')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_churches.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Churches & Faith')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.church_outlined, size: 56, color: cs.outline),
              const SizedBox(height: 12),
              Text('No churches listed yet',
                  style: TextStyle(color: cs.onSurfaceVariant)),
            ],
          ),
        ),
      );
    }

    return DefaultTabController(
      length: _churches.length,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Churches & Faith'),
          bottom: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              for (final c in _churches) Tab(text: _shortName(c.name)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            for (final c in _churches) _ChurchDetail(church: c),
          ],
        ),
      ),
    );
  }
}

class _ChurchDetail extends StatelessWidget {
  final ChurchItem church;
  const _ChurchDetail({required this.church});

  Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        // Header
        Container(
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: cs.outline.withValues(alpha: 0.4)),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: cs.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.church_outlined,
                        color: cs.primary, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(church.name,
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: cs.onSurface)),
                        if (church.denomination != null &&
                            church.denomination!.isNotEmpty)
                          Text(church.denomination!,
                              style:
                                  TextStyle(fontSize: 13, color: cs.primary)),
                      ],
                    ),
                  ),
                  if (church.isDemo)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: cs.onSurfaceVariant.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text('DEMO',
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: cs.onSurfaceVariant)),
                    ),
                ],
              ),
              if (church.description != null &&
                  church.description!.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(church.description!,
                    style: TextStyle(
                        fontSize: 14, color: cs.onSurfaceVariant, height: 1.4)),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),

        _infoSection(
            cs, Icons.schedule_outlined, 'Service Times', church.serviceTimes),
        _infoSection(cs, Icons.event_outlined, 'Events', church.events),
        _infoSection(cs, Icons.volunteer_activism_outlined, 'Food Giveaways',
            church.foodGiveaway),

        // Contact
        if (church.address != null ||
            church.phone != null ||
            church.website != null) ...[
          const SizedBox(height: 4),
          _sectionHeader(cs, 'Contact'),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: cs.outline.withValues(alpha: 0.4)),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (church.address != null)
                  _row(cs, Icons.location_on_outlined, church.address!),
                if (church.phone != null)
                  GestureDetector(
                    onTap: () => _launch(
                        'tel:${church.phone!.replaceAll(RegExp(r'[^0-9+]'), '')}'),
                    child: _row(cs, Icons.phone_outlined, church.phone!),
                  ),
                if (church.website != null)
                  GestureDetector(
                    onTap: () => _launch(church.website!),
                    child: _row(cs, Icons.open_in_new, church.website!),
                  ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _sectionHeader(ColorScheme cs, String title) => Text(title,
      style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: cs.onSurfaceVariant,
          letterSpacing: 0.3));

  Widget _infoSection(
      ColorScheme cs, IconData icon, String title, String? body) {
    if (body == null || body.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: cs.outline.withValues(alpha: 0.4)),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(icon, size: 18, color: cs.primary),
              const SizedBox(width: 8),
              Text(title,
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface)),
            ]),
            const SizedBox(height: 8),
            Text(body,
                style: TextStyle(
                    fontSize: 13, color: cs.onSurfaceVariant, height: 1.5)),
          ],
        ),
      ),
    );
  }

  Widget _row(ColorScheme cs, IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon,
              size: 16, color: cs.onSurfaceVariant.withValues(alpha: 0.7)),
          const SizedBox(width: 8),
          Expanded(
              child: Text(text,
                  style: TextStyle(
                      fontSize: 13, color: cs.onSurfaceVariant, height: 1.3))),
        ],
      ),
    );
  }
}
