# 멀티모달 감정 분석 서비스 패키지
"""
멀티모달 감정 분석 서비스 모듈

이 패키지는 다음과 같은 서비스들을 포함합니다:
- face_emotion_service: 얼굴 감정 분석
- audio_emotion_service: 음성 감정 분석 (Whisper STT + Prosody)
- text_emotion_service: 텍스트 감정 분석 (NRC Lexicon)
- vad_fusion_service: VAD Score 융합
- cbt_strategy_service: CBT 전략 매핑
- gpt_service: GPT/LLM 응답 생성
- pdf_report_service: PDF 리포트 생성
"""

__version__ = "1.0.0"
__author__ = "Capstone Design Team"
__description__ = "Multimodal Emotion Analysis Services" 