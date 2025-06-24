# BeMore: 내 감정을 인식하고 회고하는 정서 AI 파트너

## 프로젝트 개요
BeMore는 VAD 기반 멀티모달 감정 분석과 CBT(인지행동치료) 회고 리포트 시스템을 제공하는 AI 멘탈케어 서비스입니다. 사용자가 자신의 감정을 인식하고, 심리학적 피드백과 함께 일상 속 정서 회고를 습관화할 수 있도록 돕습니다.

---

## 사회적 배경
감정 표현의 어려움은 현대인의 고질적 문제입니다. 특히 MZ세대는 감정을 말로 표현하거나, 누군가에게 털어놓는 데 심리적 진입장벽이 높습니다. 기존 감정 분석 서비스는 대부분 텍스트 기반이거나 6가지 범주형 감정 분류에 그치며, 표정·음성 등 복합 신호의 통합 해석이 부족합니다.

---

## 문제 정의
감정 데이터를 수집·분석하는 시스템은 있지만, 그 결과를 정서 회고 및 피드백으로 연결하는 구조는 거의 없습니다. 단발성 분석에 그치고, 비언어적 감정 신호(표정, 억양)는 방치되고 있으며, 심리학적 해석모델과의 연결도 희박합니다. 즉, "단발성 분석"에서 "지속적인 감정 인식과 자기이해"로의 연결이 부족합니다.

---

## 핵심 제안
BeMore는 얼굴 표정, 음성 톤, 텍스트를 종합 분석해 VAD(Valence, Arousal, Dominance) 기반 감정 벡터를 산출하고, 이에 맞춰 CBT 기반 피드백과 일일 감정 회고 리포트를 제공합니다. 사용자는 자신의 감정 변화를 시각적으로 확인하고, 맞춤형 심리 피드백을 통해 자기이해와 정서적 회복탄력성을 높일 수 있습니다.

---

## 주요 특징
- 멀티모달 감정 인식 (표정 + 음성 + 텍스트)
- 감정 상태를 VAD(연속 감정 벡터)로 수치화
- CBT 전략 기반 맞춤 피드백 및 회고 리포트 제공
- 감정 변화 시각화 및 PDF 리포트 자동 생성
- 일일/주간 감정 추이 분석 및 자기 통찰 지원

---

## 데이터 흐름 및 서비스 주요 화면
1. 온보딩 페이지: 서비스 소개 및 사용법 안내
2. 상담 진행 페이지: 실시간 멀티모달 감정 분석
3. 분석 결과 페이지: VAD 기반 감정 벡터, CBT 피드백, 감정 변화 그래프, PDF 리포트 다운로드

---

## 기술 스택
- **Infra:** Cloud, REST API
- **Frontend:** Flutter (모바일/웹)
- **Backend:** Flask (Python)
- **AI/ML Module:** TensorFlow, dlib, OpenAI Whisper
- **Generative AI:** VAD Lexicon, FACS, MediaPipe, BERT

---

## 기대 효과 및 적용 분야
- 감정 회고의 자동화 → 정서적 자기인식 및 자기이해 향상
- CBT 기반 맞춤 피드백 → 심리적 복원력 및 회복탄력성 강화
- 감정 추이 리포트화 → 자기 통찰 강화 및 지속적 회고 습관 형성
- 비언어 신호까지 분석하는 정밀한 감정 해석 시스템
- **적용 분야:** 개인 감정 일기 서비스, 정신건강 앱/캘린더 연동, 웨어러블 디바이스 감정 모니터링 등

---

## 참고 문헌 및 레퍼런스
- Mehrabian & Russell (1974). VAD Emotional Model
- Paul Ekman & Friesen (1978). Facial Action Coding System (FACS)
- MediaPipe Face Landmarker – Google AI
- Whisper – OpenAI Speech-to-Text
- VAD Lexicon – NRC (Saif Mohammad)
- CBT 전략 구조 (APA, Clinical Practice)
- 국내 논문: "MTCNN 기반 얼굴 감정 인식 시스템 개선 연구", "AI 기반 회귀 BERT 모델 구현"

---

## 개발자 및 지도교수
- **우성종** (고려대학교 컴퓨터융합소프트웨어학과)
- **지도교수:** 서민석 교수님

---

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

## 라이선스

MIT License
