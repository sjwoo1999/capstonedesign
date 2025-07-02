from flask import Flask, request, jsonify
from flask_cors import CORS
import base64
import json
import logging
from datetime import datetime
import numpy as np

# 로깅 설정
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = Flask(__name__)
CORS(app)

@app.route('/health', methods=['GET'])
def health_check():
    return jsonify({'status': 'healthy', 'timestamp': datetime.now().isoformat()})

@app.route('/analyze_multimodal_emotion', methods=['POST'])
def analyze_multimodal_emotion():
    try:
        data = request.get_json()
        logger.info("멀티모달 감정 분석 요청 수신")
        
        # 입력 데이터 추출
        image_data = data.get('image', '')
        audio_data = data.get('audio', '')
        text_data = data.get('text', '')
        
        logger.info(f"입력 데이터: 이미지={len(image_data) > 0}, 오디오={len(audio_data) > 0}, 텍스트={len(text_data) > 0}")
        
        # Mock 분석 결과 생성
        result = generate_mock_analysis(image_data, audio_data, text_data)
        
        logger.info("분석 완료")
        return jsonify(result)
        
    except Exception as e:
        logger.error(f"분석 중 오류 발생: {e}")
        return jsonify({'error': str(e)}), 500

def generate_mock_analysis(image_data, audio_data, text_data):
    """Mock 감정 분석 결과 생성"""
    
    # 기본 VAD 값들
    base_valence = 0.5
    base_arousal = 0.5
    base_dominance = 0.5
    
    # 텍스트가 있으면 VAD 값 조정
    if text_data:
        text_lower = text_data.lower()
        if any(word in text_lower for word in ['좋', '행복', '기쁘', '즐거']):
            base_valence = 0.8
        elif any(word in text_lower for word in ['나쁘', '슬프', '화나', '짜증']):
            base_valence = 0.2
            
        if any(word in text_lower for word in ['!', '?', '놀라', '신기']):
            base_arousal = 0.8
    
    # 이미지가 있으면 신뢰도 증가
    confidence = 0.5
    if image_data:
        confidence = 0.7
    if text_data:
        confidence = 0.8
    if image_data and text_data:
        confidence = 0.9
    
    # 감정 카테고리 결정
    emotion_category = 'neutral'
    if base_valence > 0.7:
        emotion_category = 'happy'
    elif base_valence < 0.3:
        emotion_category = 'sad'
    elif base_arousal > 0.7:
        emotion_category = 'excited'
    elif base_arousal < 0.3:
        emotion_category = 'calm'
    
    # 감정 아이콘 매핑
    emotion_icons = {
        'happy': '😊',
        'sad': '😢',
        'excited': '😃',
        'calm': '😌',
        'neutral': '😐'
    }
    
    result = {
        'analysis': {
            'timestamp': datetime.now().isoformat(),
            'sessionDuration': 30,
            'dataPoints': 1,
            'emotionCategory': emotion_category,
            'emotionIcon': emotion_icons.get(emotion_category, '😐'),
            'confidence': confidence
        },
        'vadStats': {
            'valence': base_valence,
            'arousal': base_arousal,
            'dominance': base_dominance,
            'valenceTrend': 'stable',
            'arousalTrend': 'stable',
            'dominanceTrend': 'stable'
        },
        'emotionPattern': {
            'stability': 'stable',
            'volatility': 'low',
            'trend': emotion_category,
            'keyMoments': []
        },
        'cbtFeedback': {
            'mainAdvice': '감정 관리 전략',
            'explanation': '현재 감정 상태를 바탕으로 한 맞춤형 조언입니다.',
            'techniques': ['감정 인식하기', '호흡 조절하기'],
            'dailyPractice': ['감정 일기 작성', '명상 연습'],
            'emergencyTips': ['깊은 호흡하기', '5-4-3-2-1 감각 인식하기', '긍정적 자기 대화하기']
        },
        'recommendations': [],
        'charts': {
            'vadChart': [{
                'timestamp': int(datetime.now().timestamp() * 1000),
                'valence': base_valence,
                'arousal': base_arousal,
                'dominance': base_dominance
            }]
        }
    }
    
    return result

if __name__ == '__main__':
    logger.info("멀티모달 감정 분석 서버 시작")
    app.run(host='0.0.0.0', port=5001, debug=True) 