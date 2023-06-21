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

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.title});
  final String title;

  @override
  State<HomePage> createState() => _OrbitSceneState();
}

class _CelestialBody {
  final Offset position;
  final Color color;

  _CelestialBody(this.position, this.color);

  void paint(Canvas canvas) {
    final fg = Paint()..color = color;
    canvas.drawCircle(position, 5, fg);
  }
}

class _OrbitSceneState extends State<HomePage> {

  final bodies = [
    _CelestialBody(const Offset(200, 150), Colors.yellow),
    _CelestialBody(const Offset(400, 150), Colors.lightBlue),
    _CelestialBody(const Offset(300, 350), Colors.red),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: CustomPaint(size: Size.infinite, painter: _OrbitScenePainter(this))
    );
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
