# flutter_lid_effect

English | [简体中文](README.zh-CN.md)

Bring a lid-angle-driven depth effect to your Flutter app on macOS. As you close your MacBook, your app's content tilts, blurs, and dims smoothly; opening the lid restores it.

Inspired by [Mac-Duo](https://github.com/sumimakito/Mac-Duo) by [Makito](https://github.com/sumimakito). Thank you for sharing the original effect and sensor implementation with the open-source community.

## Features

- Read the built-in MacBook lid angle through a typed Dart stream.
- Apply perspective, Gaussian blur, and gradient dimming to Flutter content.
- Configure the trigger angle, full-effect angle, blur strength, and dimming.
- Preserve widget state while the effect changes.
- Reset on sleep, loss of window visibility, moving to an external display, or sensor failure.
- Respect the system's reduced-motion setting; stop animation ticks once settled.
- Preview the effect with simulated angles, without moving the physical lid.

The effect stays inside the Flutter view. It does not capture the screen, affect other apps, or require screen-recording permission. Native system dialogs are outside its scope.

## Requirements

- Flutter 3.38.0 or later and Dart SDK compatible with `^3.10.3`.
- The macOS plugin declares a minimum deployment target of macOS 10.15; your Flutter version or host app may require a newer version.
- A MacBook with a compatible built-in lid-angle sensor for hardware input.
- A visible host window on the built-in display, with the HID entitlement below.
- CocoaPods for native plugin integration.

`LidAngleSensor.isSupported` indicates platform support, not the presence of a compatible sensor. Without a custom angle stream, other platforms display the original child unchanged.

## Installation

Install from pub.dev:

```sh
flutter pub add flutter_lid_effect
```

Or declare the version directly:

```yaml
dependencies:
  flutter_lid_effect: ^0.1.0
```

[Package](https://pub.dev/packages/flutter_lid_effect) · [Source](https://github.com/JuYiYang/flutter_lid_effect) · [Issues](https://github.com/JuYiYang/flutter_lid_effect/issues)

### Local development

For local development, place the plugin beside your app and add:

```yaml
dependencies:
  flutter_lid_effect:
    path: ../flutter_lid_effect
```

Adjust the path to your checkout, then run `flutter pub get`. Native registration is automatic; you do not need to copy Swift files into Runner or modify `MainFlutterWindow`.

### Host entitlements

Add the following inside the root `<dict>` of **both** `macos/Runner/DebugProfile.entitlements` and `macos/Runner/Release.entitlements`. Keep App Sandbox enabled.

```xml
<key>com.apple.security.temporary-exception.iokit-user-client-class</key>
<array>
    <string>IOHIDLibUserClient</string>
</array>
```

This permits HID user-client access. The implementation matches Apple's built-in orientation sensor and reads its feature reports. The plugin cannot grant signing permissions to the host; without this entitlement, the sensor may appear unavailable. Mac App Store distribution may require justification and review of this temporary exception.

Perform a full rebuild and restart after adding the plugin or changing native permissions. Hot reload is insufficient.

## Quick start

Wrap your app's router content to include Flutter pages, dialogs, and drawers:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_lid_effect/flutter_lid_effect.dart';

void main() {
  runApp(
    MaterialApp(
      builder: (context, child) => LidAngleEffect(
        enabled: true,
        startAngle: 90,
        fullEffectAngle: 30,
        maxBlurSigma: 24,
        maxDimOpacity: 0.85,
        child: child ?? const SizedBox.shrink(),
      ),
      home: const Scaffold(
        body: Center(child: Text('Slowly close your MacBook')),
      ),
    ),
  );
}
```

The same `builder` pattern works with `MaterialApp.router` and `FluentApp.router`. You can also wrap a single bounded area of your interface.

### Configuration

| Parameter | Default | Description |
| --- | --- | --- |
| `enabled` | `true` | Enable the effect and its sensor subscription. |
| `startAngle` | `90` | Angle in degrees at which closing begins the effect. |
| `fullEffectAngle` | `30` | Angle at which visual intensity reaches its maximum. |
| `maxBlurSigma` | `24` | Maximum Gaussian blur sigma; `0` disables blur. |
| `maxDimOpacity` | `0.85` | Maximum dimming opacity at the top, from `0` to `1`. |
| `angles` | `null` | Optional `Stream<LidAngleReading>` replacing hardware input. |
| `child` | Required | Flutter content to transform. |

Use `0 <= fullEffectAngle < startAngle <= 180` and a nonnegative blur sigma. Changing the switch, angle thresholds, or input stream resets the movement baseline while preserving child state.

The sensor must first observe an angle at or above `startAngle`, then detect closing movement through the threshold. Starting the app or waking below that angle does not trigger an effect by itself. Opening the lid restores the content.

## Read angles directly

```dart
final subscription = LidAngleSensor.readings.listen((reading) {
  if (reading.reset) {
    // Discard previous movement history.
  }
  final degrees = reading.angle;
  if (degrees != null) {
    print('Lid angle: $degrees°');
  }
});

// Cancel when your controller or widget is disposed.
await subscription.cancel();
```

| Field | Meaning |
| --- | --- |
| `angle` | Degrees in `0...360`, or `null` for a status/reset event. This range is the report format, not the physical opening range of a MacBook. |
| `available` | `true`/`false` when sensor availability is reported; otherwise `null`. |
| `reset` | Discard stale movement history and treat the next angle as a fresh baseline. |

Listeners share one broadcast stream per Flutter engine. Sampling is scoped to that engine's registered view: its window must be visible on the built-in display. The stream is not an always-on background hardware monitor.

## Example and simulation

From the package directory:

```sh
cd example
flutter pub get
flutter run -d macos
```

Enable **Simulate angle**, then move the slider from 130° down through 90° and back. Type in the example's text field to check that its contents survive the effect. Controls remain outside the transformed area so you can reset it at any time.

For your own simulation, pass a `Stream<LidAngleReading>` through `angles`. Send a baseline such as `LidAngleReading(angle: 130, reset: true)`, followed by decreasing angles. Custom streams also work on non-macOS platforms. The system reduced-motion setting still applies.

## Troubleshooting

- **No effect:** check the host entitlements, sensor compatibility, built-in display, window visibility, and reduced-motion setting. Open past the start angle before closing again.
- **Works in simulation only:** simulation bypasses hardware; it does not validate the sensor or signing permissions.
- **Native changes are not applied:** fully stop, rebuild, and restart the app.
- **External display or native dialog is unaffected:** the effect is intentionally limited to Flutter content on the built-in display.

## Development

```sh
flutter test
flutter analyze
```

The `example` has its own widget test and macOS runner. Tests cover triggering, reversal, reset, state preservation, reduced motion, unsupported platforms, disabling the effect, and invalid readings. Physical lid motion, sleep/wake, and rendering performance should also be checked on target hardware.

## Acknowledgements

A special thank-you to **[Makito](https://github.com/sumimakito)** for **[Mac-Duo](https://github.com/sumimakito/Mac-Duo)**, the animation reference for this package, and for making its sensor code openly available.

- The native `LidAngleSensor.swift` is derived from Mac-Duo and retains its HID report-reading protocol.
- Closing-intent detection and critically damped smoothing draw on the reference implementation, adapted for Flutter.
- This plugin uses Flutter rendering for application-local perspective, uniform Gaussian blur, and gradient dimming. It does not port Mac-Duo's ScreenCaptureKit desktop capture or its Metal per-pixel gradient-blur renderer.

Mac-Duo is Copyright 2026 Makito, licensed under Apache-2.0. This package is distributed under [Apache-2.0](LICENSE) and retains the upstream [NOTICE](NOTICE). Both files are included as package assets. This is an independent adaptation, with no claim of upstream endorsement.
