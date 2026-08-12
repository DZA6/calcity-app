import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/content_provider.dart';
import '../widgets/empty_state.dart';

class DealsScreen extends StatefulWidget {
  const DealsScreen({super.key});
  @override
  State<DealsScreen> createState() => _DealsScreenState();
}

class _DealsScreenState extends State<DealsScreen> {
  String _filter = 'all';

  static const _categoryLabels = <String, String>{
    'home_business': 'Home Business',
    'freelancer': 'Freelancer',
    'local_shop': 'Local Shop',
    'service': 'Service',
    'restaurant': 'Restaurant',
    'business_support': 'Business Support',
    'other': 'Other',
  };

  String _label(String? cat) => _categoryLabels[cat] ?? cat ?? 'Other';

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Consumer<ContentProvider>(
      builder: (context, prov, _) {
        final deals = prov.deals;

        // Build the category filter list from what's actually present.
        final seen = <String>{};
        final cats = <String>[];
        for (final d in deals) {
          final c = (d['business_category'] as String?) ?? 'other';
          if (seen.add(c)) cats.add(c);
        }

        final filtered = _filter == 'all'
            ? deals
            : deals
                .where((d) => (d['business_category'] as String?) == _filter)
                .toList();

        return Scaffold(
          appBar: AppBar(title: const Text('Local Deals')),
          body: deals.isEmpty
              ? const EmptyStateWidget(
                  icon: Icons.local_offer_outlined,
                  title: 'No deals yet',
                  subtitle: 'Local businesses will post deals here soon.',
                )
              : Column(
                  children: [
                    // Category filter chips
                    SizedBox(
                      height: 48,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        children: [
                          _chip(cs, 'all', 'All'),
                          for (final c in cats) _chip(cs, c, _label(c)),
                        ],
                      ),
                    ),
                    Expanded(
                      child: filtered.isEmpty
                          ? const Center(
                              child: Text('No deals in this category yet',
                                  style: TextStyle(color: Colors.grey)),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
                              itemCount: filtered.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 10),
                              itemBuilder: (context, i) =>
                                  _dealCard(cs, filtered[i]),
                            ),
                    ),
                  ],
                ),
        );
      },
    );
  }

  Widget _chip(ColorScheme cs, String value, String label) {
    final selected = _filter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => setState(() => _filter = value),
        labelStyle: TextStyle(
          fontSize: 13,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
    );
  }

  Widget _dealCard(ColorScheme cs, dynamic d) {
    final name = d['business_name'] ?? 'Local Business';
    final title = d['title'] ?? 'Deal';
    final discount = d['discount'];
    final desc = d['description'];
    final cat = d['business_category'] as String?;
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outline.withValues(alpha: 0.4)),
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.local_offer, color: cs.primary, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (discount != null && discount.toString().isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(bottom: 4),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: cs.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(discount,
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: cs.primary)),
                  ),
                Text(title,
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface)),
                const SizedBox(height: 2),
                Text('$name · ${_label(cat)}',
                    style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                if (desc != null && (desc as String).isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(desc,
                      style:
                          TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                ],
              ],
            ),
          ),
          Icon(Icons.chevron_right,
              color: cs.onSurfaceVariant.withValues(alpha: 0.4)),
        ],
      ),
    );
  }
}
