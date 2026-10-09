import 'package:flutter_test/flutter_test.dart';
import 'package:foxpiry/models/item.dart';
import 'package:foxpiry/services/ocr.dart';

void main() {
  test('daysDiff expired logic', () {
    final it = TrackedItem(
      id: '1',
      name: 'Süt',
      category: Category.food,
      dateType: DateType.expiry,
      date: DateTime.now().subtract(const Duration(days: 2)),
    );
    expect(it.isExpired, true);
  });

  test('ocr parses dd.mm.yyyy', () {
    final d = OcrDate.parseBest('SKT: 31.12.2025 parti 123');
    expect(d?.day, 31);
    expect(d?.month, 12);
    expect(d?.year, 2025);
  });
}
