# BeMore: Multimodal Emotion Analysis & CBT Report

## Overview
BeMore is an AI-powered partner for emotion recognition and self-reflection. It provides VAD-based multimodal emotion analysis and CBT (Cognitive Behavioral Therapy) feedback reports, helping users understand and reflect on their emotions.

---

## Social Background
Modern people, especially the MZ generation, often struggle to express emotions and face psychological barriers to mental health care. Most existing emotion analysis services are text-based or limited to six basic categories, lacking integrated interpretation of facial, vocal, and complex signals.

---

## Problem Definition
While systems exist for collecting and analyzing emotional data, few connect these results to emotional reflection and feedback. There is a lack of continuous emotion recognition and self-understanding, and nonverbal signals (facial expressions, intonation) are often ignored. Connections to psychological interpretation models are also rare.

---

## Key Proposal
BeMore analyzes facial expressions, voice tone, and text to generate VAD-based emotion vectors. It provides CBT-based feedback and daily emotion reflection reports, supporting ongoing self-awareness and mental care.

---

## Main Features
- Multimodal emotion recognition (face, voice, text)
- VAD (Valence, Arousal, Dominance) emotion vector output
- CBT-based personalized feedback
- Emotion trend visualization and automatic PDF report generation

---

## Data Flow Diagram
1. Onboarding screens
2. Counseling session screens
3. Analysis result screens

---

## Tech Stack
- **Infra:** Cloud, REST API
- **Frontend:** Flutter (mobile/web)
- **Backend:** Flask (Python)
- **AI/ML Module:** TensorFlow, dlib, OpenAI Whisper
- **Generative AI:** VAD Lexicon, FACS, MediaPipe, BERT

---

## Expected Impact
- Automated emotion reflection → Enhanced self-awareness
- CBT-based feedback → Improved psychological resilience
- Emotion trend reports → Habitual self-reflection
- Precise analysis of nonverbal signals

---

## References
- Mehrabian & Russell (1974). VAD Emotional Model
- Paul Ekman & Friesen (1978). Facial Action Coding System (FACS)
- MediaPipe Face Landmarker – Google AI
- Whisper – OpenAI Speech-to-Text
- VAD Lexicon – NRC (Saif Mohammad)
- CBT feedback structure (APA, Clinical Practice)
- Korean papers: "MTCNN-based Facial Emotion Recognition System", "AI-based Regression BERT Model"

---

## Author & Advisor
- **Woo Seongjong** (Dept. of Computer Convergence Software, Korea Univ.)
- **Advisor:** Prof. Minseok Seo

---