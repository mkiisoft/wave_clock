import 'dart:ui';

import 'package:flutter/material.dart';

abstract class WavesConfig {
  const WavesConfig();
}

class WavesConfigCustom extends WavesConfig {
  const WavesConfigCustom({
    this.colors,
    this.gradients,
    this.gradientBegin,
    this.gradientEnd,
    @required this.durations,
    @required this.heightPercentages,
    this.blur,
  })  : assert(colors != null || gradients != null, '`gradients or `colors` must be provided.'),
        assert(colors == null || gradients == null, 'Cannot provide both gradients and colors.'),
        assert(durations != null, '`durations` must be provided.'),
        assert(heightPercentages != null, '`heightPercentages` must be provided.'),
        assert(
          colors == null ||
              colors != null && colors.length == durations.length && colors.length == heightPercentages.length,
          'Length of `colors`, `durations` and `heightPercentages` must be equal.',
        );

  final List<Color> colors;
  final List<List<Color>> gradients;
  final Alignment gradientBegin;
  final Alignment gradientEnd;
  final List<int> durations;
  final List<double> heightPercentages;
  final MaskFilter blur;
}
