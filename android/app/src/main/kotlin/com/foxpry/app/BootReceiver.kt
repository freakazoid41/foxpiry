package com.foxpry.app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import io.flutter.FlutterInjector
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor.DartEntrypoint
import io.flutter.embedding.engine.loader.FlutterLoader
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit

/// Re-arms reminders after a reboot. Scheduled alarms don't survive
/// power-off, so without this the fox goes silent until next launch.
/// Runs the Dart "bootReschedule" entrypoint in a background engine —
/// no UI, no activity, 25s cap, never crashes the boot flow.
class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != Intent.ACTION_BOOT_COMPLETED) return
        val pending = goAsync()
        Thread {
            try {
                val app = context.applicationContext
                val loader: FlutterLoader =
                    FlutterInjector.instance().flutterLoader()
                if (!loader.initialized()) {
                    loader.startInitialization(app)
                }
                loader.ensureInitializationComplete(app, null)
                val engine = FlutterEngine(app)
                try {
                    Class.forName("io.flutter.plugins.GeneratedPluginRegistrant")
                        .getMethod(
                            "registerWith",
                            FlutterEngine::class.java
                        )
                        .invoke(null, engine)
                } catch (_: Exception) {
                }
                val latch = CountDownLatch(1)
                MethodChannel(
                    engine.dartExecutor.binaryMessenger,
                    "foxpiry_boot"
                ).setMethodCallHandler { _, result ->
                    result.success(null)
                    latch.countDown()
                }
                engine.dartExecutor.executeDartEntrypoint(
                    DartEntrypoint(
                        loader.findAppBundlePath(),
                        "bootReschedule"
                    )
                )
                latch.await(25, TimeUnit.SECONDS)
                engine.destroy()
            } catch (_: Exception) {
            } finally {
                pending.finish()
            }
        }.start()
    }
}
