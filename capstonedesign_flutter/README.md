# BeMore: 내 감정을 인식하고 회고하는 정서

VAD 기반 멀티모달 감정 분석과 CBT 회고 리포트 시스템

## 프로젝트 소개

BeMore는 얼굴 표정, 음성 톤, 텍스트를 종합 분석해 VAD 기반 감정 벡터를 산출하고, 이에 맞춰 CBT(인지행동치료) 기반 피드백과 일일 감정 회고 리포트를 제공하는 멘탈케어 웹 서비스입니다.

## 주요 특징

- **멀티모달 감정 인식**: 표정 + 음성 + 텍스트
- **VAD 기반 감정 분석**: Valence(긍정성), Arousal(활성화), Dominance(지배성)
- **CBT 기반 맞춤 피드백**: 인지행동치료 기법 활용
- **감정 변화 시각화**: VAD 차트 및 통계
- **PDF 리포트 자동 생성**: 분석 결과 저장

## 기술 스택

### Frontend
- Flutter 3.5.4
- Provider (상태 관리)
- Google Fonts
- Flutter SVG

### AI/ML
- TensorFlow Lite
- MediaPipe Face Landmarker
- Whisper (Speech-to-Text)
- VAD Lexicon

### Backend
- Python Flask
- Emotion Analysis API

## 설치 및 실행

### 필수 요구사항
- Flutter SDK 3.5.4 이상
- Dart SDK
- Android Studio / VS Code

### 설치 방법

1. 저장소 클론
```bash
git clone [repository-url]
cd capstonedesign_flutter
```

2. 의존성 설치
```bash
flutter pub get
```

3. 앱 실행
```bash
flutter run
```

## 프로젝트 구조

```
lib/
├── main.dart                 # 앱 진입점
├── models/                   # 데이터 모델
│   ├── vad_emotion.dart     # VAD 감정 모델
│   ├── cbt_feedback.dart    # CBT 피드백 모델
│   └── session_data.dart    # 세션 데이터 모델
├── providers/               # 상태 관리
│   ├── emotion_provider.dart
│   ├── vad_provider.dart
│   └── cbt_provider.dart
├── screens/                 # 화면
│   ├── onboarding/         # 온보딩 화면
│   ├── home/              # 홈 화면
│   ├── session/           # 상담 세션
│   ├── analysis/          # 분석 결과
│   ├── history/           # 기록
│   └── settings/          # 설정
├── services/              # API 서비스
├── theme/                 # 테마 설정
└── utils/                 # 유틸리티
```

## 주요 기능

### 1. 온보딩
- 3단계 온보딩 프로세스
- 앱 기능 소개 및 사용법 안내

### 2. 멀티모달 감정 분석
- **얼굴 표정 분석**: 실시간 카메라 기반 감정 인식
- **음성 톤 분석**: 음성의 억양과 톤 분석
- **텍스트 분석**: 사용자 입력 텍스트 감정 분석

### 3. VAD 기반 감정 벡터
- **Valence (긍정성)**: 0.0 ~ 1.0
- **Arousal (활성화)**: 0.0 ~ 1.0
- **Dominance (지배성)**: 0.0 ~ 1.0

### 4. CBT 맞춤 피드백
- 인지 왜곡 식별
- 인지 재구성 제안
- 행동 계획 수립
- CBT 기법 추천

### 5. 감정 기록 및 통계
- 일일 감정 상태 추적
- 감정 변화 시각화
- 분석 히스토리 관리

## 개발자 정보

- **개발자**: 우성종 (2019270632)
- **지도교수**: 서민석 교수님
- **학과**: 컴퓨터융합소프트웨어학과
- **프로젝트**: 캡스톤 디자인

## 라이선스

MIT License

## 참고 문헌

- Mehrabian & Russell (1974). VAD Emotional Model
- Paul Ekman & Friesen (1978). Facial Action Coding System (FACS)
- MediaPipe Face Landmarker – Google AI
- Whisper – OpenAI, Speech-to-Text
- VAD Lexicon – NRC (Saif Mohammad)
- CBT 전략 기반 피드백 구조 참고 (APA 및 Clinical Practice)
