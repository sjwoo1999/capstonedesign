import os
import base64
import tempfile
import numpy as np
import librosa
import whisper
from typing import Dict, Optional
import json

class AudioEmotionService:
    def __init__(self, model_name: str = "base"):
        """음성 감정 분석 서비스 초기화"""
        self.whisper_model = whisper.load_model(model_name)
        
        # Prosody 특성을 VAD Score로 매핑하는 가중치
        self.prosody_weights = {
            'pitch_mean': {'valence': 0.3, 'arousal': 0.4, 'dominance': 0.2},
            'pitch_std': {'valence': 0.1, 'arousal': 0.3, 'dominance': 0.1},
            'energy_mean': {'valence': 0.2, 'arousal': 0.5, 'dominance': 0.3},
            'energy_std': {'valence': 0.1, 'arousal': 0.4, 'dominance': 0.2},
            'speech_rate': {'valence': 0.2, 'arousal': 0.3, 'dominance': 0.4}
        }
    
    def decode_audio_base64(self, audio_base64: str) -> Optional[str]:
        """Base64 오디오를 임시 파일로 디코딩"""
        try:
            audio_bytes = base64.b64decode(audio_base64)
            
            # 임시 파일 생성
            temp_file = tempfile.NamedTemporaryFile(delete=False, suffix='.wav')
            temp_file.write(audio_bytes)
            temp_file.close()
            
            return temp_file.name
        except Exception as e:
            print(f"Audio decoding error: {e}")
            return None
    
    def extract_prosody_features(self, audio_path: str) -> Dict:
        """음성의 prosody 특성 추출"""
        try:
            # 오디오 로드
            y, sr = librosa.load(audio_path, sr=None)
            
            # Pitch (F0) 추출
            pitches, magnitudes = librosa.piptrack(y=y, sr=sr)
            pitch_values = pitches[magnitudes > 0.1]
            
            if len(pitch_values) == 0:
                pitch_values = np.array([0])
            
            # Energy 추출
            energy = librosa.feature.rms(y=y)[0]
            
            # Speech rate (음성 속도) 계산
            speech_rate = len(y) / sr  # 초 단위
            
            # 특성 계산
            features = {
                'pitch_mean': float(np.mean(pitch_values)),
                'pitch_std': float(np.std(pitch_values)),
                'energy_mean': float(np.mean(energy)),
                'energy_std': float(np.std(energy)),
                'speech_rate': float(speech_rate),
                'duration': float(len(y) / sr)
            }
            
            return features
            
        except Exception as e:
            print(f"Prosody extraction error: {e}")
            return {
                'pitch_mean': 0.0, 'pitch_std': 0.0,
                'energy_mean': 0.0, 'energy_std': 0.0,
                'speech_rate': 0.0, 'duration': 0.0
            }
    
    def prosody_to_vad(self, prosody_features: Dict) -> Dict:
        """Prosody 특성을 VAD Score로 변환"""
        try:
            vad_score = {'valence': 0.5, 'arousal': 0.5, 'dominance': 0.5}
            
            # 각 특성별로 VAD Score 계산
            for feature, value in prosody_features.items():
                if feature in self.prosody_weights:
                    weights = self.prosody_weights[feature]
                    
                    # 정규화된 값 계산 (0-1 범위)
                    normalized_value = min(max(value / 1000, 0), 1)  # 간단한 정규화
                    
                    # VAD Score에 가중 적용
                    for vad_dim in ['valence', 'arousal', 'dominance']:
                        vad_score[vad_dim] += weights[vad_dim] * normalized_value
            
            # 0-1 범위로 클리핑
            for key in vad_score:
                vad_score[key] = max(0.0, min(1.0, vad_score[key]))
            
            return vad_score
            
        except Exception as e:
            print(f"Prosody to VAD conversion error: {e}")
            return {'valence': 0.5, 'arousal': 0.5, 'dominance': 0.5}
    
    def transcribe_audio(self, audio_path: str) -> Dict:
        """Whisper를 사용한 음성 인식"""
        try:
            result = self.whisper_model.transcribe(audio_path)
            return {
                'success': True,
                'transcript': result['text'],
                'language': result['language'],
                'segments': result['segments']
            }
        except Exception as e:
            return {
                'success': False,
                'error': f'Transcription failed: {str(e)}',
                'transcript': '',
                'language': 'unknown'
            }
    
    def analyze_audio_emotion(self, audio_base64: str) -> Dict:
        """음성 감정 분석 수행"""
        try:
            # Base64 디코딩
            audio_path = self.decode_audio_base64(audio_base64)
            if not audio_path:
                return {
                    'success': False,
                    'error': 'Invalid audio data'
                }
            
            # STT 수행
            stt_result = self.transcribe_audio(audio_path)
            
            # Prosody 특성 추출
            prosody_features = self.extract_prosody_features(audio_path)
            
            # VAD Score 계산
            vad_score = self.prosody_to_vad(prosody_features)
            
            # 임시 파일 삭제
            try:
                os.unlink(audio_path)
            except:
                pass
            
            return {
                'success': True,
                'transcript': stt_result.get('transcript', ''),
                'language': stt_result.get('language', 'unknown'),
                'prosody_features': prosody_features,
                'vad_score': vad_score
            }
            
        except Exception as e:
            return {
                'success': False,
                'error': f'Audio emotion analysis failed: {str(e)}'
            }
    
    def get_mock_result(self) -> Dict:
        """모킹 결과 반환 (테스트용)"""
        return {
            'success': True,
            'transcript': '안녕하세요, 오늘은 정말 기분이 좋습니다.',
            'language': 'ko',
            'prosody_features': {
                'pitch_mean': 150.0, 'pitch_std': 25.0,
                'energy_mean': 0.3, 'energy_std': 0.1,
                'speech_rate': 2.5, 'duration': 3.0
            },
            'vad_score': {'valence': 0.7, 'arousal': 0.6, 'dominance': 0.5}
        } 