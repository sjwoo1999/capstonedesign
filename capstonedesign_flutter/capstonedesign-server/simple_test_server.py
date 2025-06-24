from flask import Flask, jsonify
from flask_cors import CORS
import socket
from datetime import datetime

app = Flask(__name__)
CORS(app)

@app.route('/health', methods=['GET'])
def health_check():
    """서버 상태 확인"""
    return jsonify({
        'status': 'healthy',
        'timestamp': datetime.now().isoformat(),
        'model_loaded': False,
        'face_detector_loaded': False,
        'message': '간단한 테스트 서버가 실행 중입니다.'
    })

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
            'model_loaded': False,
            'timestamp': datetime.now().isoformat()
        })
    except Exception as e:
        return jsonify({
            'error': '서버 정보를 조회할 수 없습니다.',
            'ip': 'localhost'
        }), 500

@app.route('/analyze', methods=['POST'])
def analyze_emotion():
    """Mock 감정 분석"""
    import random
    
    emotions = ['Happy', 'Sad', 'Angry', 'Fear', 'Surprise', 'Disgust', 'Neutral']
    emotion = random.choice(emotions)
    confidence = random.uniform(0.6, 0.95)
    
    # VAD 계산
    emotion_vad_map = {
        'Happy': {'valence': 0.8, 'arousal': 0.6, 'dominance': 0.7},
        'Sad': {'valence': -0.6, 'arousal': -0.3, 'dominance': -0.4},
        'Angry': {'valence': -0.7, 'arousal': 0.8, 'dominance': 0.6},
        'Fear': {'valence': -0.4, 'arousal': 0.7, 'dominance': -0.5},
        'Surprise': {'valence': 0.2, 'arousal': 0.8, 'dominance': 0.1},
        'Disgust': {'valence': -0.8, 'arousal': 0.3, 'dominance': -0.2},
        'Neutral': {'valence': 0.0, 'arousal': 0.0, 'dominance': 0.0},
    }
    
    base_vad = emotion_vad_map[emotion]
    confidence_factor = confidence * 0.3 + 0.7
    
    vad = {
        'valence': base_vad['valence'] * confidence_factor,
        'arousal': base_vad['arousal'] * confidence_factor,
        'dominance': base_vad['dominance'] * confidence_factor
    }
    
    return jsonify({
        'success': True,
        'mock': True,
        'emotion': emotion,
        'confidence': confidence,
        'vad': vad,
        'probabilities': {e: random.uniform(0.0, 0.3) for e in emotions},
        'timestamp': datetime.now().isoformat()
    })

if __name__ == '__main__':
    print("🚀 간단한 테스트 서버 시작...")
    print("📊 서버 정보:")
    print(f"   - 포트: 5002")
    print(f"   - CORS: 활성화")
    print("\n🔗 접속 주소:")
    print("   - 로컬: http://localhost:5002")
    print("\n📋 사용 가능한 엔드포인트:")
    print("   - GET  /health     - 서버 상태 확인")
    print("   - POST /analyze    - Mock 감정 분석")
    print("   - GET  /whoami     - 서버 정보")
    
    app.run(host='0.0.0.0', port=5002, debug=True) 