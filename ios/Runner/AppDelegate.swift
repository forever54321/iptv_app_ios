import Flutter
import UIKit
import StoreKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    // Register the store channel via the engine's plugin registry. The implicit
    // engine sets up its binaryMessenger here BEFORE any rootViewController is
    // attached to the window, which is why registering in didFinishLaunchingWithOptions
    // failed (rootViewController was nil).
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "iptv.store") {
      let channel = FlutterMethodChannel(
        name: "iptv/store",
        binaryMessenger: registrar.messenger()
      )
      channel.setMethodCallHandler { call, callback in
        if call.method == "getOriginalAppVersion" {
          AppDelegate.fetchOriginalAppVersion(refresh: false, callback: callback)
        } else if call.method == "refreshOriginalAppVersion" {
          AppDelegate.fetchOriginalAppVersion(refresh: true, callback: callback)
        } else {
          callback(FlutterMethodNotImplemented)
        }
      }
    }
  }

  static func fetchOriginalAppVersion(refresh: Bool, callback: @escaping FlutterResult) {
    if #available(iOS 16.0, *) {
      Task {
        do {
          if refresh {
            try await AppTransaction.refresh()
          }
          let verification = try await AppTransaction.shared
          switch verification {
          case .verified(let tx):
            callback(tx.originalAppVersion)
          case .unverified(let tx, _):
            callback(tx.originalAppVersion)
          }
        } catch {
          callback(FlutterError(
            code: "APP_TRANSACTION_ERROR",
            message: error.localizedDescription,
            details: nil
          ))
        }
      }
    } else {
      callback(nil)
    }
  }
}
