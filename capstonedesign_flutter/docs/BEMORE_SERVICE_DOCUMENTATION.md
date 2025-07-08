# BeMore 서비스 상세 기술 문서

## 📋 목차
1. [서비스 개요](#서비스-개요)
2. [아키텍처 설계](#아키텍처-설계)
3. [핵심 기능 상세](#핵심-기능-상세)
4. [기술 스택](#기술-스택)
5. [데이터 모델](#데이터-모델)
6. [API 명세](#api-명세)
7. [UI/UX 디자인](#uiux-디자인)
8. [보안 및 권한](#보안-및-권한)
9. [배포 및 운영](#배포-및-운영)
10. [개발 가이드](#개발-가이드)

---

## 🎯 서비스 개요

### BeMore란?
BeMore는 **VAD(Valence-Arousal-Dominance) 기반 멀티모달 감정 분석 & CBT(인지행동치료) 회고 시스템**입니다. 사용자의 얼굴 표정, 음성, 텍스트를 실시간으로 분석하여 감정 상태를 파악하고, AI 기반의 맞춤형 CBT 피드백을 제공하는 Flutter 기반 모바일 애플리케이션입니다.

### 핵심 가치
- **과학적 감정 분석**: VAD 모델을 통한 정량적 감정 측정
- **멀티모달 통합**: 시각, 청각, 텍스트 데이터의 융합 분석
- **AI 기반 상담**: Gemini AI를 활용한 자연스러운 대화형 상담
- **CBT 치료**: 인지행동치료 기법을 통한 체계적 정신건강 관리
- **개인화 피드백**: 사용자별 맞춤형 감정 관리 전략 제공

### 타겟 사용자
- 정신건강에 관심이 있는 일반 사용자
- 감정 관리가 필요한 직장인/학생
- CBT 치료를 받고 있는 환자
- 정신건강 전문가 (모니터링 도구)

---

## 🏗️ 아키텍처 설계

### 전체 시스템 구조
```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Flutter App   │    │  Python Server  │    │   Gemini AI     │
│   (Frontend)    │◄──►│   (Backend)     │◄──►│   (External)    │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │
         │                       │
    ┌────▼────┐            ┌─────▼─────┐
    │  Local  │            │  Emotion  │
    │ Storage │            │ Analysis  │
    └─────────┘            └───────────┘
```

### 클라이언트-서버 아키텍처

#### 1. Flutter 클라이언트 (Frontend)
- **상태 관리**: Provider 패턴을 통한 전역 상태 관리
- **UI 레이어**: Material Design 3 기반 모던 UI
- **비즈니스 로직**: 서비스 레이어를 통한 API 통신
- **데이터 저장**: SharedPreferences를 통한 로컬 데이터 관리

#### 2. Python Flask 서버 (Backend)
- **API 서버**: Flask 기반 RESTful API
- **감정 분석**: TensorFlow를 활용한 멀티모달 분석
- **AI 연동**: Gemini AI API 프록시 서버
- **데이터 처리**: 실시간 멀티모달 데이터 통합

#### 3. 외부 서비스
- **Gemini AI**: Google의 대화형 AI 모델
- **TensorFlow**: 얼굴 감정 인식 모델
- **Whisper**: OpenAI의 음성-텍스트 변환

### 데이터 플로우
```
1. 사용자 입력 (카메라/마이크/텍스트)
   ↓
2. Flutter 앱에서 데이터 전처리
   ↓
3. Python 서버로 멀티모달 데이터 전송
   ↓
4. 각 모달리티별 감정 분석 실행
   ↓
5. VAD 기반 통합 분석 결과 생성
   ↓
6. CBT 피드백 및 AI 응답 생성
   ↓
7. 클라이언트로 결과 전송 및 UI 업데이트
```

---

## 🔧 핵심 기능 상세

### 1. VAD 기반 감정 분석 시스템

#### VAD 모델 설명
VAD(Valence-Arousal-Dominance)는 감정을 3차원으로 수치화하는 심리학적 모델입니다:

- **Valence (긍정성)**: 0.0(매우 부정적) ~ 1.0(매우 긍정적)
- **Arousal (활성화)**: 0.0(매우 차분함) ~ 1.0(매우 활발함)
- **Dominance (지배성)**: 0.0(매우 수동적) ~ 1.0(매우 적극적)

#### 감정 카테고리 매핑
```dart
String get emotionCategory {
  if (valence > 0.6 && arousal > 0.6) return '기쁨';
  if (valence > 0.6 && arousal < 0.4) return '평온';
  if (valence < 0.4 && arousal > 0.6) return '분노';
  if (valence < 0.4 && arousal < 0.4) return '슬픔';
  if (valence > 0.6 && arousal > 0.4 && arousal < 0.6) return '희망';
  if (valence < 0.4 && arousal > 0.4 && arousal < 0.6) return '불안';
  return '중립';
}
```

### 2. 멀티모달 분석 시스템

#### 시각 분석 (얼굴 표정)
- **기술**: TensorFlow 기반 얼굴 감정 인식
- **입력**: 실시간 카메라 스트림 (Base64 인코딩)
- **출력**: 7가지 감정 카테고리 + VAD 값
- **신뢰도**: 얼굴 인식 정확도에 따른 가중치 적용

#### 청각 분석 (음성 감정)
- **기술**: Whisper + 음성 감정 분석 모델
- **입력**: 실시간 음성 녹음 (WAV/MP3)
- **출력**: 음성 톤, 속도, 강세 기반 감정 분석
- **특징**: 음성 인식과 감정 분석 동시 수행

#### 텍스트 분석 (언어 감정)
- **기술**: 자연어 처리 기반 감정 분석
- **입력**: 사용자 입력 텍스트
- **출력**: 텍스트 내용 기반 감정 상태
- **장점**: 명시적 감정 표현 인식 가능

#### 통합 분석 알고리즘
```python
# 가중 평균을 통한 최종 VAD 계산
final_valence = (visual_weight * visual_valence + 
                audio_weight * audio_valence + 
                text_weight * text_valence) / total_weight
```

### 3. AI 기반 대화 시스템

#### Gemini AI 연동
- **모델**: Google Gemini Pro
- **기능**: 자연스러운 한국어 대화
- **컨텍스트**: 대화 히스토리 유지 (최대 10턴)
- **특화**: 정신건강 상담에 최적화된 프롬프트

#### 대화 시스템 구조
```dart
class GeminiService {
  List<Map<String, String>> _conversationHistory = [];
  
  Future<String> getResponse(String userMessage) async {
    // 대화 히스토리에 사용자 메시지 추가
    _conversationHistory.add({
      'role': 'user',
      'content': userMessage,
    });
    
    // 서버를 통한 Gemini API 호출
    // 응답 생성 및 히스토리 업데이트
  }
}
```

#### 음성 인식 통합
- **STT**: 실시간 Speech-to-Text 변환
- **음성 명령**: "분석 시작", "대화 종료" 등
- **자동 전송**: 음성 인식 완료 시 자동 메시지 전송

### 4. CBT 기반 피드백 시스템

#### 인지 왜곡 분석
- **과도한 일반화**: "항상", "절대" 등의 극단적 표현
- **재앙화**: 최악의 시나리오 상상
- **개인화**: 모든 일을 자신의 탓으로 돌림
- **흑백사고**: 중간 단계 없이 극단적 판단

#### CBT 피드백 구조
```dart
class CBTFeedback {
  final String cognitiveDistortion;  // 인지 왜곡 유형
  final String challenge;            // 도전 과제
  final String reframe;              // 인지 재구성
  final String actionPlan;           // 행동 계획
  final List<String> techniques;     // CBT 기법들
}
```

#### 맞춤형 기법 추천
- **슬픔**: 행동 활성화, 감사 일기, 자기 동정
- **불안**: 점진적 근육 이완, 마음챙김 명상
- **분노**: 타임아웃, 인지 재구성, 감정 표현
- **기쁨**: 감사 표현, 긍정적 경험 확장

### 5. 데이터 관리 및 분석

#### 세션 데이터 구조
```dart
class SessionData {
  final String sessionId;
  final DateTime startTime;
  final DateTime endTime;
  final List<MultimodalDataPoint> dataPoints;
  final CBTFeedback cbtFeedback;
  final List<ChatMessage> chatHistory;
}
```

#### 감정 변화 추적
- **실시간 그래프**: VAD 값의 시간별 변화
- **통계 분석**: 일별/주별/월별 감정 패턴
- **트렌드 분석**: 감정 변화 추세 및 패턴

#### PDF 리포트 생성
- **세션 요약**: 분석 결과 및 주요 인사이트
- **감정 통계**: VAD 값 통계 및 차트
- **CBT 피드백**: 맞춤형 조언 및 기법
- **행동 계획**: 구체적 실천 방안

---

## 🛠️ 기술 스택

### Frontend (Flutter)
| 기술 | 버전 | 용도 |
|------|------|------|
| Flutter | 3.x | 크로스 플랫폼 앱 개발 |
| Dart | 3.x | 프로그래밍 언어 |
| Provider | 6.x | 상태 관리 |
| camera | 0.10.x | 카메라 접근 |
| record | 5.x | 음성 녹음 |
| speech_to_text | 6.x | 실시간 음성 인식 |
| http | 1.x | API 통신 |
| flutter_dotenv | 5.x | 환경변수 관리 |
| google_fonts | 6.x | 커스텀 폰트 |
| lottie | 2.x | 애니메이션 |
| fl_chart | 0.65.x | 차트 및 그래프 |
| pdf | 3.x | PDF 리포트 생성 |
| shared_preferences | 2.x | 로컬 데이터 저장 |
| permission_handler | 11.x | 권한 관리 |

### Backend (Python)
| 기술 | 버전 | 용도 |
|------|------|------|
| Flask | 2.x | 웹 프레임워크 |
| Flask-CORS | 4.x | CORS 처리 |
| TensorFlow | 2.x | 얼굴 감정 분석 |
| OpenCV | 4.x | 이미지 처리 |
| Whisper | 1.x | 음성-텍스트 변환 |
| google-generativeai | 0.3.x | Gemini AI 연동 |
| numpy | 1.x | 수치 계산 |
| logging | - | 로깅 |

### 외부 서비스
| 서비스 | 용도 | API |
|--------|------|------|
| Google Gemini AI | 대화형 AI | REST API |
| TensorFlow Hub | 사전 훈련 모델 | Python API |
| OpenAI Whisper | 음성 인식 | Python API |

---

## 📊 데이터 모델

### 1. VAD 감정 모델
```dart
class VADEmotion {
  final double valence;    // 감정의 긍정성 (0.0 ~ 1.0)
  final double arousal;    // 감정의 활성화 정도 (0.0 ~ 1.0)
  final double dominance;  // 감정의 지배성 (0.0 ~ 1.0)
  final DateTime timestamp;
  final String source;     // 'facial', 'voice', 'text', 'combined'
}
```

### 2. 멀티모달 데이터 포인트
```dart
class MultimodalDataPoint {
  final DateTime timestamp;
  final ModalityData? visualData;    // 얼굴 표정 분석
  final ModalityData? audioData;     // 음성 감정 분석
  final ModalityData? textData;      // 텍스트 감정 분석
  final VADEmotion finalEmotion;     // 통합된 최종 감정
  final String sessionId;
  final Map<String, dynamic>? metadata;
}
```

### 3. CBT 피드백 모델
```dart
class CBTFeedback {
  final String id;
  final String emotionCategory;
  final String cognitiveDistortion;  // 인지 왜곡 유형
  final String challenge;            // 도전 과제
  final String reframe;              // 인지 재구성
  final String actionPlan;           // 행동 계획
  final List<String> techniques;     // CBT 기법들
  final DateTime createdAt;
}
```

### 4. 채팅 메시지 모델
```dart
class ChatMessage {
  final String id;
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final String? emotion;             // 메시지 감정 태그
  final Map<String, dynamic>? metadata;
}
```

### 5. 세션 데이터 모델
```dart
class SessionData {
  final String sessionId;
  final DateTime startTime;
  final DateTime endTime;
  final List<MultimodalDataPoint> dataPoints;
  final CBTFeedback cbtFeedback;
  final List<ChatMessage> chatHistory;
  final Map<String, dynamic>? metadata;
}
```

---

## 🔌 API 명세

### 서버 API (포트 5001)

#### 1. 멀티모달 감정 분석
```http
POST /analyze_multimodal_emotion
Content-Type: application/json

{
  "image": "base64_encoded_image_data",
  "audio": "base64_encoded_audio_data", 
  "text": "사용자 입력 텍스트",
  "sessionId": "unique_session_id"
}

Response:
{
  "analysis": {
    "timestamp": "2024-01-01T12:00:00Z",
    "sessionDuration": 30,
    "dataPoints": 1,
    "emotionCategory": "happy",
    "emotionIcon": "😊",
    "confidence": 0.85
  },
  "vadStats": {
    "valence": 0.8,
    "arousal": 0.7,
    "dominance": 0.6
  },
  "cbtFeedback": {
    "mainAdvice": "감정 관리 전략",
    "techniques": ["감정 인식하기", "호흡 조절하기"]
  }
}
```

#### 2. Gemini AI 채팅
```http
POST /chat/gemini
Content-Type: application/json

{
  "message": "사용자 메시지",
  "conversation_history": [
    {"role": "user", "content": "이전 메시지"},
    {"role": "model", "content": "AI 응답"}
  ]
}

Response:
{
  "success": true,
  "response": "AI 응답 메시지",
  "conversation_history": [...]
}
```

#### 3. 서버 상태 확인
```http
GET /health

Response:
{
  "status": "healthy",
  "timestamp": "2024-01-01T12:00:00Z"
}
```

### 클라이언트 API 서비스

#### EmotionAPIService
```dart
class EmotionAPIService {
  static Future<Map<String, dynamic>> sendImageForAnalysis(String base64Image);
  static Future<Map<String, dynamic>> sendAudioForAnalysis(String base64Audio);
  static Future<Map<String, dynamic>> sendTextForAnalysis(String text);
  static Future<Map<String, dynamic>> analyzeMultimodal({
    String? base64Image,
    String? base64Audio,
    String? text,
  });
}
```

#### GeminiService
```dart
class GeminiService {
  Future<String> getResponse(String userMessage);
  Future<void> clearConversation();
  List<Map<String, String>> getConversationHistory();
  Future<bool> isServiceAvailable();
}
```

---

## 🎨 UI/UX 디자인

### BeMore 디자인 시스템

#### 브랜드 컬러
```dart
class BeMoreTheme {
  static const Color primaryColor = Color(0xFF6366F1);      // 인디고
  static const Color secondaryColor = Color(0xFF8B5CF6);    // 바이올렛
  static const Color accentColor = Color(0xFF06B6D4);       // 시안
  static const Color backgroundColor = Color(0xFFF8FAFC);   // 연한 회색
  static const Color surfaceColor = Color(0xFFFFFFFF);      // 흰색
}
```

#### 감정별 컬러 매핑
```dart
static const Map<String, Color> emotionColors = {
  '기쁨': Color(0xFF10B981),      // 초록색
  '평온': Color(0xFF3B82F6),      // 파란색
  '슬픔': Color(0xFF6366F1),      // 인디고
  '불안': Color(0xFFF59E0B),      // 주황색
  '분노': Color(0xFFEF4444),      // 빨간색
  '중립': Color(0xFF6B7280),      // 회색
};
```

### 화면 구조

#### 1. 온보딩 화면
- 앱 소개 및 사용법 안내
- 권한 요청 (카메라, 마이크)
- 초기 설정 가이드

#### 2. 메인 네비게이션
- **홈**: 오늘의 감정 상태, 빠른 시작
- **소셜**: 커뮤니티 기능 (개발 중)
- **기록**: 과거 분석 기록 및 통계
- **설정**: 앱 설정, 데이터 관리

#### 3. 핵심 기능 화면
- **멀티모달 세션**: 실시간 감정 분석
- **AI 채팅**: Gemini AI와의 대화
- **분석 결과**: 상세한 감정 분석 결과
- **CBT 피드백**: 맞춤형 치료 기법

### 사용자 경험 설계

#### 1. 직관적 인터페이스
- **Material Design 3**: 모던하고 일관된 디자인
- **한국어 최적화**: Noto Sans KR 폰트 사용
- **접근성**: 색상 대비 및 터치 영역 최적화

#### 2. 실시간 피드백
- **로딩 애니메이션**: Lottie 기반 부드러운 애니메이션
- **진행 상태 표시**: 분석 진행률 실시간 업데이트
- **에러 처리**: 친화적인 에러 메시지 및 복구 가이드

#### 3. 개인화 요소
- **감정별 테마**: 사용자 감정에 따른 UI 색상 변화
- **맞춤형 콘텐츠**: 사용자 패턴 기반 추천
- **데이터 시각화**: 직관적인 차트 및 그래프

---

## 🔒 보안 및 권한

### 권한 관리

#### 필수 권한
```xml
<!-- Android Manifest -->
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
```

```xml
<!-- iOS Info.plist -->
<key>NSCameraUsageDescription</key>
<string>감정 분석을 위해 카메라 접근이 필요합니다.</string>
<key>NSMicrophoneUsageDescription</key>
<string>음성 분석을 위해 마이크 접근이 필요합니다.</string>
```

#### 권한 요청 플로우
1. **온보딩 단계**: 권한 필요성 설명
2. **실시간 요청**: 기능 사용 시점에 권한 요청
3. **설정 안내**: 권한 거부 시 설정 화면 안내

### 데이터 보안

#### 로컬 데이터 보호
- **SharedPreferences**: 민감하지 않은 설정 데이터
- **암호화 저장**: 민감한 데이터는 암호화 후 저장
- **자동 삭제**: 일정 기간 후 자동 데이터 정리

#### 네트워크 보안
- **HTTPS 통신**: 모든 API 통신은 HTTPS 사용
- **API 키 관리**: 환경변수를 통한 안전한 키 관리
- **요청 검증**: 서버 측 입력 데이터 검증

#### 개인정보 보호
- **데이터 최소화**: 필요한 데이터만 수집
- **사용자 동의**: 명시적 개인정보 수집 동의
- **데이터 삭제**: 사용자 요청 시 즉시 데이터 삭제

---

## 🚀 배포 및 운영

### 개발 환경 설정

#### 1. 환경변수 설정
```bash
# .env 파일 생성
EMOTION_API_URL=http://localhost:5001
GEMINI_API_KEY=your_actual_gemini_api_key_here
OPENAI_API_KEY=your_openai_api_key_here
```

#### 2. 서버 실행
```bash
# Python 가상환경 생성
python -m venv venv
source venv/bin/activate  # macOS/Linux
# 또는
venv\Scripts\activate     # Windows

# 의존성 설치
pip install -r requirements.txt

# 서버 실행
python multimodal_emotion_api.py
```

#### 3. Flutter 앱 실행
```bash
# 의존성 설치
flutter pub get

# 앱 실행
flutter run
```

### 배포 환경

#### Android 배포
```bash
# APK 빌드
flutter build apk --release

# App Bundle 빌드 (Google Play Store)
flutter build appbundle --release
```

#### iOS 배포
```bash
# iOS 빌드
flutter build ios --release

# Xcode에서 Archive 및 App Store Connect 업로드
```

#### 서버 배포
```bash
# Docker 컨테이너 빌드
docker build -t bemore-server .

# 컨테이너 실행
docker run -p 5001:5001 bemore-server
```

### 모니터링 및 로깅

#### 클라이언트 로깅
```dart
// 디버그 로그
print('🚀 멀티모달 분석 시작');
print('📊 입력 데이터: 영상=${base64Image != null ? "있음" : "없음"}');

// 에러 로그
print('❌ 이미지 분석 실패: ${response.statusCode}');
```

#### 서버 로깅
```python
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

logger.info("멀티모달 감정 분석 요청 수신")
logger.error(f"분석 중 오류 발생: {e}")
```

### 성능 최적화

#### 클라이언트 최적화
- **이미지 압축**: Base64 인코딩 전 이미지 크기 최적화
- **메모리 관리**: 대용량 데이터 자동 정리
- **배터리 최적화**: 백그라운드 처리 최소화

#### 서버 최적화
- **비동기 처리**: 멀티스레딩을 통한 동시 요청 처리
- **캐싱**: 자주 사용되는 데이터 메모리 캐싱
- **로드 밸런싱**: 트래픽 분산 처리

---

## 👨‍💻 개발 가이드

### 프로젝트 구조
```
lib/
├── components/          # 재사용 가능한 UI 컴포넌트
├── constants/           # 상수 정의
├── models/             # 데이터 모델
├── providers/          # 상태 관리 (Provider)
├── screens/            # 화면 UI
│   ├── analysis/       # 분석 관련 화면
│   ├── chat/          # AI 채팅 화면
│   ├── history/       # 기록 화면
│   ├── home/          # 홈 화면
│   ├── onboarding/    # 온보딩 화면
│   ├── record/        # 녹음 화면
│   ├── report/        # 리포트 화면
│   ├── session/       # 세션 화면
│   └── settings/      # 설정 화면
├── services/           # 비즈니스 로직
├── theme/             # 디자인 시스템
├── utils/             # 유틸리티 함수
└── widgets/           # 커스텀 위젯
```

### 코딩 컨벤션

#### 네이밍 규칙
```dart
// 클래스명: PascalCase
class MultimodalAnalysisService {}

// 변수/함수명: camelCase
String emotionCategory;
Future<void> analyzeEmotion() {}

// 상수: SCREAMING_SNAKE_CASE
static const String API_BASE_URL = 'http://localhost:5001';
```

#### 파일 구조
```dart
// 각 파일의 표준 구조
import 'package:flutter/material.dart';
// 기타 import...

class ClassName extends StatefulWidget {
  const ClassName({super.key});

  @override
  State<ClassName> createState() => _ClassNameState();
}

class _ClassNameState extends State<ClassName> {
  // 변수 선언
  
  @override
  void initState() {
    super.initState();
    // 초기화 로직
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // UI 구성
    );
  }
  
  // 메서드들
}
```

### 테스트 가이드

#### 단위 테스트
```dart
// test/widget_test.dart
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('VADEmotion Tests', () {
    test('should return correct emotion category', () {
      final emotion = VADEmotion(
        valence: 0.8,
        arousal: 0.7,
        dominance: 0.6,
        timestamp: DateTime.now(),
        source: 'combined',
      );
      
      expect(emotion.emotionCategory, equals('기쁨'));
    });
  });
}
```

#### 위젯 테스트
```dart
testWidgets('should display emotion analysis result', (WidgetTester tester) async {
  await tester.pumpWidget(const MaterialApp(
    home: AnalysisResultScreen(),
  ));
  
  expect(find.text('감정 분석 결과'), findsOneWidget);
  expect(find.byType(EmotionChart), findsOneWidget);
});
```

### 디버깅 가이드

#### 로그 레벨별 디버깅
```dart
// 개발 환경에서만 상세 로그 출력
if (kDebugMode) {
  print('🔍 상세 디버그 정보: $data');
}

// 에러 추적
try {
  await analyzeEmotion();
} catch (e, stackTrace) {
  print('❌ 에러 발생: $e');
  print('📍 스택 트레이스: $stackTrace');
}
```

#### 네트워크 디버깅
```dart
// API 요청/응답 로깅
print('📡 API 요청: $url');
print('📥 API 응답: ${response.body}');
```

---

## 📈 향후 개발 계획

### 단기 목표 (1-3개월)
- [ ] 실시간 얼굴 감정 인식 정확도 향상
- [ ] 음성 감정 분석 모델 개선
- [ ] CBT 피드백 시스템 고도화
- [ ] 사용자 개인화 기능 추가

### 중기 목표 (3-6개월)
- [ ] 소셜 기능 구현 (커뮤니티, 그룹 상담)
- [ ] 전문가 모드 개발 (의료진용)
- [ ] 다국어 지원 (영어, 일본어)
- [ ] 웹 버전 개발

### 장기 목표 (6개월 이상)
- [ ] AI 모델 자체 개발
- [ ] 임상 연구 및 검증
- [ ] 의료기기 인증 준비
- [ ] 글로벌 서비스 확장

---

## 📞 지원 및 문의

### 개발팀 연락처
- **프로젝트 리더**: [이메일 주소]
- **기술 문의**: [이메일 주소]
- **버그 리포트**: [GitHub Issues]

### 문서 버전
- **최종 업데이트**: 2024년 1월
- **문서 버전**: v1.0
- **Flutter 버전**: 3.x
- **Python 버전**: 3.8+

---

*이 문서는 BeMore 프로젝트의 기술적 구현과 아키텍처를 상세히 설명합니다. 추가 문의사항이나 개선 제안이 있으시면 개발팀에 연락해 주세요.* 