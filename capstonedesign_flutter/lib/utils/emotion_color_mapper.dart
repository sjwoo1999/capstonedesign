import 'package:flutter/material.dart';

Color emotionColorMapper(String emotion) {
  switch (emotion.toLowerCase()) {
    case 'happiness':
      return Colors.orange;
    case 'sadness':
      return Colors.blueAccent;
    case 'anger':
      return Colors.redAccent;
    case 'surprise':
      return Colors.purple;
    case 'disgust':
      return Colors.green;
    case 'fear':
      return Colors.indigo;
    case 'neutral':
      return Colors.grey;
    default:
      return Colors.black;
  }
}
