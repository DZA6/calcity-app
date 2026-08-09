import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/social.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import 'create_topic_screen.dart';
import 'login_screen.dart';
import 'topic_screen.dart';

/// Seddit — Reddit-style community tab.
/// Posts with upvote/downvote arrows, sort tabs, and comment counts.
class ConversationsScreen extends StatefulWidget {
  const ConversationsScreen({super.key});

  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen> {
  List<DiscussionTopicItem> _topics = [];
  bool _loading = true;
  String? _selectedCategory;
  String _sort = 'hot'; // hot | top | new

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

  static const _sortTabs = [
    ('hot', '🔥 Hot'),
    ('top', '⬆ Top'),
    ('new', '🆕 New'),
  ];

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

  List<DiscussionTopicItem> _sortedTopics() {
    final list = List<DiscussionTopicItem>.from(_topics);
    switch (_sort) {
      case 'top':
        list.sort((a, b) => (b.likes - b.dislikes).compareTo(a.likes - a.dislikes));
      case 'new':
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      default: // hot = pinned first, then by engagement
        list.sort((a, b) {
          if (a.isPinned != b.isPinned) return a.isPinned ? -1 : 1;
          return (b.likes + b.commentCount).compareTo(a.likes + a.commentCount);
        });
    }
    return list;
  }

  void _newTopic() {
    final auth = context.read<AuthProvider>();
    if (!auth.isLoggedIn) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
      return;
    }
    Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateTopicScreen()))
        .then((created) {
      if (created == true) _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFFF4500),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text('s/Seddit',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white)),
            ),
            const SizedBox(width: 8),
            Text(_categoryLabels[_selectedCategory] ?? 'Community',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: cs.onSurface)),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _newTopic,
            icon: const Icon(Icons.add_comment_outlined),
            tooltip: 'New post',
          ),
        ],
      ),
      body: Column(
        children: [
          // Sort tabs — Reddit style
          Container(
            height: 42,
            margin: const EdgeInsets.fromLTRB(12, 6, 12, 2),
            decoration: BoxDecoration(
              color: cs.surfaceVariant.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Row(
              children: [
                for (final (key, label) in _sortTabs)
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _sort = key),
                      child: Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: _sort == key ? cs.primary : Colors.transparent,
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: Text(label,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: _sort == key ? cs.onPrimary : cs.onSurfaceVariant,
                          )),
                      ),
                    ),
                  ),
              ],
            ),
          ),
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
                : _sortedTopics().isEmpty
                    ? _emptyState(cs)
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          itemCount: _sortedTopics().length,
                          itemBuilder: (context, i) =>
                              _sedditCard(cs, _sortedTopics()[i]),
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _newTopic,
        icon: const Icon(Icons.add),
        label: const Text('New Post'),
        backgroundColor: const Color(0xFFFF4500),
        foregroundColor: Colors.white,
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
          Text('No posts in Seddit yet',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: cs.onSurface)),
          const SizedBox(height: 6),
          Text('Start the first conversation!',
            style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
        ],
      ),
    );
  }

  /// Reddit-style post card: vote column on left, content on right.
  Widget _sedditCard(ColorScheme cs, DiscussionTopicItem t) {
    final score = t.likes - t.dislikes;
    final scoreColor = score > 0
        ? const Color(0xFFFF4500)
        : score < 0
            ? const Color(0xFF7193FF)
            : cs.onSurfaceVariant;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: cs.outline.withValues(alpha: 0.35)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
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
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Vote column ──
              Column(
                children: [
                  InkWell(
                    onTap: () => _vote(t, 'like'),
                    borderRadius: BorderRadius.circular(8),
                    child: Icon(
                      t.myValue == 'like' ? Icons.arrow_drop_up : Icons.arrow_drop_up,
                      size: 30,
                      color: t.myValue == 'like' ? const Color(0xFFFF4500) : cs.onSurfaceVariant,
                    ),
                  ),
                  Text('$score',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: scoreColor,
                    )),
                  InkWell(
                    onTap: () => _vote(t, 'dislike'),
                    borderRadius: BorderRadius.circular(8),
                    child: Icon(
                      Icons.arrow_drop_down,
                      size: 30,
                      color: t.myValue == 'dislike' ? const Color(0xFF7193FF) : cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 6),
              // ── Content column ──
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (t.isPinned) ...[
                          const Icon(Icons.push_pin, size: 14, color: Color(0xFFFF4500)),
                          const SizedBox(width: 3),
                        ],
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: cs.primaryContainer,
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            _categoryLabels[t.category] ?? t.category,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: cs.onPrimaryContainer,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'u/${t.author}',
                          style: TextStyle(fontSize: 10.5, color: cs.onSurfaceVariant),
                        ),
                        const Spacer(),
                        Text(
                          timeAgo(t.createdAt),
                          style: TextStyle(fontSize: 10.5, color: cs.onSurfaceVariant),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      t.title,
                      style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, height: 1.2),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      t.body,
                      style: TextStyle(fontSize: 12.5, color: cs.onSurfaceVariant, height: 1.3),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    // Footer row
                    Row(
                      children: [
                        if (t.isClosed) ...[
                          const Icon(Icons.lock, size: 13, color: Colors.grey),
                          const SizedBox(width: 3),
                          Text('Locked', style: TextStyle(fontSize: 10.5, color: Colors.grey)),
                          const SizedBox(width: 10),
                        ],
                        Icon(Icons.chat_bubble_outline, size: 13, color: cs.onSurfaceVariant),
                        const SizedBox(width: 3),
                        Text('${t.commentCount} comments',
                          style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _vote(DiscussionTopicItem t, String value) async {
    final auth = context.read<AuthProvider>();
    if (!auth.isLoggedIn) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
      return;
    }
    final summary = await ApiService().toggleReaction(
      contentType: 'topic',
      objectId: t.id,
      value: value,
    );
    if (summary != null && mounted) {
      setState(() {
        final idx = _topics.indexWhere((x) => x.id == t.id);
        if (idx >= 0) {
          _topics[idx] = DiscussionTopicItem(
            id: t.id,
            title: t.title,
            body: t.body,
            author: t.author,
            authorId: t.authorId,
            category: t.category,
            isPinned: t.isPinned,
            isClosed: t.isClosed,
            createdAt: t.createdAt,
            updatedAt: t.updatedAt,
            commentCount: t.commentCount,
            likes: summary.likes,
            dislikes: summary.dislikes,
            myValue: summary.myValue,
          );
        }
      });
    }
  }
}

String timeAgo(DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inMinutes < 1) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  return '${dt.month}/${dt.day}/${dt.year}';
}
