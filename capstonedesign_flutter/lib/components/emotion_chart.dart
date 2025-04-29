// lib/components/emotion_chart.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class EmotionChart extends StatelessWidget {
  final Map<String, double> probabilities;

  const EmotionChart({super.key, required this.probabilities});

  @override
  Widget build(BuildContext context) {
    final data = probabilities.entries.toList();

    if (data.isEmpty) {
      return const Center(child: Text('데이터 없음'));
    }

    return BarChart(
      BarChartData(
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= data.length) return Container();
                return Text(data[value.toInt()].key);
              },
            ),
          ),
        ),
        barGroups: List.generate(data.length, (i) {
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(toY: data[i].value, width: 12),
            ],
          );
        }),
      ),
    );
  }
}
