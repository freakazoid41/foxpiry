import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import '../models/item.dart';

class NotifyService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _init = false;

  static Future<void> init() async {
    if (_init) return;
    tzdata.initializeTimeZones();
    try {
      tz.setLocalLocation(tz.getLocation('Europe/Istanbul'));
    } catch (_) {}
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await _plugin.initialize(
        const InitializationSettings(android: android, iOS: ios));
    _init = true;
  }

  /// Android 13+ kills reminders silently when the user never granted
  /// the runtime permission. True = alerts can actually show.
  static Future<bool> ensurePermission() async {
    try {
      await init();
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (android == null) return true;
      if (await android.areNotificationsEnabled() ?? true) return true;
      return await android.requestNotificationsPermission() ?? false;
    } catch (_) {
      return false;
    }
  }

  static int _key(String id, int slot) =>
      (id.hashCode.abs() % 100000) * 10 + slot;

  static Future<void> scheduleFor(TrackedItem item, String lang) async {
    await init();
    await cancelFor(item.id);
    // 30, 7, 3, 1, 0 gün kala saat 09:00
    const offsets = [30, 7, 3, 1, 0];
    for (var i = 0; i < offsets.length; i++) {
      final off = offsets[i];
      final day =
          DateTime(item.date.year, item.date.month, item.date.day)
              .subtract(Duration(days: off));
      final when = DateTime(day.year, day.month, day.day, 9, 0);
      if (when.isBefore(DateTime.now())) continue;
      final title = _title(lang, off);
      await _plugin.zonedSchedule(
        _key(item.id, i),
        title,
        '${item.name} — ${item.date.day}.${item.date.month}.${item.date.year}',
        tz.TZDateTime.from(when, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
              'foxpiry_reminders', 'Foxpiry reminders',
              importance: Importance.high, priority: Priority.high),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
  }

  static String _title(String lang, int off) {
    final left = off == 0
        ? {'tr': 'Bugün son gün!', 'en': 'Last day today!', 'fr': "Dernier jour !", 'ru': 'Последний день!', 'hi': 'आज अंतिम दिन!'}
        : null;
    if (left != null) return left[lang] ?? left['en']!;
    const m = {
      'tr': 'gün kaldı', 'en': 'days left', 'fr': 'jours restants',
      'ru': 'дн. осталось', 'hi': 'दिन बाकी'
    };
    return 'Foxpiry • $off ${m[lang] ?? m['en']}';
  }

  static Future<void> cancelFor(String id) async {
    for (var i = 0; i < 5; i++) {
      await _plugin.cancel(_key(id, i));
    }
  }

  static Future<void> cancelAll() async => _plugin.cancelAll();
}
