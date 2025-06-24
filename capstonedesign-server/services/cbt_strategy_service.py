from typing import Dict, List, Optional

class CBTStrategyService:
    def __init__(self):
        """CBT 전략 매핑 서비스 초기화"""
        
        # 감정별 CBT 전략 매핑
        self.emotion_strategies = {
            'angry': {
                'name': '분노 관리 전략',
                'description': '분노를 건강하게 관리하고 표현하는 방법',
                'techniques': [
                    '심호흡 및 이완 기법',
                    '분노의 원인 분석',
                    '건강한 의사소통 방법',
                    '시간 두기 (Time-out)',
                    '신체 활동을 통한 에너지 해소'
                ],
                'exercises': [
                    '10초 심호흡: 깊게 들이마시고 천천히 내쉬기',
                    '분노 일기: 감정과 생각 기록하기',
                    '대안적 사고: 다른 관점에서 상황 바라보기'
                ],
                'resources': [
                    '분노 관리 앱 사용',
                    '전문가 상담 고려',
                    '스트레스 관리 활동 참여'
                ]
            },
            'sad': {
                'name': '우울감 완화 전략',
                'description': '우울감을 줄이고 긍정적 사고를 촉진하는 방법',
                'techniques': [
                    '활동 스케줄링',
                    '긍정적 사고 재구성',
                    '사회적 연결 유지',
                    '신체 활동 증가',
                    '자기 돌봄 활동'
                ],
                'exercises': [
                    '감사 일기: 매일 감사한 것 3가지 기록',
                    '즐거운 활동 목록 작성 및 실행',
                    '부정적 사고 도전하기'
                ],
                'resources': [
                    '인지행동치료 프로그램',
                    '지지 그룹 참여',
                    '전문 상담사 상담'
                ]
            },
            'anxious': {
                'name': '불안 완화 전략',
                'description': '불안을 줄이고 안정감을 찾는 방법',
                'techniques': [
                    '점진적 근육 이완',
                    '마음챙김 명상',
                    '현재에 집중하기',
                    '불안의 원인 파악',
                    '체계적 둔감화'
                ],
                'exercises': [
                    '5-4-3-2-1 감각 체크: 주변 환경 관찰하기',
                    '박스 호흡: 4초 들이마시고 4초 내쉬기',
                    '불안 일기: 불안의 패턴 기록'
                ],
                'resources': [
                    '명상 앱 사용',
                    '요가나 태극권 수업',
                    '전문 치료사 상담'
                ]
            },
            'happy': {
                'name': '긍정적 감정 유지 전략',
                'description': '긍정적 감정을 지속하고 확장하는 방법',
                'techniques': [
                    '긍정적 경험 확장하기',
                    '성취감 기록하기',
                    '타인과 기쁨 공유하기',
                    '미래 목표 설정',
                    '자기 격려하기'
                ],
                'exercises': [
                    '긍정적 순간 사진 찍기',
                    '성취 일기 작성',
                    '감사 편지 쓰기'
                ],
                'resources': [
                    '긍정심리학 워크샵',
                    '취미 활동 참여',
                    '자원봉사 활동'
                ]
            },
            'neutral': {
                'name': '감정 인식 및 표현 전략',
                'description': '감정을 더 잘 인식하고 표현하는 방법',
                'techniques': [
                    '감정 라벨링 연습',
                    '신체 감각 관찰',
                    '감정 표현 연습',
                    '자기 인식 향상',
                    '감정 일기 작성'
                ],
                'exercises': [
                    '감정 차트 작성',
                    '신체 스캔 명상',
                    '감정 표현 역할극'
                ],
                'resources': [
                    '감정 인식 워크북',
                    '마음챙김 프로그램',
                    '예술 치료 활동'
                ]
            }
        }
        
        # VAD Score 기반 전략 조정
        self.vad_adjustments = {
            'high_arousal': {
                'focus': '이완 및 진정 기법',
                'priority': ['심호흡', '근육 이완', '마음챙김']
            },
            'low_arousal': {
                'focus': '활동 및 동기 부여',
                'priority': ['활동 스케줄링', '운동', '사회적 연결']
            },
            'low_valence': {
                'focus': '긍정적 사고 촉진',
                'priority': ['감사 연습', '긍정적 재구성', '즐거운 활동']
            },
            'high_dominance': {
                'focus': '협력 및 공감',
                'priority': ['적극적 경청', '공감 표현', '협력적 문제해결']
            }
        }
    
    def map_emotion_to_strategy(self, emotion_tag: str, vad_score: Dict) -> Dict:
        """감정을 CBT 전략으로 매핑"""
        try:
            # 기본 전략 가져오기
            base_strategy = self.emotion_strategies.get(emotion_tag, self.emotion_strategies['neutral'])
            
            # VAD Score 기반 전략 조정
            adjusted_strategy = self.adjust_strategy_by_vad(base_strategy, vad_score)
            
            # 개인화된 권장사항 생성
            personalized_recommendations = self.generate_personalized_recommendations(
                emotion_tag, vad_score, adjusted_strategy
            )
            
            return {
                'success': True,
                'emotion_tag': emotion_tag,
                'vad_score': vad_score,
                'strategy': adjusted_strategy,
                'personalized_recommendations': personalized_recommendations,
                'next_steps': self.get_next_steps(emotion_tag, vad_score)
            }
            
        except Exception as e:
            return {
                'success': False,
                'error': f'Strategy mapping failed: {str(e)}',
                'strategy': self.emotion_strategies['neutral']
            }
    
    def adjust_strategy_by_vad(self, base_strategy: Dict, vad_score: Dict) -> Dict:
        """VAD Score를 기반으로 전략 조정"""
        try:
            adjusted_strategy = base_strategy.copy()
            valence = vad_score.get('valence', 0.5)
            arousal = vad_score.get('arousal', 0.5)
            dominance = vad_score.get('dominance', 0.5)
            
            # 각성도가 높은 경우
            if arousal > 0.7:
                adjustment = self.vad_adjustments['high_arousal']
                adjusted_strategy['focus'] = f"{base_strategy['name']} - {adjustment['focus']}"
                adjusted_strategy['priority_techniques'] = adjustment['priority']
            
            # 각성도가 낮은 경우
            elif arousal < 0.3:
                adjustment = self.vad_adjustments['low_arousal']
                adjusted_strategy['focus'] = f"{base_strategy['name']} - {adjustment['focus']}"
                adjusted_strategy['priority_techniques'] = adjustment['priority']
            
            # 긍정성이 낮은 경우
            if valence < 0.3:
                adjustment = self.vad_adjustments['low_valence']
                adjusted_strategy['focus'] = f"{base_strategy['name']} - {adjustment['focus']}"
                if 'priority_techniques' not in adjusted_strategy:
                    adjusted_strategy['priority_techniques'] = adjustment['priority']
                else:
                    adjusted_strategy['priority_techniques'].extend(adjustment['priority'])
            
            # 지배성이 높은 경우
            if dominance > 0.7:
                adjustment = self.vad_adjustments['high_dominance']
                adjusted_strategy['focus'] = f"{base_strategy['name']} - {adjustment['focus']}"
                if 'priority_techniques' not in adjusted_strategy:
                    adjusted_strategy['priority_techniques'] = adjustment['priority']
                else:
                    adjusted_strategy['priority_techniques'].extend(adjustment['priority'])
            
            return adjusted_strategy
            
        except Exception as e:
            print(f"Strategy adjustment error: {e}")
            return base_strategy
    
    def generate_personalized_recommendations(self, emotion_tag: str, vad_score: Dict, strategy: Dict) -> List[str]:
        """개인화된 권장사항 생성"""
        try:
            recommendations = []
            
            # 감정 강도에 따른 권장사항
            intensity = self.calculate_emotion_intensity(vad_score)
            
            if intensity > 0.7:
                recommendations.append("현재 감정이 강하므로 즉시 적용 가능한 기법을 우선적으로 시도해보세요.")
                recommendations.append("필요시 전문가의 도움을 받는 것을 고려해보세요.")
            elif intensity < 0.3:
                recommendations.append("감정이 안정적이므로 장기적인 자기 관리 전략을 계획해보세요.")
                recommendations.append("일상적인 감정 관리 습관을 만들어보세요.")
            
            # 특정 감정에 따른 권장사항
            if emotion_tag == 'angry':
                recommendations.append("분노가 가라앉을 때까지 잠시 시간을 두고 심호흡을 해보세요.")
            elif emotion_tag == 'sad':
                recommendations.append("혼자 있기보다는 신뢰할 수 있는 사람과 대화해보세요.")
            elif emotion_tag == 'anxious':
                recommendations.append("현재 순간에 집중하여 불안한 미래 생각을 잠시 내려놓아보세요.")
            
            return recommendations
            
        except Exception as e:
            print(f"Personalized recommendations error: {e}")
            return ["감정 상태에 맞는 적절한 전략을 선택하여 적용해보세요."]
    
    def calculate_emotion_intensity(self, vad_score: Dict) -> float:
        """감정 강도 계산"""
        try:
            import numpy as np
            valence = vad_score.get('valence', 0.5)
            arousal = vad_score.get('arousal', 0.5)
            dominance = vad_score.get('dominance', 0.5)
            
            # VAD 공간에서 원점으로부터의 거리
            distance = np.sqrt((valence - 0.5)**2 + (arousal - 0.5)**2 + (dominance - 0.5)**2)
            intensity = min(1.0, distance * 2)
            
            return float(intensity)
        except:
            return 0.5
    
    def get_next_steps(self, emotion_tag: str, vad_score: Dict) -> List[str]:
        """다음 단계 제안"""
        try:
            steps = []
            
            # 즉시 적용 가능한 단계
            steps.append("1. 현재 제안된 기법 중 하나를 선택하여 시도해보세요.")
            steps.append("2. 효과를 관찰하고 필요시 다른 기법을 시도해보세요.")
            
            # 중기 단계
            steps.append("3. 일주일간 선택한 기법을 꾸준히 연습해보세요.")
            steps.append("4. 감정 변화를 기록하고 패턴을 관찰해보세요.")
            
            # 장기 단계
            steps.append("5. 효과적인 기법들을 일상에 통합해보세요.")
            steps.append("6. 필요시 전문가와 상담하여 더 체계적인 도움을 받아보세요.")
            
            return steps
            
        except Exception as e:
            print(f"Next steps error: {e}")
            return ["제안된 전략을 단계적으로 적용해보세요."]
    
    def get_mock_result(self) -> Dict:
        """모킹 결과 반환 (테스트용)"""
        return {
            'success': True,
            'emotion_tag': 'happy',
            'vad_score': {'valence': 0.7, 'arousal': 0.6, 'dominance': 0.6},
            'strategy': {
                'name': '긍정적 감정 유지 전략',
                'description': '긍정적 감정을 지속하고 확장하는 방법',
                'techniques': [
                    '긍정적 경험 확장하기',
                    '성취감 기록하기',
                    '타인과 기쁨 공유하기'
                ],
                'exercises': [
                    '긍정적 순간 사진 찍기',
                    '성취 일기 작성',
                    '감사 편지 쓰기'
                ]
            },
            'personalized_recommendations': [
                "현재 기분이 좋으니 이 순간을 충분히 즐겨보세요.",
                "긍정적인 경험을 다른 사람과 공유해보세요."
            ],
            'next_steps': [
                "1. 현재 제안된 기법 중 하나를 선택하여 시도해보세요.",
                "2. 효과를 관찰하고 필요시 다른 기법을 시도해보세요."
            ]
        } 