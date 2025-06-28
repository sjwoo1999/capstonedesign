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

# 서비스 인스턴스 (지연 초기화)
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
                'pdf_service': 'available'
            }
        })
    except Exception as e:
        logger.error(f"❌ PDF 리포트 생성 오류: {str(e)}")
        return jsonify({"error": f"PDF report generation failed: {str(e)}"}), 500

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
                "error": result.get('error', '알 수 없는 오류')
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