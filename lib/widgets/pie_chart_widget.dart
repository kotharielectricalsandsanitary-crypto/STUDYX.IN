import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';

import '../providers/graph_provider.dart';

class PieChartWidget extends StatelessWidget {
  final String range;

  const PieChartWidget({
    super.key,
    required this.range,
  });

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<GraphProvider>(context);

    final data = provider.studyDistribution;

    final colors = [
      const Color(0xFF3B82F6),
      const Color(0xFF06B6D4),
      const Color(0xFF8B5CF6),
      const Color(0xFFF59E0B),
      const Color(0xFF10B981),
    ];

    int colorIndex = 0;

    return Column(
      children: [
        Expanded(
          child: PieChart(
            PieChartData(
              centerSpaceRadius: 55,
              sectionsSpace: 4,
              sections: data.entries.map((entry) {
                final color = colors[colorIndex % colors.length];
                colorIndex++;

                return PieChartSectionData(
                  value: entry.value,
                  title: "${entry.value.toInt()}%",
                  radius: 90,
                  color: color,
                  titleStyle: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                );
              }).toList(),
            ),
          ),
        ),

        const SizedBox(height: 20),

        Wrap(
          spacing: 16,
          runSpacing: 10,
          alignment: WrapAlignment.center,
          children: List.generate(
            data.length,
            (index) {
              final entry = data.entries.elementAt(index);

              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: colors[index % colors.length],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    entry.key,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}