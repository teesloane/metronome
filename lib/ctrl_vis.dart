import 'package:flare_dart/math/mat2d.dart';
import 'package:flare_flutter/flare.dart';
import 'package:flare_flutter/flare_controls.dart';
import 'package:metronome/util.dart';
// import 'package:metronome/flare_controls_patch.dart';

class MetroSimple extends FlareControls {
  FlutterActorArtboard _artboard;
  double _elapsedTime = 0.0;
  double _speed = 1.0;
  Map animations = {};
  ActorAnimation _ani;
  bool _isPlaying = false;
  int tempo;

  MetroSimple({ this.tempo = 120 });

  // @override
  advance(FlutterActorArtboard artboard, double elapsed) {
    super.advance(artboard, elapsed);

    // speed needs to be mapped between 0.5 (60pm) and 2.0 (240bpm)
    // basically, take tempo and map it's current value between 0.5 -> 2.0
    _speed = scaleNum(tempo, 60, 240, 0.5, 2.0);

    if (_isPlaying) {
      _artboard = artboard;
      _elapsedTime += elapsed * _speed;
      _ani.apply( _elapsedTime % _ani.duration, artboard, 1.0);
      return true;
    } else {
      _elapsedTime = 0;
      _ani.apply( _elapsedTime % _ani.duration, artboard, 1.0);
      return true;
    }
  }

  @override
  void initialize(FlutterActorArtboard artboard) {
    super.initialize(artboard);
    _ani = artboard.getAnimation("Main");
    // animations["Square"] = artboard.getAnimation("Square");
    // animations["Triangle"] = artboard.getAnimation("Triangle");
    // animations["Idle"] = artboard.getAnimation("Idle");
  }

  @override
  void setViewTransform(Mat2D viewTransform) {}

  
  updateChosenAnimation(val) {
    _elapsedTime = 0;
    // currentAni = val;
  }

  startAnimations() {
    _isPlaying = true;
  }

  stopAnimations() {
    _isPlaying = false; 
  }

  updateTempo(double t) {
    tempo = tempo; 
  }
  
  update(t) {
    tempo = t;
    _elapsedTime = 0; // start at beginning again.
  }
}
