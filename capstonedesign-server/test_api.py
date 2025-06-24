#!/usr/bin/env python3
"""
멀티모달 감정 분석 API 테스트 스크립트
"""

import requests
import json
import base64
import time

# API 서버 URL
BASE_URL = "http://localhost:5001"

def test_health():
    """서버 상태 확인"""
    print("🔍 서버 상태 확인...")
    try:
        response = requests.get(f"{BASE_URL}/health")
        if response.status_code == 200:
            print("✅ 서버가 정상적으로 실행 중입니다.")
            print(f"📊 서버 정보: {response.json()}")
            return True
        else:
            print(f"❌ 서버 상태 확인 실패: {response.status_code}")
            return False
    except requests.exceptions.ConnectionError:
        print("❌ 서버에 연결할 수 없습니다. 서버가 실행 중인지 확인해주세요.")
        return False

def test_mock_data():
    """모킹 데이터 테스트"""
    print("\n🧪 모킹 데이터 테스트...")
    try:
        response = requests.get(f"{BASE_URL}/test_mock")
        if response.status_code == 200:
            data = response.json()
            print("✅ 모킹 데이터 테스트 성공!")
            print(f"📝 얼굴 감정: {data['face_service']['emotion']}")
            print(f"📝 음성 전사: {data['audio_service']['transcript']}")
            print(f"📝 텍스트 감정: {data['text_service']['dominant_emotion']}")
            print(f"📝 융합 감정: {data['vad_fusion_service']['emotion_tag']}")
            return True
        else:
            print(f"❌ 모킹 데이터 테스트 실패: {response.status_code}")
            return False
    except Exception as e:
        print(f"❌ 모킹 데이터 테스트 오류: {e}")
        return False

def test_text_emotion():
    """텍스트 감정 분석 테스트"""
    print("\n📝 텍스트 감정 분석 테스트...")
    test_texts = [
        "오늘은 정말 기분이 좋고 행복합니다.",
        "너무 화가 나서 참을 수 없어요.",
        "무섭고 불안한 마음이 듭니다.",
        "슬프고 우울한 기분입니다."
    ]
    
    for i, text in enumerate(test_texts, 1):
        print(f"  테스트 {i}: '{text}'")
        try:
            response = requests.post(
                f"{BASE_URL}/analyze_text_emotion",
                json={"text": text},
                headers={"Content-Type": "application/json"}
            )
            
            if response.status_code == 200:
                data = response.json()
                if data.get('success'):
                    print(f"    ✅ 감정: {data.get('dominant_emotion', 'N/A')}")
                    print(f"    📊 VAD: {data.get('vad_score', {})}")
                else:
                    print(f"    ❌ 분석 실패: {data.get('error', 'Unknown error')}")
            else:
                print(f"    ❌ 요청 실패: {response.status_code}")
                
        except Exception as e:
            print(f"    ❌ 오류: {e}")
        
        time.sleep(0.5)  # 요청 간 간격

def test_cbt_strategy():
    """CBT 전략 매핑 테스트"""
    print("\n🧠 CBT 전략 매핑 테스트...")
    test_cases = [
        {"emotion": "happy", "vad": {"valence": 0.8, "arousal": 0.6, "dominance": 0.7}},
        {"emotion": "angry", "vad": {"valence": 0.2, "arousal": 0.9, "dominance": 0.8}},
        {"emotion": "sad", "vad": {"valence": 0.2, "arousal": 0.3, "dominance": 0.2}},
        {"emotion": "anxious", "vad": {"valence": 0.3, "arousal": 0.8, "dominance": 0.3}}
    ]
    
    for i, case in enumerate(test_cases, 1):
        print(f"  테스트 {i}: {case['emotion']} 감정")
        try:
            response = requests.post(
                f"{BASE_URL}/get_cbt_strategy",
                json={
                    "emotion_tag": case['emotion'],
                    "vad_score": case['vad']
                },
                headers={"Content-Type": "application/json"}
            )
            
            if response.status_code == 200:
                data = response.json()
                if data.get('success'):
                    strategy = data.get('strategy', {})
                    print(f"    ✅ 전략: {strategy.get('name', 'N/A')}")
                    print(f"    📋 기법: {', '.join(strategy.get('techniques', [])[:2])}")
                else:
                    print(f"    ❌ 전략 매핑 실패: {data.get('error', 'Unknown error')}")
            else:
                print(f"    ❌ 요청 실패: {response.status_code}")
                
        except Exception as e:
            print(f"    ❌ 오류: {e}")
        
        time.sleep(0.5)

def test_gpt_response():
    """GPT 응답 생성 테스트"""
    print("\n🤖 GPT 응답 생성 테스트...")
    test_case = {
        "emotion_tag": "happy",
        "vad_score": {"valence": 0.8, "arousal": 0.6, "dominance": 0.7},
        "context": "오늘 친구들과 즐거운 시간을 보냈습니다."
    }
    
    try:
        response = requests.post(
            f"{BASE_URL}/generate_gpt_response",
            json=test_case,
            headers={"Content-Type": "application/json"}
        )
        
        if response.status_code == 200:
            data = response.json()
            if data.get('success'):
                print("✅ GPT 응답 생성 성공!")
                print(f"🤖 모델: {data.get('model', 'N/A')}")
                print(f"💬 응답: {data.get('response', '')[:100]}...")
            else:
                print(f"❌ GPT 응답 생성 실패: {data.get('error', 'Unknown error')}")
        else:
            print(f"❌ 요청 실패: {response.status_code}")
            
    except Exception as e:
        print(f"❌ 오류: {e}")

def test_multimodal_analysis():
    """멀티모달 분석 테스트 (텍스트만)"""
    print("\n🎯 멀티모달 분석 테스트 (텍스트만)...")
    
    # 간단한 테스트 데이터
    test_data = {
        "text": "오늘은 정말 기분이 좋고 행복합니다. 친구들과 즐거운 시간을 보냈어요."
    }
    
    try:
        response = requests.post(
            f"{BASE_URL}/analyze_multimodal_emotion",
            json=test_data,
            headers={"Content-Type": "application/json"}
        )
        
        if response.status_code == 200:
            data = response.json()
            print("✅ 멀티모달 분석 성공!")
            print(f"📅 타임스탬프: {data.get('timestamp', 'N/A')}")
            print(f"📊 요청 데이터: {data.get('request_data', {})}")
            print(f"📝 텍스트 감정: {data.get('text_emotion', 'N/A')}")
            print(f"🎯 최종 감정: {data.get('emotion_tag', 'N/A')}")
            print(f"📈 최종 VAD: {data.get('final_vad', {})}")
            print(f"🧠 CBT 전략: {data.get('cbt_strategy', {}).get('name', 'N/A')}")
            print(f"🤖 GPT 응답: {data.get('gpt_response', '')[:100]}...")
            print(f"📄 PDF 리포트: {'생성됨' if data.get('pdf_report') else '생성되지 않음'}")
        else:
            print(f"❌ 멀티모달 분석 실패: {response.status_code}")
            print(f"📝 응답: {response.text}")
            
    except Exception as e:
        print(f"❌ 오류: {e}")

def main():
    """메인 테스트 함수"""
    print("🚀 멀티모달 감정 분석 API 테스트 시작")
    print("=" * 50)
    
    # 1. 서버 상태 확인
    if not test_health():
        print("\n❌ 서버가 실행되지 않았습니다. 먼저 서버를 시작해주세요.")
        print("   python multimodal_emotion_api.py")
        return
    
    # 2. 모킹 데이터 테스트
    test_mock_data()
    
    # 3. 텍스트 감정 분석 테스트
    test_text_emotion()
    
    # 4. CBT 전략 매핑 테스트
    test_cbt_strategy()
    
    # 5. GPT 응답 생성 테스트
    test_gpt_response()
    
    # 6. 멀티모달 분석 테스트
    test_multimodal_analysis()
    
    print("\n" + "=" * 50)
    print("✅ 모든 테스트 완료!")
    print("\n💡 추가 테스트:")
    print("   - 얼굴 이미지 분석: 실제 base64 이미지 데이터로 테스트")
    print("   - 음성 분석: 실제 base64 오디오 데이터로 테스트")
    print("   - PDF 리포트: 생성된 base64 PDF 데이터 확인")

if __name__ == "__main__":
    main() 