#!/usr/bin/env python3
"""
간단한 멀티모달 감정 분석 서버 시작 스크립트
"""

import subprocess
import sys
import time
import requests

def main():
    print("🚀 멀티모달 감정 분석 서버 시작...")
    
    try:
        # 서버 시작
        print("📡 서버를 시작합니다...")
        server_process = subprocess.Popen([
            sys.executable, "multimodal_emotion_api.py"
        ])
        
        # 서버 시작 대기
        print("⏳ 서버 시작 대기 중...")
        time.sleep(3)
        
        # 서버 상태 확인
        try:
            response = requests.get("http://localhost:5001/health", timeout=5)
            if response.status_code == 200:
                print("✅ 서버가 성공적으로 시작되었습니다!")
                print("🌐 서버 URL: http://localhost:5001")
                print("📝 API 문서: http://localhost:5001/health")
                print("\n💡 사용 방법:")
                print("   - 텍스트 감정 분석: POST /analyze_text_emotion")
                print("   - 멀티모달 분석: POST /analyze_multimodal_emotion")
                print("   - 서버 상태 확인: GET /health")
                print("   - 모킹 데이터 테스트: GET /test_mock")
                print("\n🛑 서버를 종료하려면 Ctrl+C를 누르세요.")
                
                # 서버가 종료될 때까지 대기
                server_process.wait()
                
            else:
                print(f"❌ 서버 시작 실패: {response.status_code}")
                server_process.terminate()
                
        except requests.exceptions.RequestException:
            print("❌ 서버에 연결할 수 없습니다.")
            server_process.terminate()
            
    except KeyboardInterrupt:
        print("\n🛑 서버를 종료합니다...")
        server_process.terminate()
        print("✅ 서버가 종료되었습니다.")
    except Exception as e:
        print(f"❌ 오류: {e}")

if __name__ == "__main__":
    main() 