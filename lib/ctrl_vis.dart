import 'package:flare_dart/math/mat2d.dart';
import 'package:flare_flutter/flare.dart';
import 'package:flare_flutter/flare_controls.dart';
import 'package:metronome/util.dart';

class MetroSimple extends FlareControls {
  FlutterActorArtboard _artboard;
  double _elapsedTime = 0.0;
  double _speed = 1.0;
  Map animations = {};
  ActorAnimation _ani;
  bool _isPlaying = false;
  int tempo;

  bool firstBeatPlayed = false;

  MetroSimple({this.tempo = 120});

  @override
  advance(FlutterActorArtboard artboard, double elapsed) {
    super.advance(artboard, elapsed);

    // speed needs to be mapped between 0.5 (60pm) and 2.0 (240bpm)
    // basically, take tempo and map it's current value between 0.5 -> 2.0
    _speed = scaleNum(tempo, 60, 240, 0.5, 2.0);

    if (_isPlaying && firstBeatPlayed) {
      _artboard = artboard;
      _elapsedTime += elapsed * _speed;
      _ani.apply(_elapsedTime % _ani.duration, artboard, 1.0);
      return true;
    } else {
      _elapsedTime = 0;
      _ani.apply(_elapsedTime % _ani.duration, artboard, 1.0);
      return true;
    }
  }

  @override
  void initialize(FlutterActorArtboard artboard) {
    super.initialize(artboard);
    _ani = artboard.getAnimation("Main");
  }

  @override
  void setViewTransform(Mat2D viewTransform) {}

  startAnimations() {
    _isPlaying = true;
  }

  stopAnimations() {
    _isPlaying = false;
  }

  /// restarts a visualization with updated tempo,
  restartVis(
    bool _firstBeatPlayed,
    int _tempoInt,
  ) {
    _elapsedTime = 0;
    firstBeatPlayed = _firstBeatPlayed;
    _isPlaying = true;
    tempo = _tempoInt;
  }

  updateTempo(t) {
    tempo = t;
    _elapsedTime = 0; // start at beginning again.
  }
}
