import os
import json
import logging
import google.generativeai as genai
from typing import Dict, List, Optional

logger = logging.getLogger(__name__)

class GeminiService:
    def __init__(self):
        self.api_key = os.getenv('GEMINI_API_KEY')
        self.model = None
        self.conversation_history = []
        
        if self.api_key:
            try:
                genai.configure(api_key=self.api_key)
                self.model = genai.GenerativeModel('gemini-pro')
                logger.info("✅ Gemini 서비스 초기화 완료")
            except Exception as e:
                logger.error(f"❌ Gemini 서비스 초기화 실패: {e}")
        else:
            logger.warning("⚠️ GEMINI_API_KEY가 설정되지 않음")
    
    def get_response(self, user_message: str, conversation_history: Optional[List[Dict]] = None) -> Dict:
        """
        사용자 메시지에 대한 Gemini AI 응답 생성
        
        Args:
            user_message: 사용자 메시지
            conversation_history: 대화 히스토리 (선택사항)
            
        Returns:
            Dict: {'success': bool, 'response': str, 'error': str}
        """
        try:
            if not self.model:
                return {
                    'success': False,
                    'response': '',
                    'error': 'Gemini API 키가 설정되지 않았습니다.'
                }
            
            # 대화 히스토리 구성
            if conversation_history:
                self.conversation_history = conversation_history
            
            # 사용자 메시지 추가
            self.conversation_history.append({
                'role': 'user',
                'content': user_message
            })
            
            # Gemini API 호출
            response = self.model.generate_content(user_message)
            
            if response.text:
                # AI 응답을 히스토리에 추가
                ai_response = response.text.strip()
                self.conversation_history.append({
                    'role': 'model',
                    'content': ai_response
                })
                
                # 대화 히스토리가 너무 길어지면 오래된 메시지 제거
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
    
    def set_system_prompt(self, prompt: str) -> None:
        """시스템 프롬프트 설정"""
        self.conversation_history = [{
            'role': 'user',
            'content': prompt
        }]
        logger.info("🔧 시스템 프롬프트 설정됨")
    
    def clear_conversation(self) -> None:
        """대화 히스토리 초기화"""
        self.conversation_history = []
        logger.info("🗑️ 대화 히스토리 초기화됨")
    
    def get_conversation_history(self) -> List[Dict]:
        """대화 히스토리 반환"""
        return self.conversation_history.copy()
    
    def is_available(self) -> bool:
        """Gemini 서비스 사용 가능 여부"""
        return self.model is not None and self.api_key is not None 