import 'package:flutter/material.dart';
import '../services/history_service.dart';
import '../models/haber.dart';
import 'haber_detay_page.dart';

class HistoryPage extends StatefulWidget {
  @override
  _HistoryPageState createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  
  final HistoryService historyService = HistoryService();
  
  List<Haber> history = [];
  
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadHistory();
  }

  Future<void> loadHistory() async {
    try {
      final data = await historyService.api_haber_getir(); 

      setState(() {
        history = data.reversed.toList();
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Geçmiş alınamadı')),
      );
    }
  }
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Okunan Haberler'),
        
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              
              setState(() {
                isLoading = true;
              });
              loadHistory();
            },
          ),
        ],
      ),
      
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : history.isEmpty
              ? Center(child: Text('Henüz okunan haber yok'))
              
              : ListView.builder(
                  itemCount: history.length,
                  itemBuilder: (context, index) {
                    final haber = history[index];
                    
                    return Card(
                      margin:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: ListTile(
                        
                        leading: haber.imageUrl != null
                            ? Image.network(
                                haber.imageUrl!,
                                
                                width: 60,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Icon(Icons.broken_image);
                                },
                              )
                            : Icon(Icons.image),
                        
                        title: Text(haber.title),
                        
                        subtitle: haber.description != null
                            ? Text(
                                haber.description!,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              )
                            : null,
                        
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => HaberDetayPage(haber: haber)),
                          );
                        },
                      ),
                    );
                  },
                ),
    );
  }
}