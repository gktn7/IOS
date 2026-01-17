import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/yorum.dart';

class ProfileService {
  final String baseUrl = 'http://127.0.0.1:5000';

  Future<Map<String, dynamic>?> getProfile(String email) async {
    final encodedEmail = Uri.encodeComponent(email);
    final url = Uri.parse('$baseUrl/profile?email=$encodedEmail');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      print('Profil alınırken hata: $e');
      return null;
    }
  }

  Future<List<Yorum>> getUserComments(String email) async {
    final encodedEmail = Uri.encodeComponent(email);
    final url = Uri.parse('$baseUrl/user/comments?email=$encodedEmail');

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

  Future<bool> toggleLike({
    required String email,
    required String newsUrl,
    String? newsTitle,
    String? newsImage,
  }) async {
    final url = Uri.parse('$baseUrl/likes');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'news_url': newsUrl,
          'news_title': newsTitle,
          'news_image': newsImage,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['liked'] ?? false;
      }
      return false;
    } catch (e) {
      print('Beğeni toggle hatası: $e');
      return false;
    }
  }

  Future<bool> checkLike(String email, String newsUrl) async {
    final encodedEmail = Uri.encodeComponent(email);
    final encodedUrl = Uri.encodeComponent(newsUrl);
    final url = Uri.parse('$baseUrl/likes/check?email=$encodedEmail&news_url=$encodedUrl');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['liked'] ?? false;
      }
      return false;
    } catch (e) {
      print('Like kontrol hatası: $e');
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getLikedNews(String email) async {
    final encodedEmail = Uri.encodeComponent(email);
    final url = Uri.parse('$baseUrl/likes?email=$encodedEmail');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List;
        return data.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      print('Beğeniler alınırken hata: $e');
      return [];
    }
  }
}
