class CBTFeedback {
  final String id;
  final String emotionCategory;
  final String cognitiveDistortion;  // 인지 왜곡 유형
  final String challenge;            // 도전 과제
  final String reframe;              // 인지 재구성
  final String actionPlan;           // 행동 계획
  final List<String> techniques;     // CBT 기법들
  final DateTime createdAt;

  CBTFeedback({
    required this.id,
    required this.emotionCategory,
    required this.cognitiveDistortion,
    required this.challenge,
    required this.reframe,
    required this.actionPlan,
    required this.techniques,
    required this.createdAt,
  });

  // 감정 카테고리에 따른 CBT 피드백 생성
  factory CBTFeedback.fromEmotion(String emotionCategory) {
    final feedbacks = {
      '슬픔': CBTFeedback(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        emotionCategory: '슬픔',
        cognitiveDistortion: '과도한 일반화',
        challenge: '현재 상황을 전체 삶으로 확대하지 않도록 주의하세요.',
        reframe: '이것은 일시적인 상황이며, 시간이 지나면 나아질 것입니다.',
        actionPlan: '작은 목표를 세우고 하나씩 달성해보세요.',
        techniques: ['행동 활성화', '감사 일기', '자기 동정'],
        createdAt: DateTime.now(),
      ),
      '불안': CBTFeedback(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        emotionCategory: '불안',
        cognitiveDistortion: '재앙화',
        challenge: '최악의 시나리오를 상상하지 말고 현재에 집중하세요.',
        reframe: '대부분의 걱정은 실제로 일어나지 않습니다.',
        actionPlan: '호흡 운동을 통해 신체적 긴장을 풀어보세요.',
        techniques: ['점진적 근육 이완', '마음챙김 명상', '인지 재구성'],
        createdAt: DateTime.now(),
      ),
      '분노': CBTFeedback(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        emotionCategory: '분노',
        cognitiveDistortion: '개인화',
        challenge: '다른 사람의 행동을 개인적으로 받아들이지 마세요.',
        reframe: '상대방도 자신만의 이유가 있을 수 있습니다.',
        actionPlan: '10초 동안 심호흡을 하고 상황을 다시 생각해보세요.',
        techniques: ['타임아웃', '인지 재구성', '감정 표현'],
        createdAt: DateTime.now(),
      ),
      '기쁨': CBTFeedback(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        emotionCategory: '기쁨',
        cognitiveDistortion: '과도한 낙관',
        challenge: '긍정적인 감정을 유지하면서도 현실적 시각을 유지하세요.',
        reframe: '이 순간을 소중히 여기고 미래에도 긍정적인 기대를 가져보세요.',
        actionPlan: '이 기쁨을 다른 사람과 공유해보세요.',
        techniques: ['감사 표현', '긍정적 경험 확장', '사회적 연결'],
        createdAt: DateTime.now(),
      ),
      '평온': CBTFeedback(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        emotionCategory: '평온',
        cognitiveDistortion: '무관심',
        challenge: '평온함을 유지하면서도 적절한 관심과 동기를 유지하세요.',
        reframe: '평온함은 건강한 감정 상태입니다.',
        actionPlan: '이 평온함을 활용해 중요한 결정을 내려보세요.',
        techniques: ['마음챙김', '자기 성찰', '목표 설정'],
        createdAt: DateTime.now(),
      ),
    };

    return feedbacks[emotionCategory] ?? CBTFeedback(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      emotionCategory: '중립',
      cognitiveDistortion: '감정 회피',
      challenge: '현재 감정을 인정하고 적절히 표현해보세요.',
      reframe: '모든 감정은 의미가 있으며, 인정받을 가치가 있습니다.',
      actionPlan: '일기를 쓰거나 신뢰할 수 있는 사람과 대화해보세요.',
      techniques: ['감정 인식', '자기 표현', '사회적 지원'],
      createdAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'emotionCategory': emotionCategory,
      'cognitiveDistortion': cognitiveDistortion,
      'challenge': challenge,
      'reframe': reframe,
      'actionPlan': actionPlan,
      'techniques': techniques,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory CBTFeedback.fromJson(Map<String, dynamic> json) {
    return CBTFeedback(
      id: json['id'],
      emotionCategory: json['emotionCategory'],
      cognitiveDistortion: json['cognitiveDistortion'],
      challenge: json['challenge'],
      reframe: json['reframe'],
      actionPlan: json['actionPlan'],
      techniques: List<String>.from(json['techniques']),
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
} 