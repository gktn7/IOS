class Yorum {
  final String id;
  final String newsUrl;
  final String userEmail;
  final String commentText;
  final int likeCount;
  final DateTime? createdAt;

  Yorum({
    required this.id,
    required this.newsUrl,
    required this.userEmail,
    required this.commentText,
    this.likeCount = 0,
    this.createdAt,
  });

  factory Yorum.fromJson(Map<String, dynamic> json) {
    return Yorum(
      id: json['_id'] ?? '',
      newsUrl: json['news_url'] ?? '',
      userEmail: json['user_email'] ?? '',
      commentText: json['comment_text'] ?? '',
      likeCount: json['like_count'] ?? 0,
      createdAt: json['created_at'] != null 
          ? DateTime.tryParse(json['created_at']) 
          : null,
    );
  }

  String get userName {
    if (userEmail.contains('@')) {
      return userEmail.split('@')[0];
    }
    return userEmail;
  }

  String get timeAgo {
    if (createdAt == null) return '';
    final diff = DateTime.now().difference(createdAt!);
    if (diff.inDays > 0) return '${diff.inDays} gün önce';
    if (diff.inHours > 0) return '${diff.inHours} saat önce';
    if (diff.inMinutes > 0) return '${diff.inMinutes} dakika önce';
    return 'Az önce';
  }
}
