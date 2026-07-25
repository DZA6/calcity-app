import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/content_provider.dart';
import '../widgets/event_card.dart';
import '../widgets/category_chip.dart';
import 'detail_screen.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  String? _selectedCategory;
  final List<String> _categories = [
    'All',
    'Community',
    'School',
    'Sports',
    'City',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Events')),
      body: Consumer<ContentProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.events.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.events.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.event_busy,
                    size: 64,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No events available',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Pull down to refresh',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            );
          }

          var events = List<dynamic>.from(provider.events);
          events.sort((a, b) {
            if (a.startDate == null && b.startDate == null) return 0;
            if (a.startDate == null) return 1;
            if (b.startDate == null) return -1;
            return a.startDate!.compareTo(b.startDate!);
          });

          if (_selectedCategory != null && _selectedCategory != 'All') {
            events = events
                .where((e) =>
                    e.category?.toLowerCase() ==
                    _selectedCategory!.toLowerCase())
                .toList();
          }

          return RefreshIndicator(
            onRefresh: () => provider.refreshEvents(),
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: _buildCategoryFilter(theme),
                ),
                if (events.isEmpty)
                  SliverFillRemaining(
                    child: Center(
                      child: Text(
                        'No events in this category',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final item = events[index];
                        return EventCard(
                          item: item,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DetailScreen(
                                title: item.title,
                                itemType: 'event',
                                content: item.description ??
                                    'No description available.',
                                metadata: {
                                  if (item.startDate != null)
                                    'start_date':
                                        item.startDate!.toIso8601String(),
                                  if (item.endDate != null)
                                    'end_date':
                                        item.endDate!.toIso8601String(),
                                  if (item.location != null)
                                    'location': item.location!,
                                  if (item.category != null)
                                    'category': item.category!,
                                },
                              ),
                            ),
                          ),
                        );
                      },
                      childCount: events.length,
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCategoryFilter(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          ..._categories.map(
            (cat) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: CategoryChip(
                label: cat,
                isSelected: _selectedCategory == cat ||
                    (_selectedCategory == null && cat == 'All'),
                onTap: () {
                  setState(() {
                    _selectedCategory = cat == 'All' ? null : cat;
                  });
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
