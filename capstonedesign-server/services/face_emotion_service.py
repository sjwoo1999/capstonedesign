import os
import numpy as np
import cv2
import dlib
import base64
from keras.models import load_model
from typing import Dict, Optional, Tuple

class FaceEmotionService:
    def __init__(self, model_path: str = "models/emotion_model.h5"):
        """얼굴 감정 분석 서비스 초기화"""
        self.emotion_model = load_model(model_path, compile=False)
        self.face_detector = dlib.get_frontal_face_detector()
        self.expression_labels = ['Angry', 'Disgust', 'Fear', 'Happy', 'Sad', 'Surprise', 'Neutral']
        
        # 감정을 VAD Score로 매핑 (Valence, Arousal, Dominance)
        self.emotion_to_vad = {
            'Angry': {'valence': 0.2, 'arousal': 0.9, 'dominance': 0.8},
            'Disgust': {'valence': 0.1, 'arousal': 0.7, 'dominance': 0.6},
            'Fear': {'valence': 0.1, 'arousal': 0.9, 'dominance': 0.2},
            'Happy': {'valence': 0.9, 'arousal': 0.7, 'dominance': 0.8},
            'Sad': {'valence': 0.2, 'arousal': 0.3, 'dominance': 0.2},
            'Surprise': {'valence': 0.6, 'arousal': 0.8, 'dominance': 0.5},
            'Neutral': {'valence': 0.5, 'arousal': 0.3, 'dominance': 0.5}
        }
    
    def preprocess_face(self, image: np.ndarray) -> Optional[np.ndarray]:
        """얼굴 이미지 전처리"""
        try:
            gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
            faces = self.face_detector(gray)
            
            if not faces:
                return None
                
            face = faces[0]
            x, y, w, h = face.left(), face.top(), face.width(), face.height()
            roi = gray[y:y+h, x:x+w]
            roi = cv2.resize(roi, (64, 64))
            roi = roi.astype("float32") / 255.0
            roi = np.expand_dims(roi, axis=-1)
            roi = np.expand_dims(roi, axis=0)
            return roi
        except Exception as e:
            print(f"Face preprocessing error: {e}")
            return None
    
    def analyze_emotion(self, face_image_base64: str) -> Dict:
        """얼굴 감정 분석 수행"""
        try:
            # Base64 디코딩
            img_bytes = base64.b64decode(face_image_base64)
            img_array = np.frombuffer(img_bytes, np.uint8)
            img = cv2.imdecode(img_array, cv2.IMREAD_COLOR)
            
            if img is None:
                return {
                    'success': False,
                    'error': 'Invalid image data'
                }
            
            # 얼굴 전처리
            face = self.preprocess_face(img)
            if face is None:
                return {
                    'success': False,
                    'error': 'No face detected'
                }
            
            # 감정 예측
            preds = self.emotion_model.predict(face)[0]
            emotion_idx = int(np.argmax(preds))
            emotion_label = self.expression_labels[emotion_idx]
            confidence = float(preds[emotion_idx])
            
            # 확률 분포
            probabilities = {
                self.expression_labels[i]: float(preds[i]) 
                for i in range(len(preds))
            }
            
            # VAD Score 계산
            vad_score = self.emotion_to_vad[emotion_label].copy()
            
            return {
                'success': True,
                'emotion': emotion_label,
                'confidence': confidence,
                'probabilities': probabilities,
                'vad_score': vad_score
            }
            
        except Exception as e:
            return {
                'success': False,
                'error': f'Face emotion analysis failed: {str(e)}'
            }
    
    def get_mock_result(self) -> Dict:
        """모킹 결과 반환 (테스트용)"""
        return {
            'success': True,
            'emotion': 'Happy',
            'confidence': 0.85,
            'probabilities': {
                'Angry': 0.05, 'Disgust': 0.02, 'Fear': 0.01,
                'Happy': 0.85, 'Sad': 0.03, 'Surprise': 0.02, 'Neutral': 0.02
            },
            'vad_score': {'valence': 0.9, 'arousal': 0.7, 'dominance': 0.8}
        } 