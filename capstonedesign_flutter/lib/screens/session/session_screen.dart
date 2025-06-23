import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/vad_provider.dart';
import '../../providers/cbt_provider.dart';
import '../../theme/bemore_theme.dart';
import '../../models/vad_emotion.dart';
import '../analysis/analysis_result_screen.dart';

class SessionScreen extends StatefulWidget {
  const SessionScreen({super.key});

  @override
  State<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends State<SessionScreen> {
  bool _isRecording = false;
  bool _isAnalyzing = false;
  String _currentText = '';
  final TextEditingController _textController = TextEditingController();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _startSession() {
    setState(() {
      _isRecording = true;
    });
    
    // VAD Provider 초기화
    Provider.of<VADProvider>(context, listen: false).clearAllEmotions();
  }

  void _stopSession() {
    setState(() {
      _isRecording = false;
      _isAnalyzing = true;
    });

    // 분석 시작
    _analyzeEmotions();
  }

  void _analyzeEmotions() async {
    final vadProvider = Provider.of<VADProvider>(context, listen: false);
    final cbtProvider = Provider.of<CBTProvider>(context, listen: false);

    // 시뮬레이션된 감정 데이터 생성
    await Future.delayed(const Duration(seconds: 2));
    
    // 얼굴 표정 감정 (시뮬레이션)
    final facialEmotion = VADEmotion(
      valence: 0.6,
      arousal: 0.4,
      dominance: 0.5,
      timestamp: DateTime.now(),
      source: 'facial',
    );
    vadProvider.addFacialEmotion(facialEmotion);

    // 음성 감정 (시뮬레이션)
    final voiceEmotion = VADEmotion(
      valence: 0.5,
      arousal: 0.6,
      dominance: 0.4,
      timestamp: DateTime.now(),
      source: 'voice',
    );
    vadProvider.addVoiceEmotion(voiceEmotion);

    // 텍스트 감정 (시뮬레이션)
    if (_currentText.isNotEmpty) {
      final textEmotion = VADEmotion(
        valence: 0.7,
        arousal: 0.3,
        dominance: 0.6,
        timestamp: DateTime.now(),
        source: 'text',
      );
      vadProvider.addTextEmotion(textEmotion);
    }

    // 통합 감정 계산
    final combinedEmotion = vadProvider.combinedEmotion;
    if (combinedEmotion != null) {
      vadProvider.setCurrentEmotion(combinedEmotion);
      
      // CBT 피드백 생성
      cbtProvider.generateFeedbackFromEmotion(combinedEmotion);
    }

    if (mounted) {
      setState(() {
        _isAnalyzing = false;
      });

      // 결과 화면으로 이동
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const AnalysisResultScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BeMoreTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('감정 분석'),
        backgroundColor: BeMoreTheme.surfaceColor,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // 상태 표시
              _buildStatusCard(),
              
              const SizedBox(height: 32),
              
              // 카메라 뷰 (시뮬레이션)
              _buildCameraView(),
              
              const SizedBox(height: 32),
              
              // 텍스트 입력
              _buildTextInput(),
              
              const SizedBox(height: 32),
              
              // 컨트롤 버튼
              _buildControlButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: _isRecording 
                    ? BeMoreTheme.successColor 
                    : _isAnalyzing 
                        ? BeMoreTheme.warningColor 
                        : BeMoreTheme.textSecondary,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isRecording 
                        ? '감정 분석 중...'
                        : _isAnalyzing 
                            ? '분석 처리 중...'
                            : '준비 완료',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    _isRecording 
                        ? '얼굴 표정, 음성, 텍스트를 분석하고 있습니다'
                        : _isAnalyzing 
                            ? '수집된 데이터를 종합 분석하고 있습니다'
                            : '시작 버튼을 눌러 감정 분석을 시작하세요',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: BeMoreTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraView() {
    return Container(
      width: double.infinity,
      height: 300,
      decoration: BoxDecoration(
        color: BeMoreTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: BeMoreTheme.primaryColor.withOpacity(0.2),
          width: 2,
        ),
      ),
      child: _isRecording 
          ? _buildRecordingView()
          : _buildPlaceholderView(),
    );
  }

  Widget _buildRecordingView() {
    return Stack(
      children: [
        // 카메라 프리뷰 (시뮬레이션)
        Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Center(
            child: Icon(
              Icons.camera_alt,
              size: 64,
              color: Colors.white,
            ),
          ),
        ),
        
        // 감정 인식 오버레이
        Positioned(
          top: 16,
          left: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: BeMoreTheme.primaryColor.withOpacity(0.8),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.face,
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  '얼굴 인식 중',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
        
        // 음성 인식 오버레이
        Positioned(
          top: 16,
          right: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: BeMoreTheme.secondaryColor.withOpacity(0.8),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.mic,
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  '음성 분석 중',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceholderView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.camera_alt_outlined,
          size: 64,
          color: BeMoreTheme.textSecondary,
        ),
        const SizedBox(height: 16),
        Text(
          '카메라를 활성화하여\n얼굴 표정을 분석하세요',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: BeMoreTheme.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildTextInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '현재 감정이나 생각을 자유롭게 적어보세요',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _textController,
          maxLines: 4,
          enabled: !_isRecording,
          decoration: InputDecoration(
            hintText: '예: 오늘은 정말 기분이 좋다. 새로운 프로젝트를 시작하게 되어서 설렌다.',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onChanged: (value) {
            setState(() {
              _currentText = value;
            });
          },
        ),
      ],
    );
  }

  Widget _buildControlButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: _isRecording ? _stopSession : _startSession,
            style: ElevatedButton.styleFrom(
              backgroundColor: _isRecording 
                  ? BeMoreTheme.errorColor 
                  : BeMoreTheme.primaryColor,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _isRecording ? Icons.stop : Icons.play_arrow,
                  color: Colors.white,
                ),
                const SizedBox(width: 8),
                Text(
                  _isRecording ? '분석 중지' : '분석 시작',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
} 