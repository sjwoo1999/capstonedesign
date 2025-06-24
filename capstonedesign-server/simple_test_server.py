from flask import Flask, jsonify
from flask_cors import CORS
import socket
from datetime import datetime

app = Flask(__name__)
CORS(app)

@app.route('/health', methods=['GET'])
def health_check():
    return jsonify({
        'status': 'healthy',
        'timestamp': datetime.now().isoformat(),
        'message': '간단한 테스트 서버가 실행 중입니다.'
    })

@app.route('/analyze', methods=['POST'])
def analyze_emotion():
    import random
    emotions = ['Happy', 'Sad', 'Angry', 'Fear', 'Surprise', 'Disgust', 'Neutral']
    emotion = random.choice(emotions)
    confidence = random.uniform(0.6, 0.95)
    
    return jsonify({
        'success': True,
        'mock': True,
        'emotion': emotion,
        'confidence': confidence,
        'vad': {'valence': 0.5, 'arousal': 0.3, 'dominance': 0.4},
        'timestamp': datetime.now().isoformat()
    })

if __name__ == '__main__':
    print("🚀 테스트 서버 시작... (포트: 5002)")
    app.run(host='0.0.0.0', port=5002, debug=True)
