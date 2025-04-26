import 'package:flutter/material.dart';
import 'screens/map.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: '道路圖資分析與計算 Demo',
      debugShowCheckedModeBanner: false,
      home: MapPage(),
    );
  }
}
