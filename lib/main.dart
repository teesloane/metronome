import 'package:audioplayers/audio_cache.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:async';

import 'package:metronome/tempoSlider.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.lightGreen,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

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
  Duration _tempo = Duration(milliseconds: 500);
  bool _isRunning = false;
  double _tempo2 = 0;
  double _sliderOffset = 20;

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

  // _onVerticalGesture(DragUpdateDetails details) {
  //   setState(() {
  //     _tempo += Duration(milliseconds: details.delta.dy.round());
  //   });
  // }

  // _onReleaseTempoSlider() {
  //   // If running, stop it, adjust tempo with new timer and resume
  //   if (_isRunning) {
  //     _timer.cancel();
  //     setState(() {
  //       _timer = Timer.periodic(_tempo, _metroInc);
  //     });
  //   } else {
  //     print("do nothing"); // Remove at some point.
  //   }
  // }

  _toggleTimer() {
    if (_isRunning) {
      setState(() {
        _timer.cancel();
        _isRunning = false;
      });
    } else {
      setState(() {
        _timer = Timer.periodic(_tempo, _metroInc);
        _isRunning = true;
      });
    }
  }

  _buildToggleButton() {
    if (!_isRunning) {
      return MaterialButton(
          child: Text("Start"),
          onPressed: () {
            _toggleTimer();
          },
          color: Colors.orangeAccent);
    } else {
      return MaterialButton(
          child: Text("Stop"),
          onPressed: () {
            _toggleTimer();
          },
          color: Colors.orangeAccent);
    }
  }

  String getTempo() {
    var sliceOfString = _tempo.toString().substring(8, 11);
    var intTempo = (60000 / int.parse(sliceOfString)).round();
    return intTempo.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        // appBar: AppBar(
        //   title: Text(widget.title),
        // ),
        body: Center(
      child: Stack(children: <Widget>[
        Container(), // Makes the stack full screen size.
        Center(
          child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  '$_beat / $_bar',
                  style: Theme.of(context).textTheme.display1,
                ),
                _buildToggleButton(),
                Text(
                  getTempo(),
                  style: Theme.of(context).textTheme.display1,
                ),
                Text(_tempo2.toString()),

                // InteractableWidget,
              ]),
        ),
        // TempoScroller(
        //   notifyParent: _onVerticalGesture,
        //   handleOVDE: _onReleaseTempoSlider,
        // )

        Positioned(
          right: 0,
          bottom: _sliderOffset,
          // top: 50,
          child: RotatedBox(
            quarterTurns: 3,
            child: TempoSlider(
              width: MediaQuery.of(context).size.height - (_sliderOffset * 2),
              color: Colors.red,
              onChanged: (double val) {
                setState(() {
                  _tempo2 = (val * 100).roundToDouble();
                });
              },
              onChangedStart: (double val) {
                setState(() {
                  _tempo2 = (val * 100).roundToDouble();
                });
              },
            ),
          ),
        )
      ]),
    ));
  }
}

class TempoScroller extends StatelessWidget {
  final Function(DragUpdateDetails details) notifyParent;
  final Function() handleOVDE;
  TempoScroller(
      {Key key, @required this.notifyParent, @required this.handleOVDE})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Positioned(
        top: 0,
        bottom: 0,
        right: 0,
        child: Container(
            width: 45.0,
            child: GestureDetector(
                child: Container(color: Colors.lightGreen.withOpacity(0.3)),
                onVerticalDragEnd: (e) => handleOVDE(),
                onVerticalDragDown: (e) => print(e),
                onVerticalDragUpdate: (e) {
                  notifyParent(e);
                })));
  }
}
