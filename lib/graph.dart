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
  final CircularBuffer<double> points;
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
    // Update the displayed graph ten times a second.  Displaying a graph is
    // pretty time-consuming, so we don't want to do this too often.
    timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
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
    final List<double> xCoords = graphData[0].points;
    final double xMin =
        xCoords.isEmpty ? 0 : (xCoords.first.floorToDouble() + 1);
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
        child: LineChart(
            LineChartData(
                minY: 0,
                maxY: 8,
                minX: xMin,
                maxX: xMin + 5,
                titlesData: const FlTitlesData(
                  rightTitles: AxisTitles(),
                  topTitles: AxisTitles(),
                ),
                lineBarsData: [
                  makeBarData(xMin, graphData[0], graphData[1]),
                  makeBarData(xMin, graphData[0], graphData[2]),
                  makeBarData(xMin, graphData[0], graphData[3]),
                  makeBarData(xMin, graphData[0], graphData[4]),
                ]),
            duration: const Duration(seconds: 0)));
  }

  LineChartBarData makeBarData(
      final double xMin, GraphData xValues, GraphData yValues) {
    //
    // We graph the *logarithm* of the value + 1.  These values have a big
    // range; doing a logarithmic graph lets us see what's really going
    // on when orbiting bodies get close to eachother.  Adding one makes it
    // so very low values don't produce huge negative logarithms that obscure
    // the interesting part of the graph.
    //
    double f(double y) => log(y + 1) / ln10;
    double deltaX = 0.05;
    int r = max(2, (xValues.points.maxLines ~/ 1024 * 4));
    // reduce factor, 1024 pixels of resolution in the x direction is plenty
    final spots = List<FlSpot>.empty(growable: true);
    if (yValues.points.isNotEmpty) {
      double minY = yValues.points[0];
      double maxY = minY;
      double lastX = (xValues.points[0] / deltaX).floorToDouble() * deltaX;
      for (int i = 0; i < yValues.points.length; i++) {
        bool done = (i == yValues.points.length - 1);
        double x = (xValues.points[i] / deltaX).floorToDouble() * deltaX;
        if (x > lastX || done) {
          if (x >= xMin) {
            spots.add(FlSpot(x, f(maxY)));
          }
          minY = maxY = yValues.points[i];
          lastX = x;
        } else {
          minY = min(minY, yValues.points[i]);
          maxY = max(maxY, yValues.points[i]);
        }
      }
    }
    return LineChartBarData(
        spots: spots,
        dotData: const FlDotData(show: false),
        barWidth: 2,
        isCurved: false,
        color: yValues.color);
  }
}
