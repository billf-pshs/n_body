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

class _OrbitSceneState extends State<HomePage> {

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
    final bg = Paint();
    bg.color = Colors.black;
    bg.style = PaintingStyle.fill;
    // Dart language tip:  A shortcut for the preceeding three lines is:
    // final bg = Paint()..color = Colors.black, style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bg);
  }
}
