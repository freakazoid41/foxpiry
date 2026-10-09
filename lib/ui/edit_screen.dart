import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import '../data/store.dart';
import '../l10n/strings.dart';
import '../models/item.dart';
import '../services/barcode.dart';
import '../services/ocr.dart';
import 'scan_screen.dart';

class EditScreen extends StatefulWidget {
  final TrackedItem? existing;
  const EditScreen({super.key, this.existing});
  @override
  State<EditScreen> createState() => _EditScreenState();
}

class _EditScreenState extends State<EditScreen> {
  static final _picker = ImagePicker();
  final _form = GlobalKey<FormState>();
  late TextEditingController _name;
  late TextEditingController _note;
  Category _cat = Category.food;
  DateType _type = DateType.expiry;
  DateTime _date = DateTime.now().add(const Duration(days: 7));
  String? _photo;
  String _code = '';
  bool _ocrBusy = false;
  bool _codeBusy = false;
  // Rich OFF info pulled on scan — saved on the item.
  String? _brand;
  String? _quantity;
  String? _offImage;
  String? _offCats;
  String? _offLabels;
  String? _nutri;
  int? _nova;
  String? _eco;
  String? _ingr;
  String? _aller;
  String? _offLang;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _name = TextEditingController(text: e?.name ?? '');
    _note = TextEditingController(text: e?.note ?? '');
    if (e != null) {
      _cat = e.category;
      _type = e.dateType;
      _date = e.date;
      _photo = e.photoPath;
      _code = e.barcode;
      _brand = e.brand;
      _quantity = e.quantity;
      _offImage = e.offImageUrl;
      _offCats = e.offCategories;
      _offLabels = e.offLabels;
      _nutri = e.nutriGrade;
      _nova = e.novaGroup;
      _eco = e.ecoscore;
      _ingr = e.ingredients;
      _aller = e.allergens;
      _offLang = e.offLang;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<String> _persist(XFile f) async {
    final dir = await getApplicationDocumentsDirectory();
    final p = '${dir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';
    await File(f.path).copy(p);
    return p;
  }

  Future<void> _pick(ImageSource src) async {
    final f = await _picker.pickImage(source: src, imageQuality: 85);
    if (f == null) return;
    final p = await _persist(f);
    setState(() => _photo = p);
    // Otomatik OCR dene
    await _runOcr(p);
  }

  Future<void> _runOcr(String path) async {
    if (!mounted) return;
    setState(() => _ocrBusy = true);
    final d = await OcrDate.fromImage(path);
    if (!mounted) return;
    setState(() => _ocrBusy = false);
    if (d != null) {
      setState(() => _date = d);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              '${d.day}.${d.month}.${d.year} — ${AppStrings(context.read<Store>().lang).get('date')} ✓')));
    }
  }

  Future<void> _scanCode() async {
    final code = await Navigator.push<String>(
        context, MaterialPageRoute(builder: (_) => const ScanScreen()));
    if (code == null || code.isEmpty || !mounted) return;
    final st = context.read<Store>();
    setState(() {
      _code = code;
      _codeBusy = true;
    });
    // 1) Fox memory — instant + offline, full info when learned.
    final known = st.recallCode(code);
    if (known != null) {
      if (!mounted) return;
      setState(() {
        _name.text = known.name;
        _cat = known.category;
        _brand = known.extra['brand'] as String?;
        _quantity = known.extra['quantity'] as String?;
        _offImage = known.extra['offImageUrl'] as String?;
        _offCats = known.extra['offCategories'] as String?;
        _offLabels = known.extra['offLabels'] as String?;
        _nutri = known.extra['nutriGrade'] as String?;
        _nova = (known.extra['novaGroup'] as num?)?.toInt();
        _eco = known.extra['ecoscore'] as String?;
        _ingr = known.extra['ingredients'] as String?;
        _aller = known.extra['allergens'] as String?;
        _offLang = known.extra['offLang'] as String?;
        _codeBusy = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppStrings(st.lang).get('codeLearned'))));
      return;
    }
    // 2) Web lookup — needs internet, first time only. Tries food,
    // beauty, pet, general DBs + smart category guess. Localized name
    // (product_name_tr etc) when the API has it, fallback to default.
    final hit = await BarcodeFood.lookup(code, lang: st.lang);
    if (!mounted) return;
    setState(() => _codeBusy = false);
    if (hit != null) {
      final ci = BarcodeFood.guessCategoryIndex(
          hit.categoriesTags, hit.categories);
      final cat = (ci >= 0 && ci < Category.values.length)
          ? Category.values[ci]
          : Category.food;
      setState(() {
        _name.text = hit.displayName;
        _cat = cat;
        _brand = hit.brand.isEmpty ? null : hit.brand;
        _quantity = hit.quantity.isEmpty ? null : hit.quantity;
        _offImage = hit.imageUrl.isEmpty ? null : hit.imageUrl;
        _offCats = hit.categories.isEmpty ? null : hit.categories;
        _offLabels = hit.labels.isEmpty ? null : hit.labels;
        _nutri = hit.nutritionGrade.isEmpty ? null : hit.nutritionGrade;
        _nova = hit.novaGroup;
        _eco = hit.ecoscore.isEmpty ? null : hit.ecoscore;
        _ingr = hit.ingredients.isEmpty ? null : hit.ingredients;
        _aller = hit.allergens.isEmpty ? null : hit.allergens;
        _offLang = hit.lang;
      });
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppStrings(st.lang).get('codeFound'))));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppStrings(st.lang).get('codeUnknown'))));
    }
  }

  Map<String, dynamic> _offExtra() => {
        'brand': _brand,
        'quantity': _quantity,
        'offImageUrl': _offImage,
        'offCategories': _offCats,
        'offLabels': _offLabels,
        'nutriGrade': _nutri,
        'novaGroup': _nova,
        'ecoscore': _eco,
        'ingredients': _ingr,
        'allergens': _aller,
        'offLang': _offLang,
      };

  @override
  Widget build(BuildContext context) {
    final store = context.watch<Store>();
    final s = AppStrings(store.lang);
    return Scaffold(
      appBar: AppBar(title: Text(widget.existing == null ? s.get('add') : s.get('save'))),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _name,
              decoration: InputDecoration(
                  labelText: s.get('productName'),
                  border: const OutlineInputBorder()),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? '!' : null,
            ),
            const SizedBox(height: 12),
            ListTile(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade400)),
              leading: _codeBusy
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child:
                          CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.qr_code_2),
              title: Text(_code.isEmpty
                  ? '${s.get('barcode')} • ${s.get('scanAction')}'
                  : _code),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_code.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => setState(() => _code = ''),
                    ),
                  const Icon(Icons.photo_camera),
                ],
              ),
              onTap: _codeBusy ? null : _scanCode,
            ),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: DropdownButtonFormField<Category>(
                  initialValue: _cat,
                  decoration: InputDecoration(
                      labelText: s.get('category'),
                      border: const OutlineInputBorder()),
                  items: Category.values
                      .map((c) => DropdownMenuItem(
                          value: c, child: Text(c.label(store.lang))))
                      .toList(),
                  onChanged: (v) => setState(() => _cat = v ?? _cat),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<DateType>(
                  initialValue: _type,
                  decoration: InputDecoration(
                      labelText: s.get('dateType'),
                      border: const OutlineInputBorder()),
                  items: DateType.values
                      .map((t) => DropdownMenuItem(
                          value: t, child: Text(t.label(store.lang))))
                      .toList(),
                  onChanged: (v) => setState(() => _type = v ?? _type),
                ),
              ),
            ]),
            const SizedBox(height: 12),
            ListTile(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade400)),
              leading: const Icon(Icons.calendar_month),
              title: Text(
                  '${s.get('date')}: ${_date.day}.${_date.month}.${_date.year}'),
              trailing: const Icon(Icons.edit),
              onTap: () async {
                final d = await showDatePicker(
                  context: context,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2045),
                  initialDate: _date,
                );
                if (d != null) setState(() => _date = d);
              },
            ),
            const SizedBox(height: 12),
            Text(s.get('photo'),
                style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Row(children: [
              if (_photo != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(File(_photo!),
                      width: 90, height: 90, fit: BoxFit.cover),
                ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => _pick(ImageSource.camera),
                      icon: const Icon(Icons.photo_camera),
                      label: Text(s.get('camera')),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => _pick(ImageSource.gallery),
                      icon: const Icon(Icons.photo),
                      label: Text(s.get('gallery')),
                    ),
                    if (_photo != null)
                      FilledButton.tonalIcon(
                        onPressed: _ocrBusy ? null : () => _runOcr(_photo!),
                        icon: _ocrBusy
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2))
                            : const Icon(Icons.text_fields),
                        label: Text(s.get('readDate')),
                      ),
                  ],
                ),
              ),
            ]),
            const SizedBox(height: 12),
            TextFormField(
              controller: _note,
              maxLines: 2,
              decoration: InputDecoration(
                  labelText: s.get('note'),
                  border: const OutlineInputBorder()),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () async {
                if (!_form.currentState!.validate()) return;
                final nav = Navigator.of(context);
                final st = context.read<Store>();
                if (widget.existing == null) {
                  await st.add(TrackedItem(
                    id: st.newId(),
                    name: _name.text.trim(),
                    category: _cat,
                    dateType: _type,
                    date: _date,
                    photoPath: _photo,
                    note: _note.text.trim(),
                    barcode: _code,
                    brand: _brand,
                    quantity: _quantity,
                    offImageUrl: _offImage,
                    offCategories: _offCats,
                    offLabels: _offLabels,
                    nutriGrade: _nutri,
                    novaGroup: _nova,
                    ecoscore: _eco,
                    ingredients: _ingr,
                    allergens: _aller,
                    offLang: _offLang,
                  ));
                  await st.rememberCode(
                      _code, _name.text.trim(), _cat,
                      extra: _offExtra());
                } else {
                  final e = widget.existing!;
                  e.name = _name.text.trim();
                  e.category = _cat;
                  e.dateType = _type;
                  e.date = _date;
                  e.photoPath = _photo;
                  e.note = _note.text.trim();
                  e.barcode = _code;
                  e.brand = _brand;
                  e.quantity = _quantity;
                  e.offImageUrl = _offImage;
                  e.offCategories = _offCats;
                  e.offLabels = _offLabels;
                  e.nutriGrade = _nutri;
                  e.novaGroup = _nova;
                  e.ecoscore = _eco;
                  e.ingredients = _ingr;
                  e.allergens = _aller;
                  e.offLang = _offLang;
                  await st.update(e);
                  await st.rememberCode(
                      _code, _name.text.trim(), _cat,
                      extra: _offExtra());
                }
                nav.pop();
              },
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Text(s.get('save')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
