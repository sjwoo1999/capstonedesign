from flask import Flask, request, jsonify
from flask_cors import CORS
import numpy as np
import cv2
import base64
import logging
import os
from datetime import datetime
import socket
from typing import Dict, Any, Optional

# 로깅 설정
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

app = Flask(__name__)
CORS(app)  # Flutter 앱과의 CORS 문제 해결

# 모델 로드 (에러 처리 포함)
try:
    from keras.models import load_model
    import dlib
    
    # 모델 파일 경로 확인
    emotion_model_path = "models/emotion_model.h5"
    if os.path.exists(emotion_model_path):
        emotion_model = load_model(emotion_model_path, compile=False)
        logger.info("✅ 감정 분석 모델 로드 완료")
    else:
        logger.warning("⚠️ 감정 분석 모델 파일을 찾을 수 없습니다. Mock 모드로 실행됩니다.")
        emotion_model = None
    
    face_detector = dlib.get_frontal_face_detector()
    logger.info("✅ 얼굴 검출기 로드 완료")
    
except ImportError as e:
    logger.error(f"❌ 필요한 라이브러리가 설치되지 않았습니다: {e}")
    logger.info("💡 pip install -r requirements.txt 를 실행해주세요.")
    emotion_model = None
    face_detector = None

# 감정 라벨
expression_labels = ['Angry', 'Disgust', 'Fear', 'Happy', 'Sad', 'Surprise', 'Neutral']

def preprocess_face(image: np.ndarray) -> Optional[np.ndarray]:
    """얼굴 이미지 전처리"""
    try:
        gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
        faces = face_detector(gray)
        
        if not faces:
            logger.warning("얼굴이 검출되지 않았습니다.")
            return None
            
        face = faces[0]
        x, y, w, h = face.left(), face.top(), face.width(), face.height()
        roi = gray[y:y+h, x:x+w]
        roi = cv2.resize(roi, (64, 64))
        roi = roi.astype("float32") / 255.0
        roi = np.expand_dims(roi, axis=-1)
        roi = np.expand_dims(roi, axis=0)
        return roi
        
    except Exception as e:
        logger.error(f"얼굴 전처리 중 오류: {e}")
        return None

def calculate_vad_from_emotion(emotion: str, confidence: float) -> Dict[str, float]:
    """감정을 VAD 값으로 변환"""
    # 감정별 VAD 매핑 (Valence, Arousal, Dominance)
    emotion_vad_map = {
        'Happy': {'valence': 0.8, 'arousal': 0.6, 'dominance': 0.7},
        'Sad': {'valence': -0.6, 'arousal': -0.3, 'dominance': -0.4},
        'Angry': {'valence': -0.7, 'arousal': 0.8, 'dominance': 0.6},
        'Fear': {'valence': -0.4, 'arousal': 0.7, 'dominance': -0.5},
        'Surprise': {'valence': 0.2, 'arousal': 0.8, 'dominance': 0.1},
        'Disgust': {'valence': -0.8, 'arousal': 0.3, 'dominance': -0.2},
        'Neutral': {'valence': 0.0, 'arousal': 0.0, 'dominance': 0.0},
    }
    
    base_vad = emotion_vad_map.get(emotion, emotion_vad_map['Neutral'])
    
    # 신뢰도에 따른 조정
    confidence_factor = confidence * 0.3 + 0.7  # 0.7 ~ 1.0 범위
    
    return {
        'valence': base_vad['valence'] * confidence_factor,
        'arousal': base_vad['arousal'] * confidence_factor,
        'dominance': base_vad['dominance'] * confidence_factor
    }

def mock_emotion_analysis() -> Dict[str, Any]:
    """Mock 감정 분석 (모델이 없을 때 사용)"""
    import random
    
    emotions = ['Happy', 'Sad', 'Angry', 'Fear', 'Surprise', 'Disgust', 'Neutral']
    emotion = random.choice(emotions)
    confidence = random.uniform(0.6, 0.95)
    
    vad = calculate_vad_from_emotion(emotion, confidence)
    
    return {
        'emotion': emotion,
        'confidence': confidence,
        'vad': vad,
        'probabilities': {e: random.uniform(0.0, 0.3) for e in emotions}
    }

@app.route('/health', methods=['GET'])
def health_check():
    """서버 상태 확인"""
    return jsonify({
        'status': 'healthy',
        'timestamp': datetime.now().isoformat(),
        'model_loaded': emotion_model is not None,
        'face_detector_loaded': face_detector is not None
    })

@app.route('/analyze', methods=['POST'])
def analyze_emotion():
    """감정 분석 API (Flutter 앱용)"""
    try:
        data = request.get_json()
        if not data or 'image' not in data:
            return jsonify({'error': '이미지 데이터가 필요합니다.'}), 400
        
        # Base64 이미지 디코딩
        img_data = data['image']
        img_bytes = base64.b64decode(img_data)
        img_array = np.frombuffer(img_bytes, np.uint8)
        img = cv2.imdecode(img_array, cv2.IMREAD_COLOR)
        
        if img is None:
            return jsonify({'error': '이미지를 디코딩할 수 없습니다.'}), 400
        
        logger.info(f"이미지 분석 요청: {img.shape}")
        
        # 모델이 없는 경우 Mock 분석
        if emotion_model is None:
            logger.info("Mock 감정 분석 실행")
            result = mock_emotion_analysis()
            return jsonify({
                'success': True,
                'mock': True,
                **result
            })
        
        # 실제 감정 분석
        face = preprocess_face(img)
        if face is None:
            return jsonify({'error': '얼굴이 검출되지 않았습니다.'}), 400
        
        # 모델 예측
        preds = emotion_model.predict(face, verbose=0)[0]
        emotion_idx = int(np.argmax(preds))
        emotion_label = expression_labels[emotion_idx]
        confidence = float(preds[emotion_idx])
        
        # VAD 계산
        vad = calculate_vad_from_emotion(emotion_label, confidence)
        
        # 확률 분포
        probabilities = {
            expression_labels[i]: float(preds[i]) for i in range(len(preds))
        }
        
        result = {
            'success': True,
            'emotion': emotion_label,
            'confidence': confidence,
            'vad': vad,
            'probabilities': probabilities,
            'timestamp': datetime.now().isoformat()
        }
        
        logger.info(f"분석 완료: {emotion_label} (신뢰도: {confidence:.2f})")
        return jsonify(result)
        
    except Exception as e:
        logger.error(f"분석 중 오류 발생: {e}")
        return jsonify({
            'error': f'분석 중 오류가 발생했습니다: {str(e)}',
            'success': False
        }), 500

@app.route('/whoami', methods=['GET'])
def get_server_info():
    """서버 정보 반환"""
    try:
        hostname = socket.gethostname()
        ip_address = socket.gethostbyname(hostname)
        
        return jsonify({
            'hostname': hostname,
            'ip': ip_address,
            'port': 5001,
            'model_loaded': emotion_model is not None,
            'timestamp': datetime.now().isoformat()
        })
    except Exception as e:
        logger.error(f"서버 정보 조회 중 오류: {e}")
        return jsonify({
            'error': '서버 정보를 조회할 수 없습니다.',
            'ip': 'localhost'
        }), 500

@app.route('/models', methods=['GET'])
def list_models():
    """사용 가능한 모델 목록"""
    models_dir = "models"
    available_models = []
    
    if os.path.exists(models_dir):
        for file in os.listdir(models_dir):
            if file.endswith(('.h5', '.tflite', '.pb')):
                file_path = os.path.join(models_dir, file)
                size = os.path.getsize(file_path)
                available_models.append({
                    'name': file,
                    'size_mb': round(size / (1024 * 1024), 2),
                    'path': file_path
                })
    
    return jsonify({
        'models': available_models,
        'total_count': len(available_models)
    })

if __name__ == '__main__':
    print("🚀 BeMore 감정 분석 서버 시작...")
    print("📊 서버 정보:")
    print(f"   - 모델 로드: {'✅' if emotion_model else '❌'}")
    print(f"   - 얼굴 검출기: {'✅' if face_detector else '❌'}")
    print(f"   - 포트: 5001")
    print(f"   - CORS: 활성화")
    print("\n🔗 접속 주소:")
    print("   - 로컬: http://localhost:5001")
    print("   - 네트워크: http://[IP]:5001")
    print("\n📋 사용 가능한 엔드포인트:")
    print("   - GET  /health     - 서버 상태 확인")
    print("   - POST /analyze    - 감정 분석")
    print("   - GET  /whoami     - 서버 정보")
    print("   - GET  /models     - 모델 목록")
    
    app.run(host='0.0.0.0', port=5001, debug=True) 