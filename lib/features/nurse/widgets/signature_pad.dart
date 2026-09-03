import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Minimal finger-drawn signature capture — no external package, just a
/// [CustomPainter] over the raw drag points, exported as PNG bytes via a
/// [RenderRepaintBoundary]. Used by the consent-form sign flow.
class SignaturePadController {
  final GlobalKey boundaryKey = GlobalKey();
  final List<Offset?> points = [];
  VoidCallback? _onChange;

  void _attach(VoidCallback onChange) => _onChange = onChange;

  void addPoint(Offset point) {
    points.add(point);
    _onChange?.call();
  }

  void endStroke() {
    points.add(null);
    _onChange?.call();
  }

  void clear() {
    points.clear();
    _onChange?.call();
  }

  bool get isEmpty => points.where((p) => p != null).isEmpty;

  Future<Uint8List?> toPngBytes() async {
    if (isEmpty) return null;
    final boundary = boundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return null;
    final image = await boundary.toImage(pixelRatio: 2.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData?.buffer.asUint8List();
  }
}

class SignaturePad extends StatefulWidget {
  final SignaturePadController controller;
  const SignaturePad({super.key, required this.controller});

  @override
  State<SignaturePad> createState() => _SignaturePadState();
}

class _SignaturePadState extends State<SignaturePad> {
  @override
  void initState() {
    super.initState();
    widget.controller._attach(() => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      key: widget.controller.boundaryKey,
      child: Container(
        color: Colors.white,
        width: double.infinity,
        height: double.infinity,
        child: GestureDetector(
          onPanUpdate: (details) {
            final box = context.findRenderObject() as RenderBox;
            widget.controller.addPoint(box.globalToLocal(details.globalPosition));
          },
          onPanEnd: (_) => widget.controller.endStroke(),
          child: CustomPaint(
            painter: _SignaturePainter(widget.controller.points),
            size: Size.infinite,
          ),
        ),
      ),
    );
  }
}

class _SignaturePainter extends CustomPainter {
  final List<Offset?> points;
  _SignaturePainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < points.length - 1; i++) {
      final a = points[i];
      final b = points[i + 1];
      if (a != null && b != null) canvas.drawLine(a, b, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SignaturePainter oldDelegate) => true;
}
