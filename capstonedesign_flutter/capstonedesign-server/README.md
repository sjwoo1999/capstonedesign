# BeMore 감정 분석 서버

Flutter 앱과 연동되는 실시간 감정 분석 서버입니다.

## 🚀 빠른 시작

### 1. 환경 설정
```bash
# Python 가상환경 생성
python -m venv venv

# 가상환경 활성화
source venv/bin/activate  # macOS/Linux
# venv\Scripts\activate  # Windows

# 의존성 설치
pip install -r requirements.txt
```

### 2. 서버 실행
```bash
python app.py
```

### 3. 서버 확인
- 브라우저에서 `http://localhost:5001/health` 접속
- 또는 `curl http://localhost:5001/health`

## 📋 API 엔드포인트

### 1. 서버 상태 확인
```http
GET /health
```

**응답:**
```json
{
  "status": "healthy",
  "timestamp": "2024-01-01T12:00:00",
  "model_loaded": true,
  "face_detector_loaded": true
}
```

### 2. 감정 분석
```http
POST /analyze
Content-Type: application/json

{
  "image": "base64_encoded_image_data"
}
```

**응답:**
```json
{
  "success": true,
  "emotion": "Happy",
  "confidence": 0.85,
  "vad": {
    "valence": 0.68,
    "arousal": 0.51,
    "dominance": 0.60
  },
  "probabilities": {
    "Angry": 0.02,
    "Disgust": 0.01,
    "Fear": 0.03,
    "Happy": 0.85,
    "Sad": 0.05,
    "Surprise": 0.02,
    "Neutral": 0.02
  },
  "timestamp": "2024-01-01T12:00:00"
}
```

### 3. 서버 정보
```http
GET /whoami
```

**응답:**
```json
{
  "hostname": "your-computer",
  "ip": "192.168.1.100",
  "port": 5001,
  "model_loaded": true,
  "timestamp": "2024-01-01T12:00:00"
}
```

### 4. 모델 목록
```http
GET /models
```

**응답:**
```json
{
  "models": [
    {
      "name": "emotion_model.h5",
      "size_mb": 852.0,
      "path": "models/emotion_model.h5"
    }
  ],
  "total_count": 1
}
```

## 🔧 Flutter 앱 연동

### 1. 서버 URL 설정
Flutter 앱의 `lib/services/emotion_api_services.dart`에서 서버 URL을 설정하세요:

```dart
class EmotionAPIService {
  // 개발 환경
  static const String baseUrl = 'http://localhost:5001';
  
  // 실제 디바이스에서 테스트할 때는 서버의 IP 주소 사용
  // static const String baseUrl = 'http://192.168.1.100:5001';
}
```

### 2. API 호출 예시
```dart
Future<Map<String, dynamic>> sendImageForAnalysis(String base64Image) async {
  try {
    final response = await http.post(
      Uri.parse('$baseUrl/analyze'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'image': base64Image}),
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('서버 오류: ${response.statusCode}');
    }
  } catch (e) {
    throw Exception('네트워크 오류: $e');
  }
}
```

## 📁 프로젝트 구조

```
capstonedesign-server/
├── app.py                 # 메인 서버 파일
├── requirements.txt       # Python 의존성
├── README.md             # 이 파일
├── models/               # AI 모델 파일들
│   ├── emotion_model.h5  # 감정 분석 모델
│   ├── model.tflite      # TensorFlow Lite 모델
│   └── mobilenet_v2_1.0_224.tflite
└── venv/                 # Python 가상환경 (자동 생성)
```

## 🛠️ 개발 가이드

### 1. 로그 확인
서버 실행 시 상세한 로그가 출력됩니다:
```
2024-01-01 12:00:00 - __main__ - INFO - ✅ 감정 분석 모델 로드 완료
2024-01-01 12:00:00 - __main__ - INFO - ✅ 얼굴 검출기 로드 완료
2024-01-01 12:00:01 - __main__ - INFO - 이미지 분석 요청: (480, 640, 3)
2024-01-01 12:00:01 - __main__ - INFO - 분석 완료: Happy (신뢰도: 0.85)
```

### 2. Mock 모드
모델 파일이 없거나 라이브러리 설치에 문제가 있을 때 자동으로 Mock 모드로 실행됩니다.

### 3. CORS 설정
Flutter 앱과의 통신을 위해 CORS가 활성화되어 있습니다.

## 🔍 문제 해결

### 1. 모델 로드 실패
```bash
# 모델 파일 확인
ls -la models/

# 의존성 재설치
pip install -r requirements.txt
```

### 2. 포트 충돌
```bash
# 포트 사용 확인
lsof -i :5001

# 다른 포트 사용
python app.py --port 5002
```

### 3. 네트워크 연결 문제
```bash
# 방화벽 설정 확인
sudo ufw status

# 서버 IP 확인
python -c "import socket; print(socket.gethostbyname(socket.gethostname()))"
```

## 📊 성능 최적화

### 1. 모델 최적화
- TensorFlow Lite 모델 사용 고려
- 모델 양자화 (Quantization)
- 배치 처리 구현

### 2. 서버 최적화
- Gunicorn + Nginx 조합
- Redis 캐싱
- 비동기 처리 (FastAPI 고려)

## 🔄 배포

### 1. 로컬 개발
```bash
python app.py
```

### 2. 프로덕션 배포
```bash
# Gunicorn 사용
pip install gunicorn
gunicorn -w 4 -b 0.0.0.0:5001 app:app

# Docker 사용
docker build -t bemore-server .
docker run -p 5001:5001 bemore-server
```

## 📞 지원

문제가 발생하면 다음을 확인하세요:
1. 로그 메시지 확인
2. `/health` 엔드포인트로 서버 상태 확인
3. 모델 파일 존재 여부 확인
4. 네트워크 연결 상태 확인 