import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/social.dart';
import '../providers/auth_provider.dart';
import '../screens/login_screen.dart';
import '../services/api_service.dart';

/// Comment list + composer for any content (news, event, business, topic…).
///
/// Renders a bounded column: header, scrollable comment list, and a pinned
/// composer (or a login prompt when signed out). Use inside a bottom sheet
/// or inside a fixed-height SizedBox — the list scrolls internally.
class CommentsSection extends StatefulWidget {
  final String contentType;
  final int objectId;

  const CommentsSection({
    super.key,
    required this.contentType,
    required this.objectId,
  });

  @override
  State<CommentsSection> createState() => _CommentsSectionState();
}

class _CommentsSectionState extends State<CommentsSection> {
  final List<CommentItem> _comments = [];
  final TextEditingController _controller = TextEditingController();
  bool _loading = true;
  bool _sending = false;
  int? _replyToId;
  String _replyToAuthor = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final items =
        await ApiService().fetchComments(widget.contentType, widget.objectId);
    if (mounted) {
      setState(() {
        _comments
          ..clear()
          ..addAll(items);
        _loading = false;
      });
    }
  }

  Future<void> _send() async {
    final auth = context.read<AuthProvider>();
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;
    if (!auth.isLoggedIn) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
      return;
    }
    setState(() => _sending = true);
    final created = await ApiService().postComment(
      contentType: widget.contentType,
      objectId: widget.objectId,
      body: text,
      parentId: _replyToId,
    );
    if (mounted) {
      setState(() {
        _sending = false;
        if (created != null) {
          _comments.add(created);
          _controller.clear();
          _replyToId = null;
          _replyToAuthor = '';
        }
      });
    }
  }

  Future<void> _delete(CommentItem comment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete comment?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final ok = await ApiService().deleteComment(comment.id);
    if (ok && mounted) {
      setState(() => _comments.removeWhere((c) => c.id == comment.id));
    }
  }

  void _startReply(CommentItem c) {
    setState(() {
      _replyToId = c.id;
      _replyToAuthor = c.author;
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final auth = context.watch<AuthProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header + count
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Row(
            children: [
              Icon(Icons.chat_bubble_outline, size: 18, color: cs.onSurfaceVariant),
              const SizedBox(width: 6),
              Text(
                'Comments (${_comments.length})',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        // List / loading / empty
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _comments.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.forum_outlined,
                              size: 40, color: cs.onSurfaceVariant),
                          const SizedBox(height: 8),
                          Text(
                            'No comments yet — start the conversation',
                            style: TextStyle(color: cs.onSurfaceVariant),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      children: _buildCommentTiles(cs),
                    ),
        ),
        // Composer / login prompt
        if (auth.isLoggedIn) ...[
          if (_replyToId != null)
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 4),
              child: InputChip(
                label: Text('Replying to @$_replyToAuthor'),
                onDeleted: () => setState(() {
                  _replyToId = null;
                  _replyToAuthor = '';
                }),
                deleteIcon: const Icon(Icons.close, size: 16),
                visualDensity: VisualDensity.compact,
              ),
            ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  enabled: !_sending,
                  minLines: 1,
                  maxLines: 3,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _send(),
                  decoration: InputDecoration(
                    hintText: 'Add a comment…',
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              IconButton.filled(
                onPressed: _sending ? null : _send,
                icon: _sending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send, size: 20),
                tooltip: 'Send',
              ),
            ],
          ),
        ] else
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              ),
              icon: const Icon(Icons.login, size: 18),
              label: const Text('Log in to join the conversation'),
            ),
          ),
      ],
    );
  }

  List<Widget> _buildCommentTiles(ColorScheme cs) {
    final tops = _comments
        .where((c) => c.parentId == null)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final tiles = <Widget>[];
    for (final t in tops) {
      tiles.add(_commentTile(cs, t));
      final replies =
          _comments.where((c) => c.parentId == t.id).toList()
            ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
      for (final r in replies) {
        tiles.add(
          Padding(
            padding: const EdgeInsets.only(left: 36),
            child: _commentTile(cs, r, isReply: true),
          ),
        );
      }
    }
    return tiles;
  }

  Widget _commentTile(ColorScheme cs, CommentItem c, {bool isReply = false}) {
    final auth = context.read<AuthProvider>();
    final canDelete = auth.username != null && c.author == auth.username;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 3),
      padding: EdgeInsets.only(
        left: isReply ? 10 : 8,
        right: 4,
        top: 6,
        bottom: 6,
      ),
      decoration: BoxDecoration(
        color: isReply
            ? cs.surfaceContainerHighest.withValues(alpha: 0.4)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        border: isReply
            ? Border(left: BorderSide(color: cs.outlineVariant, width: 2))
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 11,
                backgroundColor: cs.primaryContainer,
                child: Text(
                  c.author.isNotEmpty ? c.author[0].toUpperCase() : '?',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: cs.onPrimaryContainer,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  c.author,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                timeAgo(c.createdAt),
                style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
              ),
              if (canDelete)
                IconButton(
                  onPressed: () => _delete(c),
                  icon: const Icon(Icons.delete_outline, size: 16),
                  color: cs.onSurfaceVariant,
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Delete',
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 30, top: 2),
            child: Text(
              c.body,
              style: TextStyle(fontSize: 13.5, height: 1.4, color: cs.onSurface),
            ),
          ),
          if (!isReply)
            Padding(
              padding: const EdgeInsets.only(left: 26),
              child: TextButton.icon(
                onPressed: () => _startReply(c),
                icon: const Icon(Icons.reply, size: 13),
                label: const Text('Reply', style: TextStyle(fontSize: 11.5)),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  minimumSize: const Size(0, 28),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Open the comments UI as a modal bottom sheet for a content item.
void showCommentsSheet(
  BuildContext context, {
  required String contentType,
  required int objectId,
  required String title,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => Container(
      height: MediaQuery.of(ctx).size.height * 0.75,
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.forum_outlined,
                  size: 20, color: Theme.of(ctx).colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(ctx).textTheme.titleMedium,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: CommentsSection(
              contentType: contentType,
              objectId: objectId,
            ),
          ),
        ],
      ),
    ),
  );
}
