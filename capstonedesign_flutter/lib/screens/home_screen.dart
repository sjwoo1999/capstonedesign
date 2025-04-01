import 'package:flutter/material.dart';
import 'camera_screen.dart';
import 'result_screen.dart';
import '../providers/emotion_provider.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatelessWidget {
  final TextEditingController _textController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('CapstoneDesign')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => CameraScreen()),
                );
              },
              child: Text('Capture Image'),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _textController,
              decoration: InputDecoration(
                labelText: 'How do you feel today?',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            SizedBox(height: 20),
            Consumer<EmotionProvider>(
              builder: (context, provider, child) {
                return provider.isLoading
                    ? CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: () async {
                          if (_textController.text.isNotEmpty) {
                            await provider.analyze(text: _textController.text);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ResultScreen(),
                              ),
                            );
                          }
                        },
                        child: Text('Analyze Text'),
                      );
              },
            ),
          ],
        ),
      ),
    );
  }
}
