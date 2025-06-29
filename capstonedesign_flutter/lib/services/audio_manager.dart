import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:record/record.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

/// 오디오 관리자 - 마이크 충돌 방지
class AudioManager {
  static final AudioManager _instance = AudioManager._internal();
  factory AudioManager() => _instance;
  AudioManager._internal();

  // STT 관련
  late stt.SpeechToText _speech;
  bool _isListening = false;
  
  // 녹음 관련
  final Record _audioRecorder = Record();
  bool _isRecording = false;
  String? _currentRecordingPath;
  DateTime? _recordingStartTime;
  
  // 상태 관리
  bool _isInitialized = false;
  StreamController<double>? _soundLevelController;
  
  // 콜백 함수들
  Function(String)? onTextRecognized;
  Function(double)? onSoundLevelChanged;
  Function(String)? onError;
  Function(String)? onStatusChanged;
  
  /// 현재 녹음 중인지 확인
  bool get isRecording => _isRecording;

  /// 초기화
  Future<bool> initialize({
    Function(String)? onTextRecognized,
    Function(double)? onSoundLevelChanged,
    Function(String)? onError,
    Function(String)? onStatusChanged,
  }) async {
    if (_isInitialized) return true;
    
    this.onTextRecognized = onTextRecognized;
    this.onSoundLevelChanged = onSoundLevelChanged;
    this.onError = onError;
    this.onStatusChanged = onStatusChanged;
    
    try {
      // STT 초기화
      _speech = stt.SpeechToText();
      final available = await _speech.initialize(
        onError: (error) {
          print('🎤 [AudioManager] STT 에러: ${error.errorMsg}');
          // error_no_match는 정상적인 상황이므로 에러로 처리하지 않음
          if (!error.errorMsg.contains('no_match')) {
            onError?.call('STT Error: ${error.errorMsg}');
          } else {
            print('ℹ️ [AudioManager] 음성 인식 없음 (정상적인 상황)');
          }
        },
        onStatus: (status) {
          print('STT Status: $status');
          onStatusChanged?.call(status);
        },
      );
      
      if (!available) {
        onError?.call('STT 사용 불가');
        return false;
      }
      
      // 오디오 레코더 초기화
      final hasPermission = await _audioRecorder.hasPermission();
      if (!hasPermission) {
        onError?.call('마이크 권한 없음');
        return false;
      }
      
      _isInitialized = true;
      print('✅ AudioManager 초기화 성공');
      return true;
      
    } catch (e) {
      onError?.call('오디오 매니저 초기화 실패: $e');
      return false;
    }
  }

  /// 오디오 권한 확인
  Future<bool> _checkPermissions() async {
    try {
      final hasPermission = await _audioRecorder.hasPermission();
      print('🔐 [AudioManager] 오디오 권한 상태: $hasPermission');
      return hasPermission;
    } catch (e) {
      print('❌ [AudioManager] 권한 확인 실패: $e');
      return false;
    }
  }

  /// 오디오 녹음 시작
  Future<void> startRecording() async {
    try {
      print('🎤 [AudioManager] 녹음 시작 시도');
      
      if (_isRecording) {
        print('⚠️ [AudioManager] 이미 녹음 중입니다');
        return;
      }

      // 권한 확인
      final hasPermission = await _checkPermissions();
      if (!hasPermission) {
        print('❌ [AudioManager] 오디오 권한이 없습니다');
        throw Exception('오디오 권한이 필요합니다');
      }

      print('✅ [AudioManager] 오디오 권한 확인 완료');

      // 녹음 파일 경로 설정
      final directory = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      _currentRecordingPath = '${directory.path}/audio_$timestamp.m4a';
      
      print('📁 [AudioManager] 녹음 파일 경로: $_currentRecordingPath');

      // 녹음 설정 - STT와 충돌하지 않도록 별도 인스턴스 사용
      final recorder = Record();
      
      // 녹음 시작
      await recorder.start(
        path: _currentRecordingPath,
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
        samplingRate: 44100,
        numChannels: 2,
      );

      _isRecording = true;
      _recordingStartTime = DateTime.now();
      
      print('✅ [AudioManager] 녹음 시작 완료');
      print('📊 [AudioManager] 녹음 설정:');
      print('   - 인코더: AAC LC');
      print('   - 비트레이트: 128kbps');
      print('   - 샘플링 레이트: 44.1kHz');
      print('   - 채널: 2 (스테레오)');
      print('   - 시작 시간: $_recordingStartTime');
      print('   - STT와 동시 실행: ${_isListening ? "예" : "아니오"}');

    } catch (e) {
      print('❌ [AudioManager] 녹음 시작 실패: $e');
      _isRecording = false;
      rethrow;
    }
  }

  /// 현재 녹음된 오디오 데이터를 Base64로 반환
  Future<String?> getCurrentAudioData() async {
    try {
      print('🎤 [AudioManager] 현재 오디오 데이터 수집 시도');
      
      if (!_isRecording || _currentRecordingPath == null) {
        print('⚠️ [AudioManager] 녹음 중이 아니거나 파일 경로가 없습니다');
        return null;
      }

      // 녹음 중지 (임시로)
      await stopRecording();
      print('⏹️ [AudioManager] 분석을 위해 녹음 일시 중지');

      // 파일 존재 확인
      final file = File(_currentRecordingPath!);
      if (!await file.exists()) {
        print('❌ [AudioManager] 녹음 파일이 존재하지 않습니다: $_currentRecordingPath');
        return null;
      }

      // 파일 크기 확인
      final fileSize = await file.length();
      print('📊 [AudioManager] 녹음 파일 크기: $fileSize bytes');
      
      if (fileSize < 1000) {
        print('⚠️ [AudioManager] 녹음 파일이 너무 작습니다 (${fileSize} bytes)');
        print('💡 [AudioManager] 최소 1초 이상 녹음이 필요합니다');
      }

      // 파일을 Base64로 인코딩
      final bytes = await file.readAsBytes();
      final base64Audio = base64Encode(bytes);
      
      print('✅ [AudioManager] 오디오 데이터 수집 완료');
      print('📊 [AudioManager] Base64 데이터 크기: ${base64Audio.length} bytes');
      print('📊 [AudioManager] 녹음 시간: ${_recordingStartTime != null ? DateTime.now().difference(_recordingStartTime!).inSeconds : 0}초');

      // 녹음 재시작
      await startRecording();
      print('🔄 [AudioManager] 분석 후 녹음 재시작');

      return base64Audio;

    } catch (e) {
      print('❌ [AudioManager] 오디오 데이터 수집 실패: $e');
      return null;
    }
  }

  /// 녹음 중지
  Future<void> stopRecording() async {
    if (_isRecording) {
      await _audioRecorder.stop();
      _isRecording = false;
      print('🎤 멀티모달 녹음 중지');
    }
  }
  
  /// STT만 사용하는 모드 (VAD 충돌 방지)
  Future<bool> startSTTOnly({
    required String localeId,
    Duration listenFor = const Duration(seconds: 30),
    Duration pauseFor = const Duration(seconds: 3),
  }) async {
    if (!_isInitialized) {
      await initialize();
    }
    
    if (_isListening) {
      await stopSTT();
    }
    
    try {
      print('🎤 [AudioManager] STT 시작 시도');
      print('🎤 [AudioManager] 로케일: $localeId');
      print('🎤 [AudioManager] 청취 시간: ${listenFor.inSeconds}초');
      print('🎤 [AudioManager] 일시정지 시간: ${pauseFor.inSeconds}초');
      
      await _speech.listen(
        onResult: (result) {
          print('🎤 [AudioManager] STT 결과: ${result.recognizedWords} (final: ${result.finalResult})');
          if (result.finalResult) {
            final text = result.recognizedWords.trim();
            if (text.isNotEmpty) {
              print('✅ [AudioManager] 최종 텍스트 인식: "$text"');
              onTextRecognized?.call(text);
            } else {
              print('⚠️ [AudioManager] 빈 텍스트 결과');
            }
          } else {
            print('🔄 [AudioManager] 부분 텍스트 인식: "${result.recognizedWords}"');
          }
        },
        listenFor: listenFor,
        pauseFor: pauseFor,
        partialResults: true,
        cancelOnError: false,
        listenMode: stt.ListenMode.dictation,
        localeId: localeId,
        onSoundLevelChange: (level) {
          // VAD 충돌 방지를 위해 소리 레벨은 별도로 처리하지 않음
          // print('🎤 [AudioManager] 소리 레벨: $level');
        },
      );
      
      _isListening = true;
      print('✅ [AudioManager] STT 시작 성공');
      
      // STT 세션 완료 후 자동 재시작 (더 짧은 간격으로)
      final totalDuration = listenFor + pauseFor + const Duration(seconds: 1);
      print('⏰ [AudioManager] STT 자동 재시작 예약: ${totalDuration.inSeconds}초 후');
      
      Timer(totalDuration, () {
        if (_isListening) {
          print('🔄 [AudioManager] STT 세션 완료, 자동 재시작');
          startSTTOnly(
            localeId: localeId,
            listenFor: listenFor,
            pauseFor: pauseFor,
          );
        } else {
          print('⏹️ [AudioManager] STT가 중지됨, 자동 재시작 취소');
        }
      });
      
      return true;
      
    } catch (e) {
      print('❌ [AudioManager] STT 시작 실패: $e');
      onError?.call('STT 시작 실패: $e');
      return false;
    }
  }
  
  /// STT 시작 (한국어)
  Future<bool> startSTT() async {
    return await startSTTOnly(
      localeId: 'ko_KR',
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
    );
  }
  
  /// 독립적인 VAD 모드 (STT와 분리)
  Future<bool> startIndependentVAD() async {
    if (!_isInitialized) {
      await initialize();
    }
    
    if (_isRecording) {
      await stopVAD();
    }
    
    try {
      _soundLevelController = StreamController<double>();
      
      // 독립적인 오디오 스트림으로 VAD 처리
      await _audioRecorder.start(
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
        samplingRate: 44100,
      );
      
      _isRecording = true;
      
      // 주기적으로 소리 레벨 측정
      Timer.periodic(const Duration(milliseconds: 100), (timer) async {
        if (!_isRecording) {
          timer.cancel();
          return;
        }
        
        try {
          final amplitude = await _audioRecorder.getAmplitude();
          final level = _convertAmplitudeToDb(amplitude.current);
          onSoundLevelChanged?.call(level);
        } catch (e) {
          // VAD 에러는 무시 (STT에 영향 없음)
        }
      });
      
      return true;
      
    } catch (e) {
      onError?.call('VAD 시작 실패: $e');
      return false;
    }
  }
  
  /// 텍스트 기반 VAD 추정
  double estimateVADFromText(String text) {
    // 텍스트 길이, 단어 수, 특수문자 등을 기반으로 VAD 추정
    final words = text.split(' ').length;
    final length = text.length;
    final hasExclamation = text.contains('!') || text.contains('?');
    final hasEmoji = RegExp(r'[\u{1F600}-\u{1F64F}\u{1F300}-\u{1F5FF}]', unicode: true).hasMatch(text);
    
    // Valence (긍정성) - 간단한 키워드 기반
    double valence = 0.5; // 기본값
    final positiveWords = ['좋', '행복', '기쁘', '즐거', '감사', '사랑'];
    final negativeWords = ['나쁘', '슬프', '화나', '짜증', '불만', '싫'];
    
    if (positiveWords.any((word) => text.contains(word))) {
      valence = 0.8;
    } else if (negativeWords.any((word) => text.contains(word))) {
      valence = 0.2;
    }
    
    // Arousal (각성도) - 텍스트 길이와 특수문자 기반
    double arousal = 0.5;
    if (hasExclamation || hasEmoji) {
      arousal = 0.8;
    } else if (length < 10) {
      arousal = 0.3;
    }
    
    // Dominance (지배성) - 단어 수 기반
    double dominance = 0.5;
    if (words > 10) {
      dominance = 0.8; // 긴 문장 = 높은 지배성
    } else if (words < 3) {
      dominance = 0.3; // 짧은 문장 = 낮은 지배성
    }
    
    return (valence + arousal + dominance) / 3; // 평균값 반환
  }
  
  /// STT 중지
  Future<void> stopSTT() async {
    if (_isListening) {
      await _speech.stop();
      _isListening = false;
    }
  }
  
  /// VAD 중지
  Future<void> stopVAD() async {
    if (_isRecording) {
      await _audioRecorder.stop();
      _isRecording = false;
      _soundLevelController?.close();
      _soundLevelController = null;
    }
  }
  
  /// 모든 오디오 중지
  Future<void> stopAll() async {
    await stopSTT();
    await stopVAD();
    await stopRecording();
  }
  
  /// 리소스 정리
  void dispose() {
    stopAll();
    _audioRecorder.dispose();
  }
  
  /// 진폭을 데시벨로 변환
  double _convertAmplitudeToDb(double amplitude) {
    if (amplitude <= 0) return -60.0;
    return 20 * log(amplitude / 32767) / ln10;
  }
  
  // 수학 함수들
  static const double ln10 = 2.302585092994046;
  double log(double x) => x <= 0 ? 0 : x.log();
}

// double 확장 메서드
extension DoubleExtension on double {
  double log() => this <= 0 ? 0 : this.log();
} 