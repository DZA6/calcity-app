import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/content.dart';

class BusinessCard extends StatelessWidget {
  final BusinessItem item;
  final VoidCallback? onTap;

  const BusinessCard({super.key, required this.item, this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    IconData icon;
    Color iconColor;
    switch (item.category) {
      case 'home_business':
        icon = Icons.home_work;
        iconColor = Colors.amber.shade600;
        break;
      case 'freelancer':
        icon = Icons.computer;
        iconColor = Colors.blue.shade400;
        break;
      case 'local_shop':
        icon = Icons.store;
        iconColor = Colors.green.shade500;
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
        iconColor = cs.primary;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cs.outline.withValues(alpha: 0.35)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Optional business photo on top
            if (item.imageUrl != null && item.imageUrl!.isNotEmpty)
              SizedBox(
                height: 92,
                width: double.infinity,
                child: CachedNetworkImage(
                  imageUrl: item.imageUrl!,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => _headerRow(cs, icon, iconColor),
                  placeholder: (_, __) => _headerRow(cs, icon, iconColor),
                ),
              )
            else
              _headerRow(cs, icon, iconColor),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          item.name,
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: cs.onSurface, height: 1.2),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (item.isDemo) ...[
                        const SizedBox(width: 5),
                        Container(
                          margin: const EdgeInsets.only(top: 1),
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFD600).withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: const Text('DEMO',
                              style: TextStyle(fontSize: 8, fontWeight: FontWeight.w800, color: Color(0xFFB28704), letterSpacing: 0.4)),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Description
                  if (item.description != null && item.description!.isNotEmpty)
                    Text(
                      item.description!,
                      style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant, height: 1.3),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const Spacer(),
                  // Bottom info
                  if (item.contactPhone != null && item.contactPhone!.isNotEmpty)
                    Row(
                      children: [
                        Icon(Icons.phone_outlined, size: 13, color: cs.onSurfaceVariant.withValues(alpha: 0.5)),
                        const SizedBox(width: 4),
                        Text(
                          item.contactPhone!,
                          style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant.withValues(alpha: 0.6)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Icon + featured badge row (also the image fallback/placeholder)
  Widget _headerRow(ColorScheme cs, IconData icon, Color iconColor) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: iconColor),
          ),
          const Spacer(),
          if (item.isFeatured)
            Icon(Icons.star_rounded, size: 18, color: Colors.amber.shade500),
          if (item.isHomeBased)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text('Local',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.amber.shade700)),
            ),
        ],
      ),
    );
  }
}
