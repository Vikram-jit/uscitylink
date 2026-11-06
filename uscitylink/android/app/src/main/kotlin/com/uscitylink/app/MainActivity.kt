package com.uscitylink.app

import android.os.Build
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // The call screen shows over the lock screen (like the phone's own calls), so a call answered
        // on a locked phone can be talked on without unlocking. lib/services/call/lock_screen.dart turns
        // it on only while the call screen is open: anywhere else the lock covers the app again.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "uscitylink/lock_screen")
            .setMethodCallHandler { call, result ->
                if (call.method == "showWhenLocked") {
                    showWhenLocked(call.argument<Boolean>("on") == true)
                    result.success(null)
                } else {
                    result.notImplemented()
                }
            }
    }

    private fun showWhenLocked(on: Boolean) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(on)
            setTurnScreenOn(on)
        } else {
            @Suppress("DEPRECATION")
            val flags = WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON
            if (on) window.addFlags(flags) else window.clearFlags(flags)
        }
    }
}
