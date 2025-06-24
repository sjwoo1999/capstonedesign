import numpy as np
from typing import Dict, List, Optional

class VADFusionService:
    def __init__(self):
        """VAD Score 융합 서비스 초기화"""
        # 각 모달리티별 가중치 (신뢰도 기반)
        self.modality_weights = {
            'face': 0.4,      # 얼굴 표정
            'audio': 0.3,     # 음성 prosody
            'text': 0.3       # 텍스트 감정
        }
        
        # VAD 차원별 가중치
        self.vad_dimension_weights = {
            'valence': 1.0,   # 긍정성
            'arousal': 1.0,   # 각성도
            'dominance': 1.0  # 지배성
        }
    
    def normalize_vad_score(self, vad_score: Dict) -> Dict:
        """VAD Score 정규화 (0-1 범위)"""
        try:
            normalized = {}
            for key, value in vad_score.items():
                if isinstance(value, (int, float)):
                    normalized[key] = max(0.0, min(1.0, float(value)))
                else:
                    normalized[key] = 0.5
            return normalized
        except Exception as e:
            print(f"VAD normalization error: {e}")
            return {'valence': 0.5, 'arousal': 0.5, 'dominance': 0.5}
    
    def calculate_confidence_weight(self, confidence: float) -> float:
        """신뢰도 기반 가중치 계산"""
        try:
            # 신뢰도가 높을수록 가중치 증가
            return min(1.0, max(0.1, confidence))
        except:
            return 0.5
    
    def fuse_vad_scores(self, 
                       face_vad: Optional[Dict] = None,
                       audio_vad: Optional[Dict] = None,
                       text_vad: Optional[Dict] = None,
                       face_confidence: float = 0.5,
                       audio_confidence: float = 0.5,
                       text_confidence: float = 0.5) -> Dict:
        """여러 모달리티의 VAD Score 융합"""
        try:
            # 사용 가능한 모달리티 확인
            available_modalities = []
            total_weight = 0.0
            weighted_vad = {'valence': 0.0, 'arousal': 0.0, 'dominance': 0.0}
            
            # 얼굴 감정 융합
            if face_vad:
                face_vad_norm = self.normalize_vad_score(face_vad)
                face_weight = self.modality_weights['face'] * self.calculate_confidence_weight(face_confidence)
                available_modalities.append('face')
                total_weight += face_weight
                
                for vad_dim in ['valence', 'arousal', 'dominance']:
                    weighted_vad[vad_dim] += face_weight * face_vad_norm[vad_dim]
            
            # 음성 감정 융합
            if audio_vad:
                audio_vad_norm = self.normalize_vad_score(audio_vad)
                audio_weight = self.modality_weights['audio'] * self.calculate_confidence_weight(audio_confidence)
                available_modalities.append('audio')
                total_weight += audio_weight
                
                for vad_dim in ['valence', 'arousal', 'dominance']:
                    weighted_vad[vad_dim] += audio_weight * audio_vad_norm[vad_dim]
            
            # 텍스트 감정 융합
            if text_vad:
                text_vad_norm = self.normalize_vad_score(text_vad)
                text_weight = self.modality_weights['text'] * self.calculate_confidence_weight(text_confidence)
                available_modalities.append('text')
                total_weight += text_weight
                
                for vad_dim in ['valence', 'arousal', 'dominance']:
                    weighted_vad[vad_dim] += text_weight * text_vad_norm[vad_dim]
            
            # 최종 VAD Score 계산
            if total_weight > 0:
                final_vad = {}
                for vad_dim in ['valence', 'arousal', 'dominance']:
                    final_vad[vad_dim] = weighted_vad[vad_dim] / total_weight
            else:
                # 기본값
                final_vad = {'valence': 0.5, 'arousal': 0.5, 'dominance': 0.5}
            
            # 감정 태그 생성
            emotion_tag = self.generate_emotion_tag(final_vad)
            
            return {
                'success': True,
                'final_vad': final_vad,
                'emotion_tag': emotion_tag,
                'available_modalities': available_modalities,
                'fusion_weights': {
                    'face': face_weight if face_vad else 0.0,
                    'audio': audio_weight if audio_vad else 0.0,
                    'text': text_weight if text_vad else 0.0
                },
                'total_weight': total_weight
            }
            
        except Exception as e:
            return {
                'success': False,
                'error': f'VAD fusion failed: {str(e)}',
                'final_vad': {'valence': 0.5, 'arousal': 0.5, 'dominance': 0.5},
                'emotion_tag': 'neutral'
            }
    
    def generate_emotion_tag(self, vad_score: Dict) -> str:
        """VAD Score를 기반으로 감정 태그 생성"""
        try:
            valence = vad_score.get('valence', 0.5)
            arousal = vad_score.get('arousal', 0.5)
            dominance = vad_score.get('dominance', 0.5)
            
            # VAD 공간에서 감정 분류
            if valence > 0.7 and arousal > 0.6:
                return 'excited'
            elif valence > 0.7 and arousal <= 0.6:
                return 'happy'
            elif valence <= 0.3 and arousal > 0.6:
                return 'angry'
            elif valence <= 0.3 and arousal <= 0.6:
                return 'sad'
            elif valence > 0.4 and valence <= 0.7 and arousal > 0.6:
                return 'surprised'
            elif valence > 0.4 and valence <= 0.7 and arousal <= 0.6:
                return 'calm'
            else:
                return 'neutral'
                
        except Exception as e:
            print(f"Emotion tag generation error: {e}")
            return 'neutral'
    
    def get_emotion_intensity(self, vad_score: Dict) -> float:
        """감정 강도 계산"""
        try:
            # VAD 공간에서 원점으로부터의 거리로 강도 계산
            valence = vad_score.get('valence', 0.5)
            arousal = vad_score.get('arousal', 0.5)
            dominance = vad_score.get('dominance', 0.5)
            
            # 정규화된 거리 계산
            distance = np.sqrt((valence - 0.5)**2 + (arousal - 0.5)**2 + (dominance - 0.5)**2)
            intensity = min(1.0, distance * 2)  # 0-1 범위로 정규화
            
            return float(intensity)
            
        except Exception as e:
            print(f"Emotion intensity calculation error: {e}")
            return 0.5
    
    def get_mock_result(self) -> Dict:
        """모킹 결과 반환 (테스트용)"""
        return {
            'success': True,
            'final_vad': {'valence': 0.7, 'arousal': 0.6, 'dominance': 0.6},
            'emotion_tag': 'happy',
            'available_modalities': ['face', 'audio', 'text'],
            'fusion_weights': {'face': 0.4, 'audio': 0.3, 'text': 0.3},
            'total_weight': 1.0
        } 