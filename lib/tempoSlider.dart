import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class TempoSlider extends StatefulWidget {
  final double width;
  final double height;
  final Color color;

  final ValueChanged<double> onChanged;
  final ValueChanged<double> onChangedStart;

  const TempoSlider(
      {this.width,
      this.height = 50,
      this.color = Colors.black,
      @required this.onChanged,
      @required this.onChangedStart});

  @override
  _TempoSliderState createState() => _TempoSliderState();
}

// Uses animation mixin.
class _TempoSliderState extends State<TempoSlider>
    with SingleTickerProviderStateMixin {
  double _dragPos = 0.0;
  double _dragPercentage = 0.0;
  WaveSliderController _slideController;

  @override
  void initState() {
    super.initState();
    _slideController = WaveSliderController(vsync: this)
      ..addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    super.dispose();
    _slideController.dispose();
  }

// Called every time one of the drag functions are called
  void _updateDragPosition(Offset val) {
    double newDragPosition = 0.0;

    // Stop the dragging from exceeding the bounds of the slider.
    // NOTE: this will be irrelevant if the slider is going to take the whole bounds of the right screen.
    if (val.dx <= 0.0) {
      newDragPosition = 0.0;
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

  // These two could be refactored into one + some message passing.
  _handleChangeUpdate(double val) {
    assert(widget.onChanged != null); // make sure user passes in a callback
    widget.onChanged(val);
  }

  // Refactor ☝️
  _handleChangeStart(double val) {
    assert(widget.onChanged != null); // make sure user passes in a callback
    widget.onChangedStart(val);
  }

  void _onDragUpdate(BuildContext context, DragUpdateDetails update) {
    // Find the x and y coordinates of the drawn GestureDetector.
    RenderBox box = context.findRenderObject();
    // we want local coordinates, not global position, so we use offset.
    Offset offset = box.globalToLocal(update.globalPosition);
    _slideController.setStateToSliding();
    _updateDragPosition(offset);
    _handleChangeUpdate(_dragPercentage);
  }

  void _onDragStart(BuildContext ctx, DragStartDetails start) {
    RenderBox box = context.findRenderObject();
    Offset offset = box.globalToLocal(start.globalPosition);
    _slideController.setStateToStart();
    _updateDragPosition(offset);
    _handleChangeStart(_dragPercentage);
  }

  void _onDragEnd(BuildContext ctx, DragEndDetails end) {
    _slideController.setStateToStopping();
    setState(() {}); // empty setState to rebuild on dragEnd
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: GestureDetector(
        onHorizontalDragUpdate: (d) => _onDragUpdate(context, d),
        onHorizontalDragStart: (s) => _onDragStart(context, s),
        onHorizontalDragEnd: (end) => _onDragEnd(context, end),
        child: Container(
          width: widget.width,
          height: widget.height,
          // color: Colors.red.withOpacity(0.1),
          child: CustomPaint(
              painter: WavePainter(
                  color: widget.color,
                  dragPercentage: _dragPercentage,
                  sliderPosition: _dragPos,
                  sliderState: _slideController.state,
                  animationProgress: _slideController.progress)),
        ),
      ),
    );
  }
}

/// controls the state of our slider's animation and dragger.
class WaveSliderController extends ChangeNotifier {
  final AnimationController ctrl;
  SliderState _state = SliderState.resting;

  WaveSliderController({@required TickerProvider vsync})
      : ctrl = AnimationController(vsync: vsync) {
    ctrl
      ..addListener(_onProgressUpdate)
      ..addStatusListener(_onStatusUpdate);
  }

  double get progress => ctrl.value;
  SliderState get state => _state;

  void _onProgressUpdate() {
    notifyListeners();
  }

  void _onStatusUpdate(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      _onTransitionCompleted();
    }
  }

  void _onTransitionCompleted() {
    if (_state == SliderState.stopping) {
      setStateToResting();
    }
  }

  void _startAnimation() {
    ctrl.duration = Duration(milliseconds: 500);
    ctrl.forward(from: 0.0);
    notifyListeners();
  }

  void setStateToResting() {
    _state = SliderState.resting;
  }

  void setStateToStart() {
    _startAnimation();
    _state = SliderState.starting;
  }

  void setStateToSliding() {
    _state = SliderState.sliding;
  }

  void setStateToStopping() {
    _startAnimation();
    _state = SliderState.stopping;
  }
}

enum SliderState {
  starting,
  resting,
  sliding,
  stopping,
}

//
// —— CUSTOM PAINTER (canvas stuff) ———————————————————————————————————————————
//

/// Responsible for drawing the slider in all it's potential states.
class WavePainter extends CustomPainter {
  final double sliderPosition;
  final double dragPercentage;
  final Paint fillPainter;
  final Paint wavePainter;
  final Color color;
  final double animationProgress;
  final SliderState sliderState;

  // for determining if the current position is diff from previous pos.
  double _previousSliderPosition = 0;

  WavePainter(
      {@required this.animationProgress,
      @required this.sliderState,
      @required this.sliderPosition,
      @required this.dragPercentage,
      @required this.color})
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

    switch (sliderState) {
      case (SliderState.starting):
        _paintStartupWave(canvas, size);
        // _paintSlidingWave(canvas, size);
        break;
      case (SliderState.stopping):
        _paintStoppingWave(canvas, size);
        break;
      case (SliderState.sliding):
        _paintSlidingWave(canvas, size);
        break;
      case (SliderState.resting):
        _paintRestingWave(canvas, size);
        break;
      default:
        break;
    }
  }

  // Sub Paint loops; each draw a part of the animation and are
  // Then collected and painted by `paint`.

  // ------ SUB PAINT LOOPS ---------------------------------------------------
  // -- different parts of the animation

  void _paintStartupWave(Canvas canvas, Size size) {
    WaveCurveDefinitions line = _calculateWaveLineDefinitions(size);

    double waveHeight = lerpDouble(
        size.height,
        line.controlHeight,
        Curves.elasticOut
            .transform(animationProgress)); // for bouncing animation

    line.controlHeight = waveHeight;
    _paintWaveLine(canvas, size, line);
  }

  void _paintStoppingWave(Canvas canvas, Size size) {
    WaveCurveDefinitions line = _calculateWaveLineDefinitions(size);

    double waveHeight = lerpDouble(
        line.controlHeight,
        size.height,
        Curves.elasticOut
            .transform(animationProgress)); // for bouncing animation

    line.controlHeight = waveHeight;
    _paintWaveLine(canvas, size, line);
  }

  void _paintSlidingWave(Canvas canvas, Size size) {
    WaveCurveDefinitions wd = _calculateWaveLineDefinitions(size);
    _paintWaveLine(canvas, size, wd);
  }

  void _paintRestingWave(Canvas canvas, Size size) {
    Path path = Path();
    path.moveTo(0.0, size.height);
    path.lineTo(size.width, size.height);
    canvas.drawPath(path, wavePainter);
  }

  void _paintAnchors(Canvas canvas, Size size) {
    canvas.drawCircle(Offset(0.0, size.height), 5.0, fillPainter);
    canvas.drawCircle(Offset(size.width, size.height), 5.0, fillPainter);
  }

  /// - Calculates the definitions of the wave line
  /// - Everytime we paint, based on the input of a gesture,
  /// calculates the bend start and ends, as well as the control points of the bezier.
  /// - Returns a set of WaveCurveDefinitions that can be used in _paintWaveLine
  WaveCurveDefinitions _calculateWaveLineDefinitions(Size size) {
    double controlHeight = 0.0;
    double bendWidth = 20;
    double bezierWidth = 20;

    double centerPoint = sliderPosition;
    centerPoint = (centerPoint > size.width) ? size.width : centerPoint;
    double startOfBend = sliderPosition - bendWidth / 2;
    double startOfBezier = startOfBend - bezierWidth;
    double endOfBend = sliderPosition + bendWidth / 2;
    double endOfBezier = endOfBend + bezierWidth;

    // don't let the start or end of bend go below 0.
    startOfBend = (startOfBend <= 0.0) ? 0.0 : startOfBend;
    startOfBezier = (startOfBezier <= 0.0) ? 0.0 : startOfBezier;
    endOfBend = (endOfBend >= size.width) ? size.width : endOfBend;
    endOfBezier = (endOfBezier >= size.width) ? size.width : endOfBezier;

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

    // interpolates how much we want the bend: faster the move -> faster it bends
    double bend =
        lerpDouble(0.0, bendability, slideDifference / maxSlideDifference);

    // Adjust bending based on direction
    bool moveLeft = sliderPosition < _previousSliderPosition;
    bend = moveLeft ? -bend : bend;
    leftControlPoint1 = leftControlPoint1 + bend;
    leftControlPoint2 = leftControlPoint2 - bend;
    rightControlPoint1 = rightControlPoint2 - bend;
    rightControlPoint2 = rightControlPoint2 + bend;
    centerPoint = centerPoint - bend;

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
  _paintWaveLine(Canvas canvas, Size size, WaveCurveDefinitions wd) {
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

// Repeatedly used parts of the bezier; DRY.
class WaveCurveDefinitions {
  final double startOfBend;
  final double startOfBezier;
  final double endOfBend;
  final double endOfBezier;
  double controlHeight;
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
