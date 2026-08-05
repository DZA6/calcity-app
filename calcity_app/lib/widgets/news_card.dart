import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/content.dart';

class NewsCard extends StatelessWidget {
  final NewsItem item;
  final VoidCallback? onTap;

  const NewsCard({super.key, required this.item, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final dateFormat = DateFormat('MMM d, yyyy');

    return GestureDetector(
      onTap: onTap,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Hero image at top — with fallback color bar if no image
            if (item.imageUrl != null && item.imageUrl!.isNotEmpty)
              Stack(
                children: [
                  AspectRatio(
                    aspectRatio: 16 / 10,
                    child: Image.network(
                      item.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _imageFallback(cs),
                      loadingBuilder: (ctx, child, progress) {
                        if (progress == null) return child;
                        return _imageFallback(cs);
                      },
                    ),
                  ),
                  if (item.videoUrl != null && item.videoUrl!.isNotEmpty)
                    Positioned(
                      bottom: 8, right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.play_circle_filled, color: Colors.white, size: 14),
                            SizedBox(width: 4),
                            Text('Video', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                ],
              )
            else
              Container(
                height: 4,
                color: item.featured ? cs.primary : cs.tertiary,
              ),
            // Text content
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (item.featured)
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: cs.primaryContainer, borderRadius: BorderRadius.circular(6)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.star, size: 12, color: cs.onPrimaryContainer),
                          const SizedBox(width: 4),
                          Text('Featured',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: cs.onPrimaryContainer)),
                        ],
                      ),
                    ),
                  Text(item.title,
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: cs.onSurface, height: 1.3),
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 6),
                  Text(item.excerpt,
                      style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant, height: 1.4),
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 10),
                  Row(children: [
                    Icon(Icons.schedule, size: 13, color: cs.onSurfaceVariant.withValues(alpha: 0.6)),
                    const SizedBox(width: 4),
                    Text(dateFormat.format(item.createdAt),
                        style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant.withValues(alpha: 0.6))),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imageFallback(ColorScheme cs) {
    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceVariant,
      ),
      child: Center(
        child: Icon(Icons.article_outlined, color: cs.outline, size: 32),
      ),
    );
  }
}
