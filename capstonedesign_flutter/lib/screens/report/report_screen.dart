// lib/screens/report/report_screen.dart
import 'package:flutter/material.dart';
import '../../models/emotion_result.dart';
import '../../constants/emotion_constants.dart';
import 'package:fl_chart/fl_chart.dart';

class ReportScreen extends StatelessWidget {
  final EmotionResult result;

  const ReportScreen({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final top = result.topEmotion;
    final emoji = emotionLabelMap[top] ?? top;
    final nickname = emotionNicknameMap[top] ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('분석 결과')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 16),
            Text(
              '감정 분석 결과',
              style: Theme.of(context).textTheme.headline6,
            ),
            const SizedBox(height: 16),
            Text(
              '$emoji  $nickname',
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              '자신의 감정을 인식하는 것은 건강한 마음의 출발점입니다.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
            const SizedBox(height: 32),
            Expanded(child: _buildBarChart()),
          ],
        ),
      ),
    );
  }

  Widget _buildBarChart() {
    final sortedEntries = result.probabilities.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceEvenly,
        maxY: 1.0,
        barTouchData: BarTouchData(enabled: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 28),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= sortedEntries.length) return const SizedBox.shrink();
                return Text(emotionLabelMap[sortedEntries[index].key] ?? sortedEntries[index].key,
                    style: const TextStyle(fontSize: 12));
              },
            ),
          ),
        ),
        barGroups: List.generate(
          sortedEntries.length,
          (index) => BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: sortedEntries[index].value,
                width: 18,
                color: Colors.deepPurple,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
