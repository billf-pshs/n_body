import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:jovial_misc/circular_buffer.dart';

/*
 *  This file has some debugging code.  It can be used to draw a graph
 *  of the position and acceleration of the different objects
 *  orbiting around.
 *
 *  For someone doing numerical analysis, understanding the size of the
 *  numbers being dealt with can be a big help.  A graph is a great
 *  tool for this.
 */

final graphData = [
  /*

  To graph the velocity and acceleration of the four orbiting
  bodies, un-comment these four statements:

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

/**
 * A little data holder to hold the graph data for a single
 * orbiting body's data along one axis.  We graph the points
 * starting at the beginning of the points list.
 */
class GraphData {
  final Color color;
  final List<double> points;
  GraphData(this.color, this.points);
}

/**
 * A widget to display a set of graphs.
 */
class Graph extends StatefulWidget {
  const Graph({super.key});

  @override
  State<Graph> createState() => GraphState();
}

/**
 * The real widget for displaying a graph, as required by the
 * Flutter framework for widgets that hold information (also
 * known of as "state".
 **/
class GraphState extends State<Graph> {
  late Timer timer;

  @override
  void initState() {
    super.initState();
    // Update the displayed graph once a second.  Displaying a graph is
    // pretty time-consuming, so we don't want to do this too often.
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
        //
        // LineChart and LineChart Data are graphical widgets
        // to display any kind of graph.  We set them up with
        // properly-formatted data to display.
        //
        // No attempt was made to make this fast, and with 50,000
        // points being graphed, it is, in fact, pretty slow.  With
        // a little effort, this could be made much faster, for
        // example by combining points.
        //
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
    //
    // We graph the *logarithm* of the value.  These values have a big
    // range; doing a logarithmic graph lets us see what's really going
    // on when orbiting bodies get close to eachother.
    //
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
