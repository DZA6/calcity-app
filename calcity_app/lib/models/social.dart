/// Social models: comments, reactions, discussion topics.
///
/// Field names mirror the Django API (community/serializers.py) exactly —
/// backend is the source of truth; change both sides together.
library;

class ReactionSummary {
  final int likes;
  final int dislikes;
  final String? myValue; // 'like' | 'dislike' | null

  const ReactionSummary({
    required this.likes,
    required this.dislikes,
    this.myValue,
  });

  factory ReactionSummary.fromJson(Map<String, dynamic> json) =>
      ReactionSummary(
        likes: (json['likes'] as num?)?.toInt() ?? 0,
        dislikes: (json['dislikes'] as num?)?.toInt() ?? 0,
        myValue: json['my_value'] as String?,
      );

  ReactionSummary copyWith({int? likes, int? dislikes, String? myValue}) =>
      ReactionSummary(
        likes: likes ?? this.likes,
        dislikes: dislikes ?? this.dislikes,
        myValue: myValue ?? this.myValue,
      );

  int get total => likes + dislikes;
}

class CommentItem {
  final int id;
  final String contentType; // 'news' | 'event' | 'business' | 'school' | 'topic'
  final int objectId;
  final String author;
  final int authorId;
  final String body;
  final int? parentId;
  final DateTime createdAt;

  const CommentItem({
    required this.id,
    required this.contentType,
    required this.objectId,
    required this.author,
    required this.authorId,
    required this.body,
    this.parentId,
    required this.createdAt,
  });

  factory CommentItem.fromJson(Map<String, dynamic> json) => CommentItem(
        id: (json['id'] as num).toInt(),
        contentType: json['content_type'] as String? ?? '',
        objectId: (json['object_id'] as num).toInt(),
        author: json['author'] as String? ?? 'anonymous',
        authorId: (json['author_id'] as num?)?.toInt() ?? 0,
        body: json['body'] as String? ?? '',
        parentId: (json['parent'] as num?)?.toInt(),
        createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
            DateTime.now(),
      );
}

class DiscussionTopicItem {
  final int id;
  final String title;
  final String body;
  final String author;
  final int authorId;
  final String category;
  final bool isPinned;
  final bool isClosed;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int commentCount;
  final int likes;
  final int dislikes;
  final String? myValue;

  const DiscussionTopicItem({
    required this.id,
    required this.title,
    required this.body,
    required this.author,
    required this.authorId,
    required this.category,
    required this.isPinned,
    required this.isClosed,
    required this.createdAt,
    required this.updatedAt,
    required this.commentCount,
    required this.likes,
    required this.dislikes,
    this.myValue,
  });

  factory DiscussionTopicItem.fromJson(Map<String, dynamic> json) =>
      DiscussionTopicItem(
        id: (json['id'] as num).toInt(),
        title: json['title'] as String? ?? '',
        body: json['body'] as String? ?? '',
        author: json['author'] as String? ?? 'anonymous',
        authorId: (json['author_id'] as num?)?.toInt() ?? 0,
        category: json['category'] as String? ?? 'general',
        isPinned: json['is_pinned'] as bool? ?? false,
        isClosed: json['is_closed'] as bool? ?? false,
        createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
            DateTime.now(),
        updatedAt: DateTime.tryParse(json['updated_at'] as String? ?? '') ??
            DateTime.now(),
        commentCount: (json['comment_count'] as num?)?.toInt() ?? 0,
        likes: (json['likes'] as num?)?.toInt() ?? 0,
        dislikes: (json['dislikes'] as num?)?.toInt() ?? 0,
        myValue: json['my_value'] as String?,
      );
}

/// Compact relative time: "just now", "5m", "3h", "2d".
String timeAgo(DateTime time, {DateTime? now}) {
  final ref = now ?? DateTime.now();
  final diff = ref.difference(time);
  if (diff.inSeconds < 60) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m';
  if (diff.inHours < 24) return '${diff.inHours}h';
  if (diff.inDays < 7) return '${diff.inDays}d';
  if (diff.inDays < 365) return '${(diff.inDays / 30).floor()}mo';
  return '${(diff.inDays / 365).floor()}y';
}
