import 'package:flutter/material.dart';

class AiProcessingScreen extends StatelessWidget {
  final String message;

  const AiProcessingScreen({super.key, this.message = "AI 正在處理中…"});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 使用半透明背景，通常會透過 Navigator 疊加在畫面上
      backgroundColor: Colors.black54, 
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                message,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}


