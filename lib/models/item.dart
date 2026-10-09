import 'package:flutter/material.dart';

enum Category { food, medicine, cosmetic, electronics, clothing, other }
enum DateType { expiry, ret, warranty }

extension CategoryX on Category {
  String label(String lang) {
    const m = {
      Category.food: {
        'tr': 'Gıda', 'en': 'Food', 'fr': 'Alimentaire', 'ru': 'Еда', 'hi': 'खाद्य'
      },
      Category.medicine: {
        'tr': 'İlaç', 'en': 'Medicine', 'fr': 'Médicament', 'ru': 'Лекарства', 'hi': 'दवा'
      },
      Category.cosmetic: {
        'tr': 'Kozmetik', 'en': 'Cosmetic', 'fr': 'Cosmétique', 'ru': 'Косметика', 'hi': 'कॉस्मेटिक'
      },
      Category.electronics: {
        'tr': 'Elektronik', 'en': 'Electronics', 'fr': 'Électronique', 'ru': 'Электроника', 'hi': 'इलेक्ट्रॉनिक्स'
      },
      Category.clothing: {
        'tr': 'Giyim', 'en': 'Clothing', 'fr': 'Vêtement', 'ru': 'Одежда', 'hi': 'कपड़े'
      },
      Category.other: {
        'tr': 'Diğer', 'en': 'Other', 'fr': 'Autre', 'ru': 'Другое', 'hi': 'अन्य'
      },
    };
    return m[this]![lang] ?? m[this]!['en']!;
  }

  IconData get icon {
    switch (this) {
      case Category.food: return Icons.restaurant;
      case Category.medicine: return Icons.medication;
      case Category.cosmetic: return Icons.face;
      case Category.electronics: return Icons.devices;
      case Category.clothing: return Icons.checkroom;
      case Category.other: return Icons.inventory_2;
    }
  }

  Color get color {
    switch (this) {
      case Category.food: return Colors.green;
      case Category.medicine: return Colors.red;
      case Category.cosmetic: return Colors.pink;
      case Category.electronics: return Colors.blue;
      case Category.clothing: return Colors.orange;
      case Category.other: return Colors.grey;
    }
  }
}

extension DateTypeX on DateType {
  String label(String lang) {
    const m = {
      DateType.expiry: {
        'tr': 'Son kullanma', 'en': 'Expiry', 'fr': 'Expiration', 'ru': 'Срок годности', 'hi': 'समाप्ति'
      },
      DateType.ret: {
        'tr': 'İade son', 'en': 'Return by', 'fr': 'Retour', 'ru': 'Возврат до', 'hi': 'वापसी'
      },
      DateType.warranty: {
        'tr': 'Garanti bitiş', 'en': 'Warranty end', 'fr': 'Fin garantie', 'ru': 'Гарантия до', 'hi': 'वारंटी'
      },
    };
    return m[this]![lang] ?? m[this]!['en']!;
  }

  IconData get icon {
    switch (this) {
      case DateType.expiry: return Icons.event;
      case DateType.ret: return Icons.undo;
      case DateType.warranty: return Icons.verified_user;
    }
  }
}

class TrackedItem {
  final String id;
  String name;
  Category category;
  DateType dateType;
  DateTime date;
  String? photoPath;
  String note;
  String barcode;
  DateTime createdAt;
  // Rich OFF product info — all optional, old saves stay valid.
  String? brand;
  String? quantity;
  String? offImageUrl;
  String? offCategories;
  String? offLabels;
  String? nutriGrade;
  int? novaGroup;
  String? ecoscore;
  String? ingredients;
  String? allergens;
  String? offLang;

  TrackedItem({
    required this.id,
    required this.name,
    required this.category,
    required this.dateType,
    required this.date,
    this.photoPath,
    this.note = '',
    this.barcode = '',
    DateTime? createdAt,
    this.brand,
    this.quantity,
    this.offImageUrl,
    this.offCategories,
    this.offLabels,
    this.nutriGrade,
    this.novaGroup,
    this.ecoscore,
    this.ingredients,
    this.allergens,
    this.offLang,
  }) : createdAt = createdAt ?? DateTime.now();

  int get daysDiff {
    final now = DateTime.now();
    final a = DateTime(now.year, now.month, now.day);
    final b = DateTime(date.year, date.month, date.day);
    return b.difference(a).inDays;
  }

  bool get isExpired => daysDiff < 0;
  bool get isCritical => daysDiff >= 0 && daysDiff <= 3;
  bool get isSoon => daysDiff >= 0 && daysDiff <= 7;

  factory TrackedItem.fromJson(Map<String, dynamic> j) => TrackedItem(
        id: j['id'] as String,
        name: j['name'] as String,
        category: Category.values[(j['category'] as num).toInt()],
        dateType: DateType.values[(j['dateType'] as num).toInt()],
        date: DateTime.parse(j['date'] as String),
        photoPath: j['photoPath'] as String?,
        note: (j['note'] ?? '') as String,
        barcode: (j['barcode'] ?? '') as String,
        createdAt: DateTime.parse(j['createdAt'] as String),
        brand: j['brand'] as String?,
        quantity: j['quantity'] as String?,
        offImageUrl: j['offImageUrl'] as String?,
        offCategories: j['offCategories'] as String?,
        offLabels: j['offLabels'] as String?,
        nutriGrade: j['nutriGrade'] as String?,
        novaGroup: (j['novaGroup'] as num?)?.toInt(),
        ecoscore: j['ecoscore'] as String?,
        ingredients: j['ingredients'] as String?,
        allergens: j['allergens'] as String?,
        offLang: j['offLang'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'category': category.index,
        'dateType': dateType.index,
        'date': date.toIso8601String(),
        'photoPath': photoPath,
        'note': note,
        'barcode': barcode,
        'createdAt': createdAt.toIso8601String(),
        'brand': brand,
        'quantity': quantity,
        'offImageUrl': offImageUrl,
        'offCategories': offCategories,
        'offLabels': offLabels,
        'nutriGrade': nutriGrade,
        'novaGroup': novaGroup,
        'ecoscore': ecoscore,
        'ingredients': ingredients,
        'allergens': allergens,
        'offLang': offLang,
      };

  bool get hasOffInfo =>
      (brand?.isNotEmpty ?? false) ||
      (quantity?.isNotEmpty ?? false) ||
      (offImageUrl?.isNotEmpty ?? false) ||
      (offCategories?.isNotEmpty ?? false) ||
      (offLabels?.isNotEmpty ?? false) ||
      (nutriGrade?.isNotEmpty ?? false) ||
      novaGroup != null ||
      (ecoscore?.isNotEmpty ?? false) ||
      (ingredients?.isNotEmpty ?? false) ||
      (allergens?.isNotEmpty ?? false);
}
