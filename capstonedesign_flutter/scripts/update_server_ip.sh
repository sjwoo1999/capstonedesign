#!/bin/bash

# 현재 IP 주소 감지
CURRENT_IP=$(ifconfig | grep "inet " | grep -v 127.0.0.1 | head -1 | awk '{print $2}')

if [ -z "$CURRENT_IP" ]; then
    echo "❌ IP 주소를 찾을 수 없습니다."
    exit 1
fi

echo "🔍 현재 IP 주소: $CURRENT_IP"

# .env 파일 업데이트
ENV_FILE=".env"
BACKUP_FILE=".env.backup"

# 백업 생성
if [ -f "$ENV_FILE" ]; then
    cp "$ENV_FILE" "$BACKUP_FILE"
    echo "📋 기존 .env 파일 백업: $BACKUP_FILE"
fi

# 새로운 .env 파일 생성
cat > "$ENV_FILE" << INNER_EOF
EMOTION_API_URL=http://$CURRENT_IP:5001
SERVER_URL=http://$CURRENT_IP:5001
INNER_EOF

echo "✅ .env 파일 업데이트 완료: $CURRENT_IP:5001"

# 서버 연결 테스트
echo "🧪 서버 연결 테스트 중..."
if curl -s -o /dev/null -w "%{http_code}" "http://$CURRENT_IP:5001/health" | grep -q "200"; then
    echo "✅ 서버 연결 성공!"
else
    echo "❌ 서버 연결 실패. 서버가 실행 중인지 확인하세요."
fi
