import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class EmotionChart extends StatelessWidget {
  final Map<String, double> probabilities;

  const EmotionChart({super.key, required this.probabilities});

  @override
  Widget build(BuildContext context) {
    if (probabilities.isEmpty) {
      return Center(
        child:
            Text("감정 분석 결과 없음", style: GoogleFonts.poppins(color: Colors.grey)),
      );
    }

    final sortedEntries = probabilities.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return ListView(
      children: sortedEntries.map((entry) {
        final label = entry.key;
        final value = entry.value;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "$label (${(value * 100).toStringAsFixed(1)}%)",
                style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: value,
                  backgroundColor: Colors.grey.shade300,
                  color: Colors.deepPurple,
                  minHeight: 12,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
