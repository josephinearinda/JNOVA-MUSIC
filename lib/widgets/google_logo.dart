import 'package:flutter/material.dart';

/// Widget logo resmi Google dengan 4 warna identitas (Biru, Merah, Kuning, Hijau)
/// digambar secara vektor presisi agar selalu tajam di setiap resolusi layar.
class GoogleLogo extends StatelessWidget {
  final double size;

  const GoogleLogo({
    super.key,
    this.size = 18.0,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _GoogleLogoPainter(),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final Offset center = Offset(w / 2, h / 2);
    final double radius = w / 2;
    final double strokeWidth = w * 0.22;

    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    final Rect rect = Rect.fromCircle(center: center, radius: radius - strokeWidth / 2);

    // 1. Busur Biru (Kanan bawah ke kanan tengah)
    paint.color = const Color(0xFF4285F4);
    canvas.drawArc(rect, -0.15, 1.25, false, paint);

    // 2. Busur Hijau (Bawah)
    paint.color = const Color(0xFF34A853);
    canvas.drawArc(rect, 1.1, 1.35, false, paint);

    // 3. Busur Kuning (Kiri)
    paint.color = const Color(0xFFFBBC05);
    canvas.drawArc(rect, 2.45, 1.25, false, paint);

    // 4. Busur Merah (Atas)
    paint.color = const Color(0xFFEA4335);
    canvas.drawArc(rect, 3.7, 1.35, false, paint);

    // 5. Batang horizontal biru di tengah huruf "G"
    final Paint fillBlue = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.fill;

    final double barHeight = strokeWidth;
    final double barWidth = radius * 0.95;
    final Rect barRect = Rect.fromLTWH(
      center.dx - radius * 0.05,
      center.dy - barHeight / 2,
      barWidth,
      barHeight,
    );
    canvas.drawRect(barRect, fillBlue);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
