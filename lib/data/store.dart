import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' hide Category;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/item.dart';
import '../services/notify.dart';

class Store extends ChangeNotifier {
  static const _itemsKey = 'foxpiry_items_v1';
  static const _langKey = 'foxpiry_lang';
  static const _notifKey = 'foxpiry_notif';
  static const _codesKey = 'foxpiry_barcodes_v1';
  static const _permAskedKey = 'foxpiry_perm_asked';

  final _uuid = const Uuid();
  SharedPreferences? _prefs;
  Future<SharedPreferences> _prefsAsync() async =>
      _prefs ??= await SharedPreferences.getInstance();
  List<TrackedItem> items = [];
  String lang = 'tr';
  bool notifOn = true;
  bool loaded = false;

  /// Learned barcode → {name, category} pairs. Survives offline.
  Map<String, Map<String, dynamic>> codeMemory = {};

  String newId() => _uuid.v4();

  String _systemLang() {
    try {
      final code = PlatformDispatcher.instance.locale.languageCode
          .toLowerCase()
          .split('_')
          .first;
      const supported = ['tr', 'en', 'fr', 'ru', 'hi'];
      if (supported.contains(code)) return code;
    } catch (_) {}
    return 'tr';
  }

  /// True once the startup permission nudge has fired — asked once,
  /// never nagged every launch. The settings switch always asks.
  Future<bool> permAsked() async {
    try {
      return (await _prefsAsync()).getBool(_permAskedKey) ?? false;
    } catch (_) {
      return true;
    }
  }

  Future<void> markPermAsked() async {
    try {
      await (await _prefsAsync()).setBool(_permAskedKey, true);
    } catch (_) {}
  }

  Future<void> load() async {
    final p = await _prefsAsync();
    // New installs sniff the device tongue — saved users keep theirs.
    lang = p.getString(_langKey) ?? _systemLang();
    notifOn = p.getBool(_notifKey) ?? true;
    try {
      final rawCodes = p.getString(_codesKey);
      if (rawCodes != null && rawCodes.isNotEmpty) {
        final m = (jsonDecode(rawCodes) as Map).cast<String, dynamic>();
        codeMemory = m.map((k, v) =>
            MapEntry(k, (v as Map).cast<String, dynamic>()));
      }
    } catch (_) {
      codeMemory = {};
    }
    final raw = p.getString(_itemsKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
        items = list.map(TrackedItem.fromJson).toList()
          ..sort((a, b) => a.date.compareTo(b.date));
      } catch (_) {
        items = [];
      }
    }
    loaded = true;
    notifyListeners();
  }

  Future<void> _save() async {
    // Never let a disk hiccup break the UI — same bytes on success.
    try {
      final p = await _prefsAsync();
      await p.setString(
          _itemsKey, jsonEncode(items.map((e) => e.toJson()).toList()));
    } catch (_) {}
  }

  Future<void> setLang(String v) async {
    lang = v;
    final p = await _prefsAsync();
    await p.setString(_langKey, v);
    notifyListeners();
  }

  Future<void> setNotif(bool v) async {
    // Ask the OS first when turning on — same persisted outcome,
    // just no more silent-dead reminders on Android 13+.
    if (v) {
      try {
        await NotifyService.ensurePermission();
      } catch (_) {}
    }
    notifOn = v;
    final p = await _prefsAsync();
    await p.setBool(_notifKey, v);
    if (!v) {
      await NotifyService.cancelAll();
    } else {
      await rescheduleAll();
    }
    notifyListeners();
  }

  Future<void> add(TrackedItem item) async {
    items.add(item);
    items.sort((a, b) => a.date.compareTo(b.date));
    await _save();
    notifyListeners();
    if (notifOn) await NotifyService.scheduleFor(item, lang);
  }

  Future<void> update(TrackedItem item) async {
    final i = items.indexWhere((e) => e.id == item.id);
    String? stalePhoto;
    if (i >= 0) {
      if (items[i].photoPath != null &&
          items[i].photoPath != item.photoPath) {
        stalePhoto = items[i].photoPath;
      }
      items[i] = item;
    }
    items.sort((a, b) => a.date.compareTo(b.date));
    await _save();
    notifyListeners();
    if (stalePhoto != null) await _deletePhoto(stalePhoto);
    if (notifOn) await NotifyService.scheduleFor(item, lang);
  }

  Future<void> remove(String id) async {
    final doomed =
        items.where((e) => e.id == id).map((e) => e.photoPath).toList();
    items.removeWhere((e) => e.id == id);
    await _save();
    notifyListeners();
    for (final p in doomed) {
      if (p != null) await _deletePhoto(p);
    }
    await NotifyService.cancelFor(id);
  }

  Future<void> clearExpired() async {
    final doomed = items.where((e) => e.isExpired).toList();
    final ids = doomed.map((e) => e.id).toList();
    items.removeWhere((e) => e.isExpired);
    await _save();
    notifyListeners();
    for (final it in doomed) {
      if (it.photoPath != null) await _deletePhoto(it.photoPath!);
    }
    for (final id in ids) {
      await NotifyService.cancelFor(id);
    }
  }

  /// Best-effort photo cleanup — never fails the store op.
  Future<void> _deletePhoto(String path) async {
    try {
      final f = File(path);
      if (await f.exists()) await f.delete();
    } catch (_) {}
  }

  /// Remember a barcode pair the fox learned (name typed or from web).
  /// Old memory (name+category) stays readable, new saves carry full OFF.
  Future<void> rememberCode(String code, String name, Category cat,
      {Map<String, dynamic>? extra}) async {
    if (code.isEmpty) return;
    final Map<String, dynamic> m = {'name': name, 'category': cat.index};
    if (extra != null) m.addAll(extra);
    codeMemory[code] = m;
    try {
      final p = await _prefsAsync();
      await p.setString(_codesKey, jsonEncode(codeMemory));
    } catch (_) {}
  }

  /// Offline lookup of a learned barcode. Null = never seen.
  /// Returns name + category + full extra map when present.
  ({String name, Category category, Map<String, dynamic> extra})? recallCode(
      String code) {
    final m = codeMemory[code];
    if (m == null) return null;
    final name = (m['name'] ?? '') as String;
    if (name.isEmpty) return null;
    var cat = Category.food;
    final ci = (m['category'] as num?)?.toInt();
    if (ci != null && ci >= 0 && ci < Category.values.length) {
      cat = Category.values[ci];
    }
    final extra = Map<String, dynamic>.from(m)..remove('name');
    extra.remove('category');
    return (name: name, category: cat, extra: extra);
  }

  Future<void> rescheduleAll() async {
    // Same IDs, same times — just fanned out so 20 cans don't
    // queue up one by one on a slow phone.
    try {
      await NotifyService.cancelAll();
    } catch (_) {}
    if (!notifOn) return;
    final jobs = <Future>[];
    for (final it in items) {
      if (!it.isExpired) jobs.add(NotifyService.scheduleFor(it, lang));
    }
    try {
      await Future.wait(jobs);
    } catch (_) {}
  }

  List<TrackedItem> get upcoming =>
      items.where((e) => !e.isExpired).toList();
  List<TrackedItem> get expired =>
      items.where((e) => e.isExpired).toList();
  int get criticalCount =>
      items.where((e) => e.daysDiff >= 0 && e.daysDiff <= 7).length;
}
