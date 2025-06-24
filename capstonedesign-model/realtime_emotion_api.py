from flask import Flask, request, jsonify
from flask_socketio import SocketIO, emit, disconnect
from flask_cors import CORS
import numpy as np
import cv2
import base64
from keras.models import load_model
import dlib
import socket
import jwt
import os
import logging
import time
from datetime import datetime

# 로깅 설정
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = Flask(__name__)
app.config['SECRET_KEY'] = os.environ.get('JWT_SECRET', 'your-secret-key-here')

# CORS 설정
CORS(app, origins=['http://localhost:3001', 'https://stockweather-frontend.vercel.app'], supports_credentials=True)

# SocketIO 설정 (프론트엔드와 동기화)
socketio = SocketIO(app, 
    cors_allowed_origins=['http://localhost:3001', 'https://stockweather-frontend.vercel.app'],
    ping_timeout=20,
    ping_interval=25,
    upgrade_timeout=10,
    transports=['websocket', 'polling'],
    max_http_buffer_size=1024*1024,  # 1MB
    logger=True,
    engineio_logger=True
)

# 모델 로드
emotion_model = load_model("models/emotion_model.h5", compile=False)
face_detector = dlib.get_frontal_face_detector()
expression_labels = ['Angry', 'Disgust', 'Fear', 'Happy', 'Sad', 'Surprise', 'Neutral']

# 연결된 클라이언트 관리
connected_clients = {}

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

# JWT 토큰 검증 함수
def verify_jwt_token(token):
    try:
        if not token:
            logger.warning("JWT 토큰이 제공되지 않았습니다.")
            return None
        
        # Bearer 토큰에서 실제 토큰 추출
        if token.startswith('Bearer '):
            token = token[7:]
        
        # JWT_SECRET 확인
        secret_key = app.config['SECRET_KEY']
        if not secret_key or secret_key == 'your-secret-key-here':
            logger.warning("JWT_SECRET이 설정되지 않았습니다. 기본값을 사용합니다.")
            # 개발 환경에서는 기본값 허용
            if os.environ.get('NODE_ENV') == 'production':
                return None
        
        payload = jwt.decode(token, secret_key, algorithms=['HS256'])
        logger.info(f"JWT 토큰 검증 성공: {payload.get('sub', 'unknown')}")
        return payload
        
    except jwt.ExpiredSignatureError:
        logger.warning("JWT 토큰이 만료되었습니다.")
        return None
    except jwt.InvalidTokenError as e:
        logger.warning(f"JWT 토큰이 유효하지 않습니다: {e}")
        return None
    except Exception as e:
        logger.error(f"JWT 토큰 검증 중 오류 발생: {e}")
        return None

# 안정적인 이벤트 전송 함수 (재시도 포함)
def emit_with_retry(socket_id, event, data, max_retries=3):
    attempt = 0
    delay = 1000
    while attempt < max_retries:
        try:
            if socket_id in connected_clients:
                socketio.emit(event, {**data, 'socketId': socket_id}, room=socket_id)
                logger.info(f"[Emit Retry] {event} 성공 (시도 {attempt + 1}): {socket_id}")
                return True
        except Exception as err:
            logger.error(f"[Emit Retry] {event} 실패 (시도 {attempt + 1}): {err}")
        time.sleep(delay / 1000)
        delay *= 2
        attempt += 1
    logger.error(f"[Emit Retry] {event} 최종 실패: {socket_id}")
    return False

# 헬스체크 엔드포인트
@app.route('/health', methods=['GET'])
def health_check():
    logger.info("[Health] 헬스체크 요청 수신")
    return jsonify({
        'status': 'ok',
        'timestamp': datetime.now().isoformat(),
        'connected_clients': len(connected_clients),
        'server': 'Flask-SocketIO'
    }), 200

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

# 서버 IP를 알려주는 엔드포인트
@app.route('/whoami', methods=['GET'])
def whoami():
    ip_address = socket.gethostbyname(socket.gethostname())
    return jsonify({'ip': ip_address})

# SocketIO 이벤트 핸들러들

@socketio.on('connect')
def handle_connect():
    logger.info(f"[SocketIO] 클라이언트 연결 시도: {request.sid}")
    
    # 개발 환경에서 JWT 검증 우회 옵션
    skip_auth = os.environ.get('SKIP_JWT_AUTH', 'false').lower() == 'true'
    
    if not skip_auth:
        # JWT 토큰 검증
        token = request.args.get('token') or request.headers.get('Authorization')
        payload = verify_jwt_token(token)
        
        if not payload:
            logger.warning(f"[SocketIO] 인증 실패: {request.sid}")
            emit('auth_error', {'message': 'JWT token required or invalid'})
            disconnect()
            return
    else:
        logger.info(f"[SocketIO] 개발 환경: JWT 검증 우회됨")
        payload = {'sub': 'dev-user', 'dev': True}
    
    # 클라이언트 정보 저장
    connected_clients[request.sid] = {
        'user': payload,
        'connected_at': datetime.now(),
        'socket': request
    }
    
    logger.info(f"[SocketIO] 클라이언트 연결 성공: {request.sid}, 사용자: {payload.get('sub', 'unknown')}")
    
    # 연결 확인 이벤트 전송
    emit('connectionConfirmed', {
        'socketId': request.sid,
        'timestamp': datetime.now().isoformat(),
        'user': payload.get('sub', 'unknown')
    })
    
    # 현재 연결 상태 로깅
    logger.info(f"[SocketIO] 현재 연결 수: {len(connected_clients)}")

@socketio.on('disconnect')
def handle_disconnect():
    logger.info(f"[SocketIO] 클라이언트 연결 해제: {request.sid}")
    
    if request.sid in connected_clients:
        del connected_clients[request.sid]
    
    logger.info(f"[SocketIO] 현재 연결 수: {len(connected_clients)}")

@socketio.on('message')
def handle_message(data):
    logger.info(f"[SocketIO] 메시지 수신: {request.sid} - {data}")
    emit('message', f'Echo: {data}')

@socketio.on('ping')
def handle_ping():
    logger.debug(f"[SocketIO] Ping 수신: {request.sid}")
    emit('pong', {
        'timestamp': datetime.now().isoformat(),
        'socketId': request.sid
    })

# HTTP를 통한 이벤트 전송 엔드포인트 (서버리스 환경 대응)
@app.route('/emit', methods=['POST'])
def emit_event():
    try:
        data = request.get_json()
        socket_id = data.get('socketId')
        event_name = data.get('eventName')
        event_data = data.get('data', {})
        
        if not socket_id or not event_name:
            return jsonify({'error': 'socketId and eventName are required'}), 400
        
        logger.info(f"[HTTP Emit] 이벤트 전송 요청: {socket_id} - {event_name}")
        
        success = emit_with_retry(socket_id, event_name, event_data)
        
        if success:
            return jsonify({'success': True, 'message': 'Event sent successfully'})
        else:
            return jsonify({'success': False, 'error': 'Failed to send event'}), 500
            
    except Exception as e:
        logger.error(f"[HTTP Emit] 오류 발생: {e}")
        return jsonify({'success': False, 'error': str(e)}), 500

# 연결 상태 모니터링
def log_connection_status():
    logger.info(f"[SocketIO] 연결 상태 체크: {len(connected_clients)}명 연결 중")
    for sid, client_info in connected_clients.items():
        logger.debug(f"  - {sid}: {client_info['user'].get('sub', 'unknown')}")

# 30초마다 연결 상태 체크
@socketio.on('connect')
def start_status_monitoring():
    import threading
    def monitor():
        while True:
            time.sleep(30)
            log_connection_status()
    
    monitor_thread = threading.Thread(target=monitor, daemon=True)
    monitor_thread.start()

if __name__ == '__main__':
    # 환경변수 설정 확인
    jwt_secret = os.environ.get('JWT_SECRET', 'your-secret-key-here')
    skip_auth = os.environ.get('SKIP_JWT_AUTH', 'false').lower() == 'true'
    
    logger.info("🚀 Flask-SocketIO 서버 실행 중... (http://0.0.0.0:5001)")
    logger.info("📡 SocketIO 서버: ws://0.0.0.0:5001")
    logger.info("🏥 헬스체크: http://0.0.0.0:5001/health")
    logger.info(f"🔐 JWT_SECRET 설정: {'있음' if jwt_secret != 'your-secret-key-here' else '기본값 사용'}")
    logger.info(f"🔓 JWT 검증 우회: {'활성화' if skip_auth else '비활성화'}")
    
    # 개발 환경에서 JWT 검증 우회 활성화
    if not os.environ.get('JWT_SECRET'):
        logger.warning("⚠️ JWT_SECRET이 설정되지 않았습니다. 개발 환경에서는 SKIP_JWT_AUTH=true로 설정하세요.")
    
    socketio.run(app, host='0.0.0.0', port=5001, debug=True, allow_unsafe_werkzeug=True)