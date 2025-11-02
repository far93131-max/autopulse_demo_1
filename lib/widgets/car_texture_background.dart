import 'package:flutter/material.dart';
import 'dart:math' as math;

class CarTextureBackground extends StatelessWidget {
  final Widget child;
  final double opacity;

  const CarTextureBackground({
    super.key,
    required this.child,
    this.opacity = 0.03,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Car texture pattern
        CustomPaint(
          painter: CarTexturePainter(opacity: opacity),
          size: Size.infinite,
        ),
        // Content on top
        child,
      ],
    );
  }
}

class CarTexturePainter extends CustomPainter {
  final double opacity;

  CarTexturePainter({this.opacity = 0.03});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(opacity)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    // Draw tire tread patterns (wavy lines)
    _drawTireTreads(canvas, size, paint);

    // Draw road lines
    _drawRoadLines(canvas, size, paint);

    // Draw car silhouettes
    _drawCarSilhouettes(canvas, size, paint);

    // Draw speed lines
    _drawSpeedLines(canvas, size, paint);
  }

  void _drawTireTreads(Canvas canvas, Size size, Paint paint) {
    final path = Path();
    final waveHeight = 8.0;
    final waveLength = 40.0;
    final spacing = 60.0;

    // Horizontal tire treads
    for (double y = 0; y < size.height; y += spacing) {
      path.reset();
      path.moveTo(0, y);
      
      for (double x = 0; x < size.width; x += waveLength) {
        path.quadraticBezierTo(
          x + waveLength / 2,
          y + waveHeight,
          x + waveLength,
          y,
        );
      }
      
      canvas.drawPath(path, paint);
      
      // Parallel tread line
      final path2 = Path();
      path2.moveTo(0, y + 12);
      for (double x = 0; x < size.width; x += waveLength) {
        path2.quadraticBezierTo(
          x + waveLength / 2,
          y + 12 - waveHeight,
          x + waveLength,
          y + 12,
        );
      }
      canvas.drawPath(path2, paint);
    }
  }

  void _drawRoadLines(Canvas canvas, Size size, Paint paint) {
    final lineSpacing = 150.0;
    final dashLength = 40.0;
    final dashGap = 30.0;

    for (double y = 0; y < size.height; y += lineSpacing) {
      final path = Path();
      bool isDrawing = true;
      double currentX = 0;

      while (currentX < size.width) {
        if (isDrawing) {
          path.moveTo(currentX, y);
          path.lineTo(currentX + dashLength, y);
        }
        currentX += isDrawing ? dashLength : dashGap;
        isDrawing = !isDrawing;
      }

      canvas.drawPath(path, paint);
    }
  }

  void _drawCarSilhouettes(Canvas canvas, Size size, Paint paint) {
    final carWidth = 80.0;
    final carHeight = 40.0;
    final spacing = 200.0;

    // Draw subtle car silhouettes at different angles
    for (double x = -carWidth; x < size.width + carWidth; x += spacing) {
      for (double y = -carHeight; y < size.height + carHeight; y += spacing * 1.5) {
        final carPath = Path();
        
        // Car body (simplified)
        carPath.moveTo(x, y + carHeight * 0.3);
        carPath.lineTo(x + carWidth * 0.2, y);
        carPath.lineTo(x + carWidth * 0.8, y);
        carPath.lineTo(x + carWidth, y + carHeight * 0.3);
        carPath.lineTo(x + carWidth, y + carHeight);
        carPath.lineTo(x, y + carHeight);
        carPath.close();

        canvas.drawPath(carPath, paint);
      }
    }
  }

  void _drawSpeedLines(Canvas canvas, Size size, Paint paint) {
    final lineCount = 20;
    final angle = -math.pi / 6; // 30 degrees angle

    for (int i = 0; i < lineCount; i++) {
      final y = (size.height / lineCount) * i.toDouble();
      final startX = -100.0 + ((i * 50) % 200).toDouble();
      final endX = startX + 200.0;

      final path = Path();
      path.moveTo(startX, y);
      path.lineTo(endX, y - 30);
      
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

