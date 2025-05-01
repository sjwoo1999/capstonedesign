import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../../models/emotion_result.dart';
import '../../providers/emotion_provider.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EmotionProvider>();
    final result = provider.result;

    return Scaffold(
      appBar: AppBar(title: const Text('Emotion History')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: result == null
            ? const Center(
                child: Text(
                  '아직 분석 기록이 없습니다.',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              )
            : buildChart(result),
      ),
    );
  }

  Widget buildChart(EmotionResult result) {
    final data = result.probabilities.entries.toList();

    return BarChart(
      BarChartData(
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                int index = value.toInt();
                if (index < 0 || index >= data.length) return Container();
                return Text(data[index].key);
              },
            ),
          ),
        ),
        barGroups: List.generate(
          data.length,
          (i) => BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(toY: data[i].value, width: 12),
            ],
          ),
        ),
      ),
    );
  }
}
