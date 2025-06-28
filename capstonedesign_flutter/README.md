# 멀티모달 감정 분석 앱

Flutter 기반의 실시간 멀티모달 감정 분석 앱으로, 얼굴 표정, 음성, 텍스트를 통합 분석하여 감정 상태를 파악하고 AI 기반 대화형 상담을 제공합니다.

## 🚀 주요 기능

- **멀티모달 감정 분석**: 얼굴 표정, 음성, 텍스트 통합 분석
- **실시간 STT**: 음성-텍스트 변환 및 감정 분석
- **AI 기반 대화**: Gemini AI를 활용한 동적 질문 생성
- **AI 채팅**: 음성/텍스트로 Gemini AI와 자연스러운 대화
- **CBT 전략 매핑**: 감정 상태에 따른 인지행동치료 전략 제안
- **PDF 리포트**: 종합 감정 분석 리포트 생성

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

## 📱 앱 기능

### 1. AI 채팅 (새로운 기능)
- **음성 인식**: 마이크 버튼을 길게 눌러 음성으로 대화
- **텍스트 입력**: 키보드로 직접 메시지 입력
- **실시간 응답**: Gemini AI가 즉시 응답 생성
- **대화 히스토리**: 이전 대화 내용 유지
- **한국어 지원**: 한국어로 자연스러운 대화

### 2. 권한 관리
- 카메라, 마이크 권한 자동 요청
- 권한 거부 시 설정 화면으로 안내

### 3. 실시간 감정 분석
- 얼굴 표정 실시간 분석
- 음성 녹음 및 STT 변환
- 텍스트 직접 입력 지원

### 4. AI 대화 시스템
- 대화 히스토리 기반 동적 질문 생성
- 감정 상태에 따른 맞춤형 질문
- 자연스러운 대화 흐름

### 5. 데이터 관리
- 대화 세션별 데이터 저장
- 감정 변화 추적
- PDF 리포트 생성

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
- Flutter 3.x
- speech_to_text: 음성 인식
- camera: 카메라 접근
- http: API 통신
- flutter_dotenv: 환경변수 관리
- uuid: 고유 ID 생성

### Backend (Python Flask)
- Flask: 웹 프레임워크
- TensorFlow: 얼굴 감정 분석
- Whisper: 음성-텍스트 변환
- google-generativeai: Gemini AI 연동
- OpenAI: GPT 응답 생성

## 🔍 문제 해결

### 권한 문제
- iOS: 설정 > 개인정보 보호 > 카메라/마이크에서 앱 권한 확인
- Android: 설정 > 앱 > 권한에서 확인

### 서버 연결 문제
- 서버가 실행 중인지 확인
- IP 주소와 포트 번호 확인
- 방화벽 설정 확인

### API 키 문제
- `.env` 파일에 올바른 API 키가 설정되었는지 확인
- API 키의 유효성 확인
- 할당량 초과 여부 확인

### AI 채팅 문제
- Gemini API 키가 올바르게 설정되었는지 확인
- 인터넷 연결 상태 확인
- 음성 인식 권한 확인

## 📄 라이선스

이 프로젝트는 교육 목적으로 개발되었습니다. 