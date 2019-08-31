import 'package:audioplayers/audio_cache.dart';
import 'package:flare_flutter/flare_actor.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:metronome/ctrl_vis.dart';
import 'package:metronome/tempoSlider.dart';
import 'package:metronome/util.dart';
import 'dart:async';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
          primarySwatch: Colors.lightGreen,
          textTheme: Theme.of(context).textTheme.apply(
                // fontFamily: 'Open Sans', // TODO: set a font.
                bodyColor: Colors.white,
                displayColor: Colors.white,
              )),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  static AudioCache player = AudioCache();
  Timer _timer;

  /// The incremented beat.
  int _beat = 1;

  /// The top number on the time signature.
  int _tsTop = 4;

  /// The bottom number on the time signature.
  int _tsBottom = 4;

  /// UI - The current tempo
  int _tempoInt = 120;

  /// The ms duration for the Darty async timer.
  Duration _tempoDuration = Duration(milliseconds: 500);

  /// Whether or not the metronome is running
  bool _isRunning = false;

  /// Used for deciding the UI offset of the sliders.
  double _sliderOffset = 100;

  /// Most recent slider value.
  double _lastTempoSliderVal = 0.33; // this coordinates to 120 bpm on init.

  /// Min/Max Tempo
  static double _minTempoBpm = 60; // move to constant
  static double _maxTempoBpm = 240; // move to constant
  double _maxTempoMS = bpmToMS(_maxTempoBpm);
  double _minTempoMS = bpmToMS(_minTempoBpm);

  /// Map of time signatures; _tsTop and _tsBottom are set based on the time signature slider
  /// as the value of the slider pulls values out of this map.
  final Map signatures = {
    0.0: [3, 4, "ani_tri"],
    0.1: [3, 4, "ani_tri"],
    0.2: [4, 4, "ani_square"],
    0.3: [4, 4, "ani_square"],
    0.4: [5, 4, "ani_square"],
    0.5: [5, 4, "ani_square"],
    0.6: [6, 4, "ani_square"],
    0.7: [6, 4, "ani_square"],
    0.8: [6, 8, "ani_square"],
    0.9: [6, 8, "ani_square"],
    1.0: [12, 8, "ani_square"],
  };

  String _currentAnimation = "ani_square";

  // Supers and Overrides
  MetroSimple _metroVisualizationCtlr; // better naming.

  @override
  void initState() {
    _metroVisualizationCtlr = MetroSimple(); // better naming
    super.initState();
  }

  // Methods --

  /// Increments the beats of the time signature.
  /// Runs checks on time signature to determine downbeat.
  void _metroInc(Timer timer) {
    // Play the sound
    if (_beat == 1) {
      player.play("click_1.mp3");
    } else {
      player.play("click_2.mp3");
    }

    // reset the beat to one if it matches time sig top
    if (_beat == _tsTop) {
      setState(() {
        _beat = 1;
      });
    } else {
      setState(() {
        _beat++;
      });
    }
  }

  void _toggleTimer() {
    if (_isRunning) {
      setState(() {
        _timer.cancel();
        _isRunning = false;
        _beat = 1;
      });
      _metroVisualizationCtlr.stopAnimations();
    } else {
      setState(() {
        _timer = Timer.periodic(_tempoDuration, _metroInc);
        _isRunning = true;
      });
      _metroVisualizationCtlr.startAnimations();
    }
  }

  void _stopTimer() {
    setState(() {
      _timer.cancel();
      _beat = 1;
      _isRunning = false;
    });
  }

  void _startTimer() {
    setState(() {
      _timer = Timer.periodic(_tempoDuration, _metroInc);
      _isRunning = true;
    });
    _metroVisualizationCtlr.startAnimations();
  }

  /// Sets the tempo of the metronome via incoming tempo slider value.
  /// TODO: Should be converted to "onSlider" -> change the ui tempo; that's all it does.
  _setTempo(double sliderVal) {
    // let's lerp the tempo, where max is 1000ms(60bpm) and min is 250ms(240)bpm
    var _scaledTempo = sliderVal * (_minTempoMS - _maxTempoMS) + _maxTempoMS;
    _lastTempoSliderVal = sliderVal;
    if (_isRunning) {
      _timer.cancel();
    }
    setState(() {
      _tempoInt = msToBpm(_scaledTempo).toInt();
    });
  }

  /// - Sets the new tempo when user releases slider
  /// - If metrotimer is running, it resumes it.
  /// - Sets the final UI tempo to be viewed by user.
  void _handleDragEnd() {
    var _scaledTempo =
        _lastTempoSliderVal * (_minTempoMS - _maxTempoMS) + _maxTempoMS;
    var uiTempo = _scaledTempo;

    if (_tsBottom == 8) {
      _scaledTempo /= 2;
    }

    //dry this out with _tempoInt and _tempoDur being done twice.
    if (_isRunning) {
      setState(() {
        _tempoDuration = Duration(milliseconds: _scaledTempo.toInt());
        _tempoInt = msToBpm(uiTempo).toInt();
        _timer = Timer.periodic(_tempoDuration, _metroInc);
        // reset beat count and animation.
        _beat = 1;
        _metroVisualizationCtlr.update(_tempoInt);
        // _metroShapeTime = 0;
      });
    } else {
      setState(() {
        _tempoDuration = Duration(milliseconds: _scaledTempo.toInt());
        _tempoInt = msToBpm(uiTempo).toInt();
        _metroVisualizationCtlr.update(_tempoInt);
      });
    }
  }

  _handleDragEndSignature() {
    _stopTimer();

    var _scaledTempo =
        _lastTempoSliderVal * (_minTempoMS - _maxTempoMS) + _maxTempoMS;
    var uiTempo = _scaledTempo;

    if (_tsBottom == 8) {
      _scaledTempo /= 2;
    }

    //dry this out with _tempoInt and _tempoDur being done twice.
    // tons of duplication here.
    if (_isRunning) {
      setState(() {
        _tempoDuration = Duration(milliseconds: _scaledTempo.toInt());
        _tempoInt = msToBpm(uiTempo).toInt();
        _timer = Timer.periodic(_tempoDuration, _metroInc);
        // reset beat count and animation.
        _beat = 1;
        _metroVisualizationCtlr.update(_tempoInt);
        // _metroShapeTime = 0;
      });
    } else {
      setState(() {
        _tempoDuration = Duration(milliseconds: _scaledTempo.toInt());
        _tempoInt = msToBpm(uiTempo).toInt();
        _metroVisualizationCtlr.update(_tempoInt);
      });
    }

    _startTimer();


  }

  // Time Signature stuff ---

  /// Turns a slider percentage into pulling vals out of sig map
  /// and setting them into the _ts states.
  /// todo - rename to "handleDragTimeSignature"
  void _setTimeSignature(double v) {
    var n = num.parse(v.toStringAsFixed(1));
    _stopTimer();
    setState(() {
      _tsTop = signatures[n][0];
      _tsBottom = signatures[n][1];
      _currentAnimation = signatures[n][2];
    });
    // _metroVisualizationCtlr.updateChosenAnimation(signatures[n][2]);
    _metroVisualizationCtlr.update(_tempoInt);
    // _setTempo(_lastTempoSliderVal);
  }

  // —— Builder Fns ———————————————————————————————————————————————————————————

  _buildToggleButton() {
    if (!_isRunning) {
      return IconButton(
        icon: Icon(Icons.play_arrow, color: Colors.white, size: 32),
        alignment: Alignment.center,
        onPressed: () => _toggleTimer(),
      );
    } else {
      return IconButton(
        icon: Icon(Icons.stop, color: Colors.white, size: 32),
        alignment: Alignment.center,
        onPressed: () => _toggleTimer(),
      );
    }
  }

  Container buildControlPanel() {
    return Container(
        height: 100,
        width: double.infinity,
        decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.04),
            border: Border(
                top:
                    BorderSide(width: 2.0, color: Colors.deepOrange.shade800))),
        child: Row(children: <Widget>[
          Expanded(
            child: Container(
                color: Colors.black12,
                alignment: Alignment.center,
                height: double.infinity,
                child: Text(
                  '$_tsTop / $_tsBottom',
                  style: Theme.of(context).textTheme.display1,
                )),
          ),
          Expanded(
              child: Container(
            color: Colors.black26,
            alignment: Alignment.center,
            height: double.infinity,
            child: Container(child: _buildToggleButton()),
          )),
          Expanded(
            child: Container(
                alignment: Alignment.center,
                color: Colors.black12,
                height: double.infinity,
                child: Text(_tempoInt.toString(),
                    style: Theme.of(context).textTheme.display1)),
          )
        ]));
  }

  /// Creates the main section where animations that represent the metronome are viewed.
  Expanded buildMetroRetro(BuildContext context) {
    return Expanded(
        flex: 1,
        child: Container(
          color: Colors.orange.withOpacity(0.02),
          child: Container(
              width: double.infinity,
              color: Colors.black12,
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Container(
                      height: 128,
                      // <-- 4. Main menu row
                      child: FlareActor('assets/$_currentAnimation.flr',
                          alignment: Alignment.center,
                          fit: BoxFit.contain,
                          // animation: "Main",
                          controller: _metroVisualizationCtlr),
                    )
                    // InteractableWidget,
                  ])),
        ));
  }

  String getTempo() {
    var sliceOfString = _tempoDuration.toString().substring(8, 11);
    var intTempo = (60000 / int.parse(sliceOfString)).round();
    return intTempo.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.white.withOpacity(0.1),
        body: AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle.light,
          child: Stack(
            children: <Widget>[
              Column(children: <Widget>[
                buildMetroRetro(context),
                buildControlPanel(),
              ]),
              Positioned(
                right: -4,
                bottom: _sliderOffset,
                child: RotatedBox(
                  quarterTurns: 3,
                  child: TempoSlider(
                    width: MediaQuery.of(context).size.height -
                        (_sliderOffset * 2),
                    color: Colors.white,
                    onChanged: (val) => _setTempo(val),
                    onChangedStart: (val) => _setTempo(val),
                    onChangedFinish: (v) => _handleDragEnd(),
                  ),
                ),
              ),
              Positioned(
                left: -4,
                bottom: _sliderOffset,
                child: RotatedBox(
                    quarterTurns: 1,
                    child: TempoSlider(
                        width: MediaQuery.of(context).size.height -
                            (_sliderOffset * 2),
                        color: Colors.white,
                        onChanged: (val) => _setTimeSignature(val),
                        onChangedStart: (val) => _setTimeSignature(val),
                        onChangedFinish: (v) => _handleDragEndSignature())),
              ),
            ],
          ),
        ));
  }
}
