import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'graph.dart';

late final ui.Image background;
late final ui.Image earth;
late final ui.Image saturn;
late final ui.Image sun;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  background = await loadImage('assets/firefly.jpg');
  earth = await loadImage('assets/earth.png');
  saturn = await loadImage('assets/saturn.png');
  sun = await loadImage('assets/sun.png');
  runApp(const MyApp());
}

Future<ui.Image> loadImage(String assetName) async {
  final encoded = (await rootBundle.load(assetName)).buffer.asUint8List();
  final des = await ui.ImageDescriptor.encoded(
      await ImmutableBuffer.fromUint8List(encoded));
  final ui.FrameInfo fi = await (await des.instantiateCodec()).getNextFrame();
  return fi.image;
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
        home: Scaffold(
            appBar: AppBar(
              backgroundColor: Theme.of(context).colorScheme.inversePrimary,
              title: const Text('Flutter N-Body Problem'),
            ),
            body: Column(children: [
              const Expanded(flex: 2, child: HomePage(title: 'N-Body Problem')),
              (graphData.isEmpty
                  ? Container()
                  : const Expanded(child: Graph())),
            ])));
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
      int i = 0;
      if (graphData.isNotEmpty) {
        graphData[i++].points.add(currentTime);
      }
      for (final b in bodies) {
        final acc = b.updateVelocity(bodies, timeGranularity);
        if (graphData.isNotEmpty) {
          graphData[i++].points.add(acc.distance);
        }
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

  // Returns the acceleration vector
  Offset updateVelocity(List<_CelestialBody> universe, double deltaT) {
    var acceleration = Offset.zero;
    for (final b in universe) {
      if (b != this) {
        final Offset dist = b.position - position;
        // F = G (m1 m2) / d^2
        // F = m a, so a = F / m = G m2 / d^2
        final a = _G * b.mass / dist.distanceSquared;
        final scaleFactor = a / dist.distance;
        acceleration += dist.scale(scaleFactor, scaleFactor);
      }
    }
    velocity += acceleration.scale(deltaT, deltaT);
    return acceleration;
  }

  void updatePosition(double deltaT) {
    position = position + velocity * deltaT;
  }
}

class _Animator {
  final List<_CelestialBodyAnimation> bodies;

  _Animator({required this.bodies, bool zeroMomentum = false}) {
    if (zeroMomentum) {
      Offset momentum = Offset.zero;
      var biggest = bodies[0].body;
      for (final b in bodies) {
        momentum += b.body.velocity * b.body.mass;
        if (b.body.mass > biggest.mass) {
          biggest = b.body;
        }
      }
      biggest.velocity -= momentum / biggest.mass;
    }
  }

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

abstract class _CelestialBodyAnimation {
  final _CelestialBody body;
  Offset drawPosition;

  _CelestialBodyAnimation({required this.body}) : drawPosition = body.position;

  void setDrawPosition(double pendingIntegration) =>
      drawPosition = body.position + body.velocity * pendingIntegration;

  void paint(Canvas canvas);
}

class _CelestialBodyCircleAnimation extends _CelestialBodyAnimation {
  final Color color;
  final double radius;

  _CelestialBodyCircleAnimation(
      {required super.body, this.color = Colors.yellow, this.radius = 7});

  @override
  void paint(Canvas canvas) {
    final fg = Paint()..color = color;
    canvas.drawCircle(drawPosition, radius, fg);
  }
}

class _CelestialBodyImageAnimation extends _CelestialBodyAnimation {
  final ui.Image image;
  final double radius;

  _CelestialBodyImageAnimation(
      {required super.body, required this.image, this.radius = 7});

  @override
  void paint(Canvas canvas) {
    canvas.drawImageRect(
        image,
        Rect.fromLTWH(0, 0, image.width + 0, image.height + 0),
        Rect.fromLTWH(drawPosition.dx - radius, drawPosition.dy - radius,
            2 * radius + 1, 2 * radius + 1),
        ui.Paint());
  }
}

// Now we try something symmetrical and periodic
class _OrbitSceneState extends State<HomePage> {
  late final Timer timer;
  final watch = Stopwatch();
  final animator = _Animator(zeroMomentum: true, bodies: [
    _CelestialBodyImageAnimation(
        body: _CelestialBody(
            position: const Offset(600, 350),
            velocity: const Offset(0, 0),
            mass: 1000000),
        image: sun,
        radius: 45),
    _CelestialBodyImageAnimation(
        body: _CelestialBody(
            position: const Offset(450, 350),
            velocity: const Offset(0, 600),
            mass: 1000),
        image: earth,
        radius: 25),
    _CelestialBodyImageAnimation(
        body: _CelestialBody(
            position: const Offset(350, 350),
            velocity: const Offset(0, 300),
            mass: 5000),
        image: saturn,
        radius: 35),
    _CelestialBodyCircleAnimation(
        body: _CelestialBody(
            position: const Offset(100, 350),
            velocity: const Offset(0, 100),
            mass: 10),
        radius: 15,
        color: Colors.green),
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
    return CustomPaint(size: Size.infinite, painter: _OrbitScenePainter(this));
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
    canvas.drawImageRect(
        background,
        Rect.fromLTWH(0, 0, background.width + 0, background.height + 0),
        Rect.fromLTWH(0, 0, size.width, size.height),
        ui.Paint());
    _state.animator.paintAll(canvas);
  }
}
