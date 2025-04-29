// lib/screens/social/social_screen.dart
import 'package:flutter/material.dart';

class SocialScreen extends StatelessWidget {
  const SocialScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('소셜'),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.people_alt,
              size: 80,
              color: Colors.deepPurple,
            ),
            const SizedBox(height: 16),
            const Text(
              '아직 게시물이 없습니다.',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
