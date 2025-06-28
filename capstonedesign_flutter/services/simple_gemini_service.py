import os
import logging

class SimpleGeminiService:
    def __init__(self):
        self.api_key = os.getenv('GEMINI_API_KEY')
        self.conversation_history = []
        
        if self.api_key:
            try:
                import google.generativeai as genai
                genai.configure(api_key=self.api_key)
                self.model = genai.GenerativeModel('gemini-1.5-pro')
                logging.info("✅ Gemini 서비스 초기화 완료")
            except Exception as e:
                logging.error(f"❌ Gemini 서비스 초기화 실패: {e}")
                self.model = None
        else:
            logging.warning("⚠️ GEMINI_API_KEY가 설정되지 않음")
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
            logging.error(f"❌ Gemini 응답 생성 실패: {e}")
            return {
                'success': False,
                'response': '',
                'error': f'Gemini API 오류: {str(e)}'
            }

    def clear_conversation(self):
        self.conversation_history = []
        logging.info("🗑️ 대화 히스토리 초기화됨")

    def get_conversation_history(self):
        return self.conversation_history.copy()

    def is_available(self):
        return self.model is not None and self.api_key is not None 