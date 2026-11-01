import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class GraphCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<FlSpot>? lineSpots;
  final List<BarChartGroupData>? barGroups;
  final bool isBarChart;

  const GraphCard({
    super.key,
    required this.title,
    required this.subtitle,
    this.lineSpots,
    this.barGroups,
    this.isBarChart = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xff111111),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white10,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(.08),
            blurRadius: 25,
            spreadRadius: 2,
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            subtitle,
            style: const TextStyle(
              color: Colors.white54,
            ),
          ),

          const SizedBox(height: 25),

          SizedBox(
            height: 260,
            child: isBarChart
                ? _buildBarChart()
                : _buildLineChart(),
          ),
        ],
      ),
    );
  }

  Widget _buildLineChart() {
    return LineChart(
      LineChartData(
        minX: 0,
        maxX: 6,
        minY: 0,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) {
            return const FlLine(
              color: Colors.white10,
              strokeWidth: 1,
            );
          },
        ),
        borderData: FlBorderData(show: false),

        titlesData: FlTitlesData(
          topTitles: const AxisTitles(),
          rightTitles: const AxisTitles(),

          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
            ),
          ),

          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
            ),
          ),
        ),

        lineBarsData: [

          LineChartBarData(
            spots: lineSpots ?? [],

            isCurved: true,

            barWidth: 4,

            color: Colors.cyanAccent,

            dotData: const FlDotData(show: true),

            belowBarData: BarAreaData(
              show: true,
              color: Colors.cyanAccent.withOpacity(.15),
            ),
          ),

        ],
      ),
    );
  }

  Widget _buildBarChart() {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,

        borderData: FlBorderData(show: false),

        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
        ),

        titlesData: FlTitlesData(
          topTitles: const AxisTitles(),
          rightTitles: const AxisTitles(),
        ),

        barGroups: barGroups ?? [],
      ),
    );
  }
}