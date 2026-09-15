import Cocoa
import FlutterMacOS

/// Publishes angles only for this window on the built-in display. No capture API.
final class LidAngleBridge: NSObject, FlutterStreamHandler {
  private weak var view: NSView?
  private let channel: FlutterEventChannel
  private var sensor: LidAngleSensor?
  private var sink: FlutterEventSink?
  private var timer: Timer?
  private var observers: [NSObjectProtocol] = []
  private var sleeping = false
  private var failures = 0
  private var eligible = false
  private var interval: TimeInterval = 0

  init(view: NSView?, messenger: FlutterBinaryMessenger) {
    self.view = view
    channel = FlutterEventChannel(name: "flutter_lid_effect/angles", binaryMessenger: messenger)
    super.init()
    channel.setStreamHandler(self)
    let center = NSWorkspace.shared.notificationCenter
    observers.append(center.addObserver(forName: NSWorkspace.willSleepNotification, object: nil, queue: .main) { [weak self] _ in
      self?.sleeping = true
      self?.reset()
    })
    observers.append(center.addObserver(forName: NSWorkspace.didWakeNotification, object: nil, queue: .main) { [weak self] _ in
      guard let self else { return }
      self.sleeping = false
      self.sensor = nil
      self.reset()
    })
  }

  deinit {
    timer?.invalidate()
    for observer in observers { NSWorkspace.shared.notificationCenter.removeObserver(observer) }
  }

  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    sink = events
    sensor = nil
    reset()
    schedule(1.0 / 8)
    poll()
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    timer?.invalidate()
    timer = nil
    interval = 0
    sink = nil
    sensor = nil
    eligible = false
    return nil
  }

  private func reset() {
    eligible = false
    failures = 0
    sink?(["reset": true])
  }

  private func schedule(_ value: TimeInterval) {
    guard interval != value else { return }
    interval = value
    timer?.invalidate()
    let timer = Timer(timeInterval: value, repeats: true) { [weak self] _ in self?.poll() }
    RunLoop.main.add(timer, forMode: .common)
    self.timer = timer
  }

  private func poll() {
    guard let window = view?.window, !sleeping, window.isVisible, !window.isMiniaturized,
      window.occlusionState.contains(.visible),
      let number = window.screen?.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber,
      CGDisplayIsBuiltin(number.uint32Value) != 0 else {
      if eligible { reset() }
      schedule(1.0 / 8)
      return
    }
    if sensor == nil { sensor = LidAngleSensor() }
    guard let sensor, sensor.isAvailable, let angle = sensor.angle() else {
      failures += 1
      if failures == 1 || failures == 10 { sink?(["reset": true, "available": false]) }
      if failures >= 10 { eligible = false; schedule(1) }
      // Re-enumerate occasionally so waking/reconnecting can recover.
      if failures >= 15 { self.sensor = nil; failures = 0 }
      return
    }
    failures = 0
    sink?(["angle": angle, "reset": !eligible, "available": true])
    eligible = true
    schedule(angle <= 110 ? 1.0 / 30 : 1.0 / 8)
  }
}
