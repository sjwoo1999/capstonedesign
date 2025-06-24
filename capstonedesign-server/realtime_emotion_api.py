import os
import csv
from flask import Flask, request, jsonify
import numpy as np
import cv2
from keras.models import load_model
import dlib
import base64
import socket

app = Flask(__name__)

# 얼굴 감정 분석 모델 및 dlib detector 로드
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

# NRC Lexicon 기반 한글 감정 분석
LEXICON_PATH = os.path.join(os.path.dirname(__file__), 'lexicon', 'Korean-NRC-EmoLex.txt')
korean_lexicon = {}
lexicon_emotions = []
with open(LEXICON_PATH, encoding='utf-8') as f:
    reader = csv.DictReader(f, delimiter='\t')
    lexicon_emotions = [col for col in reader.fieldnames if col not in ('English Word', 'Korean Word')]
    for row in reader:
        word = row['Korean Word'].strip()
        if word:
            korean_lexicon[word] = {emotion: int(row[emotion]) for emotion in lexicon_emotions}

def analyze_korean_text_emotion(text):
    words = text.strip().split()
    scores = {emotion: 0 for emotion in lexicon_emotions}
    count = {emotion: 0 for emotion in lexicon_emotions}
    for word in words:
        if word in korean_lexicon:
            for emotion in lexicon_emotions:
                scores[emotion] += korean_lexicon[word][emotion]
                count[emotion] += 1
    avg_scores = {emotion: (scores[emotion] / count[emotion]) if count[emotion] > 0 else 0 for emotion in lexicon_emotions}
    return avg_scores

@app.route('/analyze_text_emotion', methods=['POST'])
def analyze_text_emotion():
    data = request.get_json()
    text = data.get('text', '').strip()
    if not text:
        return jsonify({'error': 'No text provided'}), 400
    result = analyze_korean_text_emotion(text)
    return jsonify({'result': result})

@app.route('/whoami', methods=['GET'])
def whoami():
    ip_address = socket.gethostbyname(socket.gethostname())
    return jsonify({'ip': ip_address})

@app.route('/health', methods=['GET'])
def health_check():
    return jsonify({
        'status': 'healthy',
        'model_loaded': emotion_model is not None,
        'face_detector_loaded': face_detector is not None
    })

if __name__ == '__main__':
    print("🚀 Flask API 서버 실행 중... (http://0.0.0.0:5001)")
    app.run(host='0.0.0.0', port=5001) 