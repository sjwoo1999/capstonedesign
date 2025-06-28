import os
import json
import logging
from flask import Flask, request, jsonify
from flask_cors import CORS

# 간단한 로깅 설정
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = Flask(__name__)
CORS(app)

# Gemini 서비스 (간단한 버전)
class SimpleGeminiService:
    def __init__(self):
        self.api_key = os.getenv('GEMINI_API_KEY')
        self.conversation_history = []
        
        if self.api_key:
            try:
                import google.generativeai as genai
                genai.configure(api_key=self.api_key)
                self.model = genai.GenerativeModel('gemini-1.5-pro')
                logger.info("✅ Gemini 서비스 초기화 완료")
            except Exception as e:
                logger.error(f"❌ Gemini 서비스 초기화 실패: {e}")
                self.model = None
        else:
            logger.warning("⚠️ GEMINI_API_KEY가 설정되지 않음")
            self.model = None
    
    def get_response(self, user_message: str, conversation_history=None):
        try:
            if not self.model:
                return {
                    'success': False,
                    'response': '',
                    'error': 'Gemini API 키가 설정되지 않았습니다.'
                }
            
            if conversation_history:
                self.conversation_history = conversation_history
            
            self.conversation_history.append({
                'role': 'user',
                'content': user_message
            })
            
            response = self.model.generate_content(user_message)
            
            if response.text:
                ai_response = response.text.strip()
                self.conversation_history.append({
                    'role': 'model',
                    'content': ai_response
                })
                
                if len(self.conversation_history) > 10:
                    self.conversation_history = self.conversation_history[-8:]
                
                return {
                    'success': True,
                    'response': ai_response,
                    'error': ''
                }
            else:
                return {
                    'success': False,
                    'response': '',
                    'error': 'Gemini AI가 응답을 생성하지 못했습니다.'
                }
                
        except Exception as e:
            logger.error(f"❌ Gemini 응답 생성 실패: {e}")
            return {
                'success': False,
                'response': '',
                'error': f'Gemini API 오류: {str(e)}'
            }
    
    def clear_conversation(self):
        self.conversation_history = []
        logger.info("🗑️ 대화 히스토리 초기화됨")
    
    def get_conversation_history(self):
        return self.conversation_history.copy()
    
    def is_available(self):
        return self.model is not None and self.api_key is not None

# 서비스 인스턴스
gemini_service = SimpleGeminiService()

@app.route('/health', methods=['GET'])
def health_check():
    """서버 상태 확인"""
    logger.info("🏥 서버 상태 확인 요청")
    return jsonify({
        'status': 'healthy',
        'services': {
            'gemini_service': 'available' if gemini_service.is_available() else 'unavailable'
        }
    })

@app.route('/chat/gemini', methods=['POST'])
def chat_with_gemini():
    """Gemini AI와의 채팅 API"""
    logger.info("💬 Gemini 채팅 요청")
    try:
        data = request.get_json()
        user_message = data.get("message", "")
        conversation_history = data.get("conversation_history", [])
        
        if not user_message:
            return jsonify({"error": "메시지가 필요합니다"}), 400
        
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

@app.route('/chat/gemini/clear', methods=['POST'])
def clear_gemini_conversation():
    """Gemini 대화 히스토리 초기화"""
    logger.info("🗑️ Gemini 대화 히스토리 초기화 요청")
    try:
        gemini_service.clear_conversation()
        logger.info("✅ Gemini 대화 히스토리 초기화 완료")
        return jsonify({"success": True, "message": "대화 히스토리가 초기화되었습니다"})
        
    except Exception as e:
        logger.error(f"❌ Gemini 대화 초기화 오류: {str(e)}")
        return jsonify({"error": f"Clear conversation failed: {str(e)}"}), 500

@app.route('/chat/gemini/status', methods=['GET'])
def get_gemini_status():
    """Gemini 서비스 상태 확인"""
    logger.info("🔍 Gemini 서비스 상태 확인")
    try:
        is_available = gemini_service.is_available()
        
        return jsonify({
            "available": is_available,
            "api_key_configured": bool(gemini_service.api_key)
        })
        
    except Exception as e:
        logger.error(f"❌ Gemini 상태 확인 오류: {str(e)}")
        return jsonify({"error": f"Status check failed: {str(e)}"}), 500

if __name__ == '__main__':
    logger.info("🚀 Gemini 테스트 서버 시작...")
    logger.info("📝 API 엔드포인트:")
    logger.info("   - GET /health: 서버 상태 확인")
    logger.info("   - POST /chat/gemini: Gemini AI 채팅")
    logger.info("   - POST /chat/gemini/clear: 대화 히스토리 초기화")
    logger.info("   - GET /chat/gemini/status: Gemini 서비스 상태")
    logger.info(f"   - Gemini 서비스 사용 가능: {gemini_service.is_available()}")
    
    app.run(host='0.0.0.0', port=5001, debug=True) 