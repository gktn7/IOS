import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthService {
  final String baseUrl = 'http://127.0.0.1:5000';

  static String? loggedInUserId;
  static String? loggedInEmail;

  Future<bool> register(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );
      return response.statusCode == 201;
    } catch (e) {
      print("Kayıt hatası: $e");
      return false;
    }
  }

  Future<bool> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        loggedInUserId = data['user_id'];
        loggedInEmail = data['email'];
        
        print("Giriş Başarılı. Kullanıcı ID: $loggedInUserId");
        return true;
      }
      return false;
    } catch (e) {
      print("Giriş hatası: $e");
      return false;
    }
  }
}