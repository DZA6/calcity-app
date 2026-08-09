import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/social.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import 'create_topic_screen.dart';
import 'login_screen.dart';
import 'topic_screen.dart';

/// Community tab — list of discussion topics people are talking about.
class ConversationsScreen extends StatefulWidget {
  const ConversationsScreen({super.key});

  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen> {
  List<DiscussionTopicItem> _topics = [];
  bool _loading = true;
  String? _selectedCategory;

  static const _categories = <String>[
    'general',
    'news',
    'events',
    'business',
    'help',
  ];

  static const _categoryLabels = <String, String>{
    'general': 'General',
    'news': 'News',
    'events': 'Events',
    'business': 'Business',
    'help': 'Help',
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final items = await ApiService().fetchTopics(category: _selectedCategory);
    if (mounted) {
      setState(() {
        _topics = items;
        _loading = false;
      });
    }
  }

  Future<void> _newTopic() async {
    final auth = context.read<AuthProvider>();
    if (!auth.isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Log in to start a discussion')),
      );
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
      return;
    }
    final created = await Navigator.push<DiscussionTopicItem>(
      context,
      MaterialPageRoute(builder: (_) => const CreateTopicScreen()),
    );
    if (created != null) {
      setState(() {
        _topics.insert(0, created);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('💬 Conversations'),
        actions: [
          IconButton(
            onPressed: _newTopic,
            icon: const Icon(Icons.add_comment_outlined),
            tooltip: 'New topic',
          ),
        ],
      ),
      body: Column(
        children: [
          // Category filter chips
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              children: [
                _filterChip(cs, null, 'All'),
                for (final c in _categories)
                  _filterChip(cs, c, _categoryLabels[c] ?? c),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _topics.isEmpty
                    ? _emptyState(cs)
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          itemCount: _topics.length,
                          itemBuilder: (context, i) =>
                              _topicCard(cs, _topics[i]),
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _newTopic,
        icon: const Icon(Icons.add),
        label: const Text('New Topic'),
      ),
    );
  }

  Widget _filterChip(ColorScheme cs, String? value, String label) {
    final selected = _selectedCategory == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) {
          setState(() {
            _selectedCategory = value;
            _loading = true;
          });
          _load();
        },
        visualDensity: VisualDensity.compact,
        showCheckmark: false,
      ),
    );
  }

  Widget _emptyState(ColorScheme cs) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.forum_outlined, size: 64, color: cs.onSurfaceVariant),
          const SizedBox(height: 16),
          Text(
            'No discussions yet',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 8),
          Text(
            'Start the first conversation!',
            style: TextStyle(color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _topicCard(ColorScheme cs, DiscussionTopicItem t) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          final updated = await Navigator.push<DiscussionTopicItem>(
            context,
            MaterialPageRoute(builder: (_) => TopicScreen(topicId: t.id)),
          );
          if (updated != null && mounted) {
            setState(() {
              final idx = _topics.indexWhere((x) => x.id == updated.id);
              if (idx >= 0) _topics[idx] = updated;
            });
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (t.isPinned) ...[
                    const Icon(Icons.push_pin, size: 16, color: Color(0xFFB8573E)),
                    const SizedBox(width: 4),
                  ],
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: cs.primaryContainer,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _categoryLabels[t.category] ?? t.category,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: cs.onPrimaryContainer,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    timeAgo(t.createdAt),
                    style:
                        TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                t.title,
                style: const TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (t.body.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  t.body,
                  style: TextStyle(
                    fontSize: 13,
                    color: cs.onSurfaceVariant,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.person_outline, size: 14, color: cs.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(
                    t.author,
                    style:
                        TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.chat_bubble_outline,
                      size: 14, color: cs.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(
                    '${t.commentCount}',
                    style:
                        TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.thumb_up_outlined,
                      size: 14, color: cs.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(
                    '${t.likes}',
                    style:
                        TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
