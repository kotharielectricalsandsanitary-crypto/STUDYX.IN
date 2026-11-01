import 'dart:math' as math;

import 'package:flutter/material.dart';

enum StudyBuddyMood { sad, happy, focused, resting }

/// A lightweight, code-drawn cartoon boy mascot. No image assets are required.
/// The gentle bob animation and facial expression change with [mood].
class StudyBuddyMascot extends StatefulWidget {
  const StudyBuddyMascot({
    super.key,
    required this.mood,
    this.size = 96,
  });

  final StudyBuddyMood mood;
  final double size;

  @override
  State<StudyBuddyMascot> createState() => _StudyBuddyMascotState();
}

class _StudyBuddyMascotState extends State<StudyBuddyMascot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bob = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _bob.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: widget.size,
      child: AnimatedBuilder(
        animation: _bob,
        builder: (context, child) {
          final bob = math.sin(_bob.value * math.pi) *
              (widget.mood == StudyBuddyMood.focused ? 1.8 : 3.2);
          return Transform.translate(
            offset: Offset(0, -bob),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 280),
              child: CustomPaint(
                key: ValueKey(widget.mood),
                painter: _StudyBuddyPainter(mood: widget.mood),
                size: Size.square(widget.size),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _StudyBuddyPainter extends CustomPainter {
  const _StudyBuddyPainter({required this.mood});
  final StudyBuddyMood mood;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 100;
    canvas.save();
    canvas.scale(scale, scale);

    final shadow = Paint()..color = const Color(0x22000000);
    canvas.drawOval(const Rect.fromLTWH(19, 88, 62, 8), shadow);

    // Hoodie/body.
    final hoodie = Paint()..color = const Color(0xFF6C63FF);
    final body = Path()
      ..moveTo(28, 57)
      ..quadraticBezierTo(17, 61, 16, 83)
      ..quadraticBezierTo(50, 96, 84, 83)
      ..quadraticBezierTo(83, 62, 71, 57)
      ..quadraticBezierTo(50, 72, 28, 57)
      ..close();
    canvas.drawPath(body, hoodie);
    final hoodieLight = Paint()..color = const Color(0xFF938DFF);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          const Rect.fromLTWH(43, 69, 14, 15), const Radius.circular(5)),
      hoodieLight,
    );

    // Neck and ears.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          const Rect.fromLTWH(42, 48, 16, 17), const Radius.circular(6)),
      Paint()..color = const Color(0xFFE9AD82),
    );
    canvas.drawCircle(
        const Offset(25, 38), 7, Paint()..color = const Color(0xFFE9AD82));
    canvas.drawCircle(
        const Offset(75, 38), 7, Paint()..color = const Color(0xFFE9AD82));

    // Face.
    canvas.drawOval(const Rect.fromLTWH(25, 12, 50, 48),
        Paint()..color = const Color(0xFFFFC99F));
    // Hair silhouette and fringe.
    final hair = Paint()..color = const Color(0xFF352A35);
    final hairPath = Path()
      ..moveTo(24, 36)
      ..quadraticBezierTo(17, 8, 42, 8)
      ..quadraticBezierTo(63, 0, 76, 21)
      ..quadraticBezierTo(81, 28, 75, 38)
      ..lineTo(69, 29)
      ..quadraticBezierTo(59, 35, 50, 26)
      ..quadraticBezierTo(41, 38, 29, 31)
      ..close();
    canvas.drawPath(hairPath, hair);

    // Brows and eyes change with the mood.
    final brow = Paint()
      ..color = const Color(0xFF49323A)
      ..strokeWidth = 2.3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final eye = Paint()
      ..color = const Color(0xFF352A35)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    if (mood == StudyBuddyMood.sad) {
      canvas.drawLine(const Offset(34, 33), const Offset(42, 35), brow);
      canvas.drawLine(const Offset(58, 35), const Offset(66, 33), brow);
      canvas.drawCircle(
          const Offset(39, 40), 2.1, Paint()..color = const Color(0xFF352A35));
      canvas.drawCircle(
          const Offset(61, 40), 2.1, Paint()..color = const Color(0xFF352A35));
    } else if (mood == StudyBuddyMood.happy) {
      final leftEye = Path()
        ..moveTo(34, 40)
        ..quadraticBezierTo(39, 34, 44, 40);
      final rightEye = Path()
        ..moveTo(56, 40)
        ..quadraticBezierTo(61, 34, 66, 40);
      canvas.drawPath(leftEye, eye);
      canvas.drawPath(rightEye, eye);
    } else {
      canvas.drawLine(const Offset(34, 34), const Offset(43, 34), brow);
      canvas.drawLine(const Offset(57, 34), const Offset(66, 34), brow);
      canvas.drawOval(const Rect.fromLTWH(36, 37, 5, 6),
          Paint()..color = const Color(0xFF352A35));
      canvas.drawOval(const Rect.fromLTWH(59, 37, 5, 6),
          Paint()..color = const Color(0xFF352A35));
    }

    // Cheeks.
    final cheek = Paint()..color = const Color(0x55F06E78);
    canvas.drawOval(const Rect.fromLTWH(29, 43, 9, 5), cheek);
    canvas.drawOval(const Rect.fromLTWH(62, 43, 9, 5), cheek);

    // Mouth: frown, smile, or calm focused line.
    final mouth = Paint()
      ..color = const Color(0xFF9C4D55)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final mouthPath = Path();
    if (mood == StudyBuddyMood.sad) {
      mouthPath.moveTo(41, 53);
      mouthPath.quadraticBezierTo(50, 44, 59, 53);
    } else if (mood == StudyBuddyMood.happy) {
      mouthPath.moveTo(39, 48);
      mouthPath.quadraticBezierTo(50, 61, 61, 48);
    } else {
      mouthPath.moveTo(43, 51);
      mouthPath.quadraticBezierTo(50, 54, 57, 51);
    }
    canvas.drawPath(mouthPath, mouth);

    // Small book badge on the hoodie.
    final book = Paint()..color = const Color(0xFFFFD166);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          const Rect.fromLTWH(43, 73, 14, 9), const Radius.circular(2)),
      book,
    );
    canvas.drawLine(
        const Offset(50, 74),
        const Offset(50, 81),
        Paint()
          ..color = const Color(0xFF6C63FF)
          ..strokeWidth = 1.2);

    // Mood sparkles when happy; tiny focus marks when studying.
    final accent = Paint()
      ..color = mood == StudyBuddyMood.sad
          ? const Color(0xFF83B7FF)
          : const Color(0xFFFFD166)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    if (mood == StudyBuddyMood.happy) {
      _drawSparkle(canvas, const Offset(13, 27), accent);
      _drawSparkle(canvas, const Offset(87, 20), accent);
    } else if (mood == StudyBuddyMood.focused) {
      canvas.drawLine(const Offset(11, 31), const Offset(17, 31), accent);
      canvas.drawLine(const Offset(14, 28), const Offset(14, 34), accent);
      canvas.drawLine(const Offset(83, 31), const Offset(89, 31), accent);
      canvas.drawLine(const Offset(86, 28), const Offset(86, 34), accent);
    } else if (mood == StudyBuddyMood.sad) {
      canvas.drawOval(const Rect.fromLTWH(82, 25, 4, 8), accent);
    }

    canvas.restore();
  }

  void _drawSparkle(Canvas canvas, Offset center, Paint paint) {
    canvas.drawLine(Offset(center.dx - 4, center.dy),
        Offset(center.dx + 4, center.dy), paint);
    canvas.drawLine(Offset(center.dx, center.dy - 4),
        Offset(center.dx, center.dy + 4), paint);
  }

  @override
  bool shouldRepaint(covariant _StudyBuddyPainter oldDelegate) =>
      oldDelegate.mood != mood;
}
