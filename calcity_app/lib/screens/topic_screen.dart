import 'package:flutter/material.dart';

import '../models/social.dart';
import '../services/api_service.dart';
import '../widgets/comments_section.dart';
import '../widgets/reaction_bar.dart';

/// A single discussion thread: topic body, reactions, comments.
class TopicScreen extends StatefulWidget {
  final int topicId;

  const TopicScreen({super.key, required this.topicId});

  @override
  State<TopicScreen> createState() => _TopicScreenState();
}

class _TopicScreenState extends State<TopicScreen> {
  DiscussionTopicItem? _topic;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final topic = await ApiService().fetchTopic(widget.topicId);
    if (mounted) {
      setState(() {
        _topic = topic;
        _loading = false;
      });
    }
  }

  static const _categoryLabels = <String, String>{
    'general': 'General',
    'news': 'News',
    'events': 'Events',
    'business': 'Business',
    'help': 'Help',
  };

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = _topic;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Discussion'),
        actions: [
          if (t != null && !t.isClosed)
            IconButton(
              onPressed: _load,
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh',
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : t == null
              ? Center(
                  child: Text(
                    'Topic not found',
                    style: TextStyle(color: cs.onSurfaceVariant),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        children: [
                          if (t.isPinned) ...[
                            const Icon(Icons.push_pin,
                                size: 16, color: Color(0xFFB8573E)),
                            const SizedBox(width: 6),
                          ],
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: cs.primaryContainer,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              _categoryLabels[t.category] ?? t.category,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: cs.onPrimaryContainer,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            timeAgo(t.createdAt),
                            style: TextStyle(
                                fontSize: 12, color: cs.onSurfaceVariant),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        t.title,
                        style: const TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.w800,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 12,
                            backgroundColor: cs.primaryContainer,
                            child: Text(
                              t.author.isNotEmpty
                                  ? t.author[0].toUpperCase()
                                  : '?',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: cs.onPrimaryContainer,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            t.author,
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                          if (t.isClosed) ...[
                            const SizedBox(width: 10),
                            const Icon(Icons.lock_outline,
                                size: 15, color: Colors.orange),
                            const SizedBox(width: 3),
                            Text(
                              'Closed',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.orange.shade800),
                            ),
                          ],
                        ],
                      ),
                      if (t.body.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        Text(
                          t.body,
                          style: const TextStyle(fontSize: 15, height: 1.6),
                        ),
                      ],
                      const SizedBox(height: 16),
                      // Reactions
                      ReactionBar(contentType: 'topic', objectId: t.id),
                      const SizedBox(height: 16),
                      Divider(color: cs.outlineVariant),
                      // Comments (inline, fixed-height scroll)
                      SizedBox(
                        height: 400,
                        child: t.isClosed
                            ? _closedMessage(cs)
                            : CommentsSection(
                                contentType: 'topic', objectId: t.id),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _closedMessage(ColorScheme cs) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.lock_outline, size: 40, color: cs.onSurfaceVariant),
          const SizedBox(height: 8),
          Text(
            'This discussion is closed',
            style: TextStyle(color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
