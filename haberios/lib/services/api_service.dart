import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/haber.dart';

class ApiService {
  final String apiKey = '39af87e842644a7c9a65e21302a518b6';

  Future<List<Haber>> api_haber_getir() async {
    
    final url = Uri.parse('https://newsapi.org/v2/top-headlines?country=us&apiKey=$apiKey');
    
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      
      final List articles = data['articles'];

      return articles.map((json) => Haber.fromJson(json)).toList();
    
    } else {
      throw Exception('Haberler alınamadı');
    }
  }
}
