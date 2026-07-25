import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/content.dart';

class EventCard extends StatelessWidget {
  final EventItem item;
  final VoidCallback? onTap;

  const EventCard({super.key, required this.item, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final dateFormat = DateFormat('MMM d');
    final timeFormat = DateFormat('h:mm a');

    // Category colors
    Color categoryColor;
    IconData categoryIcon;
    switch (item.category) {
      case 'school':
        categoryColor = Colors.blue;
        categoryIcon = Icons.school;
        break;
      case 'sports':
        categoryColor = Colors.green;
        categoryIcon = Icons.sports_soccer;
        break;
      case 'city':
        categoryColor = Colors.purple;
        categoryIcon = Icons.location_city;
        break;
      default:
        categoryColor = colorScheme.primary;
        categoryIcon = Icons.people;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Date badge
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    item.startDate != null ? dateFormat.format(item.startDate!).split(' ')[0] : '--',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.primary,
                    ),
                  ),
                  Text(
                    item.startDate != null ? dateFormat.format(item.startDate!).split(' ')[1] : '',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: colorScheme.primary.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),

            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  if (item.startDate != null)
                    Row(
                      children: [
                        Icon(Icons.access_time, size: 13, color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7)),
                        const SizedBox(width: 4),
                        Text(
                          timeFormat.format(item.startDate!),
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  if (item.location != null && item.location!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 13, color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7)),
                        const SizedBox(width: 4),
                        Text(
                          item.location!,
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // Category chip
            if (item.category != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: categoryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  item.category!,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: categoryColor,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
