#!/usr/bin/env python3
"""
Flutter 앱과 서버 간 연결 테스트 스크립트
"""

import requests
import json
import time
from datetime import datetime

class FlutterConnectionTester:
    def __init__(self, base_url="http://localhost:5001"):
        self.base_url = base_url
        self.test_results = []
    
    def test_server_health(self):
        """서버 상태 확인"""
        try:
            response = requests.get(f"{self.base_url}/health", timeout=5)
            if response.status_code == 200:
                print("✅ 서버 상태: 정상")
                return True
            else:
                print(f"❌ 서버 상태: 오류 ({response.status_code})")
                return False
        except Exception as e:
            print(f"❌ 서버 연결 실패: {e}")
            return False
    
    def test_text_analysis(self):
        """텍스트 분석 테스트"""
        try:
            test_text = "오늘은 정말 기분이 좋습니다!"
            payload = {
                "face_image": "",
                "audio": "",
                "text": test_text
            }
            
            response = requests.post(
                f"{self.base_url}/analyze_multimodal_emotion",
                json=payload,
                timeout=10
            )
            
            if response.status_code == 200:
                result = response.json()
                print("✅ 텍스트 분석: 성공")
                print(f"   감정 태그: {result.get('emotion_tag', 'N/A')}")
                print(f"   VAD 점수: {result.get('final_vad', 'N/A')}")
                return True
            else:
                print(f"❌ 텍스트 분석: 실패 ({response.status_code})")
                return False
                
        except Exception as e:
            print(f"❌ 텍스트 분석 오류: {e}")
            return False
    
    def test_gemini_question(self):
        """Gemini 질문 생성 테스트"""
        try:
            payload = {
                "history": [
                    {"question": "오늘 기분이 어때요?", "answer": "좋아요"},
                    {"question": "무엇이 기분을 좋게 만들었나요?", "answer": "친구와 만났어요"}
                ],
                "emotion_tag": "happy",
                "vad_score": {"valence": 0.8, "arousal": 0.6, "dominance": 0.7}
            }
            
            response = requests.post(
                f"{self.base_url}/generate_question",
                json=payload,
                timeout=15
            )
            
            if response.status_code == 200:
                result = response.json()
                print("✅ Gemini 질문 생성: 성공")
                print(f"   생성된 질문: {result.get('question', 'N/A')}")
                return True
            else:
                print(f"❌ Gemini 질문 생성: 실패 ({response.status_code})")
                return False
                
        except Exception as e:
            print(f"❌ Gemini 질문 생성 오류: {e}")
            return False
    
    def test_cbt_strategy(self):
        """CBT 전략 매핑 테스트"""
        try:
            payload = {
                "emotion_tag": "anxious",
                "vad_score": {"valence": 0.3, "arousal": 0.8, "dominance": 0.2}
            }
            
            response = requests.post(
                f"{self.base_url}/get_cbt_strategy",
                json=payload,
                timeout=10
            )
            
            if response.status_code == 200:
                result = response.json()
                print("✅ CBT 전략 매핑: 성공")
                print(f"   전략명: {result.get('name', 'N/A')}")
                return True
            else:
                print(f"❌ CBT 전략 매핑: 실패 ({response.status_code})")
                return False
                
        except Exception as e:
            print(f"❌ CBT 전략 매핑 오류: {e}")
            return False
    
    def test_mock_data(self):
        """모킹 데이터 테스트"""
        try:
            response = requests.get(f"{self.base_url}/test_mock", timeout=5)
            
            if response.status_code == 200:
                result = response.json()
                print("✅ 모킹 데이터: 성공")
                print(f"   사용 가능한 서비스: {list(result.keys())}")
                return True
            else:
                print(f"❌ 모킹 데이터: 실패 ({response.status_code})")
                return False
                
        except Exception as e:
            print(f"❌ 모킹 데이터 오류: {e}")
            return False
    
    def run_all_tests(self):
        """모든 테스트 실행"""
        print("🚀 Flutter 앱과 서버 연결 테스트 시작")
        print("=" * 50)
        
        tests = [
            ("서버 상태 확인", self.test_server_health),
            ("모킹 데이터 테스트", self.test_mock_data),
            ("텍스트 분석 테스트", self.test_text_analysis),
            ("CBT 전략 매핑 테스트", self.test_cbt_strategy),
            ("Gemini 질문 생성 테스트", self.test_gemini_question),
        ]
        
        passed = 0
        total = len(tests)
        
        for test_name, test_func in tests:
            print(f"\n📋 {test_name}...")
            if test_func():
                passed += 1
            time.sleep(1)  # 테스트 간 간격
        
        print("\n" + "=" * 50)
        print(f"📊 테스트 결과: {passed}/{total} 통과")
        
        if passed == total:
            print("🎉 모든 테스트 통과! Flutter 앱과 서버가 정상적으로 연결됩니다.")
        else:
            print("⚠️ 일부 테스트 실패. 서버 설정을 확인해주세요.")
        
        return passed == total

def main():
    # 로컬 서버 테스트
    tester = FlutterConnectionTester("http://localhost:5001")
    success = tester.run_all_tests()
    
    if not success:
        print("\n🔧 문제 해결 방법:")
        print("1. 서버가 실행 중인지 확인: python multimodal_emotion_api.py")
        print("2. 포트 5001이 사용 가능한지 확인")
        print("3. 방화벽 설정 확인")
        print("4. 네트워크 연결 상태 확인")

if __name__ == "__main__":
    main() 