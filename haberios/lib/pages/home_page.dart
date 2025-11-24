import 'package:flutter/material.dart';
import '../models/haber.dart';
import '../services/api_service.dart';
import 'haber_detay_page.dart';
import 'history_page.dart'; 

class HomePage extends StatefulWidget {
  
  final VoidCallback temaDegistir;

  HomePage({required this.temaDegistir});

  @override
  HomePageState createState() => HomePageState();
}


class HomePageState extends State<HomePage> {
  
  List<Haber> haberler = [];

  List<Haber> filtreliHaberler = [];
  
  bool isLoading = true;

  TextEditingController aramaController = TextEditingController();

  final apiService = ApiService();


  @override
  void initState() {
    super.initState();
    
    api_haber_getir();

    aramaController.addListener(() {
      filterHaberler(aramaController.text);
    });
  }

  Future<void> api_haber_getir() async {
    setState(() {
      isLoading = true; 
    });
    try {

      final fetchedHaberler = await apiService.api_haber_getir();
      
      setState(() {
        haberler = fetchedHaberler;
        filtreliHaberler = List.from(haberler);
        isLoading = false;
      });
    } catch (e) {

      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Haberler yüklenemedi')),
      );
    }
  }

  void filterHaberler(String query) {
    setState(() {
      if (query.isEmpty) {
        
        filtreliHaberler = List.from(haberler);
      } else {
        
        filtreliHaberler = haberler
            .where((haber) =>
                haber.title.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  Future<void> refreshHaberler() async {
    
    await api_haber_getir();
    
    filterHaberler(aramaController.text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      appBar: AppBar(
        title: Text('HaberIOS'),
        actions: [
          
          IconButton(
            icon: Icon(Icons.brightness_6),
            onPressed: widget.temaDegistir,
          ),
          
          IconButton(
            icon: Icon(Icons.history),
            tooltip: 'Okunan Haberler',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => HistoryPage()),
              );
            },
          ),
        ],
      ),
      
      body: Column(
        children: [
          
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: aramaController,
              decoration: InputDecoration(
                hintText: 'Haber ara...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              
              onChanged: (value) {
                filterHaberler(value);
              },
            ),
          ),
          
          Expanded(
            child: isLoading
                
                ? Center(child: CircularProgressIndicator())
                
                : RefreshIndicator(
                    onRefresh: refreshHaberler,
                    child: filtreliHaberler.isEmpty
                        
                        ? ListView(
                            children: [
                              SizedBox(height: 100),
                              Center(child: Text('Haber bulunamadı')),
                            ],
                          )
                        
                        : ListView.builder(
                            itemCount: filtreliHaberler.length,
                            itemBuilder: (context, index) {
                              final haber = filtreliHaberler[index];
                              return GestureDetector(
                                
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          HaberDetayPage(haber: haber),
                                    ),
                                  );
                                },
                                
                                child: Card(
                                  margin: EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 4,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      
                                      haber.imageUrl != null
                                          ? ClipRRect(
                                              borderRadius: BorderRadius.vertical(
                                                  top: Radius.circular(12)),
                                              child: Image.network(
                                                haber.imageUrl!.replaceFirst(
                                                    'http://', 'https://'),
                                                width: double.infinity,
                                                height: 180,
                                                fit: BoxFit.cover,
                                                
                                                errorBuilder:
                                                    (context, error, stackTrace) {
                                                  return Container(
                                                    height: 180,
                                                    color: Colors.grey[300],
                                                    child: Icon(
                                                      Icons.broken_image,
                                                      size: 60,
                                                      color: Colors.grey[600],
                                                    ),
                                                  );
                                                },
                                              ),
                                            )
                                          : Container(
                                              height: 180,
                                              color: Colors.grey[300],
                                              child: Icon(
                                                Icons.image,
                                                size: 60,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                      
                                      Padding(
                                        padding: const EdgeInsets.all(12.0),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            
                                            Text(
                                              haber.title,
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            SizedBox(height: 6),
                                            
                                            Text(
                                              haber.description ?? '',
                                              style: TextStyle(fontSize: 14),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }
}