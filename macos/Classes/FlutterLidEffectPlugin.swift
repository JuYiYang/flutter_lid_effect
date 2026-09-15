import Cocoa
import FlutterMacOS

public final class FlutterLidEffectPlugin: NSObject, FlutterPlugin {
  private let bridge: LidAngleBridge

  private init(registrar: FlutterPluginRegistrar) {
    bridge = LidAngleBridge(view: registrar.view, messenger: registrar.messenger)
    super.init()
  }

  public static func register(with registrar: FlutterPluginRegistrar) {
    let plugin = FlutterLidEffectPlugin(registrar: registrar)
    registrar.publish(plugin)
  }
}
