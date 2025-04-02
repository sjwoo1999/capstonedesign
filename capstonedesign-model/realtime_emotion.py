import cv2
import numpy as np
import dlib
from keras.models import load_model
from keras.preprocessing.image import img_to_array
import time

# 모델 경로
emotion_model_path = 'models/emotion_model.h5'
landmark_path = 'assets/shape_predictor_68_face_landmarks.dat'

# 감정 라벨 정의
emotion_labels = ['Angry', 'Disgust', 'Fear', 'Happy', 'Sad', 'Surprise', 'Neutral']

# 모델 로딩 (중요!)
emotion_classifier = load_model(emotion_model_path, compile=False)
face_detector = dlib.get_frontal_face_detector()
landmark_predictor = dlib.shape_predictor(landmark_path)

# 웹캠 스트리밍 시작
cap = cv2.VideoCapture(0)
print("[INFO] 웹캠 스트리밍 시작...")

while True:
    ret, frame = cap.read()
    if not ret:
        print("프레임을 가져올 수 없습니다.")
        break

    gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
    faces = face_detector(gray)

    for face in faces:
        x, y, w, h = face.left(), face.top(), face.width(), face.height()
        roi = gray[y:y+h, x:x+w]

        try:
            roi = cv2.resize(roi, (64, 64))
        except:
            continue

        roi = roi.astype("float") / 255.0
        roi = img_to_array(roi)
        roi = np.expand_dims(roi, axis=-1)
        roi = np.expand_dims(roi, axis=0)

        preds = emotion_classifier.predict(roi, verbose=0)[0]
        emotion_probability = np.max(preds)
        label = emotion_labels[preds.argmax()]

        cv2.rectangle(frame, (x, y), (x + w, y + h), (100, 100, 250), 2)
        cv2.putText(frame, f"{label}: {emotion_probability:.2f}", (x, y - 10),
                    cv2.FONT_HERSHEY_SIMPLEX, 0.9, (0, 255, 0), 2)

        for (i, (emotion, prob)) in enumerate(zip(emotion_labels, preds)):
            text = f"{emotion}: {prob:.2f}"
            bar_width = int(prob * 150)
            cv2.rectangle(frame, (10, 30 + i * 25), (10 + bar_width, 50 + i * 25), (255, 100, 100), -1)
            cv2.putText(frame, text, (10, 47 + i * 25), cv2.FONT_HERSHEY_SIMPLEX, 0.5, (255, 255, 255), 1)

    cv2.imshow("Real-Time Emotion Recognition", frame)

    if cv2.waitKey(1) & 0xFF == ord('q'):
        break

cap.release()
cv2.destroyAllWindows()
