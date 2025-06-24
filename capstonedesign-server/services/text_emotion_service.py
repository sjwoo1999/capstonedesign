import os
import csv
from typing import Dict, List

class TextEmotionService:
    def __init__(self, lexicon_path: str = "lexicon/Korean-NRC-EmoLex.txt"):
        """텍스트 감정 분석 서비스 초기화"""
        self.lexicon_path = lexicon_path
        self.korean_lexicon = {}
        self.lexicon_emotions = []
        self.load_lexicon()
        
        # 감정을 VAD Score로 매핑
        self.emotion_to_vad = {
            'joy': {'valence': 0.9, 'arousal': 0.7, 'dominance': 0.8},
            'trust': {'valence': 0.8, 'arousal': 0.4, 'dominance': 0.6},
            'anticipation': {'valence': 0.7, 'arousal': 0.6, 'dominance': 0.7},
            'surprise': {'valence': 0.6, 'arousal': 0.8, 'dominance': 0.5},
            'anger': {'valence': 0.2, 'arousal': 0.9, 'dominance': 0.8},
            'disgust': {'valence': 0.1, 'arousal': 0.7, 'dominance': 0.6},
            'fear': {'valence': 0.1, 'arousal': 0.9, 'dominance': 0.2},
            'sadness': {'valence': 0.2, 'arousal': 0.3, 'dominance': 0.2}
        }
    
    def load_lexicon(self):
        """NRC Lexicon 로드"""
        try:
            if os.path.exists(self.lexicon_path):
                with open(self.lexicon_path, encoding='utf-8') as f:
                    reader = csv.DictReader(f, delimiter='\t')
                    self.lexicon_emotions = [col for col in reader.fieldnames 
                                           if col not in ('English Word', 'Korean Word')]
                    
                    for row in reader:
                        word = row['Korean Word'].strip()
                        if word:
                            self.korean_lexicon[word] = {
                                emotion: int(row[emotion]) 
                                for emotion in self.lexicon_emotions
                            }
                print(f"Loaded {len(self.korean_lexicon)} words from lexicon")
            else:
                print(f"Lexicon file not found: {self.lexicon_path}")
                # 기본 감정 리스트 설정
                self.lexicon_emotions = ['joy', 'trust', 'anticipation', 'surprise', 
                                       'anger', 'disgust', 'fear', 'sadness']
        except Exception as e:
            print(f"Error loading lexicon: {e}")
            self.lexicon_emotions = ['joy', 'trust', 'anticipation', 'surprise', 
                                   'anger', 'disgust', 'fear', 'sadness']
    
    def preprocess_text(self, text: str) -> List[str]:
        """텍스트 전처리"""
        # 간단한 토큰화 (공백 기준)
        words = text.strip().split()
        return words
    
    def analyze_text_emotion(self, text: str) -> Dict:
        """텍스트 감정 분석 수행"""
        try:
            if not text.strip():
                return {
                    'success': False,
                    'error': 'Empty text provided'
                }
            
            # 텍스트 전처리
            words = self.preprocess_text(text)
            
            if not words:
                return {
                    'success': False,
                    'error': 'No valid words found'
                }
            
            # 감정 점수 계산
            scores = {emotion: 0 for emotion in self.lexicon_emotions}
            count = {emotion: 0 for emotion in self.lexicon_emotions}
            matched_words = []
            
            for word in words:
                if word in self.korean_lexicon:
                    matched_words.append(word)
                    for emotion in self.lexicon_emotions:
                        scores[emotion] += self.korean_lexicon[word][emotion]
                        if self.korean_lexicon[word][emotion] > 0:
                            count[emotion] += 1
            
            # 평균 점수 계산
            avg_scores = {}
            for emotion in self.lexicon_emotions:
                if count[emotion] > 0:
                    avg_scores[emotion] = scores[emotion] / count[emotion]
                else:
                    avg_scores[emotion] = 0.0
            
            # 주요 감정 찾기
            if any(avg_scores.values()):
                dominant_emotion = max(avg_scores, key=avg_scores.get)
                emotion_intensity = avg_scores[dominant_emotion]
            else:
                dominant_emotion = 'neutral'
                emotion_intensity = 0.0
            
            # VAD Score 계산
            vad_score = self.calculate_vad_score(avg_scores)
            
            return {
                'success': True,
                'text': text,
                'dominant_emotion': dominant_emotion,
                'emotion_intensity': emotion_intensity,
                'emotion_scores': avg_scores,
                'matched_words': matched_words,
                'total_words': len(words),
                'matched_count': len(matched_words),
                'vad_score': vad_score
            }
            
        except Exception as e:
            return {
                'success': False,
                'error': f'Text emotion analysis failed: {str(e)}'
            }
    
    def calculate_vad_score(self, emotion_scores: Dict) -> Dict:
        """감정 점수를 VAD Score로 변환"""
        try:
            vad_score = {'valence': 0.5, 'arousal': 0.5, 'dominance': 0.5}
            
            # 각 감정의 VAD Score를 가중 평균으로 계산
            total_weight = 0
            weighted_vad = {'valence': 0, 'arousal': 0, 'dominance': 0}
            
            for emotion, score in emotion_scores.items():
                if score > 0 and emotion in self.emotion_to_vad:
                    weight = score
                    total_weight += weight
                    
                    for vad_dim in ['valence', 'arousal', 'dominance']:
                        weighted_vad[vad_dim] += weight * self.emotion_to_vad[emotion][vad_dim]
            
            # 정규화
            if total_weight > 0:
                for vad_dim in ['valence', 'arousal', 'dominance']:
                    vad_score[vad_dim] = weighted_vad[vad_dim] / total_weight
            
            return vad_score
            
        except Exception as e:
            print(f"VAD score calculation error: {e}")
            return {'valence': 0.5, 'arousal': 0.5, 'dominance': 0.5}
    
    def get_mock_result(self) -> Dict:
        """모킹 결과 반환 (테스트용)"""
        return {
            'success': True,
            'text': '오늘은 정말 기분이 좋고 행복합니다.',
            'dominant_emotion': 'joy',
            'emotion_intensity': 0.8,
            'emotion_scores': {
                'joy': 0.8, 'trust': 0.6, 'anticipation': 0.4, 'surprise': 0.2,
                'anger': 0.0, 'disgust': 0.0, 'fear': 0.0, 'sadness': 0.0
            },
            'matched_words': ['정말', '기분', '좋고', '행복'],
            'total_words': 7,
            'matched_count': 4,
            'vad_score': {'valence': 0.8, 'arousal': 0.6, 'dominance': 0.7}
        } 