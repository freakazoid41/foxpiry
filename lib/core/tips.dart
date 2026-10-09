import '../models/item.dart';

// Gıda için çok basit, kural tabanlı öneriler. 5 dil.
String foodTip(TrackedItem item, String lang) {
  if (item.category != Category.food) return '';
  final d = item.daysDiff;
  switch (lang) {
    case 'tr':
      if (d < 0) return 'Süresi geçmiş: kokla/kontrol et, riskliyse at. Asla riske girme.';
      if (d == 0) return 'Bugün tüket. Önceliğe al, buzluk uygun mu bak.';
      if (d <= 3) return 'Öncelikli tüket / pişir / dondur. Tarif planla.';
      if (d <= 7) return 'Haftalık menüye ekle, öne koy (FIFO).';
      return 'Stokta tut, tarihi izle. Erken tüketim planı yap.';
    case 'fr':
      if (d < 0) return 'Périmé : vérifiez, si douteux jetez.';
      if (d == 0) return "À consommer aujourd'hui en priorité.";
      if (d <= 3) return 'Cuisinez / congelez vite. Planifiez recette.';
      if (d <= 7) return 'Mettez au menu de la semaine (FIFO).';
      return 'Gardez en stock, surveillez la date.';
    case 'ru':
      if (d < 0) return 'Просрочено: проверьте, при риске выбросьте.';
      if (d == 0) return 'Употребите сегодня, в приоритет.';
      if (d <= 3) return 'Приготовьте / заморозьте. Спланируйте блюдо.';
      if (d <= 7) return 'Добавьте в меню недели (FIFO).';
      return 'Храните, следите за датой.';
    case 'hi':
      if (d < 0) return 'समाप्त: जांचें, जोखिम हो तो फेंक दें।';
      if (d == 0) return 'आज ही उपयोग करें। प्राथमिकता दें।';
      if (d <= 3) return 'पकाएं / फ्रीज़ करें। रेसिपी बनाएं।';
      if (d <= 7) return 'साप्ताहिक मेनू में जोड़ें (FIFO)।';
      return 'स्टॉक में रखें, तिथि देखते रहें।';
    default: // en
      if (d < 0) return 'Expired: check smell/look, discard if risky.';
      if (d == 0) return 'Use today. Prioritize it, check if freezable.';
      if (d <= 3) return 'Cook / freeze soon. Plan a recipe.';
      if (d <= 7) return 'Add to weekly menu, front of shelf (FIFO).';
      return 'Keep stocked, keep watching the date.';
  }
}

String genericTip(TrackedItem item, String lang) {
  final d = item.daysDiff;
  if (item.dateType == DateType.ret) {
    const m = {
      'tr': 'İade fişini/faturayı hazırla.',
      'en': 'Keep receipt/invoice ready.',
      'fr': 'Gardez le reçu prêt.',
      'ru': 'Держите чек готовым.',
      'hi': 'रसीद तैयार रखें।',
    };
    if (d >= 0 && d <= 7) return m[lang] ?? m['en']!;
    return '';
  }
  if (item.dateType == DateType.warranty) {
    const m = {
      'tr': 'Garanti belgesini ve kutuyu sakla.',
      'en': 'Keep warranty doc + box.',
      'fr': 'Gardez garantie + boîte.',
      'ru': 'Храните гарантию и коробку.',
      'hi': 'वारंटी कागज संभालें।',
    };
    if (d >= 0 && d <= 30) return m[lang] ?? m['en']!;
    return '';
  }
  return '';
}
