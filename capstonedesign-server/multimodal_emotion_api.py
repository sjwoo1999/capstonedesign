import os
import json
import logging
from datetime import datetime
from flask import Flask, request, jsonify
from flask_cors import CORS

# 서비스 임포트
from services.face_emotion_service import FaceEmotionService
from services.audio_emotion_service import AudioEmotionService
from services.text_emotion_service import TextEmotionService
from services.vad_fusion_service import VADFusionService
from services.cbt_strategy_service import CBTStrategyService
from services.gpt_service import GPTService
from services.pdf_report_service import PDFReportService

# 로깅 설정
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = Flask(__name__)
CORS(app)

# 서비스 인스턴스 (지연 초기화)
face_service = None
audio_service = None
text_service = None
vad_fusion_service = None
cbt_strategy_service = None
gpt_service = None
pdf_service = None

def initialize_services():
    """서비스 인스턴스 초기화"""
    global face_service, audio_service, text_service, vad_fusion_service, cbt_strategy_service, gpt_service, pdf_service
    
    if face_service is None:
        face_service = FaceEmotionService()
    if audio_service is None:
        audio_service = AudioEmotionService()
    if text_service is None:
        text_service = TextEmotionService()
    if vad_fusion_service is None:
        vad_fusion_service = VADFusionService()
    if cbt_strategy_service is None:
        cbt_strategy_service = CBTStrategyService()
    if gpt_service is None:
        gpt_service = GPTService()
    if pdf_service is None:
        pdf_service = PDFReportService()

@app.route('/health', methods=['GET'])
def health_check():
    """서버 상태 확인"""
    try:
        initialize_services()
        return jsonify({
            'status': 'healthy',
            'timestamp': datetime.now().isoformat(),
            'services': {
                'face_emotion': 'available',
                'audio_emotion': 'available',
                'text_emotion': 'available',
                'vad_fusion': 'available',
                'cbt_strategy': 'available',
                'gpt_service': 'available',
                'pdf_service': 'available'
            }
        })
    except Exception as e:
        logger.error(f"Service initialization error: {e}")
        return jsonify({
            'status': 'error',
            'timestamp': datetime.now().isoformat(),
            'error': str(e)
        }), 500

@app.route('/analyze_multimodal_emotion', methods=['POST'])
def analyze_multimodal_emotion():
    """멀티모달 감정 분석 메인 API"""
    try:
        # 서비스 초기화 확인
        initialize_services()
        
        # 요청 데이터 파싱
        data = request.get_json()
        if not data:
            return jsonify({'error': 'No JSON data provided'}), 400
        
        face_image = data.get('face_image', '')
        audio = data.get('audio', '')
        text = data.get('text', '')
        
        logger.info(f"Received request - Face: {bool(face_image)}, Audio: {bool(audio)}, Text: {bool(text)}")
        
        # 결과 저장용 딕셔너리
        results = {
            'timestamp': datetime.now().isoformat(),
            'request_data': {
                'has_face': bool(face_image),
                'has_audio': bool(audio),
                'has_text': bool(text)
            }
        }
        
        # 1. 얼굴 감정 분석
        face_result = None
        if face_image:
            logger.info("Starting face emotion analysis...")
            face_result = face_service.analyze_emotion(face_image)
            results['face_emotion'] = face_result.get('emotion', 'N/A') if face_result.get('success') else 'N/A'
            results['face_vad'] = face_result.get('vad_score', {}) if face_result.get('success') else {}
        else:
            logger.info("No face image provided, skipping face analysis")
        
        # 2. 음성 감정 분석
        audio_result = None
        if audio:
            logger.info("Starting audio emotion analysis...")
            audio_result = audio_service.analyze_audio_emotion(audio)
            results['transcript'] = audio_result.get('transcript', '') if audio_result.get('success') else ''
            results['prosody'] = audio_result.get('prosody_features', {}) if audio_result.get('success') else {}
            results['audio_vad'] = audio_result.get('vad_score', {}) if audio_result.get('success') else {}
        else:
            logger.info("No audio provided, skipping audio analysis")
        
        # 3. 텍스트 감정 분석 (음성 전사 또는 직접 입력)
        text_result = None
        text_to_analyze = text
        if not text_to_analyze and audio_result and audio_result.get('success'):
            text_to_analyze = audio_result.get('transcript', '')
        
        if text_to_analyze:
            logger.info("Starting text emotion analysis...")
            text_result = text_service.analyze_text_emotion(text_to_analyze)
            results['text_emotion'] = text_result.get('dominant_emotion', 'N/A') if text_result.get('success') else 'N/A'
            results['text_vad'] = text_result.get('vad_score', {}) if text_result.get('success') else {}
        else:
            logger.info("No text provided, skipping text analysis")
        
        # 4. VAD Score 융합
        logger.info("Starting VAD fusion...")
        fusion_result = vad_fusion_service.fuse_vad_scores(
            face_vad=face_result.get('vad_score') if face_result and face_result.get('success') else None,
            audio_vad=audio_result.get('vad_score') if audio_result and audio_result.get('success') else None,
            text_vad=text_result.get('vad_score') if text_result and text_result.get('success') else None,
            face_confidence=face_result.get('confidence', 0.5) if face_result and face_result.get('success') else 0.5,
            audio_confidence=0.7 if audio_result and audio_result.get('success') else 0.5,
            text_confidence=text_result.get('emotion_intensity', 0.5) if text_result and text_result.get('success') else 0.5
        )
        
        results['final_vad'] = fusion_result.get('final_vad', {})
        results['emotion_tag'] = fusion_result.get('emotion_tag', 'neutral')
        
        # 5. CBT 전략 매핑
        logger.info("Starting CBT strategy mapping...")
        cbt_strategy_result = cbt_strategy_service.map_emotion_to_strategy(
            results['emotion_tag'], 
            results['final_vad']
        )
        results['cbt_strategy'] = cbt_strategy_result.get('strategy', {}) if cbt_strategy_result.get('success') else {}
        
        # 6. GPT 응답 생성
        logger.info("Starting GPT response generation...")
        gpt_result = gpt_service.generate_summary_response(
            face_result or face_service.get_mock_result(),
            audio_result or audio_service.get_mock_result(),
            text_result or text_service.get_mock_result(),
            fusion_result,
            cbt_strategy_result
        )
        results['gpt_response'] = gpt_result.get('response', '') if gpt_result.get('success') else ''
        
        # 7. PDF 리포트 생성
        logger.info("Starting PDF report generation...")
        pdf_result = pdf_service.create_emotion_report(
            face_result or face_service.get_mock_result(),
            audio_result or audio_service.get_mock_result(),
            text_result or text_service.get_mock_result(),
            fusion_result,
            cbt_strategy_result,
            gpt_result
        )
        results['pdf_report'] = pdf_result.get('pdf_base64', '') if pdf_result.get('success') else ''
        
        # 성공 응답
        logger.info("Multimodal emotion analysis completed successfully")
        return jsonify(results)
        
    except Exception as e:
        logger.error(f"Error in multimodal emotion analysis: {str(e)}")
        return jsonify({
            'error': f'Analysis failed: {str(e)}',
            'timestamp': datetime.now().isoformat()
        }), 500

@app.route('/analyze_face_emotion', methods=['POST'])
def analyze_face_emotion():
    """얼굴 감정 분석 API"""
    try:
        data = request.get_json()
        face_image = data.get('face_image', '')
        
        if not face_image:
            return jsonify({'error': 'No face image provided'}), 400
        
        result = face_service.analyze_emotion(face_image)
        return jsonify(result)
        
    except Exception as e:
        logger.error(f"Error in face emotion analysis: {str(e)}")
        return jsonify({'error': f'Face analysis failed: {str(e)}'}), 500

@app.route('/analyze_audio_emotion', methods=['POST'])
def analyze_audio_emotion():
    """음성 감정 분석 API"""
    try:
        data = request.get_json()
        audio = data.get('audio', '')
        
        if not audio:
            return jsonify({'error': 'No audio provided'}), 400
        
        result = audio_service.analyze_audio_emotion(audio)
        return jsonify(result)
        
    except Exception as e:
        logger.error(f"Error in audio emotion analysis: {str(e)}")
        return jsonify({'error': f'Audio analysis failed: {str(e)}'}), 500

@app.route('/analyze_text_emotion', methods=['POST'])
def analyze_text_emotion():
    """텍스트 감정 분석 API"""
    try:
        data = request.get_json()
        text = data.get('text', '')
        
        if not text:
            return jsonify({'error': 'No text provided'}), 400
        
        result = text_service.analyze_text_emotion(text)
        return jsonify(result)
        
    except Exception as e:
        logger.error(f"Error in text emotion analysis: {str(e)}")
        return jsonify({'error': f'Text analysis failed: {str(e)}'}), 500

@app.route('/fuse_vad_scores', methods=['POST'])
def fuse_vad_scores():
    """VAD Score 융합 API"""
    try:
        data = request.get_json()
        
        result = vad_fusion_service.fuse_vad_scores(
            face_vad=data.get('face_vad'),
            audio_vad=data.get('audio_vad'),
            text_vad=data.get('text_vad'),
            face_confidence=data.get('face_confidence', 0.5),
            audio_confidence=data.get('audio_confidence', 0.5),
            text_confidence=data.get('text_confidence', 0.5)
        )
        return jsonify(result)
        
    except Exception as e:
        logger.error(f"Error in VAD fusion: {str(e)}")
        return jsonify({'error': f'VAD fusion failed: {str(e)}'}), 500

@app.route('/get_cbt_strategy', methods=['POST'])
def get_cbt_strategy():
    """CBT 전략 매핑 API"""
    try:
        data = request.get_json()
        emotion_tag = data.get('emotion_tag', 'neutral')
        vad_score = data.get('vad_score', {})
        
        result = cbt_strategy_service.map_emotion_to_strategy(emotion_tag, vad_score)
        return jsonify(result)
        
    except Exception as e:
        logger.error(f"Error in CBT strategy mapping: {str(e)}")
        return jsonify({'error': f'CBT strategy mapping failed: {str(e)}'}), 500

@app.route('/generate_gpt_response', methods=['POST'])
def generate_gpt_response():
    """GPT 응답 생성 API"""
    try:
        data = request.get_json()
        emotion_tag = data.get('emotion_tag', 'neutral')
        vad_score = data.get('vad_score', {})
        context = data.get('context', '')
        cbt_strategy = data.get('cbt_strategy')
        
        result = gpt_service.generate_response(emotion_tag, vad_score, context, cbt_strategy)
        return jsonify(result)
        
    except Exception as e:
        logger.error(f"Error in GPT response generation: {str(e)}")
        return jsonify({'error': f'GPT response generation failed: {str(e)}'}), 500

@app.route('/generate_pdf_report', methods=['POST'])
def generate_pdf_report():
    """PDF 리포트 생성 API"""
    try:
        data = request.get_json()
        
        result = pdf_service.create_emotion_report(
            face_result=data.get('face_result', {}),
            audio_result=data.get('audio_result', {}),
            text_result=data.get('text_result', {}),
            fusion_result=data.get('fusion_result', {}),
            cbt_strategy=data.get('cbt_strategy', {}),
            gpt_response=data.get('gpt_response', {})
        )
        return jsonify(result)
        
    except Exception as e:
        logger.error(f"Error in PDF report generation: {str(e)}")
        return jsonify({'error': f'PDF report generation failed: {str(e)}'}), 500

@app.route('/test_mock', methods=['GET'])
def test_mock():
    """모킹 데이터 테스트 API"""
    try:
        # 각 서비스의 모킹 결과 반환
        return jsonify({
            'face_service': face_service.get_mock_result(),
            'audio_service': audio_service.get_mock_result(),
            'text_service': text_service.get_mock_result(),
            'vad_fusion_service': vad_fusion_service.get_mock_result(),
            'cbt_strategy_service': cbt_strategy_service.get_mock_result(),
            'gpt_service': gpt_service.get_mock_result(),
            'pdf_service': pdf_service.get_mock_result()
        })
        
    except Exception as e:
        logger.error(f"Error in mock test: {str(e)}")
        return jsonify({'error': f'Mock test failed: {str(e)}'}), 500

if __name__ == '__main__':
    logger.info("🚀 멀티모달 감정 분석 API 서버 시작...")
    logger.info("📝 API 엔드포인트:")
    logger.info("   - POST /analyze_multimodal_emotion: 메인 멀티모달 분석")
    logger.info("   - POST /analyze_face_emotion: 얼굴 감정 분석")
    logger.info("   - POST /analyze_audio_emotion: 음성 감정 분석")
    logger.info("   - POST /analyze_text_emotion: 텍스트 감정 분석")
    logger.info("   - GET /health: 서버 상태 확인")
    logger.info("   - GET /test_mock: 모킹 데이터 테스트")
    
    initialize_services()
    app.run(host='0.0.0.0', port=5001, debug=True) 