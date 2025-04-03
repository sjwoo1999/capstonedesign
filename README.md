# 💡 마음온도 (MindThermo) - 감정 인식 기반 정서 케어 서비스

![App Screenshot](screenshots/mindthermo_ui.png) <!-- UI 캡처 이미지 위치 -->

## 📖 프로젝트 개요

`마음온도`는 실시간 표정 분석을 통해 사용자의 감정을 시각화하고, 나아가 상담 및 자가 정서 케어에 활용 가능한 감정 데이터를 수집, 분석, 제공하는 정서 인식 기반 서비스입니다.  
기본적으로 전면 카메라로 표정을 분석하고, (옵션으로) 음성 텍스트 변환을 통해 대화 기반의 감정 분석도 병행합니다.

---

## 🧠 주요 기능

| 기능 | 설명 |
|------|------|
| 실시간 표정 기반 감정 인식 | 전면 카메라를 활용하여 표정을 0.5초 간격으로 분석 |
| 감정 확률 막대그래프 | 분석된 감정 분포를 실시간으로 시각화 |
| UX 문구 및 프라이버시 고려 | "영상을 저장하지 않아요" 등의 문구 제공 |
| 히스토리 화면 (준비 중) | 감정 변화 기록 시각화 (기록 기능은 추후 확장 예정) |

---

## 🏗️ 시스템 아키텍처 (CoT 흐름)

### 1. 입력
- `CameraImage`: Flutter의 `camera` 패키지를 활용하여 전면 카메라의 프레임을 실시간 스트리밍
- 프레임은 0.5초 간격으로 추출됨

### 2. 전처리
- 카메라 이미지 YUV 또는 BGRA8888 → Grayscale 변환
- 중앙 70% 영역 Crop → 224x224 리사이즈
- JPEG로 인코딩 후 base64 문자열로 Flask API로 전송

### 3. 서버 측 분석 (Python Flask)
- 모델: Keras 기반 감정 분류 모델 (`emotion_model.h5`)
- 얼굴 인식: dlib의 `get_frontal_face_detector()` 사용
- 예측된 softmax 확률값 → 감정 label + confidence 추출
- 응답 예시:
  ```json
  {
    "emotion": "Surprise",
    "confidence": 0.7645
  }
  ```

## 4. 클라이언트 처리 (Flutter)

Flutter 앱에서는 다음과 같은 흐름으로 감정 분석 결과를 처리하고 UI에 반영합니다.

### 📥 입력 처리
- `CameraImage`를 실시간 스트림 형태로 받아옴 (`CameraController.startImageStream`)
- 0.5초 간격으로 프레임 캡처 → `_convertToBase64()`에서 다음 수행:
  - 이미지 포맷 (YUV420, BGRA8888) 에 따라 처리 분기
  - grayscale 변환 및 중앙 crop → 224x224로 resize
  - JPEG 인코딩 후 base64로 전송

### 📤 API 호출 및 상태 관리
- `EmotionAPIService.sendImageForAnalysis()`:
  - Flask 서버에 POST 요청 (`/predict`)
  - 성공 시: `emotion`, `confidence`, `probabilities` 필드 포함 응답
  - 실패 시: `{"error": "No face detected"}` 형태 응답
- `EmotionProvider`에서 응답 상태를 전역 관리:
  - 성공 시 → `EmotionResult`로 감정 결과 저장
  - 실패 시 → `errorMessage`에 에러 문자열 저장

### 🎨 UI 반영
- `RealtimeCameraScreen` 화면 구성:
  - 좌측: 카메라 프리뷰 (`CameraPreview`)
  - 우측: 감정 확률 막대 차트 (`EmotionChart`)
  - 하단: 실시간 감정 결과 텍스트 or 에러 메시지 출력

### 🛡️ 프라이버시 UX 문구
- 사용자 신뢰를 위한 문구 삽입:
  @@@text
  🙌 마음을 분석하는 중이에요.
  분석은 실시간으로 진행되며 영상은 저장되지 않아요.
  @@@

---

## 🧪 감정 모델 상세 정보

| 항목 | 내용 |
|------|------|
| 프레임워크 | TensorFlow + Keras |
| 모델 파일 | `emotion_model.h5` |
| 입력 | 64x64 grayscale 얼굴 이미지 |
| 출력 | 7개 감정 분류: Angry, Disgust, Fear, Happy, Sad, Surprise, Neutral |
| 사용 라이브러리 | OpenCV, dlib (face detection), NumPy |

---

## 📂 프로젝트 구조

@@@
capstonedesign_flutter/
│
├── lib/
│   ├── models/            # EmotionResult 모델 정의
│   ├── providers/         # EmotionProvider 상태관리
│   ├── services/          # API 호출
│   ├── screens/           # UI 화면들
│   └── widgets/           # EmotionChart 등 위젯
│
├── .env                   # API 주소 정의
├── pubspec.yaml
└── main.dart              # 앱 진입점
@@@

---

## 📈 향후 확장 계획

| 항목 | 내용 |
|------|------|
| 음성 → 텍스트 감정 분석 | 실시간 음성 텍스트 분석 병행 |
| 감정 히스토리 기록 | 시간에 따른 감정 변화 시각화 |
| 정서 피드백 | 감정 상태 기반 멘트 추천 시스템 |
| 정서 리포트 생성 | 주간/월간 감정 리포트 자동 생성 (PDF 등) |

---

## ✨ 기타 특징

- 💡 **앱 이름 변경**: Emotion Analyzer → **마음온도 (MindThermo)**
  - 사용자 정서적 공감을 끌어내기 위한 브랜딩 전략
- 🧠 **UX 개선**:
  - Google Fonts, 감정 색상 맵핑, 고급스러운 라운딩 카드 UI 적용
- 🧪 **Debug Print 향상**:
  - 분석 성공/실패 로그에 타임스탬프와 시도 횟수 포함

---

## 🧑‍💻 개발자 정보

| 이름 | 역할 |
|------|------|
| 우성종 | 전체 기획 및 개발, 모델 구축, UI/UX 리디자인, 서버 연동 |

---

## 📮 문의 및 라이선스

- 📧 Email: sjwoo1999@korea.ac.kr
- 캡스톤디자인 프로젝트

---