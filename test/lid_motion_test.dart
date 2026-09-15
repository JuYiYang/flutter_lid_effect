import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_lid_effect/src/lid_motion.dart';

void main() {
  test(
    'starting below threshold and opening do not trigger closing effect',
    () {
      final motion = LidMotion();
      motion.sample(45, 0);
      motion.sample(40, 0.1);
      expect(motion.active, isFalse);
      motion.sample(70, 0.2);
      expect(motion.active, isFalse);
      motion.sample(110, 0.3);
      motion.sample(80, 0.4);
      expect(motion.active, isTrue);
      expect(motion.target, closeTo(1 / 6, 0.001));
      motion.sample(91, 0.5);
      expect(motion.active, isFalse);
      expect(motion.target, 0);
    },
  );

  test('spring follows a reversal and settles without an idle animation', () {
    final motion = LidMotion();
    motion.sample(110, 0);
    motion.sample(30, 0.1);
    for (var i = 0; i < 30; i++) {
      motion.advance(1 / 60);
      expect(motion.value, inInclusiveRange(0, 1));
    }
    expect(motion.value, greaterThan(0.9));
    motion.sample(110, 1);
    for (var i = 0; i < 120; i++) {
      motion.advance(1 / 60);
    }
    expect(motion.value, 0);
    expect(motion.advance(1 / 60), isFalse);
  });

  test('wake baseline and invalid reports never leave a stale effect', () {
    final motion = LidMotion();
    motion.sample(110, 0);
    motion.sample(30, 0.1);
    motion.advance(0.05);
    motion.sample(30, 1, baseline: true);
    expect(motion.active, isFalse);
    expect(motion.value, 0);
    motion.sample(double.nan, 2);
    motion.sample(-1, 3);
    expect(motion.target, 0);
  });
}
