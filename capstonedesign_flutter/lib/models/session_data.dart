import 'vad_emotion.dart';
import 'cbt_feedback.dart';

class SessionData {
  final String id;
  final DateTime startTime;
  final DateTime? endTime;
  final List<VADEmotion> facialEmotions;
  final List<VADEmotion> voiceEmotions;
  final List<VADEmotion> textEmotions;
  final VADEmotion? combinedEmotion;
  final CBTFeedback? cbtFeedback;
  final String? userText;
  final String? audioPath;
  final List<String>? imagePaths;
  final String status; // 'recording', 'analyzing', 'completed'

  SessionData({
    required this.id,
    required this.startTime,
    this.endTime,
    this.facialEmotions = const [],
    this.voiceEmotions = const [],
    this.textEmotions = const [],
    this.combinedEmotion,
    this.cbtFeedback,
    this.userText,
    this.audioPath,
    this.imagePaths,
    this.status = 'recording',
  });

  // 세션 지속 시간 계산
  Duration get duration {
    final end = endTime ?? DateTime.now();
    return end.difference(startTime);
  }

  // 세션 복사본 생성 (상태 업데이트용)
  SessionData copyWith({
    String? id,
    DateTime? startTime,
    DateTime? endTime,
    List<VADEmotion>? facialEmotions,
    List<VADEmotion>? voiceEmotions,
    List<VADEmotion>? textEmotions,
    VADEmotion? combinedEmotion,
    CBTFeedback? cbtFeedback,
    String? userText,
    String? audioPath,
    List<String>? imagePaths,
    String? status,
  }) {
    return SessionData(
      id: id ?? this.id,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      facialEmotions: facialEmotions ?? this.facialEmotions,
      voiceEmotions: voiceEmotions ?? this.voiceEmotions,
      textEmotions: textEmotions ?? this.textEmotions,
      combinedEmotion: combinedEmotion ?? this.combinedEmotion,
      cbtFeedback: cbtFeedback ?? this.cbtFeedback,
      userText: userText ?? this.userText,
      audioPath: audioPath ?? this.audioPath,
      imagePaths: imagePaths ?? this.imagePaths,
      status: status ?? this.status,
    );
  }

  // JSON 변환
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'facialEmotions': facialEmotions.map((e) => e.toJson()).toList(),
      'voiceEmotions': voiceEmotions.map((e) => e.toJson()).toList(),
      'textEmotions': textEmotions.map((e) => e.toJson()).toList(),
      'combinedEmotion': combinedEmotion?.toJson(),
      'cbtFeedback': cbtFeedback?.toJson(),
      'userText': userText,
      'audioPath': audioPath,
      'imagePaths': imagePaths,
      'status': status,
    };
  }

  factory SessionData.fromJson(Map<String, dynamic> json) {
    return SessionData(
      id: json['id'],
      startTime: DateTime.parse(json['startTime']),
      endTime: json['endTime'] != null ? DateTime.parse(json['endTime']) : null,
      facialEmotions: (json['facialEmotions'] as List)
          .map((e) => VADEmotion.fromJson(e))
          .toList(),
      voiceEmotions: (json['voiceEmotions'] as List)
          .map((e) => VADEmotion.fromJson(e))
          .toList(),
      textEmotions: (json['textEmotions'] as List)
          .map((e) => VADEmotion.fromJson(e))
          .toList(),
      combinedEmotion: json['combinedEmotion'] != null
          ? VADEmotion.fromJson(json['combinedEmotion'])
          : null,
      cbtFeedback: json['cbtFeedback'] != null
          ? CBTFeedback.fromJson(json['cbtFeedback'])
          : null,
      userText: json['userText'],
      audioPath: json['audioPath'],
      imagePaths: json['imagePaths'] != null
          ? List<String>.from(json['imagePaths'])
          : null,
      status: json['status'],
    );
  }

  // 새 세션 생성
  factory SessionData.create() {
    return SessionData(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      startTime: DateTime.now(),
    );
  }
} 