import Flutter
import UIKit
import GoogleMaps
import PushKit
import flutter_callkit_incoming

// import flutter_local_notifications

// UIScene lifecycle (required by upcoming iOS versions): the window is managed by SceneDelegate
// (Info.plist → UIApplicationSceneManifest) and plugins register on the implicit Flutter engine.
@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate, PKPushRegistryDelegate {
  // Strong reference: a registry that is released stops receiving VoIP pushes
  private var voipRegistry: PKPushRegistry?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GMSServices.provideAPIKey("AIzaSyBoOuJLi6p2J748EZDbRKibMpVEXiZbSi0")

    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    // Voice calls: VoIP pushes ring the phone through CallKit even when the app is closed.
    // Created after the plugins register, so the CallKit plugin exists when a push is delivered
    // (PushKit holds pending pushes until the registry is created).
    let registry = PKPushRegistry(queue: DispatchQueue.main)
    registry.delegate = self
    registry.desiredPushTypes = [PKPushType.voIP]
    voipRegistry = registry
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
      plugin.showCallkitIncoming(data, fromPushKit: true) { completion() }
    } else {
      completion()
    }
  }
}

/// Hosts the Flutter view for the app's window (UIScene lifecycle). Kept in this file so no
/// Xcode project change is needed; referenced from Info.plist as $(PRODUCT_MODULE_NAME).SceneDelegate.
class SceneDelegate: FlutterSceneDelegate {}
