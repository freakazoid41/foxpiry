import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/theme.dart';
import '../data/store.dart';
import '../l10n/strings.dart';

/// Public policy URL — same link goes into the Play Console listing.
const _privacyUrl = 'https://freakazoid41.github.io/foxpiry/privacy.html';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    // Cheap slices — item adds no longer rebuild language + switches.
    final lang = context.select<Store, String>((s) => s.lang);
    final notifOn = context.select<Store, bool>((s) => s.notifOn);
    final s = AppStrings(lang);
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset('assets/branding/fox_gear.png',
                width: 44, height: 44),
            const SizedBox(width: 8),
            Text(s.get('settings')),
          ],
        ),
      ),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        // Den card
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: FoxTheme.denGradient,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
                color: FoxColors.foxOrange.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Image.asset('assets/branding/fox_gear.png',
                  width: 88, height: 88),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('🦊 ${s.get('foxDen')}',
                        style: const TextStyle(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text(s.get('onTrail'),
                        style: const TextStyle(
                            fontSize: 12, color: Colors.black54)),
                  ],
                ),
              ),
              const Icon(
                Icons.wb_sunny_outlined,
                color: FoxColors.tealGround,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(s.get('language'),
            style: const TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: AppStrings.supported
              .map((l) => ChoiceChip(
                    label: Text(AppStrings.names[l]!),
                    selected: lang == l,
                    onSelected: (_) =>
                        context.read<Store>().setLang(l),
                  ))
              .toList(),
        ),
        const Divider(height: 32),
        SwitchListTile(
          title: Text(s.get('notifications')),
          secondary: const Icon(Icons.notifications_active_outlined),
          value: notifOn,
          onChanged: (v) => context.read<Store>().setNotif(v),
        ),
        const Divider(height: 32),
        OutlinedButton.icon(
          onPressed: () => context.read<Store>().clearExpired(),
          icon: const Icon(Icons.cleaning_services),
          label: Text(s.get('clearExpired')),
        ),
        ListTile(
          leading: const Icon(Icons.privacy_tip_outlined),
          title: Text(s.get('privacy')),
          trailing: const Icon(Icons.open_in_new, size: 18),
          onTap: () async {
            final uri = Uri.parse(_privacyUrl);
            try {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            } catch (_) {}
          },
        ),
        const SizedBox(height: 24),
        Center(
          child: Text(s.get('footer'),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, fontSize: 12)),
        ),
      ]),
    );
  }
}
