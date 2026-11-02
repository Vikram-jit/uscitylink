import Flutter
import UIKit
import GoogleMaps
import PushKit
import flutter_callkit_incoming

// import flutter_local_notifications

// One Flutter engine for the whole app, started at launch. With the UIScene lifecycle Flutter would
// otherwise create its engine only when a window opens — but when the app is killed, iOS launches
// it in the background for an incoming call (VoIP push) WITHOUT a window. The engine, the plugins
// and the PushKit registry must exist by then, or the call can't be shown (and iOS stops
// delivering VoIP pushes to apps that fail to report them). SceneDelegate shows this same engine
// when the window opens.
@main
@objc class AppDelegate: FlutterAppDelegate, PKPushRegistryDelegate {
  lazy var flutterEngine = FlutterEngine(name: "uscitylink")
  // Strong reference: a registry that is released stops receiving VoIP pushes
  private var voipRegistry: PKPushRegistry?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GMSServices.provideAPIKey("AIzaSyBoOuJLi6p2J748EZDbRKibMpVEXiZbSi0")

    flutterEngine.run()
    GeneratedPluginRegistrant.register(with: flutterEngine)

    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
    }

    // Voice calls: VoIP pushes ring the phone through CallKit even when the app is closed.
    // Created after the plugins register, so the CallKit plugin exists when a push is delivered.
    let registry = PKPushRegistry(queue: DispatchQueue.main)
    registry.delegate = self
    registry.desiredPushTypes = [PKPushType.voIP]
    voipRegistry = registry

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // MARK: - PushKit (VoIP) — server/src/calls/callPush.ts sends these

  func pushRegistry(_ registry: PKPushRegistry, didUpdate credentials: PKPushCredentials, for type: PKPushType) {
    let token = credentials.token.map { String(format: "%02x", $0) }.joined()
    SwiftFlutterCallkitIncomingPlugin.sharedInstance?.setDevicePushTokenVoIP(token)
  }

  func pushRegistry(_ registry: PKPushRegistry, didInvalidatePushTokenFor type: PKPushType) {
    SwiftFlutterCallkitIncomingPlugin.sharedInstance?.setDevicePushTokenVoIP("")
  }

  func pushRegistry(
    _ registry: PKPushRegistry,
    didReceiveIncomingPushWith payload: PKPushPayload,
    for type: PKPushType,
    completion: @escaping () -> Void
  ) {
    guard type == .voIP else { return completion() }
    let p = payload.dictionaryPayload
    let callId = p["callId"] as? String ?? UUID().uuidString
    let callerRole = p["callerRole"] as? String ?? "staff"
    let callerName = p["callerName"] as? String ?? "Dispatch"
    let channelName = p["channelName"] as? String ?? ""

    // Same wording as lib/services/call/call_kit.dart
    let title = callerRole == "staff" ? (channelName.isEmpty ? "Dispatch" : channelName) : callerName
    let subtitle = callerRole == "staff" ? "Dispatch · \(callerName)" : "Driver · \(channelName)"

    let data = flutter_callkit_incoming.Data(id: callId, nameCaller: title, handle: subtitle, type: 0)
    data.appName = "USCityLink"
    data.duration = 45000
    data.handleType = "generic"
    data.supportsVideo = false
    data.maximumCallGroups = 1
    data.maximumCallsPerCallGroup = 1
    data.audioSessionMode = "voiceChat"
    data.extra = [
      "callId": callId,
      "callerId": p["callerId"] as? String ?? "",
      "callerName": callerName,
      "callerRole": callerRole,
      "channelId": p["channelId"] as? String ?? "",
      "channelName": channelName,
      "callType": p["callType"] as? String ?? "audio",
    ] as NSDictionary
    // iOS requires every VoIP push to be reported to CallKit right away
    if let plugin = SwiftFlutterCallkitIncomingPlugin.sharedInstance {
      // Only one call at a time is allowed, so a call left over in CallKit (caller hung up while the
      // app was closed) would make iOS reject this one. The server only rings a driver who isn't on
      // a call, so anything else still listed is stale: end it first.
      for active in plugin.activeCalls() {
        if let id = active["id"] as? String, id.lowercased() != callId.lowercased() {
          plugin.saveEndCall(id, 2)
        }
      }
      plugin.showCallkitIncoming(data, fromPushKit: true) { completion() }
    } else {
      completion()
    }
  }
}

/// Hosts the app's window (UIScene lifecycle) on the engine AppDelegate started at launch. Kept in
/// this file so no Xcode project change is needed; referenced from Info.plist as
/// $(PRODUCT_MODULE_NAME).SceneDelegate.
class SceneDelegate: FlutterSceneDelegate {
  override func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions
  ) {
    if let windowScene = scene as? UIWindowScene, let app = UIApplication.shared.delegate as? AppDelegate {
      let window = UIWindow(windowScene: windowScene)
      window.rootViewController = FlutterViewController(engine: app.flutterEngine, nibName: nil, bundle: nil)
      self.window = window
      window.makeKeyAndVisible()
    }
    super.scene(scene, willConnectTo: session, options: connectionOptions)
  }

  override func sceneDidDisconnect(_ scene: UIScene) {
    super.sceneDidDisconnect(scene)
    // Release the view so the engine can be shown again if iOS reconnects the scene later
    window?.rootViewController = nil
    window = nil
  }
}
