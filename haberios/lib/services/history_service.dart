import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/haber.dart'; 

class HistoryService {

  final String baseUrl = 'http://127.0.0.1:5000'; 

  Future<void> saveHistory(Haber haber) async { 
    
    final url = Uri.parse('$baseUrl/save_history');
    
    final response = await http.post(
      
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        "title": haber.title,
        "description": haber.description,
        "content": haber.content,
        "imageUrl": haber.imageUrl,
        "url": haber.url,
      }),
    ); 
    
    if (response.statusCode != 201) {
      throw Exception('Haber geçmişe kaydedilemedi: ${response.body}');
    }
  }

  Future<List<Haber>> api_haber_getir() async {
    
    final url = Uri.parse('$baseUrl/history');
    
    final response = await http.get(url);
    
    if (response.statusCode == 200) {

      final data = json.decode(response.body) as List;
      
      return data.map((json) => Haber.fromJson(json)).toList(); 
    
    } else {
      throw Exception('Geçmiş alınamadı');
    }
  }
}