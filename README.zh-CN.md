# flutter_lid_effect

[![pub package](https://img.shields.io/pub/v/flutter_lid_effect.svg)](https://pub.dev/packages/flutter_lid_effect)
[![Tests](https://github.com/JuYiYang/flutter_lid_effect/actions/workflows/ci.yml/badge.svg)](https://github.com/JuYiYang/flutter_lid_effect/actions/workflows/ci.yml)
[![License: Apache-2.0](https://img.shields.io/badge/license-Apache--2.0-blue.svg)](LICENSE)

[English](README.md) | 简体中文

**Flutter macOS 开合角度传感器与模糊动画插件。** 为应用添加由 MacBook 屏幕开合角度驱动的景深效果。缓慢合盖时，应用内容平滑倾斜、模糊、变暗；重新打开时恢复正常。

动画参考来自 [Makito](https://github.com/sumimakito) 的 [Mac-Duo](https://github.com/sumimakito/Mac-Duo)。感谢作者向开源社区分享原始动画效果与传感器实现。

## 效果预览

![Flutter macOS 开合动画：合盖时应用内容倾斜、模糊和变暗](https://raw.githubusercontent.com/JuYiYang/flutter_lid_effect/master/doc/media/lid-effect-preview.gif)

*使用实际 Flutter 组件渲染，角度为模拟输入，并非真实硬件合盖录像。效果仅作用于应用内容。*

## 功能

- 通过具有明确类型的 Dart 数据流读取 MacBook 内置开合角度传感器。
- 对 Flutter 内容应用透视、高斯模糊和渐变暗化。
- 可配置触发角度、最大效果角度、模糊强度和暗化程度。
- 动画期间保留组件状态。
- 休眠、窗口不可见、移动到外接屏或传感器读取失败时复位。
- 尊重系统“减少动画”设置，效果稳定后停止逐帧更新。
- 支持模拟角度，无需实际合盖即可预览。

效果仅作用于 Flutter 视图，不捕获屏幕、不影响其他应用，也不需要屏幕录制权限。系统原生对话框不在处理范围内。

## 环境要求

- Flutter 3.38.0 或更新版本，Dart SDK 满足 `^3.10.3`。
- macOS 插件声明的最低部署版本为 macOS 10.15；实际使用的 Flutter 或宿主应用可能要求更高版本。
- 使用真实角度时，需要配备兼容内置开合角度传感器的 MacBook。
- 宿主窗口在内置屏幕上可见，并配置下述 HID 权限。
- 原生插件通过 CocoaPods 集成。

`LidAngleSensor.isSupported` 只表示平台支持，不代表当前设备一定具有兼容传感器。未传入自定义角度流时，其他平台原样显示 `child`。

## 安装

从 pub.dev 安装：

```sh
flutter pub add flutter_lid_effect
```

也可以直接声明版本：

```yaml
dependencies:
  flutter_lid_effect: ^0.1.1
```

[包主页](https://pub.dev/packages/flutter_lid_effect) · [源码](https://github.com/JuYiYang/flutter_lid_effect) · [问题反馈](https://github.com/JuYiYang/flutter_lid_effect/issues)

### 本地开发

本地开发时，将插件与应用放在相邻目录，添加依赖：

```yaml
dependencies:
  flutter_lid_effect:
    path: ../flutter_lid_effect
```

根据实际目录调整路径，再执行 `flutter pub get`。原生插件自动注册，无需向 Runner 复制 Swift 文件，也无需修改 `MainFlutterWindow`。

### 宿主应用权限

在以下**两个文件**的根 `<dict>` 内添加权限，并保持 App Sandbox 启用：

- `macos/Runner/DebugProfile.entitlements`
- `macos/Runner/Release.entitlements`

```xml
<key>com.apple.security.temporary-exception.iokit-user-client-class</key>
<array>
    <string>IOHIDLibUserClient</string>
</array>
```

此权限允许访问 HID 用户客户端。实现只匹配 Apple 内置角度传感器并读取其特征报告。插件无法替宿主授予签名权限；缺少该配置时，传感器可能显示为不可用。如果通过 Mac App Store 分发，可能需要说明并审核此临时例外权限。

添加插件或更改原生权限后，请完整重新构建并重启应用，仅热重载无法生效。

## 快速开始

包裹应用路由内容，即可让 Flutter 页面、弹窗和抽屉一起参与效果：

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
        body: Center(child: Text('缓慢合上 MacBook 屏幕试试看')),
      ),
    ),
  );
}
```

同样适用于 `MaterialApp.router` 和 `FluentApp.router` 的 `builder`，也可以只包裹界面中具有明确尺寸的局部区域。

### 参数

| 参数 | 默认值 | 说明 |
| --- | --- | --- |
| `enabled` | `true` | 开启效果及对应的传感器订阅。 |
| `startAngle` | `90` | 向下合盖时开始触发效果的角度，单位为度。 |
| `fullEffectAngle` | `30` | 视觉强度达到最大时的角度。 |
| `maxBlurSigma` | `24` | 最大高斯模糊 sigma，设为 `0` 可关闭模糊。 |
| `maxDimOpacity` | `0.85` | 顶部最大暗化不透明度，范围为 `0` 到 `1`。 |
| `angles` | `null` | 可选的 `Stream<LidAngleReading>`，用于替代硬件输入。 |
| `child` | 必填 | 参与效果的 Flutter 内容。 |

角度应满足 `0 <= fullEffectAngle < startAngle <= 180`，模糊 sigma 不得小于零。改变开关、角度阈值或输入流时，会重置运动基准，同时保留子组件状态。

需要先观察到屏幕角度达到或超过 `startAngle`，再向下合盖跨过阈值。启动应用或唤醒时，如果屏幕已经低于阈值，不会仅因此触发效果。重新打开屏幕时，内容恢复正常。

## 只读取角度

```dart
final subscription = LidAngleSensor.readings.listen((reading) {
  if (reading.reset) {
    // 清除之前的运动记录。
  }
  final degrees = reading.angle;
  if (degrees != null) {
    print('屏幕开合角度：$degrees°');
  }
});

// 控制器或组件销毁时取消订阅。
await subscription.cancel();
```

| 字段 | 含义 |
| --- | --- |
| `angle` | `0...360` 范围的角度；状态或复位事件中可能为 `null`。此范围是报告格式，并非 MacBook 实际可打开的角度范围。 |
| `available` | 报告传感器可用性时为 `true` 或 `false`，其他情况下为 `null`。 |
| `reset` | 清除旧的运动记录，将下一次角度作为新的基准。 |

同一 Flutter 引擎中的订阅者共享广播流。采样与该引擎注册的视图关联，其窗口必须在内置屏幕上可见。这不是持续在后台运行的全局硬件监控流。

## 示例与模拟

在插件根目录执行：

```sh
cd example
flutter pub get
flutter run -d macos
```

开启 **Simulate angle**，将滑块从 130° 向下拖过 90°，再向上恢复。可以在示例输入框中输入内容，确认动画前后输入状态保持不变。控制区域位于效果之外，便于随时复位。

自行模拟时，通过 `angles` 传入 `Stream<LidAngleReading>`。先发送 `LidAngleReading(angle: 130, reset: true)` 建立基准，再发送逐渐减小的角度。非 macOS 平台也可以使用自定义流预览，系统“减少动画”设置仍然生效。

## 常见问题

- **没有效果：** 检查宿主权限、传感器兼容性、内置屏幕、窗口可见性及“减少动画”设置。先打开到触发角度以上，再合盖。
- **只有模拟有效：** 模拟绕过硬件，不代表传感器或签名权限已经验证通过。
- **原生修改未生效：** 完整停止、重新构建并重启应用。
- **外接屏或原生对话框不变化：** 效果限定于内置屏幕上的 Flutter 内容。

## 开发验证

```sh
flutter test
flutter analyze
```

`example` 包含独立的组件测试和 macOS 工程。测试覆盖触发、反向恢复、复位、状态保留、减少动画、不支持的平台、关闭效果和异常读数。实际设备上还应验证真实开合、休眠唤醒及渲染性能。

## 致谢

特别感谢 **[Makito](https://github.com/sumimakito)** 开源 **[Mac-Duo](https://github.com/sumimakito/Mac-Duo)**，为本包提供动画参考，并分享可复用的角度传感器代码。

- 原生 `LidAngleSensor.swift` 源自 Mac-Duo，保留其 HID 报告读取协议。
- 合盖意图判断和临界阻尼平滑借鉴参考实现，并针对 Flutter 做了适配。
- 本插件采用 Flutter 渲染应用内透视、整体高斯模糊和渐变暗化，没有移植 Mac-Duo 的 ScreenCaptureKit 桌面捕获或 Metal 逐像素渐变模糊渲染器。

Mac-Duo 版权所有：Copyright 2026 Makito，采用 Apache-2.0 许可证。本包以 [Apache-2.0](LICENSE) 分发，并保留上游 [NOTICE](NOTICE)，两者均随包资源提供。本包是独立适配项目，不代表上游作者对本包的背书。
