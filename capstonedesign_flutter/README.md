# BeMore: VAD 기반 멀티모달 감정 분석 & CBT 회고 시스템

Flutter 기반의 실시간 멀티모달 감정 분석 앱으로, 얼굴 표정, 음성, 텍스트를 통합 분석하여 VAD(Valence-Arousal-Dominance) 기반으로 감정 상태를 파악하고, CBT(인지행동치료) 기법을 활용한 맞춤형 피드백을 제공합니다.

## 🚀 주요 기능

### 📊 멀티모달 감정 분석
- **얼굴 표정 분석**: 실시간 카메라를 통한 표정 인식
- **음성 감정 분석**: 음성 톤과 패턴을 통한 감정 파악
- **텍스트 감정 분석**: 입력된 텍스트의 감정 상태 분석
- **VAD 기반 통합 분석**: Valence(긍정성), Arousal(활성화), Dominance(지배성) 세 차원으로 감정 수치화

### 🤖 AI 기반 대화 시스템
- **Gemini AI 연동**: Google Gemini AI를 활용한 자연스러운 대화
- **음성 인식**: 실시간 STT(Speech-to-Text) 기능
- **텍스트 채팅**: 키보드를 통한 직접 메시지 입력
- **대화 히스토리**: 이전 대화 내용 유지 및 컨텍스트 활용

### 🧠 CBT 기반 맞춤 피드백
- **인지 왜곡 분석**: 감정 상태에 따른 인지 패턴 분석
- **인지 재구성**: 부정적 사고를 긍정적으로 재해석
- **행동 계획**: 구체적이고 실천 가능한 행동 전략
- **CBT 기법 추천**: 상황별 맞춤형 치료 기법

### 📈 데이터 관리 & 리포트
- **세션 기록**: 모든 감정 분석 세션의 상세 기록
- **감정 변화 추적**: 시간에 따른 감정 변화 그래프
- **PDF 리포트**: 종합적인 감정 분석 리포트 생성
- **데이터 내보내기**: 분석 결과를 PDF 형태로 저장

### 🎨 사용자 경험
- **온보딩 화면**: 앱 사용법을 안내하는 친근한 온보딩
- **직관적 UI**: BeMore 전용 테마와 모던한 디자인
- **실시간 피드백**: 분석 중 실시간 상태 표시
- **권한 관리**: 카메라, 마이크 권한 자동 요청 및 안내

## 📱 앱 구조

### 메인 화면
- **홈**: 오늘의 감정 상태, 빠른 시작, AI 대화, 최근 피드백, 통계
- **소셜**: 커뮤니티 기능 (개발 중)
- **기록**: 과거 감정 분석 기록 및 통계
- **설정**: 앱 설정, 데이터 관리, 앱 정보

### 핵심 화면
- **온보딩**: 앱 소개 및 사용법 안내
- **멀티모달 세션**: 실시간 감정 분석 세션
- **AI 채팅**: Gemini AI와의 자연스러운 대화
- **분석 결과**: 상세한 감정 분석 결과 및 CBT 피드백
- **히스토리**: 과거 분석 기록 조회

## 📋 환경 설정

### 1. 환경변수 설정

프로젝트 루트에 `.env` 파일을 생성하고 다음 내용을 추가하세요:

```env
# Emotion Analysis API Server URL
EMOTION_API_URL=http://localhost:5001

# Gemini AI API Key (AI 채팅 기능에 필수)
GEMINI_API_KEY=your_actual_gemini_api_key_here

# OpenAI API Key (기존 GPT 서비스용)
OPENAI_API_KEY=your_openai_api_key_here
```

### 2. Gemini API 키 발급 (AI 채팅 기능)

1. [Google AI Studio](https://makersuite.google.com/app/apikey)에 접속
2. Google 계정으로 로그인
3. "Create API Key" 버튼 클릭
4. 생성된 API 키를 복사하여 `.env` 파일의 `GEMINI_API_KEY`에 설정

**⚠️ 중요**: AI 채팅 기능을 사용하려면 반드시 Gemini API 키가 필요합니다.

### 3. 서버 설정

```bash
# 서버 디렉토리로 이동
cd capstonedesign-server

# Python 가상환경 생성 (선택사항)
python -m venv venv
source venv/bin/activate  # macOS/Linux
# 또는
venv\Scripts\activate  # Windows

# 의존성 설치
pip install -r requirements.txt

# 서버 실행
python multimodal_emotion_api.py
```

### 4. Flutter 앱 설정

```bash
# Flutter 앱 디렉토리로 이동
cd capstonedesign_flutter

# 의존성 설치
flutter pub get

# 앱 실행
flutter run
```

## 🎯 주요 기능 상세

### 1. VAD 기반 감정 분석
- **Valence (긍정성)**: 감정의 긍정적/부정적 특성 (0.0 ~ 1.0)
- **Arousal (활성화)**: 감정의 활성화 정도 (0.0 ~ 1.0)
- **Dominance (지배성)**: 감정의 지배성/통제력 (0.0 ~ 1.0)
- **감정 카테고리 매핑**: VAD 값을 7가지 감정 카테고리로 변환

### 2. AI 채팅 시스템
- **음성 인식**: 마이크 버튼을 길게 눌러 음성으로 대화
- **텍스트 입력**: 키보드로 직접 메시지 입력
- **실시간 응답**: Gemini AI가 즉시 응답 생성
- **대화 히스토리**: 이전 대화 내용 유지
- **한국어 지원**: 한국어로 자연스러운 대화

### 3. CBT 피드백 시스템
- **인지 왜곡 식별**: 과도한 일반화, 재앙화, 개인화 등
- **인지 재구성**: 부정적 사고를 긍정적으로 재해석
- **행동 계획**: 구체적이고 실천 가능한 행동 전략
- **CBT 기법 추천**: 상황별 맞춤형 치료 기법

### 4. 멀티모달 세션
- **실시간 카메라**: 얼굴 표정 실시간 분석
- **음성 녹음**: 음성 톤과 패턴 분석
- **텍스트 입력**: 직접 텍스트 입력으로 감정 표현
- **통합 분석**: 세 가지 모달리티의 가중 평균으로 최종 감정 결정

### 5. 데이터 관리
- **세션 저장**: 모든 분석 세션의 상세 데이터 저장
- **감정 통계**: 일별, 주별, 월별 감정 변화 통계
- **PDF 리포트**: 종합적인 분석 결과 리포트 생성
- **데이터 내보내기**: 분석 결과를 PDF 형태로 저장

## 🔧 API 엔드포인트

### 서버 API (포트 5001)

- `POST /analyze_multimodal_emotion`: 멀티모달 감정 분석
- `POST /generate_question`: Gemini AI 질문 생성
- `GET /health`: 서버 상태 확인
- `GET /test_mock`: 모킹 데이터 테스트

### AI 채팅 API (Gemini)

- `POST /v1beta/models/gemini-pro:generateContent`: Gemini AI 응답 생성
- 대화 컨텍스트 유지
- 한국어 최적화

## 🛠️ 기술 스택

### Frontend (Flutter)
- **Flutter 3.x**: 크로스 플랫폼 앱 개발
- **Provider**: 상태 관리
- **camera**: 카메라 접근 및 실시간 영상 처리
- **record**: 음성 녹음
- **speech_to_text**: 실시간 음성 인식
- **http**: API 통신
- **flutter_dotenv**: 환경변수 관리
- **google_fonts**: 커스텀 폰트
- **lottie**: 애니메이션
- **fl_chart**: 차트 및 그래프
- **pdf**: PDF 리포트 생성
- **shared_preferences**: 로컬 데이터 저장
- **permission_handler**: 권한 관리

### Backend (Python Flask)
- **Flask**: 웹 프레임워크
- **TensorFlow**: 얼굴 감정 분석
- **Whisper**: 음성-텍스트 변환
- **google-generativeai**: Gemini AI 연동
- **OpenAI**: GPT 응답 생성

### 데이터 모델
- **VADEmotion**: VAD 기반 감정 데이터
- **EmotionDataPoint**: 감정 분석 데이터 포인트
- **MultimodalDataPoint**: 멀티모달 통합 데이터
- **CBTFeedback**: CBT 기반 피드백 데이터
- **ChatMessage**: AI 채팅 메시지 데이터

## 🎨 디자인 시스템

### BeMore 테마
- **Primary Color**: 인디고 (#6366F1)
- **Secondary Color**: 바이올렛 (#8B5CF6)
- **Accent Color**: 시안 (#06B6D4)
- **Background**: 연한 회색 (#F8FAFC)
- **Surface**: 흰색 (#FFFFFF)

### 감정별 컬러
- **기쁨**: 초록색 (#10B981)
- **평온**: 파란색 (#3B82F6)
- **슬픔**: 인디고 (#6366F1)
- **불안**: 주황색 (#F59E0B)
- **분노**: 빨간색 (#EF4444)
- **중립**: 회색 (#6B7280)

## 🔍 문제 해결

### 권한 문제
- **iOS**: 설정 > 개인정보 보호 > 카메라/마이크에서 앱 권한 확인
- **Android**: 설정 > 앱 > 권한에서 확인
- **권한 거부 시**: 앱 내에서 설정 화면으로 안내

### 서버 연결 문제
- 서버가 실행 중인지 확인
- IP 주소와 포트 번호 확인 (기본: 192.168.219.108:5001)
- 방화벽 설정 확인
- 네트워크 연결 상태 확인

### API 키 문제
- `.env` 파일에 올바른 API 키가 설정되었는지 확인
- API 키의 유효성 확인
- 할당량 초과 여부 확인
- Gemini API 키가 올바르게 설정되었는지 확인

### AI 채팅 문제
- Gemini API 키가 올바르게 설정되었는지 확인
- 인터넷 연결 상태 확인
- 음성 인식 권한 확인
- 마이크 하드웨어 상태 확인

### 감정 분석 문제
- 카메라 권한 확인
- 마이크 권한 확인
- 충분한 조명 환경 확인
- 안정적인 네트워크 연결 확인

## 📄 라이선스

이 프로젝트는 교육 목적으로 개발되었습니다.

## 👨‍💻 개발자

**우성종** - BeMore 앱 개발

## 🔄 업데이트 로그

### v1.0.0
- 멀티모달 감정 분석 시스템 구현
- VAD 기반 감정 분석 알고리즘 적용
- CBT 기반 맞춤 피드백 시스템 구현
- AI 채팅 기능 (Gemini AI 연동)
- 온보딩 화면 및 사용자 경험 개선
- PDF 리포트 생성 기능
- BeMore 전용 테마 및 디자인 시스템 적용 