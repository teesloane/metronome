import 'package:audioplayers/audio_cache.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:async';

import 'package:metronome/tempoSlider.dart';
import 'package:metronome/util.dart';

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
  //
  // -- State
  //
  static AudioCache player = AudioCache();
  Timer _timer;
  int _beat = 1;
  int _bar = 4;
  int _tempoInt = 120;
  double maxTempo = 300;
  double minTempo = 30;
  Duration _tempoDuration = Duration(milliseconds: 500);
  bool _isRunning = false;
  double _sliderOffset = 100;

  // Methods --

  void _metroInc(Timer timer) {
    player.play("beep.mp3");
    if (_beat == _bar) {
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
      });
    } else {
      setState(() {
        _timer = Timer.periodic(_tempoDuration, _metroInc);
        _isRunning = true;
      });
    }
  }

  _setTempo(double sliderVal) {
    var _newTempo = (sliderVal * 100).toInt();
    var _scaledTempo =
        scaleNum(_newTempo, 0, 100, bpmToMS(minTempo), bpmToMS(maxTempo));

    // if running, cancel timer and restart it.
    if (_isRunning) {
      _timer.cancel();
      setState(() {
        _tempoDuration = Duration(milliseconds: _scaledTempo.toInt());
        _tempoInt = msToBpm(_scaledTempo).toInt();
        _timer = Timer.periodic(_tempoDuration, _metroInc);
      });
    } else {
      setState(() {
        _tempoDuration = Duration(milliseconds: _scaledTempo.toInt());
        _tempoInt = msToBpm(_scaledTempo).toInt();
      });
    }
  }

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

  String getTempo() {
    var sliceOfString = _tempoDuration.toString().substring(8, 11);
    var intTempo = (60000 / int.parse(sliceOfString)).round();
    return intTempo.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.white.withOpacity(0.1),
        body: Center(
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
                    onChanged: (val) => _setTempo(val),
                    onChangedStart: (val) => _setTempo(val),
                  ),
                ),
              ),
            ],
          ),
        ));
  }

  Container buildControlPanel() {
    return Container(
        height: 100,
        width: double.infinity,
        color: Colors.orange.withOpacity(0.04),
        child: Row(children: <Widget>[
          Expanded(
            child: Container(
                color: Colors.black12,
                alignment: Alignment.center,
                height: double.infinity,
                child: Text(
                  '$_beat / $_bar',
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
                    // InteractableWidget,
                  ])),
        ));
  }
}
