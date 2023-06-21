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

/// How fine we do our numerical integration, in seconds.
const double integrationSpan = 0.0001;

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.title});
  final String title;

  @override
  State<HomePage> createState() => _OrbitSceneState();
}

class _CelestialBody {
  Offset position;
  Offset drawPosition;
  final Color color;
  final double radius;
  Offset velocity;
  final double mass;

  _CelestialBody(
      {required this.position,
      this.color = Colors.yellow,
      this.radius = 7,
      this.velocity = const Offset(0, 0),
      required this.mass}) : drawPosition = position;

  void updateVelocity(_OrbitSceneState universe, double deltaT) {
    for (final b in universe.bodies) {
      if (b != this) {
        final Offset dist = b.position - position;
        // F = G (m1 m2) / d^2
        // F = m a, so a = F / M = G m2 / d^2
        final a = _G * b.mass / dist.distanceSquared;
        final scaleFactor = deltaT * a / dist.distance;
        velocity += dist.scale(scaleFactor, scaleFactor);
      }
    }
  }

  void advanceBy(double deltaT) {
    position = position + velocity * deltaT;
  }

  void setDrawPosition(double pendingIntegration) =>
      drawPosition = position + velocity * pendingIntegration;

  void paint(Canvas canvas) {
    final fg = Paint()..color = color;
    canvas.drawCircle(drawPosition, radius, fg);
  }
}

class _OrbitSceneState extends State<HomePage> {
  final watch = Stopwatch();
  late Duration lastTick;
  double integrationTime = 0;
  double pendingIntegration= 0;
  late final Timer timer;

  final bodies = [
    _CelestialBody(
        position: const Offset(200, 150),
        radius: 15,
        velocity: const Offset(10, 10),
        mass: 15 * 15),
    _CelestialBody(
        position: const Offset(400, 150),
        color: Colors.lightBlue,
        radius: 20,
        mass: 20 * 20),
    _CelestialBody(
        position: const Offset(300, 350),
        color: Colors.red,
        velocity: const Offset(-5, -15),
        mass: 5 * 5),
  ];

  @override
  void initState() {
    timer =
        Timer.periodic(Duration(milliseconds: (1000 / 60).round()), showFrame);
    watch.start();
    lastTick = watch.elapsed;
    super.initState();
  }

  @override
  void dispose() {
    timer.cancel();
    super.dispose();
  }

  void showFrame(Timer t) {
    final now = watch.elapsed;
    double animationDelta = (now - lastTick).inMicroseconds / 1000000;
    final integrationGoal = integrationTime + pendingIntegration + animationDelta;
    for (;;) {
      final next = integrationTime + integrationSpan;
      if (next > integrationGoal) {
        break;
      }
      for (final b in bodies) {
        b.updateVelocity(this, integrationSpan);
      }
      for (final b in bodies) {
        b.advanceBy(integrationSpan);
      }
      integrationTime = next;
    }

    // Now,  integrationTime is <= the current animation time.  We record
    // the difference in pendingIntegration.
    pendingIntegration = integrationGoal - integrationTime;
    assert(pendingIntegration >= 0 && pendingIntegration < integrationSpan * 1.0001);
    setState(() {
      for (final b in bodies) {
        b.setDrawPosition(pendingIntegration);
      }
    });
    lastTick = now;

    // Student question:  What's wrong with this code, from a design perspective?
    // How well does it obey the separation of concerns principle?
    //
    // Answer:  Terribly.  _CelestialBody has two main concerns:  The numerical
    // integration, and the animation.  _OrbitSceneState has become sorta a
    // grab-bag.  We have pretty high coupling between _CelestialBody and
    // _OrbitSceneState.  _OrbitSceneState has an unhelpful name.
    //
    // This is perfectly normal.  Iterative design and development is great,
    // PROVIDED THAT you're willing to refactor when this happens.
    //
    // Note that Single Responsibility is the first principle in the SOLID
    // design principles, where are pretty much OO 101.  Robert C. Martin
    // would be displeased if we let this stand.
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
    for (final body in _state.bodies) {
      body.paint(canvas);
    }
  }
}
