import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:jovial_misc/circular_buffer.dart';

final graphData = [
  /*
  GraphData(Colors.black, CircularBuffer(Float32List(50000))), // x values
  GraphData(
      Colors.red.shade700, CircularBuffer(Float32List(50000))), // y values
  GraphData(
      Colors.green.shade700, CircularBuffer(Float32List(50000))), // y values
  GraphData(
      Colors.amber.shade700, CircularBuffer(Float32List(50000))), // y values
  GraphData(
      Colors.blue.shade700, CircularBuffer(Float32List(50000))), // y values
   */
];

class GraphData {
  final Color color;
  final List<double> points;
  GraphData(this.color, this.points);
}

class Graph extends StatefulWidget {
  const Graph({super.key});

  @override
  State<Graph> createState() => GraphState();
}

class GraphState extends State<Graph> {
  late Timer timer;

  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(const Duration(milliseconds: 1000), (timer) {
      setState(() {});
    });
  }

  @override
  void dispose() {
    super.dispose();
    timer.cancel();
  }

  @override
  Widget build(BuildContext context) {
    final xCoords = graphData[0].points;
    final xMin = xCoords.isEmpty ? 0 : xCoords.first.floor();
    return Padding(
        padding: const EdgeInsets.only(top: 12, right: 12),
        child: LineChart(LineChartData(
            minY: 0,
            maxY: 8,
            minX: xMin + 0,
            maxX: xMin + 5,
            titlesData: const FlTitlesData(
              rightTitles: AxisTitles(),
              topTitles: AxisTitles(),
            ),
            lineBarsData: [
              makeBarData(graphData[0], graphData[1]),
              makeBarData(graphData[0], graphData[2]),
              makeBarData(graphData[0], graphData[3]),
              makeBarData(graphData[0], graphData[4]),
            ])));
  }

  LineChartBarData makeBarData(GraphData xValues, GraphData yValues) {
    double f(double y) => log(y + 1) / ln10;
    final spots = List.generate(yValues.points.length,
        (i) => FlSpot(xValues.points[i], f(yValues.points[i])));
    return LineChartBarData(
        spots: spots,
        dotData: const FlDotData(show: false),
        barWidth: 2,
        isCurved: false,
        color: yValues.color);
  }
}
