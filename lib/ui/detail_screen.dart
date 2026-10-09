import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/tips.dart';
import '../data/store.dart';
import '../l10n/strings.dart';
import '../models/item.dart';
import '../services/barcode.dart';
import 'edit_screen.dart';

class DetailScreen extends StatefulWidget {
  final TrackedItem item;
  const DetailScreen({super.key, required this.item});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  bool _offBusy = false;
  bool _expandIngr = false;

  TrackedItem get item => widget.item;

  @override
  void initState() {
    super.initState();
    // Backfill old cans saved before rich OFF — one lookup, then saved.
    // Localized when the API has it (product_name_tr etc).
    // Re-fetch when app lang changed since save (offLang mismatch).
    final lang = context.read<Store>().lang;
    final staleLang = (item.offLang != null && item.offLang != lang);
    if ((!item.hasOffInfo || staleLang) && item.barcode.isNotEmpty) {
      _offBusy = true;
      BarcodeFood.lookup(item.barcode, lang: lang).then((hit) async {
        if (!mounted) return;
        if (hit == null) {
          setState(() => _offBusy = false);
          return;
        }
        item.brand = hit.brand.isEmpty ? null : hit.brand;
        item.quantity = hit.quantity.isEmpty ? null : hit.quantity;
        item.offImageUrl = hit.imageUrl.isEmpty ? null : hit.imageUrl;
        item.offCategories = hit.categories.isEmpty ? null : hit.categories;
        item.offLabels = hit.labels.isEmpty ? null : hit.labels;
        item.nutriGrade =
            hit.nutritionGrade.isEmpty ? null : hit.nutritionGrade;
        item.novaGroup = hit.novaGroup;
        item.ecoscore = hit.ecoscore.isEmpty ? null : hit.ecoscore;
        item.ingredients = hit.ingredients.isEmpty ? null : hit.ingredients;
        item.allergens = hit.allergens.isEmpty ? null : hit.allergens;
        item.offLang = hit.lang;
        try {
          await context.read<Store>().update(item);
        } catch (_) {}
        if (mounted) setState(() => _offBusy = false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.select<Store, String>((s) => s.lang);
    final s = AppStrings(lang);
    final tip = foodTip(item, lang);
    final tip2 = genericTip(item, lang);
    final d = item.daysDiff;
    final urgency = _urgency(d);

    return Scaffold(
      appBar: AppBar(actions: [
        IconButton(
          icon: const Icon(Icons.edit_outlined),
          onPressed: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (_) => EditScreen(existing: item))),
        ),
        IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.red),
          onPressed: () async {
            await context.read<Store>().remove(item.id);
            if (context.mounted) Navigator.pop(context);
          },
        ),
      ]),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          _heroFrame(),
          const SizedBox(height: 14),
          Text(item.name,
              style:
                  const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          if ((item.brand?.isNotEmpty ?? false) ||
              (item.quantity?.isNotEmpty ?? false))
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                [
                  if (item.brand?.isNotEmpty ?? false) item.brand!,
                  if (item.quantity?.isNotEmpty ?? false) item.quantity!,
                ].join(' • '),
                style: const TextStyle(
                    color: Colors.grey, fontWeight: FontWeight.w600),
              ),
            ),
          const SizedBox(height: 12),
          // One clean countdown hero instead of 4 messy chips.
          _countdownCard(s, d, urgency),
          const SizedBox(height: 10),
          // Slim meta row: category + barcode (copyable), single line.
          _metaRow(s, lang),
          if (item.hasOffInfo) ...[
            const SizedBox(height: 12),
            _productCard(s),
          ],
          if (_offBusy) ...[
            const SizedBox(height: 12),
            const Row(children: [
              SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2)),
              SizedBox(width: 8),
              Text('OFF…', style: TextStyle(fontSize: 12, color: Colors.grey)),
            ]),
          ],
          if (tip.isNotEmpty) ...[
            const SizedBox(height: 12),
            _tipCard(
              icon: Icons.eco_outlined,
              color: Colors.green.shade700,
              title: s.get('foodTip'),
              body: tip,
            ),
          ],
          if (tip2.isNotEmpty) ...[
            const SizedBox(height: 8),
            _tipCard(
              icon: Icons.info_outline,
              color: Colors.blueGrey,
              title: '',
              body: tip2,
            ),
          ],
          if (item.note.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border:
                    Border.all(color: Colors.amber.withValues(alpha: 0.25)),
              ),
              child: Text(item.note, style: const TextStyle(fontSize: 13)),
            ),
          ],
          const SizedBox(height: 16),
          Center(
            child: TextButton.icon(
              onPressed: () async {
                await context.read<Store>().remove(item.id);
                if (context.mounted) Navigator.pop(context);
              },
              icon: const Icon(Icons.delete_outline,
                  size: 18, color: Colors.red),
              label: Text(s.get('delete'),
                  style: const TextStyle(color: Colors.red)),
            ),
          ),
        ],
      ),
    );
  }

  // ---------- urgency ----------

  ({Color c, Color bg, String emoji}) _urgency(int d) {
    if (d < 0) {
      return (c: Colors.red.shade700, bg: Colors.red.shade50, emoji: '');
    }
    if (d == 0) {
      return (c: Colors.red.shade700, bg: Colors.red.shade50, emoji: '');
    }
    if (d <= 3) {
      return (c: Colors.red.shade700, bg: Colors.red.shade50, emoji: '');
    }
    if (d <= 7) {
      return (c: const Color(0xFFEA580C), bg: const Color(0xFFFFF1E3), emoji: '');
    }
    if (d <= 30) {
      return (c: const Color(0xFFB45309), bg: const Color(0xFFFFF8E6), emoji: '');
    }
    return (c: const Color(0xFF15803D), bg: const Color(0xFFEFFDF3), emoji: '');
  }

  String _countText(AppStrings s, int d) {
    if (d < 0) return '${-d} ${s.get('daysOver')}';
    if (d == 0) return s.get('today');
    return '$d ${s.get('daysLeft')}';
  }

  // ---------- sections ----------

  Widget _heroFrame() {
    final hasPhoto = item.photoPath != null;
    final hasOff = !hasPhoto && (item.offImageUrl?.isNotEmpty ?? false);
    if (!hasPhoto && !hasOff) return const SizedBox.shrink();
    return Container(
      height: 190,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: hasPhoto
            ? Image.file(File(item.photoPath!),
                height: 190,
                width: double.infinity,
                fit: BoxFit.cover,
                gaplessPlayback: true)
            : Image.network(item.offImageUrl!,
                height: 190,
                width: double.infinity,
                fit: BoxFit.contain,
                gaplessPlayback: true,
                loadingBuilder: (c, child, progress) {
                  if (progress == null) return child;
                  return const SizedBox(
                      height: 190,
                      child: Center(
                          child: SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2.5))));
                },
                errorBuilder: (c, e, st) => const SizedBox.shrink()),
      ),
    );
  }

  Widget _countdownCard(AppStrings s, int d, ({Color c, Color bg, String emoji}) u) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: u.bg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: u.c.withValues(alpha: 0.25)),
      ),
      child: Row(children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: u.c.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(item.dateType.icon, color: u.c, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${item.date.day}.${item.date.month}.${item.date.year} • ${item.dateType.label(s.lang)}',
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.black54),
              ),
              const SizedBox(height: 2),
              Text(
                _countText(s, d),
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: u.c),
              ),
            ],
          ),
        ),
        Icon(
          d < 0 || d <= 3 ? Icons.pets : Icons.check_circle_outline,
          color: u.c.withValues(alpha: 0.6),
          size: 22,
        ),
      ]),
    );
  }

  Widget _metaRow(AppStrings s, String lang) {
    return Row(children: [
      _miniChip(item.category.icon, item.category.label(lang)),
      const SizedBox(width: 8),
      if (item.barcode.isNotEmpty)
        Expanded(
          child: GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: item.barcode));
              ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(item.barcode)));
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(999),
                border:
                    Border.all(color: Colors.black.withValues(alpha: 0.08)),
              ),
              child: Row(children: [
                const Icon(Icons.qr_code_2, size: 14, color: Colors.black54),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(item.barcode,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 12,
                          fontFamily: 'monospace',
                          color: Colors.black54)),
                ),
                const Icon(Icons.copy, size: 12, color: Colors.black38),
              ]),
            ),
          ),
        ),
    ]);
  }

  Widget _miniChip(IconData icon, String label) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 14, color: Colors.black54),
          const SizedBox(width: 6),
          Text(label,
              style:
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
        ]),
      );

  Widget _tipCard(
      {required IconData icon,
      required Color color,
      required String title,
      required String body}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title.isNotEmpty)
                  Text(title,
                      style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          color: color)),
                if (title.isNotEmpty) const SizedBox(height: 4),
                Text(body, style: const TextStyle(fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------- product card ----------

  Widget _productCard(AppStrings s) {
    Color gradeColor(String g) {
      switch (g.toLowerCase()) {
        case 'a':
          return const Color(0xFF2E7D32);
        case 'b':
          return const Color(0xFF689F38);
        case 'c':
          return const Color(0xFFF9A825);
        case 'd':
          return const Color(0xFFEF6C00);
        case 'e':
          return const Color(0xFFC62828);
        default:
          return Colors.grey;
      }
    }

    final nutri = (item.nutriGrade ?? '').trim().toLowerCase();
    final eco = (item.ecoscore ?? '').trim().toLowerCase();
    final showNutri = nutri.length == 1 && 'abcde'.contains(nutri);
    final showEco = eco.length == 1 && 'abcde'.contains(eco);
    final showNova =
        item.novaGroup != null && item.novaGroup! >= 1 && item.novaGroup! <= 4;

    List<String> splitTags(String v) => v
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .take(6)
        .toList();

    Widget gradePill(String label, String value, Color c) => Container(
          padding:
              const EdgeInsets.only(left: 10, right: 6, top: 5, bottom: 5),
          decoration: BoxDecoration(
            color: c.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: c.withValues(alpha: 0.35)),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text(label,
                style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w700, color: c)),
            const SizedBox(width: 6),
            Container(
              width: 26,
              height: 26,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: c,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: c.withValues(alpha: 0.4),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(value.toUpperCase(),
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 13)),
            ),
          ]),
        );

    Widget tag(String t) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(t,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11.5)),
        );

    final ingr = (item.ingredients ?? '').trim();
    final showIngr = ingr.isNotEmpty;
    final ingrText =
        (_expandIngr || ingr.length < 140) ? ingr : '${ingr.substring(0, 140)}…';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [
                    Color(0xFFF59E0B),
                    Color(0xFFEA580C),
                  ]),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.inventory_2_outlined,
                    size: 17, color: Colors.white),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(s.get('prodInfo'),
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 15)),
              ),
              if ((item.brand?.isNotEmpty ?? false))
                Flexible(
                  child: Text(item.brand!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.w600,
                          fontSize: 12)),
                ),
            ]),
            if (showNutri || showNova || showEco) ...[
              const SizedBox(height: 12),
              Wrap(spacing: 8, runSpacing: 8, children: [
                if (showNutri)
                  gradePill(s.get('nutri'), nutri, gradeColor(nutri)),
                if (showNova)
                  gradePill(s.get('nova'), '${item.novaGroup}', Colors.brown),
                if (showEco)
                  gradePill(s.get('eco'), eco, Colors.teal.shade700),
              ]),
            ],
            if ((item.offCategories?.isNotEmpty ?? false)) ...[
              const SizedBox(height: 12),
              Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children:
                      splitTags(item.offCategories!).map(tag).toList()),
            ],
            if ((item.offLabels?.isNotEmpty ?? false)) ...[
              const SizedBox(height: 8),
              Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: splitTags(item.offLabels!).map(tag).toList()),
            ],
            if (showIngr) ...[
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () => setState(() => _expandIngr = !_expandIngr),
                child: Text(
                  '${s.get('ingredients')} • $ingrText',
                  style: const TextStyle(fontSize: 12.5, color: Colors.black87),
                ),
              ),
            ],
            if ((item.allergens?.isNotEmpty ?? false) &&
                item.allergens != 'en:none' &&
                item.allergens != 'none')
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '${s.get('allergens')}: ${item.allergens}',
                  style: TextStyle(
                      fontSize: 12, color: Colors.red.shade700),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
