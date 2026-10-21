import 'package:flutter/material.dart';

/// Widget QR Code visual presisi untuk Kode Pengambilan JNOVAMUSIC
class QrCodeWidget extends StatelessWidget {
  final String data;
  final double size;

  const QrCodeWidget({
    super.key,
    required this.data,
    this.size = 140,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEBE8E3), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: CustomPaint(
        size: Size(size - 16, size - 16),
        painter: _QrPainter(data),
      ),
    );
  }
}

class _QrPainter extends CustomPainter {
  final String data;

  _QrPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    final paintDark = Paint()
      ..color = const Color(0xFF1E1A18)
      ..style = PaintingStyle.fill;

    final cellCount = 21; // QR Version 1 (21x21 modules)
    final cellSize = size.width / cellCount;

    // Gambar 3 Finder Patterns (Top-Left, Top-Right, Bottom-Left)
    _drawFinderPattern(canvas, 0, 0, cellSize, paintDark);
    _drawFinderPattern(canvas, (cellCount - 7) * cellSize, 0, cellSize, paintDark);
    _drawFinderPattern(canvas, 0, (cellCount - 7) * cellSize, cellSize, paintDark);

    // Timing patterns
    for (int i = 8; i < cellCount - 8; i += 2) {
      canvas.drawRect(Rect.fromLTWH(i * cellSize, 6 * cellSize, cellSize, cellSize), paintDark);
      canvas.drawRect(Rect.fromLTWH(6 * cellSize, i * cellSize, cellSize, cellSize), paintDark);
    }

    // Pattern data pseudorandom konsisten berdasarkan string data
    final hash = data.hashCode.abs();
    for (int r = 0; r < cellCount; r++) {
      for (int c = 0; c < cellCount; c++) {
        // Lewati area finder patterns
        if ((r < 8 && c < 8) ||
            (r < 8 && c >= cellCount - 8) ||
            (r >= cellCount - 8 && c < 8)) {
          continue;
        }
        if (r == 6 || c == 6) continue;

        final isFilled = ((r * 7 + c * 13 + hash) % 3) == 0;
        if (isFilled) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(c * cellSize + 0.3, r * cellSize + 0.3, cellSize - 0.6, cellSize - 0.6),
              const Radius.circular(1.0),
            ),
            paintDark,
          );
        }
      }
    }
  }

  void _drawFinderPattern(Canvas canvas, double left, double top, double cellSize, Paint paint) {
    // Kotak luar 7x7
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(left, top, cellSize * 7, cellSize * 7),
        const Radius.circular(4),
      ),
      paint,
    );
    // Kotak putih 5x5
    final paintWhite = Paint()..color = Colors.white;
    canvas.drawRect(
      Rect.fromLTWH(left + cellSize, top + cellSize, cellSize * 5, cellSize * 5),
      paintWhite,
    );
    // Kotak dalam 3x3
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(left + cellSize * 2, top + cellSize * 2, cellSize * 3, cellSize * 3),
        const Radius.circular(2),
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _QrPainter oldDelegate) => oldDelegate.data != data;
}
