import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import 'core/theme.dart';
import 'data/store.dart';
import 'l10n/strings.dart';
import 'services/notify.dart';
import 'ui/home_screen.dart';
import 'ui/settings_screen.dart';
import 'ui/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = Store();
  // Paint first, warm up heavy SDKs after — same order, no blocking.
  runApp(ChangeNotifierProvider.value(value: store, child: const FoxpiryApp()));
  // Ads never blocks the den door.
  () async {
    try {
      await MobileAds.instance.initialize();
    } catch (_) {}
  }();
  try {
    await store.load();
    await NotifyService.init();
    // One gentle nudge for the runtime permission — asked once ever,
    // never nagged. The settings switch asks every time it flips on.
    if (store.notifOn && !await store.permAsked()) {
      try {
        await NotifyService.ensurePermission();
      } catch (_) {}
      await store.markPermAsked();
    }
    await store.rescheduleAll();
  } catch (_) {}
}

class FoxpiryApp extends StatelessWidget {
  const FoxpiryApp({super.key});
  @override
  Widget build(BuildContext context) {
    // Only language rebuilds the app shell — item changes stay down-tree.
    final lang = context.select<Store, String>((s) => s.lang);
    return MaterialApp(
      title: 'Foxpiry',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.light,
      theme: FoxTheme.light,
      locale: Locale(lang),
      supportedLocales: AppStrings.supported.map((e) => Locale(e)).toList(),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const Root(),
    );
  }
}

class Root extends StatefulWidget {
  const Root({super.key});
  @override
  State<Root> createState() => _RootState();
}

class _RootState extends State<Root> {
  int idx = 0;
  bool _minTimeDone = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1600), () {
      if (mounted) setState(() => _minTimeDone = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final loaded = context.select<Store, bool>((s) => s.loaded);
    final lang = context.select<Store, String>((s) => s.lang);
    final s = AppStrings(lang);
    if (!loaded || !_minTimeDone) {
      return const SplashScreen();
    }
    return Scaffold(
      body: idx == 0 ? const HomeScreen() : const SettingsScreen(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: idx,
        onDestinationSelected: (v) => setState(() => idx = v),
        destinations: [
          NavigationDestination(
              icon: const Icon(Icons.pets_outlined),
              selectedIcon: const Icon(Icons.pets),
              label: s.get('upcoming')),
          NavigationDestination(
              icon: const Icon(Icons.settings_outlined),
              selectedIcon: const Icon(Icons.settings),
              label: s.get('settings')),
        ],
      ),
    );
  }
}
