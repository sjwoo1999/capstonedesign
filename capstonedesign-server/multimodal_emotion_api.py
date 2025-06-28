import os
import json
import logging
from datetime import datetime
from logging.handlers import RotatingFileHandler
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
from services.gemini_question_service import GeminiQuestionService

# 로그 디렉토리 생성
log_dir = "logs"
if not os.path.exists(log_dir):
    os.makedirs(log_dir)

# 로거 설정
logger = logging.getLogger(__name__)
logger.setLevel(logging.DEBUG)

# 콘솔 핸들러 (INFO 레벨)
console_handler = logging.StreamHandler()
console_handler.setLevel(logging.INFO)
console_formatter = logging.Formatter(
    '%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
console_handler.setFormatter(console_formatter)

# 파일 핸들러 (DEBUG 레벨)
file_handler = RotatingFileHandler(
    os.path.join(log_dir, 'server_enhanced.log'), 
    maxBytes=10*1024*1024,  # 10MB
    backupCount=5
)
file_handler.setLevel(logging.DEBUG)
file_formatter = logging.Formatter(
    '%(asctime)s - %(name)s - %(levelname)s - %(funcName)s:%(lineno)d - %(message)s'
)
file_handler.setFormatter(file_formatter)

# 핸들러 추가
logger.addHandler(console_handler)
logger.addHandler(file_handler)

# Flask 앱 로거 설정
app_logger = logging.getLogger('werkzeug')
app_logger.setLevel(logging.INFO)
app_logger.addHandler(console_handler)
app_logger.addHandler(file_handler)

app = Flask(__name__)
CORS(app)

# 서비스 인스턴스
face_service = None
audio_service = None
text_service = None
vad_fusion_service = None
cbt_strategy_service = None
gpt_service = None
pdf_service = None
gemini_service = None

def initialize_services():
    """서비스 인스턴스 초기화"""
    global face_service, audio_service, text_service, vad_fusion_service, cbt_strategy_service, gpt_service, pdf_service, gemini_service
    
    logger.info("🔧 서비스 초기화 시작...")
    
    if face_service is None:
        logger.info("📷 얼굴 감정 분석 서비스 초기화...")
        face_service = FaceEmotionService()
        logger.info("✅ 얼굴 감정 분석 서비스 초기화 완료")
    
    if audio_service is None:
        logger.info("🎵 음성 감정 분석 서비스 초기화...")
        audio_service = AudioEmotionService()
        logger.info("✅ 음성 감정 분석 서비스 초기화 완료")
    
    if text_service is None:
        logger.info("📝 텍스트 감정 분석 서비스 초기화...")
        text_service = TextEmotionService()
        logger.info("✅ 텍스트 감정 분석 서비스 초기화 완료")
    
    if vad_fusion_service is None:
        logger.info("🔄 VAD 융합 서비스 초기화...")
        vad_fusion_service = VADFusionService()
        logger.info("✅ VAD 융합 서비스 초기화 완료")
    
    if cbt_strategy_service is None:
        logger.info("🧠 CBT 전략 서비스 초기화...")
        cbt_strategy_service = CBTStrategyService()
        logger.info("✅ CBT 전략 서비스 초기화 완료")
    
    if gpt_service is None:
        logger.info("🤖 GPT 서비스 초기화...")
        gpt_service = GPTService()
        logger.info("✅ GPT 서비스 초기화 완료")
    
    if pdf_service is None:
        logger.info("📄 PDF 리포트 서비스 초기화...")
        pdf_service = PDFReportService()
        logger.info("✅ PDF 리포트 서비스 초기화 완료")
    
    if gemini_service is None:
        logger.info("🤖 Gemini AI 채팅 서비스 초기화...")
        gemini_service = GeminiQuestionService()
        logger.info("✅ Gemini AI 채팅 서비스 초기화 완료")
    
    logger.info("🎉 모든 서비스 초기화 완료!")
    logger.info(f"   - Gemini 서비스 사용 가능: {gemini_service.is_available() if gemini_service else False}")

@app.route('/health', methods=['GET'])
def health_check():
    """서버 상태 확인"""
    logger.info("🏥 서버 상태 확인 요청")
    try:
        initialize_services()
        logger.info("✅ 서버 상태 정상")
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
                'pdf_service': 'available',
                'gemini_service': 'available'
            }
        })
    except Exception as e:
        logger.error(f"❌ 서비스 초기화 오류: {e}")
        return jsonify({
            'status': 'error',
            'timestamp': datetime.now().isoformat(),
            'error': str(e)
        }), 500

@app.route('/whoami', methods=['GET'])
def whoami():
    """서버 탐색용 엔드포인트"""
    logger.info("🔍 서버 탐색 요청")
    return jsonify({
        'server': 'multimodal_emotion_api_enhanced',
        'version': '1.0.0',
        'status': 'running',
        'timestamp': datetime.now().isoformat()
    })

@app.route('/analyze_multimodal_emotion', methods=['POST'])
def analyze_multimodal_emotion():
    """멀티모달 감정 분석 메인 API"""
    logger.info("🚀 멀티모달 감정 분석 요청 시작")
    
    try:
        # 서비스 초기화 확인
        initialize_services()
        
        # 요청 데이터 파싱
        data = request.get_json()
        if not data:
            logger.error("❌ JSON 데이터가 제공되지 않음")
            return jsonify({'error': 'No JSON data provided'}), 400
        
        face_image = data.get('face_image', '')
        audio = data.get('audio', '')
        text = data.get('text', '')
        
        logger.info(f"📊 요청 데이터 분석 - 얼굴: {bool(face_image)}, 음성: {bool(audio)}, 텍스트: {bool(text)}")
        
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
            logger.info("📷 얼굴 감정 분석 시작...")
            face_result = face_service.analyze_emotion(face_image)
            if face_result.get('success'):
                logger.info(f"✅ 얼굴 감정 분석 완료: {face_result.get('emotion', 'N/A')}")
            else:
                logger.warning(f"⚠️ 얼굴 감정 분석 실패: {face_result.get('error', 'Unknown error')}")
            
            results['face_emotion'] = face_result.get('emotion', 'N/A') if face_result.get('success') else 'N/A'
            results['face_vad'] = face_result.get('vad_score', {}) if face_result.get('success') else {}
        else:
            logger.info("⏭️ 얼굴 이미지 없음, 얼굴 분석 건너뜀")
        
        # 2. 음성 감정 분석
        audio_result = None
        if audio:
            logger.info("🎵 음성 감정 분석 시작...")
            audio_result = audio_service.analyze_audio_emotion(audio)
            if audio_result.get('success'):
                logger.info(f"✅ 음성 감정 분석 완료: {audio_result.get('transcript', '')[:30]}...")
            else:
                logger.warning(f"⚠️ 음성 감정 분석 실패: {audio_result.get('error', 'Unknown error')}")
            
            results['transcript'] = audio_result.get('transcript', '') if audio_result.get('success') else ''
            results['prosody'] = audio_result.get('prosody_features', {}) if audio_result.get('success') else {}
            results['audio_vad'] = audio_result.get('vad_score', {}) if audio_result.get('success') else {}
        else:
            logger.info("⏭️ 음성 데이터 없음, 음성 분석 건너뜀")
        
        # 3. 텍스트 감정 분석 (음성 전사 또는 직접 입력)
        text_result = None
        text_to_analyze = text
        if not text_to_analyze and audio_result and audio_result.get('success'):
            text_to_analyze = audio_result.get('transcript', '')
        
        if text_to_analyze:
            logger.info("📝 텍스트 감정 분석 시작...")
            text_result = text_service.analyze_text_emotion(text_to_analyze)
            if text_result.get('success'):
                logger.info(f"✅ 텍스트 감정 분석 완료: {text_result.get('dominant_emotion', 'N/A')}")
            else:
                logger.warning(f"⚠️ 텍스트 감정 분석 실패: {text_result.get('error', 'Unknown error')}")
            
            results['text_emotion'] = text_result.get('dominant_emotion', 'N/A') if text_result.get('success') else 'N/A'
            results['text_vad'] = text_result.get('vad_score', {}) if text_result.get('success') else {}
        else:
            logger.info("⏭️ 텍스트 데이터 없음, 텍스트 분석 건너뜀")
        
        # 4. VAD Score 융합
        logger.info("🔄 VAD Score 융합 시작...")
        fusion_result = vad_fusion_service.fuse_vad_scores(
            face_vad=face_result.get('vad_score') if face_result and face_result.get('success') else None,
            audio_vad=audio_result.get('vad_score') if audio_result and audio_result.get('success') else None,
            text_vad=text_result.get('vad_score') if text_result and text_result.get('success') else None,
            face_confidence=face_result.get('confidence', 0.5) if face_result and face_result.get('success') else 0.5,
            audio_confidence=0.7 if audio_result and audio_result.get('success') else 0.5,
            text_confidence=text_result.get('emotion_intensity', 0.5) if text_result and text_result.get('success') else 0.5
        )
        
        if fusion_result.get('success'):
            logger.info(f"✅ VAD 융합 완료: {fusion_result.get('emotion_tag', 'N/A')}")
        else:
            logger.warning(f"⚠️ VAD 융합 실패: {fusion_result.get('error', 'Unknown error')}")
        
        results['final_vad'] = fusion_result.get('final_vad', {})
        results['emotion_tag'] = fusion_result.get('emotion_tag', 'neutral')
        
        # 5. CBT 전략 매핑
        logger.info("🧠 CBT 전략 매핑 시작...")
        cbt_strategy_result = cbt_strategy_service.map_emotion_to_strategy(
            results['emotion_tag'], 
            results['final_vad']
        )
        
        if cbt_strategy_result.get('success'):
            logger.info(f"✅ CBT 전략 매핑 완료: {cbt_strategy_result.get('strategy', {}).get('name', 'N/A')}")
        else:
            logger.warning(f"⚠️ CBT 전략 매핑 실패: {cbt_strategy_result.get('error', 'Unknown error')}")
        
        results['cbt_strategy'] = cbt_strategy_result.get('strategy', {}) if cbt_strategy_result.get('success') else {}
        
        # 6. GPT 응답 생성
        logger.info("🤖 GPT 응답 생성 시작...")
        gpt_result = gpt_service.generate_summary_response(
            face_result,
            audio_result,
            text_result,
            fusion_result,
            cbt_strategy_result
        )
        
        if gpt_result.get('success'):
            logger.info("✅ GPT 응답 생성 완료")
        else:
            logger.warning(f"⚠️ GPT 응답 생성 실패: {gpt_result.get('error', 'Unknown error')}")
        
        results['gpt_response'] = gpt_result.get('response', '') if gpt_result.get('success') else ''
        
        # 7. PDF 리포트 생성
        logger.info("📄 PDF 리포트 생성 시작...")
        
        # None 값들을 빈 딕셔너리로 변환
        safe_face_result = face_result if face_result is not None else {}
        safe_audio_result = audio_result if audio_result is not None else {}
        safe_text_result = text_result if text_result is not None else {}
        safe_fusion_result = fusion_result if fusion_result is not None else {}
        safe_cbt_strategy_result = cbt_strategy_result if cbt_strategy_result is not None else {}
        safe_gpt_result = gpt_result if gpt_result is not None else {}
        
        pdf_result = pdf_service.create_emotion_report(
            safe_face_result,
            safe_audio_result,
            safe_text_result,
            safe_fusion_result,
            safe_cbt_strategy_result,
            safe_gpt_result
        )
        
        if pdf_result.get('success'):
            logger.info("✅ PDF 리포트 생성 완료")
        else:
            logger.warning(f"⚠️ PDF 리포트 생성 실패: {pdf_result.get('error', 'Unknown error')}")
        
        results['pdf_report'] = pdf_result.get('pdf_base64', '') if pdf_result.get('success') else ''
        
        # 성공 응답
        logger.info("🎉 멀티모달 감정 분석 완료!")
        return jsonify(results)
        
    except Exception as e:
        logger.error(f"❌ 멀티모달 감정 분석 오류: {str(e)}")
        return jsonify({
            'error': f'Analysis failed: {str(e)}',
            'timestamp': datetime.now().isoformat()
        }), 500

@app.route('/analyze_face_emotion', methods=['POST'])
def analyze_face_emotion():
    """얼굴 감정 분석 API"""
    logger.info("📷 얼굴 감정 분석 요청")
    try:
        data = request.get_json()
        face_image = data.get('face_image', '')
        
        if not face_image:
            logger.error("❌ 얼굴 이미지가 제공되지 않음")
            return jsonify({'error': 'No face image provided'}), 400
        
        result = face_service.analyze_emotion(face_image)
        logger.info(f"✅ 얼굴 감정 분석 완료: {result.get('emotion', 'N/A')}")
        return jsonify(result)
        
    except Exception as e:
        logger.error(f"❌ 얼굴 감정 분석 오류: {str(e)}")
        return jsonify({'error': f'Face analysis failed: {str(e)}'}), 500

@app.route('/analyze_audio_emotion', methods=['POST'])
def analyze_audio_emotion():
    """음성 감정 분석 API"""
    logger.info("🎵 음성 감정 분석 요청")
    try:
        data = request.get_json()
        audio = data.get('audio', '')
        
        if not audio:
            logger.error("❌ 음성 데이터가 제공되지 않음")
            return jsonify({'error': 'No audio provided'}), 400
        
        result = audio_service.analyze_audio_emotion(audio)
        if result.get('success'):
            logger.info(f"✅ 음성 감정 분석 완료: {result.get('transcript', '')[:30]}...")
        else:
            logger.warning(f"⚠️ 음성 감정 분석 실패: {result.get('error', 'Unknown error')}")
        return jsonify(result)
        
    except Exception as e:
        logger.error(f"❌ 음성 감정 분석 오류: {str(e)}")
        return jsonify({'error': f'Audio analysis failed: {str(e)}'}), 500

@app.route('/analyze_text_emotion', methods=['POST'])
def analyze_text_emotion():
    """텍스트 감정 분석 API"""
    logger.info("📝 텍스트 감정 분석 요청")
    try:
        data = request.get_json()
        text = data.get('text', '')
        
        if not text:
            logger.error("❌ 텍스트가 제공되지 않음")
            return jsonify({'error': 'No text provided'}), 400
        
        result = text_service.analyze_text_emotion(text)
        if result.get('success'):
            logger.info(f"✅ 텍스트 감정 분석 완료: {result.get('dominant_emotion', 'N/A')}")
        else:
            logger.warning(f"⚠️ 텍스트 감정 분석 실패: {result.get('error', 'Unknown error')}")
        return jsonify(result)
        
    except Exception as e:
        logger.error(f"❌ 텍스트 감정 분석 오류: {str(e)}")
        return jsonify({'error': f'Text analysis failed: {str(e)}'}), 500

@app.route('/fuse_vad_scores', methods=['POST'])
def fuse_vad_scores():
    """VAD Score 융합 API"""
    logger.info("🔄 VAD Score 융합 요청")
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
        
        if result.get('success'):
            logger.info(f"✅ VAD 융합 완료: {result.get('emotion_tag', 'N/A')}")
        else:
            logger.warning(f"⚠️ VAD 융합 실패: {result.get('error', 'Unknown error')}")
        
        return jsonify(result)
        
    except Exception as e:
        logger.error(f"❌ VAD 융합 오류: {str(e)}")
        return jsonify({'error': f'VAD fusion failed: {str(e)}'}), 500

@app.route('/get_cbt_strategy', methods=['POST'])
def get_cbt_strategy():
    """CBT 전략 매핑 API"""
    logger.info("🧠 CBT 전략 매핑 요청")
    try:
        data = request.get_json()
        emotion_tag = data.get('emotion_tag', 'neutral')
        vad_score = data.get('vad_score', {})
        
        result = cbt_strategy_service.map_emotion_to_strategy(emotion_tag, vad_score)
        
        if result.get('success'):
            logger.info(f"✅ CBT 전략 매핑 완료: {result.get('strategy', {}).get('name', 'N/A')}")
        else:
            logger.warning(f"⚠️ CBT 전략 매핑 실패: {result.get('error', 'Unknown error')}")
        
        return jsonify(result)
        
    except Exception as e:
        logger.error(f"❌ CBT 전략 매핑 오류: {str(e)}")
        return jsonify({'error': f'CBT strategy mapping failed: {str(e)}'}), 500

@app.route('/generate_gpt_response', methods=['POST'])
def generate_gpt_response():
    """GPT 응답 생성 API"""
    logger.info("🤖 GPT 응답 생성 요청")
    try:
        data = request.get_json()
        emotion_tag = data.get('emotion_tag', 'neutral')
        vad_score = data.get('vad_score', {})
        context = data.get('context', '')
        cbt_strategy = data.get('cbt_strategy')
        
        result = gpt_service.generate_response(emotion_tag, vad_score, context, cbt_strategy)
        
        if result.get('success'):
            logger.info("✅ GPT 응답 생성 완료")
        else:
            logger.warning(f"⚠️ GPT 응답 생성 실패: {result.get('error', 'Unknown error')}")
        
        return jsonify(result)
        
    except Exception as e:
        logger.error(f"❌ GPT 응답 생성 오류: {str(e)}")
        return jsonify({'error': f'GPT response generation failed: {str(e)}'}), 500

@app.route('/generate_pdf_report', methods=['POST'])
def generate_pdf_report():
    """PDF 리포트 생성 API"""
    logger.info("📄 PDF 리포트 생성 요청")
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
        
        if result.get('success'):
            logger.info("✅ PDF 리포트 생성 완료")
        else:
            logger.warning(f"⚠️ PDF 리포트 생성 실패: {result.get('error', 'Unknown error')}")
        
        return jsonify(result)
        
    except Exception as e:
        logger.error(f"❌ PDF 리포트 생성 오류: {str(e)}")
        return jsonify({'error': f'PDF report generation failed: {str(e)}'}), 500

@app.route("/chat/gemini", methods=["POST"])
def chat_with_gemini():
    """Gemini AI와의 채팅 API"""
    logger.info("💬 Gemini 채팅 요청")
    try:
        data = request.get_json()
        user_message = data.get("message", "")
        conversation_history = data.get("conversation_history", [])
        
        if not user_message:
            return jsonify({"error": "메시지가 필요합니다"}), 400
        
        initialize_services()
        
        if not gemini_service:
            return jsonify({"error": "Gemini 서비스가 초기화되지 않았습니다"}), 500
        
        result = gemini_service.get_response(user_message, conversation_history)
        
        if result.get("success"):
            logger.info("✅ Gemini 채팅 응답 생성 완료")
            return jsonify({
                "success": True,
                "response": result["response"],
                "conversation_history": gemini_service.get_conversation_history()
            })
        else:
            logger.warning(f"⚠️ Gemini 채팅 응답 생성 실패: {result.get('error', 'Unknown error')}")
            return jsonify({
                "success": False,
                "error": result.get("error", "알 수 없는 오류")
            }), 500
        
    except Exception as e:
        logger.error(f"❌ Gemini 채팅 오류: {str(e)}")
        return jsonify({"error": f"Gemini chat failed: {str(e)}"}), 500

@app.route("/chat/gemini/clear", methods=["POST"])
def clear_gemini_conversation():
    """Gemini 대화 히스토리 초기화"""
    logger.info("🗑️ Gemini 대화 히스토리 초기화 요청")
    try:
        initialize_services()
        
        if gemini_service:
            gemini_service.clear_conversation()
            logger.info("✅ Gemini 대화 히스토리 초기화 완료")
            return jsonify({"success": True, "message": "대화 히스토리가 초기화되었습니다"})
        else:
            return jsonify({"error": "Gemini 서비스가 초기화되지 않았습니다"}), 500
        
    except Exception as e:
        logger.error(f"❌ Gemini 대화 초기화 오류: {str(e)}")
        return jsonify({"error": f"Clear conversation failed: {str(e)}"}), 500

@app.route("/chat/gemini/status", methods=["GET"])
def get_gemini_status():
    """Gemini 서비스 상태 확인"""
    logger.info("🔍 Gemini 서비스 상태 확인")
    try:
        initialize_services()
        
        is_available = gemini_service.is_available() if gemini_service else False
        
        return jsonify({
            "available": is_available,
            "api_key_configured": bool(gemini_service.api_key if gemini_service else None)
        })
        
    except Exception as e:
        logger.error(f"❌ Gemini 상태 확인 오류: {str(e)}")
        return jsonify({"error": f"Status check failed: {str(e)}"}), 500

@app.route('/test_mock', methods=['GET'])
def test_mock():
    """모킹 데이터 테스트 API"""
    logger.info("🧪 모킹 데이터 테스트 요청")
    try:
        # 각 서비스의 모킹 결과 반환
        result = {
            'face_service': face_service.get_mock_result(),
            'audio_service': audio_service.get_mock_result(),
            'text_service': text_service.get_mock_result(),
            'vad_fusion_service': vad_fusion_service.get_mock_result(),
            'cbt_strategy_service': cbt_strategy_service.get_mock_result(),
            'gpt_service': gpt_service.get_mock_result(),
            'pdf_service': pdf_service.get_mock_result(),
            'gemini_service': gemini_service.get_mock_result()
        }
        logger.info("✅ 모킹 데이터 테스트 완료")
        return jsonify(result)
        
    except Exception as e:
        logger.error(f"❌ 모킹 데이터 테스트 오류: {str(e)}")
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
    logger.info("   - POST /chat/gemini: Gemini AI 채팅")
    logger.info("   - POST /chat/gemini/clear: 대화 히스토리 초기화")
    logger.info("   - GET /chat/gemini/status: Gemini 서비스 상태")
    
    initialize_services()
    app.run(host='0.0.0.0', port=5001, debug=True) 