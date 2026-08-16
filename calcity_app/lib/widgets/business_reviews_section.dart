import 'package:flutter/material.dart';

import '../models/content.dart';
import '../services/api_service.dart';

/// Average rating, review list, and a "write a review" button for a business.
///
/// Shows the star average + count, lists approved reviews newest-first, and
/// (for signed-in users) opens a star-rating + comment dialog. Re-posting
/// updates the user's existing review.
class BusinessReviewsSection extends StatefulWidget {
  final int businessId;
  const BusinessReviewsSection({super.key, required this.businessId});

  @override
  State<BusinessReviewsSection> createState() => _BusinessReviewsSectionState();
}

class _BusinessReviewsSectionState extends State<BusinessReviewsSection> {
  final ApiService _api = ApiService();
  bool _loading = true;
  double? _average;
  int _count = 0;
  List<BusinessReviewItem> _reviews = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final data = await _api.fetchBusinessReviews(widget.businessId);
    if (data != null && mounted) {
      setState(() {
        _average = (data['average'] as num?)?.toDouble();
        _count = (data['count'] as int?) ?? 0;
        _reviews = (data['reviews'] as List<dynamic>? ?? [])
            .map((e) => BusinessReviewItem.fromJson(e as Map<String, dynamic>))
            .toList();
      });
    }
    if (mounted) setState(() => _loading = false);
  }

  bool get _canWrite =>
      _api.authToken != null && _api.authToken!.isNotEmpty;

  Future<void> _writeReview() async {
    var rating = 5;
    final bodyCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Rate this business'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) {
                  final star = i + 1;
                  return IconButton(
                    icon: Icon(
                      star <= rating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                    ),
                    onPressed: () => setDialogState(() => rating = star),
                  );
                }),
              ),
              TextField(
                controller: bodyCtrl,
                decoration:
                    const InputDecoration(labelText: 'Your review (optional)'),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel')),
            FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Submit')),
          ],
        ),
      ),
    );

    if (ok == true && mounted) {
      final success = await _api.submitBusinessReview(
        businessId: widget.businessId,
        rating: rating,
        body: bodyCtrl.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              success ? 'Review submitted!' : 'Could not submit. Try again.')));
      if (success) _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text('Reviews',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface)),
            ),
            if (_canWrite)
              TextButton.icon(
                onPressed: _writeReview,
                icon: const Icon(Icons.rate_review_outlined, size: 18),
                label: const Text('Write a review'),
              ),
          ],
        ),
        const SizedBox(height: 4),
        if (_loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_reviews.isEmpty)
          Text('No reviews yet. Be the first!',
              style: TextStyle(color: cs.onSurfaceVariant))
        else ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(_average?.toStringAsFixed(1) ?? '—',
                  style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: cs.onSurface)),
              const SizedBox(width: 6),
              const Icon(Icons.star, color: Colors.amber, size: 26),
              const SizedBox(width: 8),
              Text('$_count review${_count == 1 ? '' : 's'}',
                  style: TextStyle(color: cs.onSurfaceVariant)),
            ],
          ),
          const SizedBox(height: 8),
          for (final r in _reviews) _reviewTile(cs, r),
        ],
      ],
    );
  }

  Widget _reviewTile(ColorScheme cs, BusinessReviewItem r) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              for (var i = 0; i < 5; i++)
                Icon(i < r.rating ? Icons.star : Icons.star_border,
                    size: 14, color: Colors.amber),
              const SizedBox(width: 8),
              Expanded(
                child: Text(r.author,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface)),
              ),
            ],
          ),
          if (r.body.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(r.body,
                style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
          ],
        ],
      ),
    );
  }
}
