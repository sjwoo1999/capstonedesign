// lib/screens/history_screen.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/emotion_result.dart';
import 'dart:math';

class HistoryScreen extends StatelessWidget {
  final List<Map<String, dynamic>> dummyData = List.generate(7, (index) {
    return {
      'date': DateTime.now().subtract(Duration(days: 6 - index)),
      'result': EmotionResult(
        probabilities: {
          'happy': Random().nextDouble(),
          'sad': Random().nextDouble(),
          'angry': Random().nextDouble(),
          'surprised': Random().nextDouble(),
          'disgust': Random().nextDouble(),
          'fear': Random().nextDouble(),
          'neutral': Random().nextDouble(),
        },
        feedback: '',
      )
    };
  });

  HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Emotion History')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: LineChart(
          LineChartData(
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    int index = value.toInt();
                    if (index < 0 || index >= dummyData.length) {
                      return Container();
                    }
                    final date = dummyData[index]['date'] as DateTime;
                    return Text('${date.month}/${date.day}');
                  },
                ),
              ),
            ),
            lineBarsData: [
              LineChartBarData(
                isCurved: true,
                barWidth: 2,
                spots: List.generate(
                  dummyData.length,
                  (i) => FlSpot(
                    i.toDouble(),
                    dummyData[i]['result'].probabilities['happy'] ?? 0.0,
                  ),
                ),
                color: Colors.orange,
              ),
              LineChartBarData(
                isCurved: true,
                barWidth: 2,
                spots: List.generate(
                  dummyData.length,
                  (i) => FlSpot(
                    i.toDouble(),
                    dummyData[i]['result'].probabilities['sad'] ?? 0.0,
                  ),
                ),
                color: Colors.blueAccent,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
