import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../data/store.dart';
import '../l10n/strings.dart';
import '../models/item.dart';
import '../services/ads.dart';
import 'edit_screen.dart';
import 'detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  final _searchCtrl = TextEditingController();
  Timer? _searchTimer;
  String query = '';
  Category? filter;
  // One provider per photo path — a fresh FileImage every build
  // busts the image cache and makes avatars flicker + re-decode.
  final _avatarCache = <String, ImageProvider>{};

  ImageProvider? _avatarFor(String? path) {
    if (path == null) return null;
    return _avatarCache.putIfAbsent(
        path, () => ResizeImage(FileImage(File(path)), width: 112));
  }

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _searchTimer?.cancel();
    _searchCtrl.dispose();
    _avatarCache.clear();
    _tab.dispose();
    super.dispose();
  }

  void _onQueryChanged(String v) {
    // Same filter, just 250ms later — typing no longer re-sorts
    // the whole den on every single letter.
    _searchTimer?.cancel();
    _searchTimer = Timer(const Duration(milliseconds: 250), () {
      if (!mounted) return;
      setState(() => query = v.trim().toLowerCase());
    });
  }

  @override
  Widget build(BuildContext context) {
    // Cheap slices only — a new can must not rebuild banner+search+tabs.
    final lang = context.select<Store, String>((s) => s.lang);
    final items = context.select<Store, List<TrackedItem>>((s) => s.items);
    final s = AppStrings(lang);
    // Sort once, slice three views — was 3x where + 3x sort per keystroke.
    final sorted = List<TrackedItem>.of(items)
      ..sort((a, b) => a.date.compareTo(b.date));
    final upcoming = sorted.where((e) => !e.isExpired).toList();
    final expired = sorted.where((e) => e.isExpired).toList();
    return Scaffold(
      // Title header removed — AdMob banner lives on top instead.
      appBar: AppBar(
        toolbarHeight: 0,
        bottom: TabBar(controller: _tab, tabs: [
          Tab(text: s.get('upcoming'), icon: const Icon(Icons.pets, size: 22)),
          Tab(text: s.get('all'), icon: const Icon(Icons.manage_search, size: 22)),
          Tab(text: s.get('expired'), icon: const Icon(Icons.history, size: 22)),
        ]),
      ),
      body: Column(
        children: [
          const FoxAdBanner(),
          _denBanner(items, s),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search, size: 26),
                suffixIcon: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Image.asset('assets/branding/fox.png',
                      width: 38, height: 38),
                ),
                hintText: s.get('sniffHint'),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16)),
                isDense: true,
              ),
              onChanged: _onQueryChanged,
            ),
          ),
          _filters(lang),
          Expanded(
            child: TabBarView(controller: _tab, children: [
              _KeepAlive(
                  child: _list(items, s, upcoming,
                      emptyAsset: 'assets/branding/fox_calendar.png')),
              _KeepAlive(
                  child: _list(items, s, sorted,
                      emptyAsset: 'assets/branding/fox_scan.png')),
              _KeepAlive(
                  child: _list(items, s, expired,
                      emptyAsset: 'assets/branding/fox_expired.png')),
            ]),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const EditScreen())),
        icon: const Icon(Icons.add),
        label: Text(s.get('add')),
      ),
    );
  }

  Widget _denBanner(List<TrackedItem> items, AppStrings s) {
    final total = items.length;
    var crit = 0;
    var exp = 0;
    for (final e in items) {
      final dd = e.daysDiff;
      if (dd < 0) {
        exp++;
      } else if (dd <= 7) {
        crit++;
      }
    }
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 10, 12, 2),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        gradient: FoxTheme.denGradient,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: FoxColors.foxOrange.withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: FoxColors.foxOrange.withValues(alpha: 0.12),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: Border.all(
                  color:
                      FoxColors.foxOrange.withValues(alpha: 0.45),
                  width: 2),
              boxShadow: [
                BoxShadow(
                  color: FoxColors.foxDeep.withValues(alpha: 0.18),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipOval(
              child: Image.asset('assets/branding/fox.png',
                  width: 46, height: 46, fit: BoxFit.cover),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: FoxColors.leafGreen,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '🦊 ${s.get('onTrail')} • $total',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13.5,
                          color: Color(0xFF1C1917),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _chip('$total • ${s.get('all')}',
                          Colors.blueGrey, Icons.inventory_2_outlined),
                      const SizedBox(width: 6),
                      _chip('$crit • 7d',
                          crit > 0 ? FoxColors.foxOrange : FoxColors.leafGreen,
                          Icons.pets),
                      const SizedBox(width: 6),
                      _chip('$exp • ${s.get('expired')}',
                          exp > 0 ? Colors.redAccent : FoxColors.leafGreen,
                          Icons.history),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String t, Color c, [IconData? icon]) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.75),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: c.withValues(alpha: 0.45))),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 11, color: c),
              const SizedBox(width: 3),
            ],
            Text(t,
                maxLines: 1,
                style: const TextStyle(
                    color: Color(0xFF1C1917),
                    fontWeight: FontWeight.w700,
                    fontSize: 11)),
          ],
        ),
      );

  Widget _filters(String lang) {
    final s = AppStrings(lang);
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        children: [
          _catChip(
            label: s.get('all'),
            icon: Icons.travel_explore,
            selected: filter == null,
            onTap: () => setState(() => filter = null),
          ),
          const SizedBox(width: 8),
          ...Category.values.map((c) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _catChip(
                  label: c.label(lang),
                  icon: c.icon,
                  selected: filter == c,
                  onTap: () =>
                      setState(() => filter = filter == c ? null : c),
                ),
              )),
        ],
      ),
    );
  }

  /// Fancy fox-hunt category pill — one single fluid morph:
  /// gradient melts, chip breathes, paw pops. No double flashes.
  Widget _catChip({
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        onTap: onTap,
        child: AnimatedScale(
          scale: selected ? 1.05 : 1.0,
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutBack,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 320),
            curve: Curves.fastOutSlowIn,
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: selected
                    ? const [FoxColors.foxOrange, FoxColors.foxDeep]
                    : const [Colors.white, Colors.white],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: selected
                    ? FoxColors.foxDeep.withValues(alpha: 0.6)
                    : Colors.brown.withValues(alpha: 0.2),
              ),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color:
                            FoxColors.foxOrange.withValues(alpha: 0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 320),
                  curve: Curves.fastOutSlowIn,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selected
                        ? Colors.white.withValues(alpha: 0.25)
                        : FoxColors.tealGround.withValues(alpha: 0.1),
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    transitionBuilder: (child, anim) =>
                        ScaleTransition(scale: anim, child: child),
                    child: Icon(
                      selected ? Icons.pets : icon,
                      key: ValueKey<bool>(selected),
                      size: 15,
                      color:
                          selected ? Colors.white : FoxColors.tealGround,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 320),
                  curve: Curves.fastOutSlowIn,
                  style: TextStyle(
                      color: selected
                          ? Colors.white
                          : const Color(0xFF1C1917),
                      fontWeight:
                          selected ? FontWeight.w800 : FontWeight.w600,
                      fontSize: 13),
                  child: Text(label),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _list(List<TrackedItem> all, AppStrings s, List<TrackedItem> base,
      {required String emptyAsset}) {
    // base comes pre-sorted — filter only, never re-sort.
    final q = query;
    final f = filter;
    final list = base.where((e) {
      if (f != null && e.category != f) return false;
      if (q.isEmpty) return true;
      // Lowercase once per item, short-circuit on name first.
      final n = e.name.toLowerCase();
      if (n.contains(q)) return true;
      return e.note.toLowerCase().contains(q);
    }).toList();
    if (list.isEmpty) {
      // Per-fox box: canvases trimmed to art (+margin) but fills still
      // differ (calendar 0.94 / scan 0.90 / expired 0.94 wide). These
      // boxes render ~170px art height on every tab — equal foxes.
      final double boxW;
      final double boxH;
      if (emptyAsset.contains('fox_scan')) {
        boxW = 195;
        boxH = 195;
      } else if (emptyAsset.contains('fox_expired')) {
        boxW = 180;
        boxH = 180;
      } else {
        boxW = 210;
        boxH = 210;
      }
      return Center(
          child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(emptyAsset,
                      width: boxW, height: boxH, fit: BoxFit.contain),
                  const SizedBox(height: 12),
                  Text(s.get('noTrail'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.w600)),
                ],
              )));
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 90),
      itemCount: list.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (_, i) => RepaintBoundary(child: _tile(s, list[i])),
    );
  }

  Widget _tile(AppStrings s, TrackedItem it) {
    final d = it.daysDiff;
    final Color c;
    final String sub;
    if (d < 0) {
      c = Colors.redAccent;
      sub = '${-d} ${s.get('daysOver')}';
    } else if (d == 0) {
      c = Colors.redAccent;
      sub = s.get('today');
    } else if (d <= 3) {
      c = Colors.redAccent;
      sub = '$d ${s.get('daysLeft')}';
    } else if (d <= 7) {
      c = FoxColors.foxOrange;
      sub = '$d ${s.get('daysLeft')} 🐾';
    } else if (d <= 30) {
      c = Colors.amber.shade700;
      sub = '$d ${s.get('daysLeft')}';
    } else {
      c = FoxColors.leafGreen;
      sub = '$d ${s.get('daysLeft')}';
    }
    final cardColor =
        Theme.of(context).cardTheme.color ?? Theme.of(context).cardColor;
    return Card(
      child: ListTile(
        leading: Stack(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: it.category.color.withValues(alpha: 0.15),
              // Cached + downscaled — was a fresh FileImage every build,
              // busting cache and re-decoding the full JPG per frame.
              backgroundImage: _avatarFor(it.photoPath),
              child: it.photoPath == null
                  ? Icon(it.category.icon,
                      color: it.category.color, size: 28)
                  : null,
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                    color: c,
                    shape: BoxShape.circle,
                    border: Border.all(color: cardColor, width: 2)),
                child: d >= 0 && d <= 7
                    ? const Icon(Icons.pets,
                        size: 9, color: Colors.white)
                    : null,
              ),
            ),
          ],
        ),
        title: Text(it.name,
            style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(
            '${it.category.label(s.lang)} • ${it.dateType.label(s.lang)}\n${it.date.day}.${it.date.month}.${it.date.year} • $sub'),
        isThreeLine: true,
        trailing:
            Icon(it.dateType.icon, size: 18, color: Colors.grey),
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => DetailScreen(item: it))),
      ),
    );
  }
}

/// Keeps off-screen tabs alive — swiping back no longer rebuilds
/// + re-decodes the whole list on a slow phone.
class _KeepAlive extends StatefulWidget {
  final Widget child;
  const _KeepAlive({required this.child});
  @override
  State<_KeepAlive> createState() => _KeepAliveState();
}

class _KeepAliveState extends State<_KeepAlive>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
