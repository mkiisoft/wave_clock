import 'dart:async';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_clock_helper/model.dart';
import 'package:wave_clock/util/config.dart';
import 'package:wave_clock/util/wave.dart';
import 'package:intl/intl.dart';

class WavesClock extends StatefulWidget {
  const WavesClock(this.model);

  final ClockModel model;

  @override
  _WavesClockState createState() => _WavesClockState();
}

class _WavesClockState extends State<WavesClock> with TickerProviderStateMixin {
  DateTime _dateTime = DateTime.now();
  Timer _timer;

  AnimationController _controller;
  Animation<double> _animation;

  void hola() {
    CupertinoApp();
  }

  @override
  void initState() {
    super.initState();
    widget.model.addListener(_updateModel);
    _updateTime();
    _updateModel();
    _initAnimation();
  }

  @override
  void didUpdateWidget(WavesClock oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.model != oldWidget.model) {
      oldWidget.model.removeListener(_updateModel);
      widget.model.addListener(_updateModel);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    widget.model.removeListener(_updateModel);
    widget.model.dispose();
    super.dispose();
  }

  void _updateModel() {
    setState(() {

    });
  }

  void _updateTime() {
    setState(() {
      _dateTime = DateTime.now();
      _timer = Timer(
        Duration(minutes: 1) - Duration(seconds: _dateTime.second) - Duration(milliseconds: _dateTime.millisecond),
        _updateTime,
      );
    });
  }

  void _initAnimation() {
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5000),
    )..forward();
    _animation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 1.0),
    );
  }

  Color _calculateDayAndNight(int minuteOfDay, Color light, Color dark) {
    final dayR = light.red;
    final dayG = light.green;
    final dayB = light.blue;
    final nightR = dark.red;
    final nightG = dark.green;
    final nightB = dark.blue;

    var partR = (dayR - nightR) / 720;
    var partG = (dayG - nightG) / 720;
    var partB = (dayB - nightB) / 720;

    var valueR = minuteOfDay <= 720 ? nightR + (minuteOfDay * partR) : dayR - (partR * (minuteOfDay - 720));
    var valueG = minuteOfDay <= 720 ? nightG + (minuteOfDay * partG) : dayG - (partG * (minuteOfDay - 720));
    var valueB = minuteOfDay <= 720 ? nightB + (minuteOfDay * partB) : dayB - (partB * (minuteOfDay - 720));

    return Color.fromARGB(255, valueR.toInt(), valueG.toInt(), valueB.toInt());
  }

  @override
  Widget build(BuildContext context) {
    final hour = DateFormat(widget.model.is24HourFormat ? 'HH' : 'hh').format(_dateTime);
    final minute = DateFormat('mm').format(_dateTime);
    final pmAm = DateFormat('a').format(_dateTime);
    final fontSize = MediaQuery.of(context).size.width / (widget.model.is24HourFormat ? 3.5 : 4.5);

    final dayColor = Color.fromARGB(255, 75, 172, 249);
    final nightColor = Color.fromARGB(255, 25, 25, 112);


    final minuteOfDay = int.parse(hour) * 60 + int.parse(minute);
    final bgColor = _calculateDayAndNight(minuteOfDay, dayColor, nightColor);

    return Container(
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(color: bgColor),
          Column(
            children: <Widget>[
              Expanded(
                child: SizedBox(),
              ),
              Flexible(
                flex: 1,
                child: AnimatedBuilder(
                  animation: _animation,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(
                        0.0,
                        150 - (Curves.fastLinearToSlowEaseIn.transform(_animation.value) * 150),
                      ),
                      child: child,
                    );
                  },
                  child: WavesWidget(
                    config: WavesConfigCustom(
                      gradients: [
                        [Colors.cyan, Color(0xFF0E1227)],
                        [Colors.blue[900], Color(0xFF23222D)],
                        [Color(0xFF50A49E), Color(0xFF243F7B)],
                      ],
                      durations: [
                        19440,
                        10800,
                        5000,
                      ],
                      heightPercentages: [
                        0.05,
                        0.25,
                        0.50,
                      ],
                      gradientBegin: Alignment.bottomLeft,
                      gradientEnd: Alignment.topRight,
                    ),
                  ),
                ),
              ),
            ],
          ),
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Opacity(
                  opacity: 0.8,
                  child: Text(
                    '$hour:$minute',
                    style: TextStyle(
                      fontSize: fontSize,
                      fontFamily: 'sans',
                      color: Theme.of(context).brightness == Brightness.light ? Colors.white : Colors.black,
                    ),
                  ),
                ),
                if (!widget.model.is24HourFormat)
                  Opacity(
                  opacity: 0.8,
                  child: Text(
                    '$pmAm',
                    style: TextStyle(
                      fontSize: fontSize * 0.5,
                      fontFamily: 'sans',
                      color: Theme.of(context).brightness == Brightness.light ? Colors.white : Colors.black,
                    ),
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
