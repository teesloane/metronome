import 'dart:ui';

import 'package:flutter/material.dart';

class TempoSlider extends StatefulWidget {
  final double width;
  final double height;
  final Color color;

  const TempoSlider(
      {this.width = 350, this.height = 50, this.color = Colors.black});

  @override
  _TempoSliderState createState() => _TempoSliderState();
}

class _TempoSliderState extends State<TempoSlider> {
  double _dragPos = 0;
  double _dragPercentage = 0;

// Called every time one of the drag functions are called
  void _updateDragPosition(Offset val) {
    double newDragPosition = 0;

    // Stop the dragging from exceeding the bounds of the slider.
    // this will be irrelevant if the slider is going to take the whole bounds of the right screen.
    if (val.dx <= 0) {
      newDragPosition = 0;
    } else if (val.dx >= widget.width) {
      newDragPosition = widget.width;
    } else {
      newDragPosition = val.dx;
    }
    setState(() {
      _dragPos = newDragPosition;
      _dragPercentage = _dragPos / widget.width;
    });
  }

  void _onDragUpdate(BuildContext context, DragUpdateDetails update) {
    // Find the x and y coordinates of the drawn GestureDetector.
    RenderBox box = context.findRenderObject();
    // we want local coordinates, not global position, so we use offset.
    Offset offset = box.globalToLocal(update.globalPosition);
    _updateDragPosition(offset);
    print(offset);
  }

  void _onDragStart(BuildContext ctx, DragStartDetails start) {
    RenderBox box = context.findRenderObject();
    Offset offset = box.globalToLocal(start.globalPosition);
    _updateDragPosition(offset);
  }

  void _onDragEnd(BuildContext ctx, DragEndDetails end) {
    setState(() {}); // empty setState to rebuild on dragEnd
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: GestureDetector(
        child: Container(
          width: widget.width,
          height: widget.height,
          // color: Colors.red,
          child: CustomPaint(
              painter: WavePainter(
                  color: widget.color,
                  dragPercentage: _dragPercentage,
                  sliderPosition: _dragPos)),
        ),
        onHorizontalDragUpdate: (d) => _onDragUpdate(context, d),
        onHorizontalDragStart: (s) => _onDragStart(context, s),
        onHorizontalDragEnd: (end) => _onDragEnd(context, end),
      ),
    );
  }
}

class WavePainter extends CustomPainter {
  final double sliderPosition;
  final double dragPercentage;
  final Paint fillPainter;
  final Paint wavePainter;
  final Color color;

  double _previousSliderPosition =
      0; // for determining if the current position is diff from previous pos.

  WavePainter({this.sliderPosition, this.dragPercentage, this.color})
      : fillPainter = Paint()
          ..color = color
          ..style = PaintingStyle.fill,
        wavePainter = Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5;

  @override

  /// Main paint loop: paints the anchor of the tempoSlider, and the wave line.
  void paint(Canvas canvas, Size size) {
    _paintAnchors(canvas, size);
    _paintWaveLine(canvas, size);
  }

  _paintAnchors(Canvas canvas, Size size) {
    canvas.drawCircle(Offset(0.0, size.height), 5.0, fillPainter);
    canvas.drawCircle(Offset(size.width, size.height), 5.0, fillPainter);
  }

  /// Calculates the definitions of the wave line
  /// Everytime we paint, based on the input of a gesture,
  /// calculates the bend start and ends, as well as the control points of the bezier.
  /// Returns a set of WaveCurveDefinitions that can be used in _paintWaveLine
  WaveCurveDefinitions _calculateWaveLineDefinitions() {
    double bendWidth = 40.0;
    double bezierWidth = 40.0;
    double startOfBend = sliderPosition - bendWidth / 2;
    double startOfBezier = startOfBend - bezierWidth;
    double endOfBend = sliderPosition + bendWidth / 2;
    double endOfBezier = endOfBend + bezierWidth;
    double controlHeight = 0.0;
    double centerPoint = sliderPosition;

    // Control points that control the bend. These dynamically update based on movement <- or ->
    double leftControlPoint1 = startOfBend;
    double leftControlPoint2 = startOfBend;
    double rightControlPoint1 = endOfBend;
    double rightControlPoint2 = endOfBend;
    double bendability = 25.0; // how bendable the curve is
    double maxSlideDifference = 20.0; // max diff current pos : previous pos.
    double slideDifference = (sliderPosition - _previousSliderPosition).abs();

    if (slideDifference > maxSlideDifference) {
      slideDifference = maxSlideDifference;
    }

    // interpolates how much we want the bend.
    // basically, how fast you move the thing, how much it bends.
    double bend =
        lerpDouble(0.0, bendability, slideDifference / maxSlideDifference);

    // is slider Moving left?
    bool moveLeft = sliderPosition < _previousSliderPosition;

    if (moveLeft) {
      leftControlPoint1 = leftControlPoint1 - bend;
      leftControlPoint2 = leftControlPoint2 + bend;
      rightControlPoint1 = rightControlPoint2 + bend;
      rightControlPoint2 = rightControlPoint2 - bend;
      centerPoint = centerPoint + bend;
    } else {
      leftControlPoint1 = leftControlPoint1 + bend;
      leftControlPoint2 = leftControlPoint2 - bend;
      rightControlPoint1 = rightControlPoint2 - bend;
      rightControlPoint2 = rightControlPoint2 + bend;
      centerPoint = centerPoint - bend;
    }

    WaveCurveDefinitions wc = WaveCurveDefinitions(
        startOfBend,
        startOfBezier,
        endOfBend,
        endOfBezier,
        controlHeight,
        centerPoint,
        leftControlPoint1,
        leftControlPoint2,
        rightControlPoint1,
        rightControlPoint2);
    return wc;
  }

  // Paints the curve of the line reprenting the slider.
  _paintWaveLine(Canvas canvas, Size size) {
    WaveCurveDefinitions wd = _calculateWaveLineDefinitions();

    Path path = Path();
    path.moveTo(0.0, size.height);
    path.lineTo(wd.startOfBezier, size.height);
    path.cubicTo(wd.leftControlPoint1, size.height, wd.leftControlPoint2,
        wd.controlHeight, wd.centerPoint, wd.controlHeight);

    path.cubicTo(wd.rightControlPoint1, wd.controlHeight, wd.rightControlPoint2,
        size.height, wd.endOfBezier, size.height);
    path.lineTo(size.width, size.height);
    canvas.drawPath(path, wavePainter);
  }

  @override
  bool shouldRepaint(WavePainter oldDelegate) {
    _previousSliderPosition = oldDelegate.sliderPosition;
    return true; // we always want to repaint.
  }
}

// Cleans up our variables in a class
class WaveCurveDefinitions {
  final double startOfBend;
  final double startOfBezier;
  final double endOfBend;
  final double endOfBezier;
  final double controlHeight;
  final double centerPoint;
  // Control points that control the bend.
  final double leftControlPoint1;
  final double leftControlPoint2;
  final double rightControlPoint1;
  final double rightControlPoint2;

  WaveCurveDefinitions(
      this.startOfBend,
      this.startOfBezier,
      this.endOfBend,
      this.endOfBezier,
      this.controlHeight,
      this.centerPoint,
      this.leftControlPoint1,
      this.leftControlPoint2,
      this.rightControlPoint1,
      this.rightControlPoint2);
}
