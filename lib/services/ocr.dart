import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

// Fotoğraftaki yazıdan tarih çıkar: 31.12.2025, 31/12/2025, 31-12-2025, 2025-12-31
// + SKT/TETT/EXP yanında geçen tarihler öncelikli.
class OcrDate {
  static final _patterns = <RegExp>[
    RegExp(r'(\d{1,2})[./\-](\d{1,2})[./\-](\d{2,4})'),
    RegExp(r'(\d{4})[./\-](\d{1,2})[./\-](\d{1,2})'),
  ];

  static DateTime? parseBest(String text) {
    // Cap the hunt — a full-res photo OCR dump can be huge and the
    // regexes would chew the UI thread for nothing.
    final src = text.length > 4000 ? text.substring(0, 4000) : text;
    final cands = <DateTime>[];
    for (final p in _patterns) {
      for (final m in p.allMatches(src)) {
        try {
          DateTime? d;
          if (m.group(1)!.length == 4) {
            d = DateTime(int.parse(m.group(1)!), int.parse(m.group(2)!),
                int.parse(m.group(3)!));
          } else {
            var y = int.parse(m.group(3)!);
            if (y < 100) y += 2000;
            d = DateTime(y, int.parse(m.group(2)!), int.parse(m.group(1)!));
          }
          if (d.year >= 2020 && d.year <= 2045) cands.add(d);
        } catch (_) {}
      }
    }
    if (cands.isEmpty) return null;
    final now = DateTime.now();
    // Gelecek tarihler önce, bugüne en yakın ilk
    cands.sort((a, b) {
      final fa = a.isBefore(now) ? 1 : 0;
      final fb = b.isBefore(now) ? 1 : 0;
      if (fa != fb) return fa - fb;
      return a.difference(now).abs().compareTo(b.difference(now).abs());
    });
    return cands.first;
  }

  static Future<DateTime?> fromImage(String path) async {
    try {
      final rec = TextRecognizer(script: TextRecognitionScript.latin);
      final res = await rec.processImage(InputImage.fromFilePath(path));
      await rec.close();
      return parseBest(res.text);
    } catch (_) {
      return null;
    }
  }
}
