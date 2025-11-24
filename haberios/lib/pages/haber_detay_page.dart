import 'package:flutter/material.dart';
import '../models/haber.dart';
import '../services/history_service.dart';

class HaberDetayPage extends StatefulWidget {
  final Haber haber; 

  HaberDetayPage({required this.haber});

  @override
  _HaberDetayPageState createState() => _HaberDetayPageState();
}

class _HaberDetayPageState extends State<HaberDetayPage> {
  
  final HistoryService historyService = HistoryService();
  
  bool _isSaved = false;

  @override
  void initState() {
    super.initState();
    _saveHaber();
  }

  void _saveHaber() async {
    
    if (!_isSaved) {
      try {
        
        await historyService.saveHistory(widget.haber);
        
        setState(() {
          _isSaved = true;
        });
      } catch (e) {
        print('Haber kaydedilemedi: $e'); 
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      appBar: AppBar(title: Text('Haber Detayı')),
      
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            widget.haber.imageUrl != null
                ? Image.network(widget.haber.imageUrl!)
                : SizedBox(),
            
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  
                  Text(
                    widget.haber.title,
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  
                  SizedBox(height: 10),
                  Text(widget.haber.content ?? widget.haber.description ?? ''),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}