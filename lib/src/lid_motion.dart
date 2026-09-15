import 'dart:math' as math;

/// Closing intent and critically damped smoothing, adapted from Mac-Duo.
/// Copyright 2026 Makito. Apache-2.0; see LICENSE and NOTICE..
class LidMotion {
  LidMotion({this.threshold = 90, this.fullEffectAngle = 30});

  final double threshold;
  final double fullEffectAngle;
  double get span => threshold - fullEffectAngle;
  double? _lastAngle;
  double _lastChange = 0;
  bool _armed = false;
  bool active = false;
  double target = 0;
  double value = 0;
  double velocity = 0;

  void reset() {
    _lastAngle = null;
    _armed = false;
    active = false;
    target = value = velocity = 0;
  }

  void sample(double angle, double time, {bool baseline = false}) {
    if (!angle.isFinite || angle < 0 || angle > 360) return;
    if (baseline) reset();
    final previous = _lastAngle;
    if (previous == null) {
      _lastAngle = angle;
      _lastChange = time;
      _armed = angle >= threshold;
      return;
    }
    _armed = _armed || angle >= threshold;
    final dt = time - _lastChange;
    final speed = angle != previous && dt > 0 ? (angle - previous) / dt : 0.0;
    if (angle != previous) {
      _lastAngle = angle;
      _lastChange = time;
    }
    if (active) {
      if (angle >= threshold && speed > 0 || angle >= threshold + 4) {
        active = false;
      }
    } else if (_armed && speed <= -2 && angle <= threshold) {
      active = true;
    }
    target = active ? ((threshold - angle) / span).clamp(0.0, 1.0) : 0;
  }

  /// Exact solution avoids frame-rate-dependent overshoot after a long frame.
  bool advance(double dt) {
    const frequency = 16.0;
    final elapsed = dt.clamp(0.0, 0.05);
    final offset = value - target;
    final c = velocity + frequency * offset;
    final decay = math.exp(-frequency * elapsed);
    value = target + (offset + c * elapsed) * decay;
    velocity = (velocity - frequency * c * elapsed) * decay;
    if ((value - target).abs() < 0.0001 && velocity.abs() < 0.001) {
      value = target;
      velocity = 0;
      return false;
    }
    return true;
  }
}
