import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// A sensor sample or a reset caused by sleep, visibility or sensor failure.
class LidAngleReading {
  const LidAngleReading({this.angle, this.available, this.reset = false});

  final double? angle;
  final bool? available;
  final bool reset;

  factory LidAngleReading.fromEvent(dynamic event) {
    if (event is! Map) return const LidAngleReading(reset: true);
    final raw = event['angle'];
    final angle = raw is num ? raw.toDouble() : null;
    return LidAngleReading(
      angle: angle != null && angle.isFinite && angle >= 0 && angle <= 360
          ? angle
          : null,
      available: event['available'] is bool ? event['available'] as bool : null,
      reset: event['reset'] == true,
    );
  }
}

/// Shared broadcast stream scoped to this Flutter engine's registered view.
/// Only samples when its window is visible on the built-in display.
abstract final class LidAngleSensor {
  static bool get isSupported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.macOS;
  static const _channel = EventChannel('flutter_lid_effect/angles');
  static final _readings = _channel.receiveBroadcastStream().map(
    LidAngleReading.fromEvent,
  );
  static Stream<LidAngleReading> get readings => isSupported
      ? _readings
      : Stream.value(const LidAngleReading(available: false, reset: true));
}
