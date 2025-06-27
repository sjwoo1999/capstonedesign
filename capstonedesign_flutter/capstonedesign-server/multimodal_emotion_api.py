import os
import json
import logging
from datetime import datetime
from logging.handlers import RotatingFileHandler
from flask import Flask, request, jsonify
from flask_cors import CORS

# 서비스 임포트
from services.face_emotion_service import FaceEmotionService
from services.audio_emotion_service import AudioEmotionService
from services.text_emotion_service import TextEmotionService
from services.vad_fusion_service import VADFusionService
from services.cbt_strategy_service import CBTStrategyService
from services.gpt_service import GPTService
from services.pdf_report_service import PDFReportService

# 로깅 설정
import logging
from logging.handlers import RotatingFileHandler

# 로그 디렉토리 생성
log_dir = "logs"
if not os.path.exists(log_dir):
    os.makedirs(log_dir)

# 로거 설정
logger = logging.getLogger(__name__)
logger.setLevel(logging.DEBUG)

# 콘솔 핸들러 (INFO 레벨)
console_handler = logging.StreamHandler()
console_handler.setLevel(logging.INFO)
console_formatter = logging.Formatter(
    '%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
console_handler.setFormatter(console_formatter)

# 파일 핸들러 (DEBUG 레벨)
file_handler = RotatingFileHandler(
    os.path.join(log_dir, 'server.log'), 
    maxBytes=10*1024*1024,  # 10MB
    backupCount=5
)
file_handler.setLevel(logging.DEBUG)
file_formatter = logging.Formatter(
    '%(asctime)s - %(name)s - %(levelname)s - %(funcName)s:%(lineno)d - %(message)s'
)
file_handler.setFormatter(file_formatter)

# 핸들러 추가
logger.addHandler(console_handler)
logger.addHandler(file_handler)

# Flask 앱 로거 설정
app_logger = logging.getLogger('werkzeug')
app_logger.setLevel(logging.INFO)
app_logger.addHandler(console_handler)
app_logger.addHandler(file_handler)

app = Flask(__name__)
CORS(app) 