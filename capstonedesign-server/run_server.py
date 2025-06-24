#!/usr/bin/env python3
"""
멀티모달 감정 분석 서버 통합 실행 스크립트
서버 실행과 테스트를 하나의 스크립트로 통합
"""

import os
import sys
import time
import subprocess
import threading
import requests
import json
from datetime import datetime

# 서버 설정
SERVER_HOST = "localhost"
SERVER_PORT = 5001
SERVER_URL = f"http://{SERVER_HOST}:{SERVER_PORT}"

def print_banner():
    """배너 출력"""
    print("=" * 60)
    print("🎭 멀티모달 감정 분석 서버")
    print("AI 기반 종합 감정 분석 및 CBT 전략 제안")
    print("=" * 60)
    print(f"📅 시작 시간: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print()

def check_dependencies():
    """의존성 확인"""
    print("🔍 의존성 확인 중...")
    
    required_packages = [
        'flask', 'numpy', 'cv2', 'tensorflow', 
        'whisper', 'librosa', 'reportlab', 'requests'
    ]
    
    missing_packages = []
    
    for package in required_packages:
        try:
            if package == 'cv2':
                import cv2
            elif package == 'whisper':
                import whisper
            else:
                __import__(package.replace('-', '_'))
            print(f"  ✅ {package}")
        except ImportError:
            print(f"  ❌ {package} (설치 필요)")
            missing_packages.append(package)
    
    if missing_packages:
        print(f"\n⚠️  다음 패키지들이 설치되지 않았습니다:")
        for pkg in missing_packages:
            print(f"   - {pkg}")
        print(f"\n📦 설치 명령어:")
        print(f"   pip install -r requirements.txt")
        return False
    
    print("✅ 모든 의존성이 설치되어 있습니다.")
    return True

def start_server():
    """서버 시작"""
    print("🚀 서버 시작 중...")
    
    try:
        # 서버 프로세스 시작 (stdout, stderr를 파이프로 연결)
        server_process = subprocess.Popen([
            sys.executable, "multimodal_emotion_api.py"
        ], stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        
        # 서버 시작 대기 (모델 로딩 시간 고려)
        print("⏳ 서버 시작 대기 중... (모델 로딩 시간 포함)")
        
        # 단계별 확인 (5초, 10초, 15초, 20초)
        for i in range(4):
            time.sleep(5)
            print(f"   {i+1}/4 단계 확인 중... ({5*(i+1)}초 경과)")
            
            # 프로세스 상태 확인
            if server_process.poll() is not None:
                # 프로세스가 종료된 경우
                stdout, stderr = server_process.communicate()
                print(f"❌ 서버 프로세스가 종료되었습니다.")
                if stderr:
                    print(f"📝 오류 메시지: {stderr}")
                return None
            
            try:
                response = requests.get(f"{SERVER_URL}/health", timeout=5)
                if response.status_code == 200:
                    print("✅ 서버가 성공적으로 시작되었습니다!")
                    print(f"🌐 서버 URL: {SERVER_URL}")
                    return server_process
            except requests.exceptions.RequestException:
                if i < 3:  # 마지막 시도가 아니면 계속 대기
                    continue
                else:
                    print("❌ 서버에 연결할 수 없습니다.")
                    # 프로세스 종료 시도
                    server_process.terminate()
                    return None
        
        # 20초 후에도 연결되지 않으면 실패
        print("❌ 서버 시작 시간 초과 (20초)")
        server_process.terminate()
        return None
            
    except Exception as e:
        print(f"❌ 서버 시작 오류: {e}")
        return None

def run_tests():
    """테스트 실행"""
    print("\n🧪 자동 테스트 실행 중...")
    
    # 1. 서버 상태 확인
    print("1️⃣ 서버 상태 확인")
    try:
        response = requests.get(f"{SERVER_URL}/health")
        if response.status_code == 200:
            print("   ✅ 서버 정상")
        else:
            print("   ❌ 서버 오류")
            return False
    except Exception as e:
        print(f"   ❌ 연결 실패: {e}")
        return False
    
    # 2. 모킹 데이터 테스트
    print("2️⃣ 모킹 데이터 테스트")
    try:
        response = requests.get(f"{SERVER_URL}/test_mock")
        if response.status_code == 200:
            data = response.json()
            print(f"   ✅ 얼굴: {data['face_service']['emotion']}")
            print(f"   ✅ 음성: {data['audio_service']['transcript'][:20]}...")
            print(f"   ✅ 텍스트: {data['text_service']['dominant_emotion']}")
        else:
            print("   ❌ 모킹 테스트 실패")
            return False
    except Exception as e:
        print(f"   ❌ 모킹 테스트 오류: {e}")
        return False
    
    # 3. 텍스트 감정 분석 테스트
    print("3️⃣ 텍스트 감정 분석 테스트")
    try:
        test_text = "오늘은 정말 기분이 좋고 행복합니다."
        response = requests.post(
            f"{SERVER_URL}/analyze_text_emotion",
            json={"text": test_text},
            headers={"Content-Type": "application/json"}
        )
        
        if response.status_code == 200:
            data = response.json()
            if data.get('success'):
                print(f"   ✅ 감정: {data.get('dominant_emotion', 'N/A')}")
                print(f"   ✅ VAD: {data.get('vad_score', {})}")
            else:
                print(f"   ❌ 분석 실패: {data.get('error', 'Unknown')}")
                return False
        else:
            print(f"   ❌ 요청 실패: {response.status_code}")
            return False
    except Exception as e:
        print(f"   ❌ 텍스트 분석 오류: {e}")
        return False
    
    # 4. 멀티모달 분석 테스트
    print("4️⃣ 멀티모달 분석 테스트")
    try:
        test_data = {
            "text": "오늘은 정말 기분이 좋고 행복합니다. 친구들과 즐거운 시간을 보냈어요."
        }
        response = requests.post(
            f"{SERVER_URL}/analyze_multimodal_emotion",
            json=test_data,
            headers={"Content-Type": "application/json"}
        )
        
        if response.status_code == 200:
            data = response.json()
            print(f"   ✅ 최종 감정: {data.get('emotion_tag', 'N/A')}")
            print(f"   ✅ CBT 전략: {data.get('cbt_strategy', {}).get('name', 'N/A')}")
            print(f"   ✅ GPT 응답: {data.get('gpt_response', '')[:50]}...")
            print(f"   ✅ PDF 리포트: {'생성됨' if data.get('pdf_report') else '생성되지 않음'}")
        else:
            print(f"   ❌ 멀티모달 분석 실패: {response.status_code}")
            return False
    except Exception as e:
        print(f"   ❌ 멀티모달 분석 오류: {e}")
        return False
    
    print("\n🎉 모든 테스트가 성공적으로 완료되었습니다!")
    return True

def show_api_examples():
    """API 사용 예시 출력"""
    print("\n📚 API 사용 예시:")
    print("=" * 40)
    
    print("1️⃣ 텍스트 감정 분석:")
    print(f"curl -X POST {SERVER_URL}/analyze_text_emotion \\")
    print('  -H "Content-Type: application/json" \\')
    print('  -d \'{"text": "오늘은 정말 기분이 좋습니다."}\'')
    
    print("\n2️⃣ CBT 전략 매핑:")
    print(f"curl -X POST {SERVER_URL}/get_cbt_strategy \\")
    print('  -H "Content-Type: application/json" \\')
    print('  -d \'{"emotion_tag": "happy", "vad_score": {"valence": 0.8, "arousal": 0.6, "dominance": 0.7}}\'')
    
    print("\n3️⃣ 멀티모달 분석:")
    print(f"curl -X POST {SERVER_URL}/analyze_multimodal_emotion \\")
    print('  -H "Content-Type: application/json" \\')
    print('  -d \'{"text": "분석할 텍스트"}\'')
    
    print("\n4️⃣ 서버 상태 확인:")
    print(f"curl {SERVER_URL}/health")
    
    print("\n5️⃣ 모킹 데이터 테스트:")
    print(f"curl {SERVER_URL}/test_mock")

def interactive_menu():
    """대화형 메뉴"""
    while True:
        print("\n" + "=" * 40)
        print("🎛️  멀티모달 감정 분석 서버 메뉴")
        print("=" * 40)
        print("1. 서버 상태 확인")
        print("2. 모킹 데이터 테스트")
        print("3. 텍스트 감정 분석 테스트")
        print("4. CBT 전략 매핑 테스트")
        print("5. GPT 응답 생성 테스트")
        print("6. 멀티모달 분석 테스트")
        print("7. API 사용 예시 보기")
        print("8. 서버 종료")
        print("0. 종료")
        
        choice = input("\n선택하세요 (0-8): ").strip()
        
        if choice == "0":
            print("👋 서버를 종료합니다.")
            break
        elif choice == "1":
            try:
                response = requests.get(f"{SERVER_URL}/health")
                if response.status_code == 200:
                    print("✅ 서버가 정상적으로 실행 중입니다.")
                    print(f"📊 {response.json()}")
                else:
                    print(f"❌ 서버 오류: {response.status_code}")
            except Exception as e:
                print(f"❌ 서버 연결 실패: {e}")
        
        elif choice == "2":
            try:
                response = requests.get(f"{SERVER_URL}/test_mock")
                if response.status_code == 200:
                    data = response.json()
                    print("✅ 모킹 데이터 테스트 성공!")
                    print(f"📝 얼굴: {data['face_service']['emotion']}")
                    print(f"📝 음성: {data['audio_service']['transcript']}")
                    print(f"📝 텍스트: {data['text_service']['dominant_emotion']}")
                else:
                    print(f"❌ 테스트 실패: {response.status_code}")
            except Exception as e:
                print(f"❌ 오류: {e}")
        
        elif choice == "3":
            text = input("분석할 텍스트를 입력하세요: ").strip()
            if text:
                try:
                    response = requests.post(
                        f"{SERVER_URL}/analyze_text_emotion",
                        json={"text": text},
                        headers={"Content-Type": "application/json"}
                    )
                    if response.status_code == 200:
                        data = response.json()
                        if data.get('success'):
                            print(f"✅ 감정: {data.get('dominant_emotion', 'N/A')}")
                            print(f"📊 VAD: {data.get('vad_score', {})}")
                        else:
                            print(f"❌ 분석 실패: {data.get('error', 'Unknown')}")
                    else:
                        print(f"❌ 요청 실패: {response.status_code}")
                except Exception as e:
                    print(f"❌ 오류: {e}")
            else:
                print("❌ 텍스트를 입력해주세요.")
        
        elif choice == "4":
            try:
                response = requests.post(
                    f"{SERVER_URL}/get_cbt_strategy",
                    json={
                        "emotion_tag": "happy",
                        "vad_score": {"valence": 0.8, "arousal": 0.6, "dominance": 0.7}
                    },
                    headers={"Content-Type": "application/json"}
                )
                if response.status_code == 200:
                    data = response.json()
                    if data.get('success'):
                        strategy = data.get('strategy', {})
                        print(f"✅ 전략: {strategy.get('name', 'N/A')}")
                        print(f"📋 기법: {', '.join(strategy.get('techniques', [])[:3])}")
                    else:
                        print(f"❌ 전략 매핑 실패: {data.get('error', 'Unknown')}")
                else:
                    print(f"❌ 요청 실패: {response.status_code}")
            except Exception as e:
                print(f"❌ 오류: {e}")
        
        elif choice == "5":
            try:
                response = requests.post(
                    f"{SERVER_URL}/generate_gpt_response",
                    json={
                        "emotion_tag": "happy",
                        "vad_score": {"valence": 0.8, "arousal": 0.6, "dominance": 0.7},
                        "context": "오늘 친구들과 즐거운 시간을 보냈습니다."
                    },
                    headers={"Content-Type": "application/json"}
                )
                if response.status_code == 200:
                    data = response.json()
                    if data.get('success'):
                        print("✅ GPT 응답 생성 성공!")
                        print(f"🤖 {data.get('response', '')[:100]}...")
                    else:
                        print(f"❌ GPT 응답 생성 실패: {data.get('error', 'Unknown')}")
                else:
                    print(f"❌ 요청 실패: {response.status_code}")
            except Exception as e:
                print(f"❌ 오류: {e}")
        
        elif choice == "6":
            text = input("분석할 텍스트를 입력하세요 (엔터시 기본값 사용): ").strip()
            if not text:
                text = "오늘은 정말 기분이 좋고 행복합니다. 친구들과 즐거운 시간을 보냈어요."
            
            try:
                response = requests.post(
                    f"{SERVER_URL}/analyze_multimodal_emotion",
                    json={"text": text},
                    headers={"Content-Type": "application/json"}
                )
                if response.status_code == 200:
                    data = response.json()
                    print("✅ 멀티모달 분석 성공!")
                    print(f"🎯 최종 감정: {data.get('emotion_tag', 'N/A')}")
                    print(f"📈 최종 VAD: {data.get('final_vad', {})}")
                    print(f"🧠 CBT 전략: {data.get('cbt_strategy', {}).get('name', 'N/A')}")
                    print(f"🤖 GPT 응답: {data.get('gpt_response', '')[:100]}...")
                else:
                    print(f"❌ 멀티모달 분석 실패: {response.status_code}")
            except Exception as e:
                print(f"❌ 오류: {e}")
        
        elif choice == "7":
            show_api_examples()
        
        elif choice == "8":
            print("🛑 서버를 종료합니다...")
            break
        
        else:
            print("❌ 잘못된 선택입니다. 0-8 사이의 숫자를 입력해주세요.")

def main():
    """메인 함수"""
    print_banner()
    
    # 1. 의존성 확인
    if not check_dependencies():
        print("\n❌ 필요한 의존성이 설치되지 않았습니다.")
        print("다음 명령어로 의존성을 설치해주세요:")
        print("pip install -r requirements.txt")
        return
    
    # 2. 서버 시작
    server_process = start_server()
    if not server_process:
        print("❌ 서버 시작에 실패했습니다.")
        return
    
    try:
        # 3. 자동 테스트 실행
        if run_tests():
            print("\n🎉 서버가 성공적으로 실행되었습니다!")
            print(f"🌐 서버 URL: {SERVER_URL}")
            print("\n💡 다음 중 하나를 선택하세요:")
            print("   - 대화형 메뉴 사용 (권장)")
            print("   - 직접 API 호출")
            print("   - 브라우저에서 http://localhost:5001/health 접속")
            
            # 4. 대화형 메뉴 시작
            interactive_menu()
        else:
            print("❌ 테스트 중 오류가 발생했습니다.")
    
    except KeyboardInterrupt:
        print("\n\n⚠️  사용자에 의해 중단되었습니다.")
    
    finally:
        # 5. 서버 종료
        if server_process:
            print("🛑 서버를 종료합니다...")
            server_process.terminate()
            server_process.wait()
            print("✅ 서버가 종료되었습니다.")

if __name__ == "__main__":
    main() 