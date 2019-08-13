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

  WavePainter({this.sliderPosition, this.dragPercentage, this.color})
      : fillPainter = Paint()
          ..color = color
          ..style = PaintingStyle.fill,
        wavePainter = Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5;

  @override
  void paint(Canvas canvas, Size size) {
    // TODO: implement paint
    _paintAnchors(canvas, Size, size);
    _paintWaveLine(canvas, size);
    // _paintLine(canvas, size);
    // _paintBlock(canvas, size);
  }

  _paintAnchors(Canvas canvas, Size, size) {
    canvas.drawCircle(Offset(0.0, size.height), 5.0, fillPainter);
    canvas.drawCircle(Offset(size.width, size.height), 5.0, fillPainter);
  }

  // Paints the curve of the line reprenting the slider.
  _paintWaveLine(Canvas canvas, Size size) {
    double bendWidth = 40.0;
    double bezierWidth = 40.0;
    double startOfBend = sliderPosition - bendWidth / 2;
    double startOfBezier = startOfBend - bezierWidth;
    double endOfBend = sliderPosition + bendWidth / 2;
    double endOfBezier = endOfBend + bezierWidth;

    double controlHeight = 0.0;
    double centerPoint = sliderPosition;

    // Control points that control the bend.
    double leftControlPoint1 = startOfBend;
    double leftControlPoint2 = startOfBend;
    double rightControlPoint1 = endOfBend;
    double rightControlPoint2 = endOfBend;

    Path path = Path();
    path.moveTo(0.0, size.height);
    path.lineTo(startOfBezier, size.height);
    path.cubicTo(leftControlPoint1, size.height, leftControlPoint2,
        controlHeight, centerPoint, controlHeight);

    path.cubicTo(rightControlPoint1, controlHeight, rightControlPoint2,
        size.height, endOfBezier, size.height);
    path.lineTo(size.width, size.height);
    canvas.drawPath(path, wavePainter);
  }

  // _paintLine(Canvas canvas, Size size) {
  //   Path path = Path();
  //   path.moveTo(0.0, size.height);
  //   path.lineTo(size.width, size.height);
  //   canvas.drawPath(path, wavePainter);
  // }

  // _paintBlock(Canvas canvas, Size size) {
  //   Rect sliderRect = Offset(sliderPosition, size.height - 5.0) & Size(3.0, 10.0);
  //   canvas.drawRect(sliderRect, wavePainter);
  // }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true; // we always want to repaint.
  }
}
