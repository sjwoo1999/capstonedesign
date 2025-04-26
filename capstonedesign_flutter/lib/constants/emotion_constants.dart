import 'package:flutter/material.dart';

/// 감정별 닉네임 + 이모지 매핑
const Map<String, String> emotionNicknameMap = {
  'neutral': '차분해 보여요 🌿',
  'sad': '조금 우울해요 🌧️',
  'fear': '조금 불안해 보여요 😨',
  'surprise': '놀라고 있어요 😲',
  'angry': '화가 난 것 같아요 🔥',
  'disgust': '싫어하는 표정이에요 🤢',
  'happy': '기분이 좋아 보여요 😊',
};

/// 감정별 색상 매핑
const Map<String, Color> emotionColorMap = {
  'neutral': Color(0xFFA0AEC0),
  'sad': Color(0xFF3182CE),
  'fear': Color(0xFF805AD5),
  'surprise': Color(0xFFF6AD55),
  'angry': Color(0xFFE53E3E),
  'disgust': Color(0xFF48BB78),
  'happy': Color(0xFFECC94B),
};