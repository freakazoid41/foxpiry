import 'dart:convert';
import 'package:http/http.dart' as http;

/// Barcode → product info via OpenFoodFacts (free, no key).
/// Needs internet the FIRST time. After that the fox remembers
/// every pair on-device (see Store barcode memory) and works offline.
class BarcodeFood {
  static Future<ProductInfo?> lookup(String code, {String lang = 'tr'}) async {
    // Try food first, then beauty / pet / general product databases.
    // Same schema, different host — cosmetics live on beauty, etc.
    const hosts = [
      'world.openfoodfacts.org',
      'world.openbeautyfacts.org',
      'world.openpetfoodfacts.org',
      'world.openproductsfacts.org',
    ];
    final l = lang.toLowerCase().split('_').first;
    for (final h in hosts) {
      final hit = await _lookupHost(h, code, l);
      if (hit != null) return hit;
    }
    return null;
  }

  static String _str(Map<String, dynamic> p, List<String> keys) {
    for (final k in keys) {
      final v = ((p[k] ?? '') as String).trim();
      if (v.isNotEmpty) return v;
    }
    return '';
  }

  static Future<ProductInfo?> _lookupHost(
      String host, String code, String lang) async {
    try {
      final uri = Uri.parse(
          'https://$host/api/v2/product/$code.json'
          '?fields=product_name,product_name_$lang,'
          'generic_name,generic_name_$lang,brands,quantity,'
          'image_front_small_url,image_front_url,'
          'categories,categories_tags,labels,'
          'nutrition_grades,nova_group,ecoscore_grade,'
          'ingredients_text,ingredients_text_$lang,allergens');
      final res =
          await http.get(uri).timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return null;
      final j = jsonDecode(res.body) as Map<String, dynamic>;
      if (j['status'] != 1) return null;
      final p = (j['product'] ?? {}) as Map<String, dynamic>;
      final name = _str(p, ['product_name_$lang', 'product_name']);
      if (name.isEmpty) return null;
      List<String> tags(dynamic v) {
        if (v is List) return v.map((e) => '$e').toList();
        return const [];
      }

      return ProductInfo(
        name: name,
        genericName: _str(p, ['generic_name_$lang', 'generic_name']),
        brand: ((p['brands'] ?? '') as String).trim(),
        quantity: ((p['quantity'] ?? '') as String).trim(),
        imageUrl: (((p['image_front_small_url'] ?? p['image_front_url'] ?? '') as String)).trim(),
        categories: ((p['categories'] ?? '') as String).trim(),
        categoriesTags: tags(p['categories_tags']),
        labels: ((p['labels'] ?? '') as String).trim(),
        nutritionGrade: ((p['nutrition_grades'] ?? '') as String).trim(),
        novaGroup: (p['nova_group'] is num)
            ? (p['nova_group'] as num).toInt()
            : int.tryParse('${p['nova_group'] ?? ''}'),
        ecoscore: ((p['ecoscore_grade'] ?? '') as String).trim(),
        ingredients:
            _str(p, ['ingredients_text_$lang', 'ingredients_text']),
        allergens: ((p['allergens'] ?? '') as String).trim(),
        host: host,
        lang: lang,
      );
    } catch (_) {
      return null;
    }
  }

  /// Guess our 6 categories from OFF tags — food by default.
  static int guessCategoryIndex(List<String> tags, String categories) {
    final hay = '${tags.join(' ')} $categories'.toLowerCase();
    if (hay.contains('beaut') ||
        hay.contains('cosmet') ||
        hay.contains('shampoo') ||
        hay.contains('soap') ||
        hay.contains('cream') ||
        hay.contains('makeup') ||
        hay.contains('parfum')) {
      return 2; // cosmetic
    }
    if (hay.contains('medicine') ||
        hay.contains('drug') ||
        hay.contains('pharma') ||
        hay.contains('vitamin') ||
        hay.contains('supplement')) {
      return 1; // medicine
    }
    if (hay.contains('pet') ||
        hay.contains('dog') ||
        hay.contains('cat') ||
        hay.contains('animal')) {
      return 5; // other (pet lives here for now)
    }
    if (hay.contains('electronic') ||
        hay.contains('device') ||
        hay.contains('battery')) {
      return 3;
    }
    if (hay.contains('textile') || hay.contains('cloth')) return 4;
    return 0; // food
  }
}

/// Rich product pulled from OFF — stored on the item + code memory.
class ProductInfo {
  final String name;
  final String genericName;
  final String brand;
  final String quantity;
  final String imageUrl;
  final String categories;
  final List<String> categoriesTags;
  final String labels;
  final String nutritionGrade;
  final int? novaGroup;
  final String ecoscore;
  final String ingredients;
  final String allergens;
  final String host;
  final String lang;

  const ProductInfo({
    required this.name,
    this.genericName = '',
    this.brand = '',
    this.quantity = '',
    this.imageUrl = '',
    this.categories = '',
    this.categoriesTags = const [],
    this.labels = '',
    this.nutritionGrade = '',
    this.novaGroup,
    this.ecoscore = '',
    this.ingredients = '',
    this.allergens = '',
    this.host = '',
    this.lang = 'tr',
  });

  /// Display name: "Brand Name 500ml" when parts exist.
  String get displayName {
    final b = brand.split(',').first.trim();
    final q = quantity.trim();
    var out = name;
    if (b.isNotEmpty && !name.toLowerCase().contains(b.toLowerCase())) {
      out = '$b $out';
    }
    if (q.isNotEmpty && !out.contains(q)) out = '$out $q';
    return out.trim();
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'genericName': genericName,
        'brand': brand,
        'quantity': quantity,
        'imageUrl': imageUrl,
        'categories': categories,
        'categoriesTags': categoriesTags,
        'labels': labels,
        'nutritionGrade': nutritionGrade,
        'novaGroup': novaGroup,
        'ecoscore': ecoscore,
        'ingredients': ingredients,
        'allergens': allergens,
        'host': host,
        'lang': lang,
      };

  factory ProductInfo.fromJson(Map<String, dynamic> j) => ProductInfo(
        name: (j['name'] ?? '') as String,
        genericName: (j['genericName'] ?? '') as String,
        brand: (j['brand'] ?? '') as String,
        quantity: (j['quantity'] ?? '') as String,
        imageUrl: (j['imageUrl'] ?? '') as String,
        categories: (j['categories'] ?? '') as String,
        categoriesTags: ((j['categoriesTags'] as List?) ?? const [])
            .map((e) => '$e')
            .toList(),
        labels: (j['labels'] ?? '') as String,
        nutritionGrade: (j['nutritionGrade'] ?? '') as String,
        novaGroup: (j['novaGroup'] as num?)?.toInt(),
        ecoscore: (j['ecoscore'] ?? '') as String,
        ingredients: (j['ingredients'] ?? '') as String,
        allergens: (j['allergens'] ?? '') as String,
        host: (j['host'] ?? '') as String,
        lang: (j['lang'] ?? 'tr') as String,
      );
}
