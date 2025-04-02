import os
import cv2
import dlib
import numpy as np
from keras.models import load_model

# === 1. 경로 기반 설정 ===
# 현재 파일 기준으로 프로젝트 루트 경로 가져오기
BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# 모델 경로 정의
emotion_model_path = os.path.join(BASE_DIR, 'models', 'emotion_model.hdf5')
shape_predictor_path = os.path.join(BASE_DIR, 'assets', 'shape_predictor_68_face_landmarks.dat')
haar_cascade_path = os.path.join(BASE_DIR, 'assets', 'haarcascade_frontalface_default.xml')

# === 2. 모델 및 클래스 로드 ===
emotion_model = load_model(emotion_model_path, compile=False)
landmark_predictor = dlib.shape_predictor(shape_predictor_path)
face_detector = cv2.CascadeClassifier(haar_cascade_path)

emotion_labels = ['Angry', 'Disgust', 'Fear', 'Happy', 'Sad', 'Surprise', 'Neutral']

# === 3. 이미지 분석 함수 ===
def analyze_emotion(image_path):
    image = cv2.imread(image_path)
    gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)

    faces = face_detector.detectMultiScale(gray, 1.3, 5)

    results = []

    for (x, y, w, h) in faces:
        roi_gray = gray[y:y+h, x:x+w]
        roi_gray = cv2.resize(roi_gray, (48, 48))
        roi_gray = roi_gray.astype("float") / 255.0
        roi_gray = np.expand_dims(roi_gray, axis=-1)
        roi_gray = np.expand_dims(roi_gray, axis=0)

        preds = emotion_model.predict(roi_gray)[0]
        top_emotion = emotion_labels[np.argmax(preds)]
        confidence = np.max(preds)

        results.append({
            'topEmotion': top_emotion,
            'confidence': float(confidence)
        })

    return results


# === 4. 테스트 코드 ===
if __name__ == '__main__':
    test_image_path = os.path.join(BASE_DIR, 'test_images', 'sample.jpg')  # 원하는 이미지 경로
    result = analyze_emotion(test_image_path)
    print("분석 결과:", result)
