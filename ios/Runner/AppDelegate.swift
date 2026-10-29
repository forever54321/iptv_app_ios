import Flutter
import UIKit
import StoreKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Program reminders: lets flutter_local_notifications show them while the
    // app is open and receive the tap that opens the channel.
    UNUserNotificationCenter.current().delegate = self
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    // Register the store channel via the engine's plugin registry. The implicit
    // engine sets up its binaryMessenger here BEFORE any rootViewController is
    // attached to the window, which is why registering in didFinishLaunchingWithOptions
    // failed (rootViewController was nil).
    // iPhone Duo hinge: "closed" / "partiallyOpen" / "fullyOpen" (or "none" on phones without one),
    // so the player can split into video-on-top + channels-below when the Duo is half folded.
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "iptv.hinge") {
      FlutterEventChannel(name: "iptv/hinge", binaryMessenger: registrar.messenger())
        .setStreamHandler(HingeBridge.shared)
    }

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
        } else if call.method == "ownsProduct", let id = call.arguments as? String {
          AppDelegate.ownsProduct(id, callback: callback)
        } else {
          callback(FlutterMethodNotImplemented)
        }
      }
    }
  }

  /// StoreKit 2: does this Apple ID currently own `id` (not refunded)?
  /// Lets a buyer keep Pro after a reinstall without tapping Restore.
  static func ownsProduct(_ id: String, callback: @escaping FlutterResult) {
    if #available(iOS 15.0, *) {
      Task {
        for await result in Transaction.currentEntitlements {
          if case .verified(let tx) = result, tx.productID == id, tx.revocationDate == nil {
            callback(true)
            return
          }
        }
        callback(false)
      }
    } else {
      callback(false)
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

/// Watches the iPhone Duo hinge with UIKit's UIHingeInteraction (iOS 27.1) and streams it to Flutter.
/// Looked up at runtime so the app still builds with SDKs that predate the hinge API and runs on
/// every other iPhone (they simply report "none").
final class HingeBridge: NSObject, FlutterStreamHandler {
  static let shared = HingeBridge()
  private var sink: FlutterEventSink?
  private var last: [String: Any] = ["status": "none"]
  private var interaction: AnyObject?

  private override init() {
    super.init()
    // Attach once a window scene is active (no SceneDelegate override needed).
    NotificationCenter.default.addObserver(forName: UIScene.didActivateNotification, object: nil, queue: .main) { note in
      if let w = (note.object as? UIWindowScene)?.windows.first { HingeBridge.shared.attach(to: w) }
    }
  }

  private func attachToActiveWindow() {
    let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
    if let w = scenes.first(where: { $0.activationState == .foregroundActive })?.windows.first ?? scenes.first?.windows.first {
      attach(to: w)
    }
  }

  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    sink = events
    attachToActiveWindow()
    events(last)
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    sink = nil
    return nil
  }

  /// Adds the hinge interaction to the app's window (once).
  func attach(to view: UIView) {
    guard interaction == nil, let cls: AnyClass = NSClassFromString("UIHingeInteraction") else { return }
    typealias Alloc = @convention(c) (AnyClass, Selector) -> Unmanaged<AnyObject>
    typealias Handler = @convention(block) (AnyObject, AnyObject) -> Void
    typealias Init = @convention(c) (AnyObject, Selector, Handler) -> Unmanaged<AnyObject>
    let allocSel = NSSelectorFromString("alloc"), initSel = NSSelectorFromString("initWithUpdateHandler:")
    guard let am = class_getClassMethod(cls, allocSel), let im = class_getInstanceMethod(cls, initSel) else { return }
    let handler: Handler = { [weak self] _, update in self?.handle(update) }
    let raw = unsafeBitCast(method_getImplementation(am), to: Alloc.self)(cls, allocSel).takeUnretainedValue()
    let obj = unsafeBitCast(method_getImplementation(im), to: Init.self)(raw, initSel, handler).takeRetainedValue()
    guard let i = obj as? UIInteraction else { return }
    interaction = obj
    view.addInteraction(i)
  }

  private func handle(_ update: AnyObject) {
    var out: [String: Any] = ["status": "none"]
    if let hinge = (update as? NSObject)?.value(forKey: "hinge") as? NSObject {
      let status = (hinge.value(forKey: "status") as? NSNumber)?.intValue ?? 0
      out["status"] = ["unknown", "closed", "partiallyOpen", "fullyOpen"][min(max(status, 0), 3)]
      if let a = hinge.value(forKey: "angle") as? NSNumber { out["angle"] = a.doubleValue * 180 / .pi }
    }
    last = out
    DispatchQueue.main.async { self.sink?(out) }
  }
}
