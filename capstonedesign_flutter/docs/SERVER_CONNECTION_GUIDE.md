# 서버 연결 문제 해결 가이드

## 🔍 현재 상황 분석

### **서버 연결 실패 이력**
```
❌ http://10.123.5.135:5001 - 연결 실패
❌ http://192.168.219.106:5001 - 연결 실패  
❌ http://127.0.0.1:5001 - 연결 실패
❌ http://172.30.1.73:5001 (fallback) - 연결 실패
```

### **근본 원인**
1. **실제 감정 분석 서버가 실행되지 않음**
2. **네트워크 설정 문제**
3. **방화벽 또는 보안 설정**
4. **포트 충돌**

## 🛠️ 해결 방안

### **Phase 1: 즉시 해결 (Mock 시스템)**

현재 개발 초기 단계에서는 **Mock 분석 시스템**을 사용하여 즉시 결과를 제공합니다.

#### ✅ 구현된 기능
- `MockAnalysisService`: VAD 데이터 기반 즉시 분석
- 1회성 분석 결과 생성
- 데이터베이스 연동 없이 작동
- 클로바 노트 대기 시간 없음

#### 🎯 사용 방법
```dart
// 세션 데이터로 즉시 분석
final result = MockAnalysisService.analyzeSessionData(sessionData);

// 분석 결과 포함:
// - 감정 카테고리 (기쁨, 슬픔, 화남, 불안 등)
// - VAD 통계 (Valence, Arousal, Dominance)
// - 감정 변화 패턴
// - CBT 피드백
// - 개선 제안
```

### **Phase 2: 실제 서버 연동 (선택사항)**

#### **옵션 1: 로컬 서버 구축**
```bash
# 1. Python 환경 설정
python -m venv venv
source venv/bin/activate  # macOS/Linux
# venv\Scripts\activate  # Windows

# 2. 필요한 패키지 설치
pip install flask flask-cors opencv-python numpy tensorflow

# 3. 간단한 감정 분석 서버 생성
```

**예시 서버 코드 (`emotion_server.py`):**
```python
from flask import Flask, request, jsonify
from flask_cors import CORS
import numpy as np
import base64
import cv2

app = Flask(__name__)
CORS(app)

@app.route('/analyze', methods=['POST'])
def analyze_emotion():
    try:
        data = request.json
        image_data = data.get('image')
        
        # Base64 이미지 디코딩
        image_bytes = base64.b64decode(image_data)
        nparr = np.frombuffer(image_bytes, np.uint8)
        image = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
        
        # Mock 감정 분석 (실제로는 AI 모델 사용)
        vad_result = {
            'valence': np.random.uniform(-1, 1),
            'arousal': np.random.uniform(-1, 1),
            'dominance': np.random.uniform(-1, 1)
        }
        
        return jsonify({
            'success': True,
            'vad': vad_result,
            'emotion': 'neutral'
        })
    except Exception as e:
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5001, debug=True)
```

#### **옵션 2: 클라우드 서비스 활용**
- **Google Cloud Vision API**
- **AWS Rekognition**
- **Azure Computer Vision**
- **Clova Face Recognition API**

#### **옵션 3: 오픈소스 모델 활용**
- **DeepFace**: 얼굴 감정 인식
- **FER2013**: 감정 분류 모델
- **OpenCV DNN**: 사전 훈련된 모델

## 🔧 네트워크 문제 해결

### **1. IP 주소 확인**
```bash
# macOS/Linux
ifconfig | grep "inet "

# Windows
ipconfig

# 현재 IP 주소를 확인하여 올바른 주소 사용
```

### **2. 포트 확인**
```bash
# 포트 사용 중인지 확인
lsof -i :5001  # macOS/Linux
netstat -an | findstr :5001  # Windows

# 방화벽 설정 확인
sudo ufw status  # Ubuntu
sudo pfctl -s rules  # macOS
```

### **3. 서버 상태 확인**
```bash
# 서버가 실행 중인지 확인
curl http://localhost:5001/health

# 또는 브라우저에서
http://localhost:5001/health
```

## 📱 앱 설정 수정

### **서버 URL 설정**
```dart
// lib/services/emotion_api_services.dart
class EmotionAPIService {
  // 개발 환경별 서버 URL 설정
  static const String _baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:5001'
  );
  
  // 또는 환경별 설정
  static String get baseUrl {
    if (kDebugMode) {
      return 'http://localhost:5001';  // 개발
    } else {
      return 'https://your-production-server.com';  // 프로덕션
    }
  }
}
```

### **네트워크 보안 설정**

**Android (`android/app/src/main/AndroidManifest.xml`):**
```xml
<application
    android:usesCleartextTraffic="true"
    ...>
```

**iOS (`ios/Runner/Info.plist`):**
```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <true/>
</dict>
```

## 🚀 배포 고려사항

### **개발 단계 (현재)**
- ✅ Mock 시스템 사용
- ✅ 즉시 분석 결과 제공
- ✅ 데이터베이스 없이 작동

### **프로덕션 단계**
- 🔄 실제 AI 모델 연동
- 🔄 데이터베이스 구축
- 🔄 보안 강화
- 🔄 성능 최적화

## 📊 현재 Mock 시스템의 장점

### **1. 즉시 결과**
- 서버 대기 시간 없음
- 네트워크 의존성 제거
- 개발 속도 향상

### **2. 안정성**
- 서버 다운타임 없음
- 일관된 응답 시간
- 예측 가능한 동작

### **3. 확장성**
- 다양한 감정 패턴 지원
- CBT 피드백 자동 생성
- 개인화된 제안

### **4. 개발 효율성**
- 빠른 프로토타이핑
- UI/UX 테스트 용이
- 기능 검증 가능

## 🎯 다음 단계 권장사항

### **우선순위 1: Mock 시스템 완성**
- [x] 기본 감정 분석
- [x] VAD 통계 계산
- [x] CBT 피드백 생성
- [ ] 차트 시각화 개선
- [ ] 개인화 알고리즘 강화

### **우선순위 2: 사용자 경험 개선**
- [ ] 분석 결과 저장
- [ ] 히스토리 기능
- [ ] 진행 상황 추적
- [ ] 알림 시스템

### **우선순위 3: 실제 서버 연동 (선택)**
- [ ] 로컬 서버 구축
- [ ] AI 모델 통합
- [ ] 데이터베이스 설계
- [ ] 보안 강화

## 💡 결론

현재 Mock 시스템으로도 충분히 기능적인 감정 분석 앱을 제공할 수 있습니다. 서버 연결 문제는 개발 초기 단계에서는 오히려 Mock 시스템을 사용하는 것이 더 효율적입니다.

**권장사항:**
1. Mock 시스템을 완성하여 사용자 피드백 수집
2. 앱의 핵심 기능과 UI/UX에 집중
3. 사용자 기반이 확보된 후 실제 서버 연동 고려
4. 점진적으로 AI 모델 통합

이렇게 하면 개발 속도를 유지하면서도 안정적인 서비스를 제공할 수 있습니다. 