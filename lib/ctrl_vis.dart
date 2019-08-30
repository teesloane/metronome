import 'package:flare_dart/math/mat2d.dart';
import 'package:flare_flutter/flare.dart';
import 'package:flare_flutter/flare_controls.dart';
// import 'package:metronome/flare_controls_patch.dart';

class MetroSimple extends FlareControls {
  FlutterActorArtboard _artboard;
  double _elapsedTime = 0.0;
  double _speed = 1.0;
  String currentAni = "Idle";
  Map animations = {};

  // @override
  advance(FlutterActorArtboard artboard, double elapsed) {
    super.advance(artboard, elapsed);
    _artboard = artboard;
    _elapsedTime += elapsed * _speed;
    var ani = animations[currentAni];
    ani.apply( _elapsedTime % ani.duration, artboard, 1.0);
    return true;
  }

  @override
  void initialize(FlutterActorArtboard artboard) {
    super.initialize(artboard);
    animations["Square"] = artboard.getAnimation("Square");
    animations["Triangle"] = artboard.getAnimation("Triangle");
    animations["Idle"] = artboard.getAnimation("Idle");
  }

  @override
  void setViewTransform(Mat2D viewTransform) {}

  
  updateChosenAnimation(val) {
    _elapsedTime = 0;
    currentAni = val;
  }
}
