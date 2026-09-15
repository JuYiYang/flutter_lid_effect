// Run with DEMO_FONT=/path/to/font.ttf DEMO_OUTPUT=/tmp/lid-frames flutter test tool/capture_preview_test.dart
import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_lid_effect/flutter_lid_effect.dart';

void main() {
  testWidgets('render the real effect with simulated lid angles', (
    tester,
  ) async {
    final output = Directory(
      Platform.environment['DEMO_OUTPUT'] ?? '/tmp/lid-frames',
    );
    await tester.runAsync(() async {
      await output.create(recursive: true);
      final font = Platform.environment['DEMO_FONT'];
      if (font != null) {
        final bytes = await File(font).readAsBytes();
        await (FontLoader(
          'DemoFont',
        )..addFont(Future.value(ByteData.sublistView(bytes)))).load();
      }
    });
    tester.view.physicalSize = const Size(760, 460);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final stream = StreamController<LidAngleReading>.broadcast();
    final angle = ValueNotifier<double>(120);
    final boundary = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(
        key: boundary,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            fontFamily: 'DemoFont',
            colorSchemeSeed: const Color(0xff6750a4),
          ),
          home: Scaffold(
            backgroundColor: const Color(0xff101827),
            body: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'flutter_lid_effect',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ValueListenableBuilder<double>(
                    valueListenable: angle,
                    builder: (_, value, _) => Text(
                      'SIMULATED LID ANGLE  ${value.round()}°  •  Flutter widget rendering',
                      style: const TextStyle(
                        color: Color(0xffb8c5dc),
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: LidAngleEffect(
                      angles: stream.stream,
                      child: ColoredBox(
                        color: const Color(0xfff4f6fb),
                        child: Padding(
                          padding: const EdgeInsets.all(28),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Your app, with a new perspective.',
                                style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Close to blur and dim. Open to restore.',
                                style: TextStyle(fontSize: 18),
                              ),
                              const SizedBox(height: 24),
                              Row(
                                children: [
                                  for (final label in [
                                    'Perspective',
                                    'Gaussian blur',
                                    'Gradient dim',
                                  ])
                                    Expanded(
                                      child: Card(
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 20,
                                          ),
                                          child: Center(child: Text(label)),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 18),
                              const Text(
                                'Application content only. No screen capture.',
                                style: TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Inspired by Mac-Duo by Makito',
                    style: TextStyle(color: Color(0xffb8c5dc), fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    stream.add(const LidAngleReading(angle: 120, reset: true));
    await tester.pump();
    for (var frame = 0; frame < 90; frame++) {
      final value = frame < 12
          ? 120.0
          : frame < 42
          ? 120 - (frame - 12) * 3.0
          : frame < 50
          ? 33.0
          : frame < 80
          ? 33 + (frame - 50) * 2.9
          : 120.0;
      angle.value = value;
      stream.add(LidAngleReading(angle: value));
      await tester.pump(const Duration(milliseconds: 67));
      await tester.runAsync(() async {
        final image =
            await (boundary.currentContext!.findRenderObject()!
                    as RenderRepaintBoundary)
                .toImage();
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        await File(
          '${output.path}/${frame.toString().padLeft(3, '0')}.png',
        ).writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
    }
    await tester.pumpWidget(const SizedBox());
    unawaited(stream.close());
    angle.dispose();
    await tester.pump();
  });
}
