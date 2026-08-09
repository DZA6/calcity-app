import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../widgets/comments_section.dart';
import '../widgets/reaction_bar.dart';

class DetailScreen extends StatelessWidget {
  final String title;
  final String itemType;
  final String content;
  final Map<String, String> metadata;

  /// Backend ID of the item — enables comments/reactions on this screen.
  final int? itemId;

  const DetailScreen({
    super.key,
    required this.title,
    required this.itemType,
    required this.content,
    this.metadata = const {},
    this.itemId,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _typeLabel,
          style: theme.textTheme.titleMedium,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Share feature coming soon')),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Text(
              title,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            // Metadata chips
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: _buildMetadataChips(theme),
            ),
            const SizedBox(height: 20),

            // Content
            Text(
              content,
              style: theme.textTheme.bodyLarge?.copyWith(
                height: 1.6,
              ),
            ),
            const SizedBox(height: 24),

            // Social: reactions + comments (needs a backend item id)
            if (itemId != null) ...[
              Divider(color: theme.colorScheme.outlineVariant),
              Row(
                children: [
                  ReactionBar(contentType: itemType, objectId: itemId!),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () => showCommentsSheet(
                      context,
                      contentType: itemType,
                      objectId: itemId!,
                      title: title,
                    ),
                    icon: const Icon(Icons.chat_bubble_outline, size: 18),
                    label: const Text('Comments'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],

            // Action buttons
            _buildActionButtons(theme, context),
          ],
        ),
      ),
    );
  }

  String get _typeLabel {
    switch (itemType) {
      case 'news':
        return 'News Article';
      case 'event':
        return 'Event';
      case 'business':
        return 'Business';
      default:
        return 'Details';
    }
  }

  List<Widget> _buildMetadataChips(ThemeData theme) {
    final chips = <Widget>[];

    if (metadata.containsKey('date')) {
      try {
        final date = DateTime.parse(metadata['date']!);
        chips.add(_chip(
          theme,
          icon: Icons.calendar_today,
          label: DateFormat('MMMM d, yyyy').format(date),
        ));
      } catch (_) {}
    }

    if (metadata.containsKey('start_date')) {
      try {
        final date = DateTime.parse(metadata['start_date']!);
        chips.add(_chip(
          theme,
          icon: Icons.event,
          label: DateFormat('MMM d, yyyy  h:mm a').format(date),
        ));
      } catch (_) {}
    }

    if (metadata.containsKey('location')) {
      chips.add(_chip(
        theme,
        icon: Icons.location_on,
        label: metadata['location']!,
      ));
    }

    if (metadata.containsKey('category')) {
      chips.add(_chip(
        theme,
        icon: Icons.category,
        label: metadata['category']!,
        color: theme.colorScheme.primaryContainer,
        labelColor: theme.colorScheme.onPrimaryContainer,
      ));
    }

    if (metadata.containsKey('address')) {
      chips.add(_chip(
        theme,
        icon: Icons.location_city,
        label: metadata['address']!,
      ));
    }

    if (metadata.containsKey('featured')) {
      chips.add(_chip(
        theme,
        icon: Icons.star,
        label: 'Featured',
        color: Colors.amber.shade100,
        labelColor: Colors.amber.shade800,
      ));
    }

    if (metadata.containsKey('is_home_based')) {
      chips.add(_chip(
        theme,
        icon: Icons.home,
        label: 'Home-Based Business',
        color: Colors.amber.shade100,
        labelColor: Colors.amber.shade800,
      ));
    }

    return chips;
  }

  Widget _chip(
    ThemeData theme, {
    required IconData icon,
    required String label,
    Color? color,
    Color? labelColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color ?? theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: labelColor ?? theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: labelColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(ThemeData theme, BuildContext context) {
    final actions = <Widget>[];

    if (metadata.containsKey('phone')) {
      actions.add(
        _actionButton(
          theme,
          icon: Icons.phone,
          label: 'Call',
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Calling ${metadata['phone']}...')),
            );
          },
        ),
      );
    }

    if (metadata.containsKey('email')) {
      actions.add(
        _actionButton(
          theme,
          icon: Icons.email,
          label: 'Email',
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Emailing ${metadata['email']}...')),
            );
          },
        ),
      );
    }

    if (metadata.containsKey('website')) {
      actions.add(
        _actionButton(
          theme,
          icon: Icons.language,
          label: 'Website',
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Opening ${metadata['website']}...')),
            );
          },
        ),
      );
    }

    if (metadata.containsKey('source_url')) {
      actions.add(
        _actionButton(
          theme,
          icon: Icons.open_in_new,
          label: 'Source',
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text('Opening ${metadata['source_url']}...')),
            );
          },
        ),
      );
    }

    if (actions.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: actions,
    );
  }

  Widget _actionButton(
    ThemeData theme, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}
