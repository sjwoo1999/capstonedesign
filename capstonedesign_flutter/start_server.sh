#!/bin/bash

echo "🚀 멀티모달 감정 분석 서버 시작 중..."

# 가상환경 활성화
source venv/bin/activate

# 기존 서버 프로세스 종료
pkill -f "python.*run_server.py" 2>/dev/null
pkill -f "python.*multimodal_emotion_api.py" 2>/dev/null

# 서버 시작 (백그라운드)
echo "📡 서버를 백그라운드에서 시작합니다..."
nohup python -c "
import sys
import os
sys.path.append(os.getcwd())

# 서버 모듈 직접 실행
from multimodal_emotion_api import app
import logging

# 로깅 설정
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

logger.info('🚀 서버 시작 중...')
app.run(host='0.0.0.0', port=5001, debug=False)
" > server.log 2>&1 &

# 서버 시작 대기
echo "⏳ 서버 시작 대기 중..."
sleep 10

# 서버 상태 확인
if curl -s http://localhost:5001/health > /dev/null; then
    echo "✅ 서버가 성공적으로 시작되었습니다!"
    echo "🌐 서버 URL: http://192.168.0.67:5001"
    echo "📊 상태 확인: curl http://192.168.0.67:5001/health"
    echo "📝 로그 확인: tail -f server.log"
else
    echo "❌ 서버 시작 실패"
    echo "📝 로그 확인: cat server.log"
fi 