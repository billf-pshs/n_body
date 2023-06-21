import 'dart:async';

import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter N-Body Problem',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HomePage(title: 'N-Body Problem'),
    );
  }
}

/// The gravitational constant
const double _G = 47.7;

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.title});
  final String title;

  @override
  State<HomePage> createState() => _OrbitSceneState();
}

class _PhysicsSimulator {
  final List<_CelestialBody> bodies;
  final double timeGranularity;
  double currentTime = 0;

  _PhysicsSimulator({required this.bodies, required this.timeGranularity});

  /// Advance to the latest possible time <= the time argument
  /// Return the amount of time left over.
  double advanceTo(double time) {
    for (;;) {
      final next = currentTime + timeGranularity;
      if (next > time) {
        return time - currentTime;
      }
      for (final b in bodies) {
        b.updateVelocity(bodies, timeGranularity);
      }
      for (final b in bodies) {
        b.updatePosition(timeGranularity);
      }
      currentTime = next;
    }
  }
}

class _CelestialBody {
  Offset position;
  Offset velocity;
  final double mass;

  _CelestialBody(
      {required this.position,
      this.velocity = const Offset(0, 0),
      required this.mass});

  void updateVelocity(List<_CelestialBody> universe, double deltaT) {
    for (final b in universe) {
      if (b != this) {
        final Offset dist = b.position - position;
        // F = G (m1 m2) / d^2
        // F = m a, so a = F / m = G m2 / d^2
        final a = _G * b.mass / dist.distanceSquared;
        final scaleFactor = deltaT * a / dist.distance;
        velocity += dist.scale(scaleFactor, scaleFactor);
      }
    }
  }

  void updatePosition(double deltaT) {
    position = position + velocity * deltaT;
  }
}

class _Animator {
  final List<_CelestialBodyAnimation> bodies;

  _Animator(this.bodies);

  void setPositions(double leftOver) {
    for (final b in bodies) {
      b.setDrawPosition(leftOver);
    }
  }

  void paintAll(Canvas canvas) {
    for (final b in bodies) {
      b.paint(canvas);
    }
  }
}

class _CelestialBodyAnimation {
  final _CelestialBody body;
  Offset drawPosition;
  final Color color;
  final double radius;

  _CelestialBodyAnimation(
      {required this.body, this.color = Colors.yellow, this.radius = 7})
      : drawPosition = body.position;

  void setDrawPosition(double pendingIntegration) =>
      drawPosition = body.position + body.velocity * pendingIntegration;

  void paint(Canvas canvas) {
    final fg = Paint()..color = color;
    canvas.drawCircle(drawPosition, radius, fg);
  }
}

// Now we try something symmetrical and periodic
class _OrbitSceneState extends State<HomePage> {
  late final Timer timer;
  final watch = Stopwatch();
  static const _v = 45.0;
  final animator = _Animator([
    _CelestialBodyAnimation(
        body: _CelestialBody(
            position: const Offset(100, 100),
            velocity: const Offset(_v, 0),
            mass: 10000),
        radius: 15,
        color: Colors.red),
    _CelestialBodyAnimation(
        body: _CelestialBody(
            position: const Offset(300, 100),
            velocity: const Offset(0, _v),
            mass: 10000),
        radius: 15,
        color: Colors.green),
    _CelestialBodyAnimation(
        body: _CelestialBody(
            position: const Offset(300, 300),
            velocity: const Offset(-_v, 0),
            mass: 10000),
        radius: 15,
        color: Colors.yellow),
    _CelestialBodyAnimation(
        body: _CelestialBody(
            position: const Offset(100, 300),
            velocity: const Offset(0, -_v),
            mass: 10000),
        radius: 15,
        color: Colors.lightBlue),
  ]);

  late final _PhysicsSimulator simulator;

  _OrbitSceneState() {
    simulator = _PhysicsSimulator(
        timeGranularity: 0.0001,
        bodies: animator.bodies.map((b) => b.body).toList(growable: false));
  }

  @override
  void initState() {
    timer =
        Timer.periodic(Duration(milliseconds: (1000 / 60).round()), showFrame);
    watch.start();
    super.initState();
  }

  @override
  void dispose() {
    timer.cancel();
    super.dispose();
  }

  void showFrame(Timer t) {
    final now = watch.elapsed;
    final leftOver = simulator.advanceTo(now.inMicroseconds / 1000000);
    setState(() {
      animator.setPositions(leftOver);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: Text(widget.title),
        ),
        body: CustomPaint(
            size: Size.infinite, painter: _OrbitScenePainter(this)));
  }
}

class _OrbitScenePainter extends CustomPainter {
  final _OrbitSceneState _state;

  _OrbitScenePainter(this._state);

  @override
  bool shouldRepaint(_OrbitScenePainter oldDelegate) => oldDelegate != this;

  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()..color = Colors.black;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bg);
    _state.animator.paintAll(canvas);
  }
}
