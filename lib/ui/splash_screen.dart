import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../data/store.dart';
import '../l10n/strings.dart';

/// Branded splash with loader. Shown on cold start while the store
/// loads + a minimum dwell so the fox actually sniffs.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  // Only the two foxes this flow can show — the rest load lazily
  // on their own screens. 5x500px precache was peak RAM on 2GB phones.
  static const _foxes = [
    'assets/branding/fox.png',
    'assets/branding/fox_calendar.png',
  ];
  bool _warmed = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Warm the image cache so home paints without jank.
    if (_warmed) return;
    _warmed = true;
    for (final a in _foxes) {
      precacheImage(AssetImage(a), context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.select<Store, String>((s) => s.lang);
    final s = AppStrings(lang);
    return Scaffold(
      backgroundColor: Colors.white,
      // Pushed a little above center so it reads as a continuation
      // of the native splash (fox centered on white).
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 90),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset('assets/branding/fox.png', width: 280),
                const SizedBox(height: 16),
                Text(
                  s.get('appName'),
                  style: const TextStyle(
                    fontSize: 38,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1C1917),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  s.get('tagline'),
                  style: const TextStyle(fontSize: 15, color: Colors.black54),
                ),
                const SizedBox(height: 6),
                Text(
                  '🐾 ${s.get('onTrail')}...',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.black45,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 28),
                const SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(
                    strokeWidth: 3.5,
                    color: FoxColors.foxOrange,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
