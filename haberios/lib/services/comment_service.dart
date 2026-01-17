import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/yorum.dart';

class CommentService {
  final String baseUrl = 'http://127.0.0.1:5000';

  Future<bool> addComment({
    required String newsUrl,
    required String userEmail,
    required String commentText,
  }) async {
    final url = Uri.parse('$baseUrl/comments');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'news_url': newsUrl,
          'user_email': userEmail,
          'comment_text': commentText,
        }),
      );

      return response.statusCode == 201;
    } catch (e) {
      print('Yorum eklenirken hata: $e');
      return false;
    }
  }

  Future<List<Yorum>> getComments(String newsUrl) async {
    final encodedUrl = Uri.encodeComponent(newsUrl);
    final url = Uri.parse('$baseUrl/comments?news_url=$encodedUrl');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List;
        return data.map((json) => Yorum.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Yorumlar alınırken hata: $e');
      return [];
    }
  }

  Future<bool> likeComment(String commentId) async {
    final url = Uri.parse('$baseUrl/comments/like');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'comment_id': commentId}),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Beğeni eklenirken hata: $e');
      return false;
    }
  }
}
