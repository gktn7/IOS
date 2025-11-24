import 'package:flutter/material.dart';
import 'pages/home_page.dart';

void main() {
  runApp(HaberApp());
}

class HaberApp extends StatefulWidget {
  @override
  _HaberAppState createState() => _HaberAppState();
}

class _HaberAppState extends State<HaberApp> {

  bool isDarkMode = false;

  void temaDegistir() {
    setState(() {
      isDarkMode = !isDarkMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    
    return MaterialApp(
      
      title: 'HaberIOS',
      
      debugShowCheckedModeBanner: false,
      
      theme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.light,
      ),
      
      darkTheme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.dark,
      ),
      
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      
      home: HomePage(
        temaDegistir: temaDegistir,
      ),
    );
  }
}