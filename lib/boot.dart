import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'data/store.dart';
import 'services/notify.dart';

/// Background door for BOOT_COMPLETED — no UI, just re-arms reminders.
/// Invoked from native BootReceiver via the "bootReschedule" entrypoint,
/// never called from the app itself. The pragma keeps it alive
/// through tree-shaking in release builds.
@pragma('vm:entry-point')
Future<void> bootReschedule() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    final store = Store();
    await store.load();
    await NotifyService.init();
    await store.rescheduleAll();
  } catch (_) {}
  // Let the native receiver finish its goAsync window.
  try {
    await const MethodChannel('foxpiry_boot').invokeMethod('done');
  } catch (_) {}
}
