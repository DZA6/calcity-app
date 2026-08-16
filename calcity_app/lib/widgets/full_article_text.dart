import 'package:flutter/material.dart';

import '../services/api_service.dart';

/// Displays an article body, upgrading from a short snippet to the full
/// article text fetched from the server when available.
class FullArticleText extends StatefulWidget {
  final int articleId;
  final String snippet;
  const FullArticleText({
    super.key,
    required this.articleId,
    required this.snippet,
  });

  @override
  State<FullArticleText> createState() => _FullArticleTextState();
}

class _FullArticleTextState extends State<FullArticleText> {
  late String _text = widget.snippet;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final full = await ApiService().fetchNewsFull(widget.articleId);
    if (mounted && full != null && full.content.length > _text.length) {
      setState(() => _text = full.content);
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(_text, style: theme.textTheme.bodyLarge?.copyWith(height: 1.6)),
        if (_loading) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 8),
              Text(
                'Loading full article…',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
