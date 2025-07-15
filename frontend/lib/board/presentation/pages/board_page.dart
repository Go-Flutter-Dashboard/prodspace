import 'package:flutter/material.dart';

class BoardPage extends StatefulWidget {
  const BoardPage({super.key});

  @override
  State<BoardPage> createState() => _BoardPageState();
}

class _BoardPageState extends State<BoardPage> {
  Offset panOffset = Offset.zero;
  double scale = 1.0;
  Offset? panStart;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Доска с навигацией'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                panOffset = Offset.zero;
                scale = 1.0;
              });
            },
            tooltip: 'Сбросить вид',
          ),
        ],
      ),
      body: GestureDetector(
        onScaleStart: (details) {
          panStart = details.focalPoint;
        },
        onScaleUpdate: (details) {
          setState(() {
            scale = details.scale.clamp(0.5, 3.0);
            panOffset += details.focalPointDelta;
          });
        },
        child: Container(
          color: Colors.grey[100],
          child: Transform(
            transform: Matrix4.identity()
              ..translate(panOffset.dx, panOffset.dy)
              ..scale(scale),
            child: Container(
              width: 2000,
              height: 2000,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: CustomPaint(
                painter: GridPainter(),
                size: const Size(2000, 2000),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey[200]!
      ..strokeWidth = 1.0;

    // Рисуем сетку
    const gridSize = 50.0;
    
    // Вертикальные линии
    for (double x = 0; x <= size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    
    // Горизонтальные линии
    for (double y = 0; y <= size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // Рисуем центральную точку
    final centerPaint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 3.0;
    
    final center = Offset(size.width / 2, size.height / 2);
    canvas.drawCircle(center, 5, centerPaint);
    
    // Рисуем координатные оси
    final axisPaint = Paint()
      ..color = Colors.red
      ..strokeWidth = 2.0;
    
    // Ось X
    canvas.drawLine(
      Offset(0, center.dy),
      Offset(size.width, center.dy),
      axisPaint,
    );
    
    // Ось Y
    canvas.drawLine(
      Offset(center.dx, 0),
      Offset(center.dx, size.height),
      axisPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
