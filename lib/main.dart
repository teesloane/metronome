import 'package:audioplayers/audio_cache.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:async';

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
  Timer _timer;
  static AudioCache player = AudioCache();

  bool _isRunning = false;
  int _beat = 1;
  int _bar = 4;
  // int _tempo = 500; // ms

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

  _toggleTimer() {
    if (this._isRunning) {
      // stop the timer
      _timer.cancel();
      setState(() {
        _isRunning = false;
      });
    } else {
      // start the timer
      const dur = const Duration(milliseconds: 500); // TODO: make dynamic.
      _timer = Timer.periodic(dur, _metroInc);
      setState(() {
        _isRunning = true;
      });
    }
  }

  _buildToggleButton() {
    if (this._isRunning) {
      return MaterialButton(
          child: Text("Stop"),
          onPressed: () {
            _toggleTimer();
          },
          color: Colors.orangeAccent);
    } else {
      return MaterialButton(
          child: Text("Start"),
          onPressed: () {
            _toggleTimer();
          },
          color: Colors.orangeAccent);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
          child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
            Text(
              '$_beat / $_bar',
              style: Theme.of(context).textTheme.display1,
            ),
            _buildToggleButton()
          ])),
    );
  }
}
