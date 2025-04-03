from flask import Flask, request, jsonify
import numpy as np
import cv2
import base64
from keras.models import load_model
import dlib

app = Flask(__name__)

# 모델 로드
emotion_model = load_model("models/emotion_model.h5", compile=False)
face_detector = dlib.get_frontal_face_detector()
expression_labels = ['Angry', 'Disgust', 'Fear', 'Happy', 'Sad', 'Surprise', 'Neutral']

def preprocess_face(image):
    gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
    faces = face_detector(gray)
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

@app.route('/predict', methods=['POST'])
def predict():
    data = request.get_json()

    try:
        img_data = data["image"]
        img_bytes = base64.b64decode(img_data)
        img_array = np.frombuffer(img_bytes, np.uint8)
        img = cv2.imdecode(img_array, cv2.IMREAD_COLOR)
    except Exception as e:
        return jsonify({'error': f'Invalid image data: {str(e)}'}), 400

    face = preprocess_face(img)
    if face is None:
        return jsonify({'error': 'No face detected'}), 400

    try:
        preds = emotion_model.predict(face)[0]
        emotion_idx = int(np.argmax(preds))
        emotion_label = expression_labels[emotion_idx]
        confidence = float(preds[emotion_idx])
        
        # ✅ 감정별 확률 추가
        probabilities = {
            expression_labels[i]: float(preds[i]) for i in range(len(preds))
        }

        return jsonify({
            'emotion': emotion_label,
            'confidence': confidence,
            'probabilities': probabilities
        })

    except Exception as e:
        return jsonify({'error': f'Model inference failed: {str(e)}'}), 500

if __name__ == '__main__':
    print("🚀 Flask API 서버 실행 중... (http://0.0.0.0:5001)")
    app.run(host='0.0.0.0', port=5001)