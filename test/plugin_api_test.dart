import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_lid_effect/flutter_lid_effect.dart';

void main() {
  testWidgets('unsupported platform returns the original child', (
    tester,
  ) async {
    const child = SizedBox(key: ValueKey('original'));
    await tester.pumpWidget(
      const MediaQuery(
        data: MediaQueryData(),
        child: LidAngleEffect(child: child),
      ),
    );
    expect(find.byKey(const ValueKey('original')), findsOneWidget);
    expect(find.byType(ImageFiltered), findsNothing);
  });

  testWidgets('disabling an active effect preserves child and stops frames', (
    tester,
  ) async {
    final angles = StreamController<LidAngleReading>.broadcast();
    final key = GlobalKey();
    Widget host(bool enabled) => MediaQuery(
      data: const MediaQueryData(),
      child: LidAngleEffect(
        enabled: enabled,
        angles: angles.stream,
        startAngle: 100,
        fullEffectAngle: 50,
        child: SizedBox(key: key),
      ),
    );
    await tester.pumpWidget(host(true));
    final original = key.currentContext;
    angles.add(const LidAngleReading(angle: 120, reset: true));
    await tester.pump();
    angles.add(const LidAngleReading(angle: 60));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(
      tester.widget<ImageFiltered>(find.byType(ImageFiltered)).enabled,
      isTrue,
    );
    await tester.pumpWidget(host(false));
    expect(
      tester.widget<ImageFiltered>(find.byType(ImageFiltered)).enabled,
      isFalse,
    );
    expect(key.currentContext, same(original));
    expect(tester.hasRunningAnimations, isFalse);
    await tester.pumpWidget(const SizedBox());
    unawaited(angles.close());
    await tester.pump();
  });

  test('malformed hardware values never become angles', () {
    expect(LidAngleReading.fromEvent({'angle': double.nan}).angle, isNull);
    expect(LidAngleReading.fromEvent({'angle': 361}).angle, isNull);
    expect(LidAngleReading.fromEvent({'angle': 90}).angle, 90);
    expect(LidAngleReading.fromEvent(null).reset, isTrue);
  });
}
