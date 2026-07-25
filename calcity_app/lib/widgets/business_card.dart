import 'package:flutter/material.dart';
import '../models/content.dart';

class BusinessCard extends StatelessWidget {
  final BusinessItem item;
  final VoidCallback? onTap;

  const BusinessCard({super.key, required this.item, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Category icon & color
    IconData icon;
    Color iconColor;
    switch (item.category) {
      case 'home_business':
        icon = Icons.home_work;
        iconColor = Colors.amber.shade700;
        break;
      case 'freelancer':
        icon = Icons.computer;
        iconColor = Colors.blue.shade600;
        break;
      case 'local_shop':
        icon = Icons.store;
        iconColor = Colors.green.shade600;
        break;
      case 'restaurant':
        icon = Icons.restaurant;
        iconColor = Colors.red.shade400;
        break;
      case 'service':
        icon = Icons.build;
        iconColor = Colors.purple.shade400;
        break;
      default:
        icon = Icons.business;
        iconColor = colorScheme.primary;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top section
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.06),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(14),
                    topRight: Radius.circular(14),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: iconColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(icon, size: 20, color: iconColor),
                        ),
                        const Spacer(),
                        if (item.isHomeBased)
                          Tooltip(
                            message: 'Home-based business',
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.amber.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Icon(Icons.home, size: 14, color: Colors.amber.shade700),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      item.name,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    if (item.description != null && item.description!.isNotEmpty)
                      Text(
                        item.description!,
                        style: TextStyle(
                          fontSize: 11,
                          color: colorScheme.onSurfaceVariant,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ),

            // Bottom contact row
            Container(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
              child: Row(
                children: [
                  if (item.contactPhone != null && item.contactPhone!.isNotEmpty)
                    Expanded(
                      child: Row(
                        children: [
                          Icon(Icons.phone, size: 12, color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6)),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              item.contactPhone!,
                              style: TextStyle(
                                fontSize: 11,
                                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (item.isFeatured)
                    Icon(Icons.star, size: 16, color: Colors.amber.shade600),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
