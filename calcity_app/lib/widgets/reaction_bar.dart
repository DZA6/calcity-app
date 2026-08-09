import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/social.dart';
import '../providers/auth_provider.dart';
import '../screens/login_screen.dart';
import '../services/api_service.dart';

/// Like/dislike bar with live counts. Tapping toggles (like -> remove,
/// dislike -> switch). Requires login; prompts with the login screen.
class ReactionBar extends StatefulWidget {
  final String contentType; // 'news' | 'event' | 'business' | 'school' | 'topic'
  final int objectId;

  const ReactionBar({
    super.key,
    required this.contentType,
    required this.objectId,
  });

  @override
  State<ReactionBar> createState() => _ReactionBarState();
}

class _ReactionBarState extends State<ReactionBar> {
  ReactionSummary? _summary;
  bool _busy = false;

  static const _likeColor = Color(0xFF2E7D32);
  static const _dislikeColor = Color(0xFFC62828);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final s = await ApiService()
        .fetchReactionSummary(widget.contentType, widget.objectId);
    if (mounted && s != null) setState(() => _summary = s);
  }

  Future<void> _toggle(String value) async {
    final auth = context.read<AuthProvider>();
    if (!auth.isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Log in to like or dislike')),
      );
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
      return;
    }
    if (_busy) return;
    setState(() => _busy = true);
    final optimistic =
        _applyToggle(_summary ?? const ReactionSummary(likes: 0, dislikes: 0), value);
    setState(() => _summary = optimistic);
    final result = await ApiService().toggleReaction(
      contentType: widget.contentType,
      objectId: widget.objectId,
      value: value,
    );
    if (mounted) {
      setState(() {
        _summary = result ?? optimistic;
        _busy = false;
      });
    }
  }

  ReactionSummary _applyToggle(ReactionSummary s, String value) {
    final likes = math.max(0, s.likes);
    final dislikes = math.max(0, s.dislikes);
    if (s.myValue == value) {
      return value == 'like'
          ? ReactionSummary(likes: math.max(0, likes - 1), dislikes: dislikes)
          : ReactionSummary(likes: likes, dislikes: math.max(0, dislikes - 1));
    }
    if (s.myValue == 'like') {
      return ReactionSummary(
        likes: math.max(0, likes - 1),
        dislikes: dislikes + 1,
        myValue: 'dislike',
      );
    }
    if (s.myValue == 'dislike') {
      return ReactionSummary(
        likes: likes + 1,
        dislikes: math.max(0, dislikes - 1),
        myValue: 'like',
      );
    }
    return value == 'like'
        ? ReactionSummary(likes: likes + 1, dislikes: dislikes, myValue: 'like')
        : ReactionSummary(likes: likes, dislikes: dislikes + 1, myValue: 'dislike');
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final s = _summary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _button(
          icon: s?.myValue == 'like' ? Icons.thumb_up : Icons.thumb_up_outlined,
          count: s?.likes ?? 0,
          color: s?.myValue == 'like' ? _likeColor : cs.onSurfaceVariant,
          onTap: () => _toggle('like'),
        ),
        const SizedBox(width: 10),
        _button(
          icon: s?.myValue == 'dislike'
              ? Icons.thumb_down
              : Icons.thumb_down_outlined,
          count: s?.dislikes ?? 0,
          color: s?.myValue == 'dislike' ? _dislikeColor : cs.onSurfaceVariant,
          onTap: () => _toggle('dislike'),
        ),
      ],
    );
  }

  Widget _button({
    required IconData icon,
    required int count,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 5),
            Text(
              '$count',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
