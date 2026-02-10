import Flutter
import UIKit
import GoogleMaps

// import flutter_local_notifications

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GMSServices.provideAPIKey("AIzaSyBoOuJLi6p2J748EZDbRKibMpVEXiZbSi0")

    // FlutterLocalNotificationPlugin.setPluginRegistrantCallback { (registry in GeneratedPluginRegistrant.register(with: register)) }
    GeneratedPluginRegistrant.register(with: self)
 if #available(iOS 10.0, *) {
    UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
  }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
