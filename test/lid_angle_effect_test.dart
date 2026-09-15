import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_lid_effect/flutter_lid_effect.dart';

void main() {
  testWidgets(
    'angle effect resets on native failure and preserves child state',
    (tester) async {
      final angles = StreamController<dynamic>();
      final key = GlobalKey();
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: LidAngleEffect(
              angles: angles.stream.map(LidAngleReading.fromEvent),
              child: SizedBox(key: key, child: const Text('current app')),
            ),
          ),
        ),
      );
      final original = key.currentContext;
      angles.add({'angle': 110, 'reset': true});
      await tester.pump();
      angles.add({'angle': 40});
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(
        tester.widget<ImageFiltered>(find.byType(ImageFiltered)).enabled,
        isTrue,
      );
      expect(key.currentContext, same(original));
      angles.add({'reset': true, 'available': false});
      await tester.pump();
      expect(
        tester.widget<ImageFiltered>(find.byType(ImageFiltered)).enabled,
        isFalse,
      );
      expect(key.currentContext, same(original));
      expect(tester.hasRunningAnimations, isFalse);
      await tester.pumpWidget(const SizedBox());
      unawaited(angles.close());
      await tester.pump();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('reduced motion ignores lid movement', (tester) async {
    final angles = StreamController<dynamic>();
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: LidAngleEffect(
          angles: angles.stream.map(LidAngleReading.fromEvent),
          child: const SizedBox.expand(),
        ),
      ),
    );
    angles.add({'angle': 110});
    await tester.pump();
    angles.add({'angle': 30});
    await tester.pump();
    expect(
      tester.widget<ImageFiltered>(find.byType(ImageFiltered)).enabled,
      isFalse,
    );
    expect(tester.hasRunningAnimations, isFalse);
    await tester.pumpWidget(const SizedBox());
    unawaited(angles.close());
    await tester.pump();
  });
}
