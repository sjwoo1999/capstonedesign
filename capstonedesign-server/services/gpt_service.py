import os
import json
from typing import Dict, List, Optional
import openai

class GPTService:
    def __init__(self, api_key: Optional[str] = None):
        """GPT 서비스 초기화"""
        self.api_key = api_key or os.getenv('OPENAI_API_KEY')
        if self.api_key:
            openai.api_key = self.api_key
        
        # 감정별 프롬프트 템플릿
        self.emotion_prompts = {
            'angry': {
                'system': "당신은 분노 관리 전문가입니다. 사용자의 분노 상황을 이해하고 공감적이면서도 실용적인 조언을 제공하세요.",
                'user_template': "현재 분노한 상태입니다. VAD 점수: Valence={valence}, Arousal={arousal}, Dominance={dominance}. {context}"
            },
            'sad': {
                'system': "당신은 우울감 완화 전문가입니다. 사용자의 슬픔을 인정하고 위로하면서 긍정적 변화를 촉진하는 조언을 제공하세요.",
                'user_template': "현재 슬픈 상태입니다. VAD 점수: Valence={valence}, Arousal={arousal}, Dominance={dominance}. {context}"
            },
            'anxious': {
                'system': "당신은 불안 완화 전문가입니다. 사용자의 불안을 이해하고 안정감을 제공하는 실용적인 방법을 제시하세요.",
                'user_template': "현재 불안한 상태입니다. VAD 점수: Valence={valence}, Arousal={arousal}, Dominance={dominance}. {context}"
            },
            'happy': {
                'system': "당신은 긍정심리학 전문가입니다. 사용자의 긍정적 감정을 지속하고 확장하는 방법을 제안하세요.",
                'user_template': "현재 기분이 좋은 상태입니다. VAD 점수: Valence={valence}, Arousal={arousal}, Dominance={dominance}. {context}"
            },
            'neutral': {
                'system': "당신은 감정 인식 전문가입니다. 사용자가 자신의 감정을 더 잘 이해하고 표현할 수 있도록 도움을 주세요.",
                'user_template': "현재 중립적인 감정 상태입니다. VAD 점수: Valence={valence}, Arousal={arousal}, Dominance={dominance}. {context}"
            }
        }
        
        # 기본 프롬프트
        self.default_prompt = {
            'system': "당신은 감정 관리 전문가입니다. 사용자의 감정 상태를 분석하고 실용적인 조언을 제공하세요.",
            'user_template': "현재 감정 상태: {emotion_tag}. VAD 점수: Valence={valence}, Arousal={arousal}, Dominance={dominance}. {context}"
        }
    
    def generate_response(self, 
                         emotion_tag: str, 
                         vad_score: Dict, 
                         context: str = "",
                         cbt_strategy: Optional[Dict] = None) -> Dict:
        """감정 분석 결과에 대한 GPT 응답 생성"""
        try:
            if not self.api_key:
                return self.get_mock_response(emotion_tag, vad_score, context, cbt_strategy)
            
            # 프롬프트 선택
            prompt_config = self.emotion_prompts.get(emotion_tag, self.default_prompt)
            
            # 컨텍스트 구성
            context_parts = []
            if context:
                context_parts.append(f"사용자 상황: {context}")
            
            if cbt_strategy:
                strategy_info = f"""
추천된 CBT 전략:
- 전략명: {cbt_strategy.get('strategy', {}).get('name', 'N/A')}
- 기법: {', '.join(cbt_strategy.get('strategy', {}).get('techniques', [])[:3])}
- 권장사항: {' '.join(cbt_strategy.get('personalized_recommendations', [])[:2])}
"""
                context_parts.append(strategy_info)
            
            full_context = " ".join(context_parts)
            
            # 사용자 프롬프트 생성
            user_prompt = prompt_config['user_template'].format(
                valence=vad_score.get('valence', 0.5),
                arousal=vad_score.get('arousal', 0.5),
                dominance=vad_score.get('dominance', 0.5),
                emotion_tag=emotion_tag,
                context=full_context
            )
            
            # GPT API 호출
            response = openai.ChatCompletion.create(
                model="gpt-3.5-turbo",
                messages=[
                    {"role": "system", "content": prompt_config['system']},
                    {"role": "user", "content": user_prompt}
                ],
                max_tokens=500,
                temperature=0.7
            )
            
            gpt_response = response.choices[0].message.content
            
            return {
                'success': True,
                'response': gpt_response,
                'model': 'gpt-3.5-turbo',
                'tokens_used': response.usage.total_tokens if hasattr(response, 'usage') else 0
            }
            
        except Exception as e:
            print(f"GPT API error: {e}")
            return self.get_mock_response(emotion_tag, vad_score, context, cbt_strategy)
    
    def generate_summary_response(self, 
                                face_result: Dict,
                                audio_result: Dict,
                                text_result: Dict,
                                fusion_result: Dict,
                                cbt_strategy: Dict) -> Dict:
        """멀티모달 분석 결과에 대한 종합 응답 생성"""
        try:
            if not self.api_key:
                return self.get_mock_summary_response(face_result, audio_result, text_result, fusion_result, cbt_strategy)
            
            # 종합 분석 결과 구성
            summary_context = self.build_summary_context(
                face_result, audio_result, text_result, fusion_result, cbt_strategy
            )
            
            system_prompt = """당신은 멀티모달 감정 분석 전문가입니다. 
얼굴 표정, 음성, 텍스트 분석 결과를 종합하여 사용자에게 
이해하기 쉽고 실용적인 감정 분석 리포트와 조언을 제공하세요.
한국어로 친근하고 공감적이면서도 전문적인 톤으로 응답하세요."""

            user_prompt = f"""
다음은 멀티모달 감정 분석 결과입니다:

{summary_context}

위 결과를 바탕으로 다음을 포함한 종합적인 응답을 제공해주세요:
1. 현재 감정 상태 요약
2. 각 모달리티별 주요 특징
3. 개인화된 조언과 권장사항
4. 향후 감정 관리 방향
"""

            response = openai.ChatCompletion.create(
                model="gpt-3.5-turbo",
                messages=[
                    {"role": "system", "content": system_prompt},
                    {"role": "user", "content": user_prompt}
                ],
                max_tokens=800,
                temperature=0.7
            )
            
            gpt_response = response.choices[0].message.content
            
            return {
                'success': True,
                'response': gpt_response,
                'model': 'gpt-3.5-turbo',
                'tokens_used': response.usage.total_tokens if hasattr(response, 'usage') else 0
            }
            
        except Exception as e:
            print(f"GPT summary error: {e}")
            return self.get_mock_summary_response(face_result, audio_result, text_result, fusion_result, cbt_strategy)
    
    def build_summary_context(self, 
                            face_result: Dict,
                            audio_result: Dict,
                            text_result: Dict,
                            fusion_result: Dict,
                            cbt_strategy: Dict) -> str:
        """종합 분석을 위한 컨텍스트 구성"""
        try:
            context_parts = []
            
            # 얼굴 분석 결과
            if face_result.get('success'):
                context_parts.append(f"""
얼굴 표정 분석:
- 주요 감정: {face_result.get('emotion', 'N/A')}
- 신뢰도: {face_result.get('confidence', 0):.2f}
- VAD 점수: {face_result.get('vad_score', {})}
""")
            
            # 음성 분석 결과
            if audio_result.get('success'):
                context_parts.append(f"""
음성 분석:
- 전사: {audio_result.get('transcript', 'N/A')}
- 언어: {audio_result.get('language', 'N/A')}
- VAD 점수: {audio_result.get('vad_score', {})}
""")
            
            # 텍스트 분석 결과
            if text_result.get('success'):
                context_parts.append(f"""
텍스트 감정 분석:
- 주요 감정: {text_result.get('dominant_emotion', 'N/A')}
- 감정 강도: {text_result.get('emotion_intensity', 0):.2f}
- VAD 점수: {text_result.get('vad_score', {})}
""")
            
            # 융합 결과
            if fusion_result.get('success'):
                context_parts.append(f"""
종합 분석:
- 최종 감정 태그: {fusion_result.get('emotion_tag', 'N/A')}
- 최종 VAD 점수: {fusion_result.get('final_vad', {})}
- 사용된 모달리티: {', '.join(fusion_result.get('available_modalities', []))}
""")
            
            # CBT 전략
            if cbt_strategy.get('success'):
                strategy = cbt_strategy.get('strategy', {})
                context_parts.append(f"""
추천 전략:
- 전략명: {strategy.get('name', 'N/A')}
- 주요 기법: {', '.join(strategy.get('techniques', [])[:3])}
- 권장사항: {' '.join(cbt_strategy.get('personalized_recommendations', [])[:2])}
""")
            
            return "\n".join(context_parts)
            
        except Exception as e:
            print(f"Context building error: {e}")
            return "분석 결과를 구성하는 중 오류가 발생했습니다."
    
    def get_mock_response(self, 
                         emotion_tag: str, 
                         vad_score: Dict, 
                         context: str = "",
                         cbt_strategy: Optional[Dict] = None) -> Dict:
        """모킹 응답 반환 (테스트용)"""
        mock_responses = {
            'happy': "현재 기분이 좋으시군요! 이런 긍정적인 감정을 유지하고 확장하는 것은 매우 중요합니다. 주변 사람들과 기쁨을 나누고, 이 순간을 충분히 즐겨보세요. 또한 이런 긍정적인 경험을 기록해두시면 나중에 힘든 시기에 도움이 될 수 있습니다.",
            'sad': "지금 슬픈 감정을 느끼고 계시는군요. 이런 감정은 자연스러운 것이니 자신을 너무 몰아세우지 마세요. 신뢰할 수 있는 사람과 대화해보시거나, 가벼운 산책을 통해 마음을 정리해보세요. 시간이 지나면 감정이 변화할 것입니다.",
            'angry': "분노를 느끼고 계시는군요. 이런 감정이 생기는 것은 자연스러운 일입니다. 하지만 건강하게 관리하는 것이 중요해요. 심호흡을 몇 번 해보시고, 잠시 시간을 두어 감정이 가라앉을 때까지 기다려보세요. 분노의 원인을 분석해보는 것도 도움이 될 수 있습니다.",
            'anxious': "불안한 감정을 느끼고 계시는군요. 불안은 미래에 대한 걱정에서 오는 경우가 많습니다. 현재 순간에 집중해보세요. 주변을 둘러보며 5가지 보이는 것, 4가지 만질 수 있는 것, 3가지 들리는 것, 2가지 냄새, 1가지 맛을 찾아보세요. 이렇게 감각에 집중하면 불안이 줄어들 수 있습니다.",
            'neutral': "현재 중립적인 감정 상태이시군요. 이런 상태는 감정을 더 잘 인식하고 표현할 수 있는 좋은 기회입니다. 자신의 감정을 관찰하고, 필요하다면 감정 일기를 써보세요. 감정을 더 잘 이해하면 자기 관리에 도움이 됩니다."
        }
        
        response = mock_responses.get(emotion_tag, mock_responses['neutral'])
        
        if cbt_strategy and cbt_strategy.get('success'):
            strategy = cbt_strategy.get('strategy', {})
            response += f"\n\n추천 전략: {strategy.get('name', '')}"
            response += f"\n주요 기법: {', '.join(strategy.get('techniques', [])[:2])}"
        
        return {
            'success': True,
            'response': response,
            'model': 'mock-gpt',
            'tokens_used': 0
        }
    
    def get_mock_summary_response(self, 
                                face_result: Dict,
                                audio_result: Dict,
                                text_result: Dict,
                                fusion_result: Dict,
                                cbt_strategy: Dict) -> Dict:
        """모킹 종합 응답 반환 (테스트용)"""
        summary = """멀티모달 감정 분석 결과를 종합해보겠습니다.

현재 감정 상태:
- 종합 감정: 기쁨 (Happy)
- 감정 강도: 중간 정도
- 전반적으로 긍정적인 감정 상태입니다.

각 모달리티별 특징:
- 얼굴 표정: 기쁨이 명확하게 나타남 (신뢰도: 85%)
- 음성: 밝고 활기찬 톤, 긍정적인 내용
- 텍스트: 기쁨과 신뢰 감정이 우세

개인화된 조언:
현재 기분이 좋으시니 이 순간을 충분히 즐기시고, 주변 사람들과 기쁨을 나누어보세요. 이런 긍정적인 경험을 기록해두시면 향후 힘든 시기에 도움이 될 수 있습니다.

향후 감정 관리 방향:
- 긍정적 경험을 확장하고 지속하는 방법 연습
- 감사 일기 작성으로 긍정적 사고 습관화
- 타인과의 긍정적 상호작용 증가

전반적으로 건강한 감정 상태를 유지하고 계시니, 이런 긍정적인 감정을 더욱 발전시켜 나가시기 바랍니다."""

        return {
            'success': True,
            'response': summary,
            'model': 'mock-gpt',
            'tokens_used': 0
        }
    
    def get_mock_result(self) -> Dict:
        """모킹 결과 반환 (테스트용)"""
        return {
            'success': True,
            'response': '현재 기분이 좋으시군요! 이런 긍정적인 감정을 유지하고 확장하는 것은 매우 중요합니다.',
            'model': 'mock-gpt',
            'tokens_used': 0
        } 