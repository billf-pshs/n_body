import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

import 'graph.dart';

/**
 * A program to simulate the orbits of N
 * celestial bodies.
 */

late final ui.Image background;
late final ui.Image earth;
late final ui.Image saturn;
late final ui.Image sun;

void main() async {
  //
  // The stuff in main is just loading images into the
  // computer's memory, and starting the program.  It might
  // look a little complicated, but getting these steps right
  // was just a matter of reading the documentation carefully,
  // and testing things out.
  //
  WidgetsFlutterBinding.ensureInitialized();
  background = await loadImage('assets/firefly.jpg');
  earth = await loadImage('assets/earth.png');
  saturn = await loadImage('assets/saturn.png');
  sun = await loadImage('assets/sun.png');
  runApp(const MyApp());
}

Future<ui.Image> loadImage(String assetName) async {
  //
  // ... and to load an image, we need to do a little work.  Normally
  // it's not this hard, but Flutter isn't usually used to do direct
  // drawing, like we're doing, so image loading is a little less
  // convenient for us.
  //
  final encoded = (await rootBundle.load(assetName)).buffer.asUint8List();
  final des = await ui.ImageDescriptor.encoded(
      await ImmutableBuffer.fromUint8List(encoded));
  final ui.FrameInfo fi = await (await des.instantiateCodec()).getNextFrame();
  return fi.image;
}

class MyApp extends StatelessWidget {
  //
  // This is a pretty standard Flutter main application class.
  // It was mostly generated for us, when we created the
  // project.
  //
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
            body: Column(children: [
          const Expanded(flex: 2, child: HomePage(title: 'N-Body Problem')),
          (graphData.isEmpty ? Container() : const Expanded(child: Graph())),
          //
          // This last line adds a Graph widget, but only if there is
          // graph data to present.  graphData is a variable defined in
          // graph.dart that you can use to configure what gets graphed,
          // what colors are used, an other things.
          //
        ])));
  }
}

///
/// The gravitational constant.  This isn't the real number; it's just
/// a number that was found to work well.
///
const double _G = 47.7;

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.title});
  final String title;

  @override
  State<HomePage> createState() => _OrbitSceneState();
}

/**
 * This is the main class for the numerical analysis part,
 * where we simulate Newtonian physics.
 **/
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
      //
      // If we're graphing velocity and acceleration,
      // add this point to the graph.
      //
      if (graphData.isNotEmpty) {
        graphData[i++].points.add(currentTime);
      }
      // First, we update all the velocities...
      for (final b in bodies) {
        final acc = b.updateVelocity(bodies, timeGranularity);
        if (graphData.isNotEmpty) {
          graphData[i++].points.add(acc.distance);
        }
      }
      // Then, we update the positions, based on the velocity.
      for (final b in bodies) {
        b.updatePosition(timeGranularity);
      }
      currentTime = next;
    }
  }
}

/**
 * A celestial body, with a position, a velocity and a mass.
 */
class _CelestialBody {
  Offset position;
  Offset velocity;
  final double mass;

  _CelestialBody(
      {required this.position,
      this.velocity = const Offset(0, 0),
      required this.mass});

  /**
   * Update the velocity to what it should be, deltaT seconds
   * in the future.
   *
   * Returns the acceleration vector
   */
  Offset updateVelocity(List<_CelestialBody> universe, double deltaT) {
    var acceleration = Offset.zero;
    //
    // We loop over all the bodies in the universe (except us), and
    // figure out the acceleration from each body, using Newton's
    // Law.
    //
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
    //
    // Then, the velocity just changes by the acceleration multiplied
    // by the time increment.
    //
    velocity += acceleration.scale(deltaT, deltaT);
    return acceleration;
  }

  void updatePosition(double deltaT) {
    //
    // The position is changed by the velocity by the
    // time increment.
    //
    position = position + velocity * deltaT;
  }
}

///
/// This is the main class for producing the grahical
/// animation.
///
class _Animator {
  final List<_CelestialBodyAnimation> bodies;

  _Animator({required this.bodies, bool zeroMomentum = false}) {
    //
    // As a convenience, we can make the net momentum of the
    // universe zero.  This makes it less likely that things
    // will drift off the screen.
    //
    if (zeroMomentum) {
      Offset momentum = Offset.zero;
      //
      // We figure out the total momentum for all of the
      // bodies...
      //
      var biggest = bodies[0].body;
      for (final b in bodies) {
        momentum += b.body.velocity * b.body.mass;
        if (b.body.mass > biggest.mass) {
          biggest = b.body;
        }
      }
      //
      // Then we cheat, by just subtracting it off whatever
      // the biggest body is.
      //
      // This isn't really right.  What would be better?
      //
      biggest.velocity -= momentum / biggest.mass;
    }
  }

  /**
   * Set the positoin of all the bodies, at an animation
   * time that is leftOver seconds after the position of
   * the bodies according to the physics simulation.
   */
  void setPositions(double leftOver) {
    for (final b in bodies) {
      b.setDrawPosition(leftOver);
    }
  }

  /**
   * Paint everything to the screen.
   */
  void paintAll(Canvas canvas) {
    for (final b in bodies) {
      b.paint(canvas);
    }
  }
}

/**
 * This class is used to handle the animation of a single
 * celestial body.
 */
abstract class _CelestialBodyAnimation {
  final _CelestialBody body;
  Offset drawPosition;

  _CelestialBodyAnimation({required this.body}) : drawPosition = body.position;

  void setDrawPosition(double pendingIntegration) =>
      drawPosition = body.position + body.velocity * pendingIntegration;

  void paint(Canvas canvas);
}

/**
 * Handle the animation of a celestial body that's drawn as a
 * colored dot.
 */
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

/**
 * Handle the animation of a celestial body that's drawn as an
 * image.
 */
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

/**
 * This class is the top-level class for holding information
 * (state) for the program.  It keeps track of time, and
 * periodically re-displays the universe.  It also sets up
 * the Animator that displays everything, and the PhysicsSimulator
 * that does the math.
 */

class _OrbitSceneState extends State<HomePage> {
  late final Timer timer;
  final watch = Stopwatch();
  //
  // Here's where we set up all the celestial bodies, and
  // their appearance:
  //
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
    // The timer calls showFrame() 60 times a second.
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
    //
    // First, we advance the physics simulation.  Because the increment
    // of the physics simulation might not be evenly divisible by whatever
    // time has gone by, we might have some left over time.  That is, the
    // last point we can compute from our mathematical model might be a
    // little before the time we want to display.  We just assume that
    // all the bodies go at a constant velocity for this leftOver time.
    //
    final leftOver = simulator.advanceTo(now.inMicroseconds / 1000000);
    setState(() {
      //
      // And, we set the positions.  setState() is a Flutter framework
      // method that tells the widget system we want to re-paint the
      // screen.
      //
      animator.setPositions(leftOver);
    });
  }

  @override
  Widget build(BuildContext context) {
    //
    // CustomPaint is a Flutter widget that causes its painter to be called
    // whenever the screen is displayed.
    //
    return CustomPaint(size: Size.infinite, painter: _OrbitScenePainter(this));
  }
}

class _OrbitScenePainter extends CustomPainter {
  static final scale =
      (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) ? .65 : 1.0;

  final _OrbitSceneState _state;

  _OrbitScenePainter(this._state);

  @override
  bool shouldRepaint(_OrbitScenePainter oldDelegate) => oldDelegate != this;

  /**
   * This method gets called every time the screen is painted.
   */
  @override
  void paint(Canvas canvas, Size size) {
    if (scale != 1.0) {
      canvas.scale(scale);
      size = size / scale;
    }
    //
    // Paint the black background...
    //
    final bg = Paint()..color = Colors.black;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bg);
    //
    // Now paint our background image.
    //
    canvas.drawImageRect(
        background,
        Rect.fromLTWH(0, 0, background.width + 0, background.height + 0),
        Rect.fromLTWH(0, 0, size.width, size.height),
        ui.Paint());
    //
    // And, ask our animator to paint all the celestial bodies.
    //
    _state.animator.paintAll(canvas);
  }
}
