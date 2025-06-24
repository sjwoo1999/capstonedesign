# 멀티모달 감정 분석 서버

AI 기반 멀티모달 감정 분석 및 CBT 전략 제안 서버입니다. 얼굴 표정, 음성, 텍스트를 종합적으로 분석하여 개인화된 감정 관리 전략을 제공합니다.

## 🏗️ 아키텍처

```
multimodal_emotion_api.py          # 메인 Flask API 서버
├── services/
│   ├── face_emotion_service.py    # 얼굴 감정 분석
│   ├── audio_emotion_service.py   # Whisper STT + Prosody 분석
│   ├── text_emotion_service.py    # NRC Lexicon 기반 텍스트 분석
│   ├── vad_fusion_service.py      # VAD Score 융합
│   ├── cbt_strategy_service.py    # CBT 전략 매핑
│   ├── gpt_service.py             # GPT/LLM 응답 생성
│   └── pdf_report_service.py      # PDF 리포트 생성
├── models/                        # 감정 분석 모델
├── lexicon/                       # NRC Lexicon 데이터
└── assets/                        # 기타 자산 파일
```

## 🚀 주요 기능

### 1. 멀티모달 감정 분석
- **얼굴 표정 분석**: CNN 기반 감정 분류 (7가지 감정)
- **음성 분석**: Whisper STT + Prosody 특성 추출
- **텍스트 분석**: NRC Lexicon 기반 감정 점수 계산

### 2. VAD Score 융합
- Valence (긍정성), Arousal (각성도), Dominance (지배성) 기반 통합 분석
- 모달리티별 신뢰도 가중 융합
- 최종 감정 태그 생성

### 3. CBT 전략 매핑
- 감정별 맞춤형 인지행동치료 전략
- VAD Score 기반 개인화된 권장사항
- 단계별 실습 활동 제안

### 4. AI 응답 생성
- GPT 기반 개인화된 조언
- 멀티모달 분석 결과 종합 리포트
- 한국어 자연어 응답

### 5. PDF 리포트 생성
- 종합 분석 결과 리포트
- CBT 전략 상세 가이드
- 개인화된 권장사항 포함

## 📋 API 명세

### 메인 API: `/analyze_multimodal_emotion`

**Request:**
```json
{
  "face_image": "<base64 string>",
  "audio": "<base64 string>",
  "text": "분석할 텍스트"
}
```

**Response:**
```json
{
  "timestamp": "2024-01-01T12:00:00",
  "request_data": {
    "has_face": true,
    "has_audio": true,
    "has_text": false
  },
  "face_emotion": "Happy",
  "face_vad": {"valence": 0.9, "arousal": 0.7, "dominance": 0.8},
  "transcript": "안녕하세요, 오늘은 정말 기분이 좋습니다.",
  "prosody": {"pitch_mean": 150.0, "energy_mean": 0.3},
  "audio_vad": {"valence": 0.7, "arousal": 0.6, "dominance": 0.5},
  "text_emotion": "joy",
  "text_vad": {"valence": 0.8, "arousal": 0.6, "dominance": 0.7},
  "final_vad": {"valence": 0.8, "arousal": 0.6, "dominance": 0.7},
  "emotion_tag": "happy",
  "cbt_strategy": {
    "name": "긍정적 감정 유지 전략",
    "techniques": ["긍정적 경험 확장하기", "성취감 기록하기"],
    "exercises": ["긍정적 순간 사진 찍기", "감사 편지 쓰기"]
  },
  "gpt_response": "현재 기분이 좋으시군요! 이런 긍정적인 감정을...",
  "pdf_report": "<base64 string>"
}
```

### 개별 서비스 API

- `POST /analyze_face_emotion`: 얼굴 감정 분석
- `POST /analyze_audio_emotion`: 음성 감정 분석
- `POST /analyze_text_emotion`: 텍스트 감정 분석
- `POST /fuse_vad_scores`: VAD Score 융합
- `POST /get_cbt_strategy`: CBT 전략 매핑
- `POST /generate_gpt_response`: GPT 응답 생성
- `POST /generate_pdf_report`: PDF 리포트 생성
- `GET /health`: 서버 상태 확인
- `GET /test_mock`: 모킹 데이터 테스트

## 🛠️ 설치 및 실행

### 방법 1: 통합 실행 스크립트 (권장) ⭐

```bash
# 1. 의존성 설치
pip install -r requirements.txt

# 2. 통합 실행 (서버 + 테스트 + 대화형 메뉴)
python run_server.py
```

### 방법 2: 간단한 서버 시작

```bash
# 1. 의존성 설치
pip install -r requirements.txt

# 2. 서버 시작
python start.py
```

### 방법 3: 수동 실행

```bash
# 1. 의존성 설치
pip install -r requirements.txt

# 2. 환경 변수 설정 (선택사항)
export OPENAI_API_KEY="your_openai_api_key_here"

# 3. 서버 실행
python multimodal_emotion_api.py

# 4. 새 터미널에서 테스트 실행
python test_api.py
```

서버가 `http://localhost:5001`에서 실행됩니다.

## 🎛️ 통합 실행 스크립트 기능

`run_server.py`는 다음 기능을 제공합니다:

1. **의존성 자동 확인**: 필요한 패키지 설치 여부 확인
2. **서버 자동 시작**: Flask 서버 자동 실행
3. **자동 테스트**: 모든 API 엔드포인트 자동 테스트
4. **대화형 메뉴**: 
   - 서버 상태 확인
   - 모킹 데이터 테스트
   - 텍스트 감정 분석 테스트
   - CBT 전략 매핑 테스트
   - GPT 응답 생성 테스트
   - 멀티모달 분석 테스트
   - API 사용 예시 보기
5. **자동 서버 종료**: Ctrl+C로 안전한 종료

## 📊 데이터 처리 정책

- **원본 데이터 보존**: 이미지, 음성 파일은 저장하지 않음
- **임시 처리**: 메모리 또는 임시 파일에서만 일시 처리
- **즉시 폐기**: 분석 완료 후 원본 데이터 즉시 삭제
- **결과만 저장**: 분석 결과와 리포트만 반환

## 🔧 설정 및 커스터마이징

### 모델 경로 설정
```python
# services/face_emotion_service.py
face_service = FaceEmotionService(model_path="path/to/your/model.h5")

# services/audio_emotion_service.py
audio_service = AudioEmotionService(model_name="base")  # or "small", "medium", "large"

# services/text_emotion_service.py
text_service = TextEmotionService(lexicon_path="path/to/lexicon.txt")
```

### VAD 융합 가중치 조정
```python
# services/vad_fusion_service.py
self.modality_weights = {
    'face': 0.4,      # 얼굴 표정 가중치
    'audio': 0.3,     # 음성 prosody 가중치
    'text': 0.3       # 텍스트 감정 가중치
}
```

### CBT 전략 커스터마이징
```python
# services/cbt_strategy_service.py
self.emotion_strategies = {
    'custom_emotion': {
        'name': '커스텀 전략',
        'techniques': ['기법1', '기법2'],
        'exercises': ['활동1', '활동2']
    }
}
```

## 🧪 테스트

### 자동 테스트 (통합 스크립트 사용)
```bash
python run_server.py
# 자동으로 모든 테스트가 실행됩니다
```

### 수동 테스트
```bash
# 모킹 데이터 테스트
curl http://localhost:5001/test_mock

# 텍스트 감정 분석 테스트
curl -X POST http://localhost:5001/analyze_text_emotion \
  -H "Content-Type: application/json" \
  -d '{"text": "오늘은 정말 기분이 좋습니다."}'

# 멀티모달 분석 테스트
curl -X POST http://localhost:5001/analyze_multimodal_emotion \
  -H "Content-Type: application/json" \
  -d '{"text": "오늘은 정말 기분이 좋습니다."}'
```

## 📝 로그 및 모니터링

서버는 다음 정보를 로깅합니다:
- 요청 처리 상태
- 각 서비스별 분석 진행 상황
- 오류 및 예외 상황
- 성능 메트릭

## 🔒 보안 고려사항

- API 키는 환경 변수로 관리
- 원본 데이터는 저장하지 않음
- HTTPS 사용 권장 (프로덕션 환경)
- 입력 데이터 검증 및 sanitization

## 🤝 기여하기

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## 📄 라이선스

이 프로젝트는 MIT 라이선스 하에 배포됩니다.

## 📞 지원

문제가 있거나 질문이 있으시면 이슈를 생성해 주세요.

---

**Capstone Design Team** - 멀티모달 감정 분석 서버 v1.0.0