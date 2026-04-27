// lib/main.dart
import 'package:flutter/material.dart';
import 'screens/chat_screen.dart';

void main() {
  runApp(const LocalAiChatApp());
}

class LocalAiChatApp extends StatelessWidget {
  const LocalAiChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI 語音圖書館',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const ChatScreen(),
    );
  }
}
