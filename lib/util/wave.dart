import 'dart:math';

import 'package:flutter/material.dart';
import 'package:wave_clock/util/config.dart';

class WavesWidget extends StatefulWidget {
  WavesWidget({
    @required this.config,
    this.duration = 5000,
    this.wavesAmplitude = 20.0,
    this.wavesFrequency = 1.5,
    this.wavesPhase = 10.0,
    this.backgroundColor,
    this.heightPercentage = 0.25,
    double width = double.infinity,
    double height = double.infinity,
  }) : size = Size(width, height);

  final WavesConfig config;
  final Size size;
  final double wavesAmplitude;
  final double wavesPhase;
  final double wavesFrequency;
  final double heightPercentage;
  final int duration;
  final Color backgroundColor;

  @override
  State<StatefulWidget> createState() => _WavesWidgetState();
}

class _WavesWidgetState extends State<WavesWidget> with TickerProviderStateMixin {
  List<AnimationController> _controllers;
  List<Animation<double>> _phaseVales;

  Map<Animation<double>, AnimationController> valueList;

  final List<double> _waveAmplitudes = [];

  @override
  void initState() {
    super.initState();
    _initAnimations();
  }

  @override
  void dispose() {
    _disposeAnimations();
    super.dispose();
  }

  void _initAnimations() {
    if (widget.config is WavesConfigCustom) {
      final WavesConfigCustom config = widget.config;
      _controllers = config.durations.map((duration) {
        _waveAmplitudes.add(widget.wavesAmplitude + 10);
        return AnimationController(vsync: this, duration: Duration(milliseconds: duration));
      }).toList();

      _phaseVales = _controllers.map((controller) {
        final curve = CurvedAnimation(parent: controller, curve: Curves.easeInOut);
        final value = Tween(
          begin: widget.wavesPhase,
          end: 360 + widget.wavesPhase,
        ).animate(curve)
          ..addStatusListener((status) {
            switch (status) {
              case AnimationStatus.completed:
                controller.reverse();
                break;
              case AnimationStatus.dismissed:
                controller.forward();
                break;
              default:
                break;
            }
          });
        controller.forward();
        return value;
      }).toList();
    }
  }

  List<Widget> _buildPaints() {
    final paints = <Widget>[];
    if (widget.config is WavesConfigCustom) {
      final WavesConfigCustom config = widget.config;
      final colors = config.colors;
      final gradients = config.gradients;
      final begin = config.gradientBegin;
      final end = config.gradientEnd;
      for (int i = 0; i < _phaseVales.length; i++) {
        paints.add(
          Container(
            child: CustomPaint(
              painter: _CustomWavesPainter(
                color: colors == null ? null : colors[i],
                gradient: gradients == null ? null : gradients[i],
                gradientBegin: begin,
                gradientEnd: end,
                heightPercentage: config.heightPercentages[i],
                repaint: _controllers[i],
                waveFrequency: widget.wavesFrequency,
                wavePhaseValue: _phaseVales[i],
                waveAmplitude: _waveAmplitudes[i],
                blur: config.blur,
              ),
              size: widget.size,
            ),
          ),
        );
      }
    }
    return paints;
  }

  void _disposeAnimations() {
    for (final controller in _controllers) {
      controller.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: widget.backgroundColor,
      child: Stack(
        children: _buildPaints(),
      ),
    );
  }
}

class Layer {
  Layer({
    this.color,
    this.gradient,
    this.blur,
    this.path,
    this.amplitude,
    this.phase,
  });

  final Color color;
  final List<Color> gradient;
  final MaskFilter blur;
  final Path path;
  final double amplitude;
  final double phase;
}

class _CustomWavesPainter extends CustomPainter {
  _CustomWavesPainter({
    this.color,
    this.gradient,
    this.gradientBegin,
    this.gradientEnd,
    this.blur,
    this.waveAmplitude,
    this.wavePhaseValue,
    this.waveFrequency,
    this.heightPercentage,
    Listenable repaint,
  }) : super(repaint: repaint);

  final Color color;
  final List<Color> gradient;
  final Alignment gradientBegin;
  final Alignment gradientEnd;
  final MaskFilter blur;
  final double waveAmplitude;
  final Animation<double> wavePhaseValue;
  final double waveFrequency;
  final double heightPercentage;

  final _paint = Paint();

  double _tempA = 0.0;
  double _tempB = 0.0;
  double _viewWidth = 0.0;

  void _setPaths(double viewCenterY, Size size, Canvas canvas) {
    final _layer = Layer(
      path: Path(),
      color: color,
      gradient: gradient,
      blur: blur,
      amplitude: (-1.6 + 0.8) * waveAmplitude,
      phase: wavePhaseValue.value * 2 + 30,
    );

    _layer.path.reset();
    _layer.path.moveTo(0.0, viewCenterY + _layer.amplitude * _getSinY(_layer.phase, waveFrequency, -1));
    for (int i = 1; i < size.width + 1; i++) {
      _layer.path.lineTo(i.toDouble(), viewCenterY + _layer.amplitude * _getSinY(_layer.phase, waveFrequency, i));
    }

    _layer.path.lineTo(size.width, size.height);
    _layer.path.lineTo(0.0, size.height);
    _layer.path.close();
    if (_layer.color != null) {
      _paint.color = _layer.color;
    }
    if (_layer.gradient != null) {
      final rect = Offset.zero & Size(size.width, size.height - viewCenterY * heightPercentage);
      _paint.shader = LinearGradient(
        begin: gradientBegin ?? Alignment.bottomCenter,
        end: gradientEnd ?? Alignment.topCenter,
        colors: _layer.gradient,
      ).createShader(rect);
    }
    if (_layer.blur != null) {
      _paint.maskFilter = _layer.blur;
    }

    _paint.style = PaintingStyle.fill;
    canvas.drawPath(_layer.path, _paint);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final viewCenterY = size.height * (heightPercentage + 0.1);
    _viewWidth = size.width;
    _setPaths(viewCenterY, size, canvas);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }

  double _getSinY(double startRadius, double waveFrequency, int currentPosition) {
    if (_tempA == 0) {
      _tempA = pi / _viewWidth;
    }
    if (_tempB == 0) {
      _tempB = 2 * pi / 360.0;
    }

    return sin(_tempA * waveFrequency * (currentPosition + 1) + startRadius * _tempB);
  }
}
