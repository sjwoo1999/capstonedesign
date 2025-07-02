import os
import json
import google.generativeai as genai
from typing import Dict, List, Optional

class GeminiQuestionService:
    def __init__(self, api_key: Optional[str] = None):
        """Gemini 질문 생성 서비스 초기화"""
        self.api_key = api_key or os.getenv('GEMINI_API_KEY')
        if self.api_key:
            genai.configure(api_key=self.api_key)
            self.model = genai.GenerativeModel('gemini-2.5-flash')
        else:
            self.model = None
        
        # 질문 생성 프롬프트 템플릿
        self.question_prompts = {
            'angry': {
                'system': "당신은 분노 관리 전문가입니다. 사용자의 분노 상황을 이해하고, 분노의 원인을 파악하고 건강한 대처 방법을 찾을 수 있도록 도움을 주는 질문을 생성하세요.",
                'context_template': "현재 분노한 상태입니다. VAD 점수: Valence={valence}, Arousal={arousal}, Dominance={dominance}."
            },
            'sad': {
                'system': "당신은 우울감 완화 전문가입니다. 사용자의 슬픔을 인정하고 위로하면서, 슬픔의 원인을 이해하고 긍정적 변화를 촉진하는 질문을 생성하세요.",
                'context_template': "현재 슬픈 상태입니다. VAD 점수: Valence={valence}, Arousal={arousal}, Dominance={dominance}."
            },
            'anxious': {
                'system': "당신은 불안 완화 전문가입니다. 사용자의 불안을 이해하고 안정감을 제공하며, 불안의 원인을 파악하고 대처 방법을 찾을 수 있도록 도움을 주는 질문을 생성하세요.",
                'context_template': "현재 불안한 상태입니다. VAD 점수: Valence={valence}, Arousal={arousal}, Dominance={dominance}."
            },
            'happy': {
                'system': "당신은 긍정심리학 전문가입니다. 사용자의 긍정적 감정을 지속하고 확장하며, 기쁨의 원인을 이해하고 더 많은 긍정적 경험을 만들 수 있도록 도움을 주는 질문을 생성하세요.",
                'context_template': "현재 기분이 좋은 상태입니다. VAD 점수: Valence={valence}, Arousal={arousal}, Dominance={dominance}."
            },
            'neutral': {
                'system': "당신은 감정 인식 전문가입니다. 사용자가 자신의 감정을 더 잘 이해하고 표현할 수 있도록 도움을 주며, 현재 상황과 감정 상태를 탐색하는 질문을 생성하세요.",
                'context_template': "현재 중립적인 감정 상태입니다. VAD 점수: Valence={valence}, Arousal={arousal}, Dominance={dominance}."
            }
        }
        
        # 기본 프롬프트
        self.default_prompt = {
            'system': "당신은 감정 관리 전문가입니다. 사용자의 감정 상태를 분석하고, 감정의 원인을 파악하고 건강한 감정 관리를 도울 수 있는 질문을 생성하세요.",
            'context_template': "현재 감정 상태: {emotion_tag}. VAD 점수: Valence={valence}, Arousal={arousal}, Dominance={dominance}."
        }
    
    def generate_next_question(self, 
                              conversation_history: List[Dict], 
                              emotion_tag: Optional[str] = None,
                              vad_score: Optional[Dict] = None) -> Dict:
        """대화 히스토리와 감정 상태를 바탕으로 다음 질문 생성"""
        try:
            if not self.model:
                return self.get_mock_question(conversation_history, emotion_tag, vad_score)
            
            # 프롬프트 선택
            prompt_config = self.question_prompts.get(emotion_tag, self.default_prompt)
            
            # 대화 히스토리 구성
            history_text = self.build_conversation_history(conversation_history)
            
            # 감정 컨텍스트 구성
            emotion_context = ""
            if emotion_tag and vad_score:
                emotion_context = prompt_config['context_template'].format(
                    valence=vad_score.get('valence', 0.5),
                    arousal=vad_score.get('arousal', 0.5),
                    dominance=vad_score.get('dominance', 0.5),
                    emotion_tag=emotion_tag
                )
            
            # 전체 프롬프트 구성
            full_prompt = f"""
{prompt_config['system']}

{emotion_context}

지금까지의 대화 내용:
{history_text}

위 대화 내용과 현재 감정 상태를 바탕으로, 사용자의 감정을 더 깊이 이해하고 도움을 줄 수 있는 다음 질문을 한 문장으로 생성해주세요.

질문은:
1. 자연스럽고 친근한 톤이어야 합니다
2. 사용자의 이전 답변과 연결되어야 합니다
3. 감정의 원인이나 대처 방법을 탐색하는 방향이어야 합니다
4. 한 문장으로 끝나야 합니다

질문만 생성하고 다른 설명은 하지 마세요.
"""
            
            # Gemini API 호출
            response = self.model.generate_content(full_prompt)
            
            question = response.text.strip()
            
            # 질문이 너무 길거나 짧으면 조정
            if len(question) < 10:
                question = self.get_fallback_question(emotion_tag)
            elif len(question) > 100:
                question = question[:100] + "..."
            
            return {
                'success': True,
                'question': question,
                'model': 'gemini-2.5-flash',
                'conversation_length': len(conversation_history),
                'emotion_tag': emotion_tag
            }
            
        except Exception as e:
            print(f"Gemini API error: {e}")
            return self.get_mock_question(conversation_history, emotion_tag, vad_score)
    
    def build_conversation_history(self, conversation_history: List[Dict]) -> str:
        """대화 히스토리를 텍스트로 구성"""
        if not conversation_history:
            return "아직 대화가 시작되지 않았습니다."
        
        history_text = ""
        for i, turn in enumerate(conversation_history, 1):
            question = turn.get('question', '')
            answer = turn.get('answer', '')
            history_text += f"Q{i}: {question}\nA{i}: {answer}\n\n"
        
        return history_text.strip()
    
    def get_fallback_question(self, emotion_tag: Optional[str] = None) -> str:
        """API 오류 시 사용할 기본 질문들"""
        fallback_questions = {
            'angry': "지금 어떤 상황이 가장 화가 나게 만드나요?",
            'sad': "지금 가장 슬프게 만드는 것은 무엇인가요?",
            'anxious': "지금 가장 걱정되는 것은 무엇인가요?",
            'happy': "지금 기분이 좋은 이유는 무엇인가요?",
            'neutral': "오늘 하루는 어땠나요?"
        }
        
        return fallback_questions.get(emotion_tag, "지금 어떤 생각이 드나요?")
    
    def get_mock_question(self, 
                         conversation_history: List[Dict], 
                         emotion_tag: Optional[str] = None,
                         vad_score: Optional[Dict] = None) -> Dict:
        """모킹 질문 생성 (API 키가 없을 때)"""
        mock_questions = [
            "오늘 하루 중 가장 기뻤던 순간은 언제였나요?",
            "최근에 힘들었던 일은 무엇인가요?",
            "지금 기분을 한 단어로 표현한다면?",
            "가장 위로가 되는 것은 무엇인가요?",
            "지금 가장 하고 싶은 것은 무엇인가요?",
            "오늘 하루를 어떻게 보내고 싶으신가요?",
            "가장 감사한 것은 무엇인가요?",
            "지금 가장 필요한 것은 무엇인가요?",
            "어떤 일이 가장 스트레스가 되나요?",
            "기분이 좋아지는 방법은 무엇인가요?"
        ]
        
        # 대화 길이에 따라 질문 선택
        question_index = len(conversation_history) % len(mock_questions)
        question = mock_questions[question_index]
        
        return {
            'success': True,
            'question': question,
            'model': 'mock',
            'conversation_length': len(conversation_history),
            'emotion_tag': emotion_tag
        }
    
    def get_mock_result(self) -> Dict:
        """모킹 결과 반환"""
        return {
            'success': True,
            'question': "오늘 하루는 어땠나요?",
            'model': 'mock',
            'conversation_length': 0,
            'emotion_tag': 'neutral'
        }
    
    def get_response(self, user_message: str, conversation_history: List[Dict] = None) -> Dict:
        """사용자 메시지에 대한 응답 생성 (채팅용)"""
        try:
            if not self.model:
                return self.get_mock_chat_response(user_message, conversation_history)
            
            # 대화 히스토리 구성
            history_text = ""
            if conversation_history:
                history_text = self.build_conversation_history(conversation_history)
            
            # 프롬프트 구성 (전문가: 접두사 제거)
            prompt = f"""
당신은 감정 관리 전문가입니다. 사용자의 메시지에 대해 공감적이고 도움이 되는 응답을 해주세요.

{history_text}

사용자: {user_message}

응답:
"""
            
            # Gemini API 호출
            response = self.model.generate_content(prompt)
            
            # 응답에서 접두사 제거
            response_text = response.text.strip()
            
            # "전문가:", "AI:", "Assistant:", "응답:" 등의 접두사 제거
            prefixes_to_remove = [
                "전문가:", "AI:", "Assistant:", "응답:", "답변:", 
                "Expert:", "Counselor:", "Therapist:", "Advisor:"
            ]
            
            for prefix in prefixes_to_remove:
                if response_text.startswith(prefix):
                    response_text = response_text[len(prefix):].strip()
                    break
            
            return {
                'success': True,
                'response': response_text,
                'model': 'gemini-2.5-flash'
            }
            
        except Exception as e:
            print(f"Gemini chat error: {e}")
            return self.get_mock_chat_response(user_message, conversation_history)
    
    def get_mock_chat_response(self, user_message: str, conversation_history: List[Dict] = None) -> Dict:
        """모킹 채팅 응답 생성"""
        mock_responses = [
            "네, 말씀해주세요. 듣고 있습니다.",
            "그런 감정을 느끼시는군요. 더 자세히 이야기해주세요.",
            "정말 힘드셨겠어요. 어떤 도움이 필요하신가요?",
            "그런 상황이라면 충분히 이해됩니다. 어떻게 도와드릴까요?",
            "감정을 표현해주셔서 고맙습니다. 더 이야기해주세요.",
            "그런 생각을 하시는군요. 다른 관점에서도 생각해보셨나요?",
            "정말 중요한 이야기네요. 어떻게 해결하고 싶으신가요?",
            "그런 경험을 하셨군요. 지금은 어떤 기분이신가요?",
            "충분히 공감됩니다. 앞으로는 어떻게 하고 싶으신가요?",
            "그런 감정은 자연스러운 것입니다. 자신을 너무 탓하지 마세요."
        ]
        
        # 메시지 길이에 따라 응답 선택
        response_index = len(user_message) % len(mock_responses)
        response = mock_responses[response_index]
        
        return {
            'success': True,
            'response': response,
            'model': 'mock'
        }
    
    def get_conversation_history(self) -> List[Dict]:
        """대화 히스토리 반환 (현재는 빈 리스트)"""
        return []
    
    def clear_conversation(self):
        """대화 히스토리 초기화"""
        pass
    
    def is_available(self) -> bool:
        """서비스 사용 가능 여부 확인"""
        return self.model is not None 