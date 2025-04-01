import 'package:flutter/material.dart';
import 'realtime_camera_screen.dart';
import 'result_screen.dart';
import 'history_screen.dart';
import '../providers/emotion_provider.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatelessWidget {
  final TextEditingController _textController = TextEditingController();

  HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('CapstoneDesign')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => RealtimeCameraScreen()),
                );
              },
              child: const Text('Capture Image'),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _textController,
              decoration: const InputDecoration(
                labelText: 'How do you feel today?',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 20),
            Consumer<EmotionProvider>(
              builder: (context, provider, child) {
                return provider.isAnalyzingText
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: () async {
                          if (_textController.text.isNotEmpty) {
                            await provider.analyze(text: _textController.text);
                            if (context.mounted) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ResultScreen(),
                                ),
                              );
                            }
                          }
                        },
                        child: const Text('Analyze Text'),
                      );
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => HistoryScreen()),
                );
              },
              child: const Text('View Emotion History'),
            ),
          ],
        ),
      ),
    );
  }
}
