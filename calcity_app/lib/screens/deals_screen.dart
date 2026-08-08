import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/content_provider.dart';
import '../widgets/empty_state.dart';

class DealsScreen extends StatelessWidget {
  const DealsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Consumer<ContentProvider>(
      builder: (context, prov, _) {
        final deals = prov.deals;
        return Scaffold(
          appBar: AppBar(title: const Text('Local Deals')),
          body: deals.isEmpty
              ? const EmptyStateWidget(
                  icon: Icons.local_offer_outlined,
                  title: 'No deals yet',
                  subtitle: 'Local businesses will post deals here soon.',
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(14),
                  itemCount: deals.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final d = deals[i];
                    final name = d['business_name'] ?? 'Local Business';
                    final title = d['title'] ?? 'Deal';
                    final discount = d['discount'];
                    final desc = d['description'];
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
                            width: 52, height: 52,
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
                                if (discount != null && (discount as String).isNotEmpty)
                                  Container(
                                    margin: const EdgeInsets.only(bottom: 4),
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFD600).withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(discount, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFFFFD600))),
                                  ),
                                Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: cs.onSurface)),
                                const SizedBox(height: 2),
                                Text(name, style: TextStyle(fontSize: 12, color: cs.primary)),
                                if (desc != null && (desc as String).isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(desc, style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant), maxLines: 2, overflow: TextOverflow.ellipsis),
                                ],
                              ],
                            ),
                          ),
                          Icon(Icons.chevron_right, color: cs.onSurfaceVariant.withValues(alpha: 0.4)),
                        ],
                      ),
                    );
                  },
                ),
        );
      },
    );
  }
}
