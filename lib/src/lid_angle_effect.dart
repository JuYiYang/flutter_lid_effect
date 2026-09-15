import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/scheduler.dart';
import 'lid_angle_sensor.dart';
import 'package:flutter/widgets.dart';
import 'lid_motion.dart';

/// Filters only this Flutter view, including its Navigator overlays.
class LidAngleEffect extends StatefulWidget {
  const LidAngleEffect({
    super.key,
    required this.child,
    this.angles,
    this.enabled = true,
    this.startAngle = 90,
    this.fullEffectAngle = 30,
    this.maxBlurSigma = 24,
    this.maxDimOpacity = 0.85,
  }) : assert(startAngle > fullEffectAngle && startAngle <= 180),
       assert(fullEffectAngle >= 0),
       assert(maxBlurSigma >= 0),
       assert(maxDimOpacity >= 0 && maxDimOpacity <= 1);

  final bool enabled;
  final double startAngle;
  final double fullEffectAngle;
  final double maxBlurSigma;
  final double maxDimOpacity;

  final Widget child;

  /// Injectable stream for hardware-independent regression tests.
  final Stream<LidAngleReading>? angles;

  @override
  State<LidAngleEffect> createState() => _LidAngleEffectState();
}

class _LidAngleEffectState extends State<LidAngleEffect>
    with SingleTickerProviderStateMixin {
  late LidMotion _motion = _makeMotion();
  LidMotion _makeMotion() => LidMotion(
    threshold: widget.startAngle,
    fullEffectAngle: widget.fullEffectAngle,
  );
  final _clock = Stopwatch()..start();
  StreamSubscription<dynamic>? _subscription;
  late final Ticker _ticker;
  Duration _lastFrame = Duration.zero;
  bool _reducedMotion = false;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_tick);
    _subscribe();
  }

  void _subscribe() {
    if (widget.enabled &&
        (widget.angles != null || LidAngleSensor.isSupported)) {
      _subscription = (widget.angles ?? LidAngleSensor.readings).listen(
        _receive,
        onError: (Object error) => _reset(),
        onDone: _reset,
      );
    }
  }

  @override
  void didUpdateWidget(LidAngleEffect oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.enabled != widget.enabled ||
        oldWidget.angles != widget.angles ||
        oldWidget.startAngle != widget.startAngle ||
        oldWidget.fullEffectAngle != widget.fullEffectAngle) {
      _subscription?.cancel();
      _subscription = null;
      _reset();
      _motion = _makeMotion();
      _subscribe();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduced = MediaQuery.disableAnimationsOf(context);
    if (reduced != _reducedMotion) {
      _reducedMotion = reduced;
      _reset();
    }
  }

  void _reset() {
    if (!mounted) return;
    _ticker.stop();
    setState(_motion.reset);
  }

  void _receive(LidAngleReading event) {
    if (!mounted || _reducedMotion || !widget.enabled) return;
    if (event.reset) _reset();
    final angle = event.angle;
    if (angle == null) return;
    _motion.sample(angle.toDouble(), _clock.elapsedMicroseconds / 1e6);
    if ((_motion.target - _motion.value).abs() > 0.0001 && !_ticker.isActive) {
      _lastFrame = Duration.zero;
      _ticker.start();
    }
  }

  void _tick(Duration elapsed) {
    final dt = (elapsed - _lastFrame).inMicroseconds / 1e6;
    _lastFrame = elapsed;
    final moving = _motion.advance(dt);
    setState(() {});
    if (!moving) _ticker.stop();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _ticker.dispose();
    _clock.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.angles == null && !LidAngleSensor.isSupported) {
      return widget.child;
    }
    final p = _motion.value.clamp(0.0, 1.0);
    final blur = widget.maxBlurSigma * math.pow(p, 1.6).toDouble();
    final dim = widget.maxDimOpacity * math.pow(p, 0.7).toDouble();
    return LayoutBuilder(
      builder: (context, constraints) {
        final height = constraints.maxHeight;
        // Hinge at the bottom of the app content; recession into the window.
        final matrix = Matrix4.identity()
          ..setEntry(3, 2, height.isFinite && height > 0 ? 1 / (height * 6) : 0)
          ..rotateX(-p * math.pi / 3);
        return ClipRect(
          child: ColoredBox(
            color: const Color(0xff000000),
            child: Transform(
              alignment: Alignment.bottomCenter,
              transform: matrix,
              child: ImageFiltered(
                enabled: blur > 0,
                imageFilter: ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur),
                child: DecoratedBox(
                  position: DecorationPosition.foreground,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color.fromRGBO(0, 0, 0, dim),
                        Color.fromRGBO(0, 0, 0, dim * 0.2),
                      ],
                    ),
                  ),
                  child: widget.child,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
