import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:partyapp_admin/core/constants/app_colors.dart';
import 'package:partyapp_admin/models/place_item_model.dart';
import 'package:partyapp_admin/widgets/app_image.dart';

import '../data/admin_sections.dart';
import '../data/governorates.dart';
import '../data/shared_store.dart';

/// Form to add (or edit) an item: pick a photo, choose the section (قسم),
/// enter the price and full details, then save it to the shared local store so
/// it shows up in the customer app immediately.
class AddItemScreen extends StatefulWidget {
  /// When provided, the form is pre-filled and saving updates the item
  /// instead of creating a new one.
  final PlaceItem? initial;

  const AddItemScreen({super.key, this.initial});

  @override
  State<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _locationCtrl;
  late final TextEditingController _phoneCtrl;

  final _picker = ImagePicker();
  final List<String> _images = [];
  AdminSection? _section;
  String? _capacityLabel;
  String? _durationLabel;
  String? _governorate;
  bool _saving = false;

  static const List<({String label, String? checkIn, String? checkOut})>
      _durations = [
    (label: 'يوم كامل', checkIn: null, checkOut: null),
    (
      label: 'من الساعة 1 ظهراً حتى الساعة 5 مساءً',
      checkIn: '1:00 ظهراً',
      checkOut: '5:00 مساءً'
    ),
    (
      label: 'من الساعة 5 مساءً حتى الساعة 12 منتصف الليل',
      checkIn: '5:00 مساءً',
      checkOut: '12:00 منتصف الليل'
    ),
  ];

  List<String> get _capacityOptions =>
      [for (var i = 10; i <= 1000; i += 10) '$i شخص'];

  bool get _isEditing => widget.initial != null;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _nameCtrl = TextEditingController(text: initial?.name ?? '');
    _priceCtrl = TextEditingController(text: initial?.price ?? '');
    _locationCtrl = TextEditingController(text: initial?.location ?? '');
    _phoneCtrl = TextEditingController(text: initial?.phone ?? '');
    _images.addAll(initial?.allImages ?? const []);
    _section = _sectionFor(initial?.catalogId);
    _capacityLabel = _capacityLabelFor(initial?.capacity);
    _durationLabel = _durationLabelFor(initial);
    final parsed = _splitGovernorate(initial?.location);
    _governorate = parsed.governorate;
    final detail = parsed.detail;
    if (detail != null) _locationCtrl.text = detail;
  }

  /// Splits "عدن - شاطئ الفحم" into governorate 'عدن' and detail 'شاطئ الفحم'.
  ({String? governorate, String? detail}) _splitGovernorate(String? location) {
    if (location == null || location.isEmpty) {
      return (governorate: null, detail: null);
    }
    for (final gov in kGovernorates) {
      if (location.trim() == gov) {
        return (governorate: gov, detail: null);
      }
      if (location.trim().startsWith('$gov - ')) {
        return (governorate: gov, detail: location.trim().substring('$gov - '.length));
      }
    }
    return (governorate: null, detail: location.trim());
  }

  String? _capacityLabelFor(String? value) {
    if (value == null) return null;
    final match = RegExp(r'\d+').firstMatch(value);
    if (match == null) return null;
    final n = int.tryParse(match.group(0)!);
    if (n == null) return null;
    final label = '$n شخص';
    return _capacityOptions.contains(label) ? label : null;
  }

  String? _durationLabelFor(PlaceItem? initial) {
    if (initial == null) return null;
    for (final d in _durations) {
      if (initial.priceType == d.label) return d.label;
    }
    for (final d in _durations) {
      if (initial.checkIn == d.checkIn && initial.checkOut == d.checkOut) {
        return d.label;
      }
    }
    return null;
  }

  AdminSection? _sectionFor(String? id) {
    for (final s in adminSections) {
      if (s.id == id) return s;
    }
    return null;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _locationCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    try {
      final files = await _picker.pickMultiImage();
      if (files.isEmpty) return;
      final added = <String>[];
      for (final file in files) {
        final bytes = await file.readAsBytes();
        final compressed = await DashboardStore.compressAsync(bytes);
        added.add(DashboardStore.toDataUri(compressed));
      }
      if (!mounted) return;
      setState(() => _images.addAll(added));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر اختيار الصور')),
      );
    }
  }

  void _removeImage(int index) {
    setState(() => _images.removeAt(index));
  }

  void _setCover(int index) {
    setState(() {
      final uri = _images.removeAt(index);
      _images.insert(0, uri);
    });
  }

  Future<void> _save() async {
    if (_saving) return;
    if (!_formKey.currentState!.validate()) return;
    if (_images.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء إضافة صورة على الأقل')),
      );
      return;
    }
    if (_section == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء اختيار القسم')),
      );
      return;
    }
    if (_governorate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء اختيار المحافظة')),
      );
      return;
    }

    final detail = _locationCtrl.text.trim();
    final location = detail.isEmpty
        ? _governorate!
        : '$_governorate - $detail';

    ({String label, String? checkIn, String? checkOut})? duration;
    for (final d in _durations) {
      if (d.label == _durationLabel) {
        duration = d;
        break;
      }
    }

    final item = PlaceItem(
      id: _isEditing ? widget.initial!.id : 'u_${DateTime.now().millisecondsSinceEpoch}',
      name: _nameCtrl.text.trim(),
      category: _section!.title,
      catalogId: _section!.id,
      price: _priceCtrl.text.trim(),
      priceType: _durationLabel,
      capacity: _capacityLabel,
      location: location,
      mainImage: _images.first,
      images: List<String>.from(_images),
      checkIn: duration?.checkIn,
      checkOut: duration?.checkOut,
      phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
      isVendor: true,
    );

    setState(() => _saving = true);
    final ok = _isEditing
        ? await DashboardStore.instance.update(item)
        : await DashboardStore.instance.add(item);
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'تم الحفظ وسيظهر في تطبيق العميل' : 'تعذر الحفظ'),
        backgroundColor: ok ? AppColors.primaryGold : AppColors.textGray,
      ),
    );
    if (ok && Navigator.of(context).canPop()) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        foregroundColor: AppColors.textWhite,
        title: Text(
          _isEditing ? 'تعديل العنصر' : 'إضافة عنصر جديد',
          style: const TextStyle(color: AppColors.primaryGold),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionTitle('صور العنصر'),
                const SizedBox(height: 4),
                const Text(
                  'الصورة الأولى هي صورة الغلاف، والباقي صور داخلية تظهر في أعلى تفاصيل العنصر داخل تطبيق العميل',
                  style: TextStyle(color: AppColors.textGray, fontSize: 12),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 110,
                  child: _images.isEmpty
                      ? _addImageTile()
                      : ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _images.length + 1,
                          separatorBuilder: (_, _) => const SizedBox(width: 10),
                          itemBuilder: (context, index) {
                            if (index == _images.length) {
                              return _addImageTile();
                            }
                            return _imageThumb(index);
                          },
                        ),
                ),
                const SizedBox(height: 20),

                _sectionTitle('القسم'),
                const SizedBox(height: 10),
                _gridSections(),
                const SizedBox(height: 20),

                _sectionTitle('بيانات العنصر'),
                const SizedBox(height: 10),
                _textField(_nameCtrl, 'اسم العنصر', Icons.label, 'مثال: شاليه اللؤلؤة',
                    validator: (v) => (v == null || v.isEmpty) ? 'أدخل الاسم' : null),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _textField(_priceCtrl, 'السعر', Icons.attach_money,
                          'مثال: 5,000 ريال',
                          validator: (v) =>
                              (v == null || v.isEmpty) ? 'أدخل السعر' : null),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _dropdownField(
                        label: 'المدة',
                        icon: Icons.schedule_outlined,
                        value: _durationLabel,
                        options: [for (final d in _durations) d.label],
                        onChanged: (v) => setState(() => _durationLabel = v),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _dropdownField(
                  label: 'السعة',
                  icon: Icons.people_outline,
                  value: _capacityLabel,
                  options: _capacityOptions,
                  onChanged: (v) => setState(() => _capacityLabel = v),
                ),
                const SizedBox(height: 12),
                _sectionTitle('المحافظة'),
                const SizedBox(height: 6),
                _dropdownField(
                  label: 'المحافظة',
                  icon: Icons.location_on,
                  value: _governorate,
                  options: kGovernorates,
                  onChanged: (v) => setState(() => _governorate = v),
                ),
                const SizedBox(height: 12),
                _textField(_locationCtrl, 'العنوان التفصيلي', Icons.place,
                    'مثال: شاطئ الفحم'),
                const SizedBox(height: 12),
                _textField(_phoneCtrl, 'رقم التواصل', Icons.phone, 'مثال: 778066436'),

                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGold,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _saving ? null : _save,
                    icon: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.black,
                            ),
                          )
                        : const Icon(Icons.save, color: Colors.black),
                    label: Text(
                      _saving ? 'جارٍ الحفظ...' : (_isEditing ? 'حفظ التعديلات' : 'حفظ العنصر'),
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _gridSections() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: adminSections.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 2.4,
      ),
      itemBuilder: (context, index) {
        final s = adminSections[index];
        final selected = _section?.id == s.id;
        return GestureDetector(
          onTap: () => setState(() => _section = s),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.primaryGold
                  : AppColors.cardDark,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected
                    ? AppColors.primaryGold
                    : AppColors.containerBorder,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  s.icon,
                  color: selected ? Colors.black : AppColors.primaryGold,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    s.title,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: selected ? Colors.black : AppColors.textWhite,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _addImageTile() {
    return InkWell(
      onTap: _pickImages,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 110,
        decoration: BoxDecoration(
          color: AppColors.cardDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.primaryGold.withValues(alpha: 0.5),
            width: 1.5,
          ),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_a_photo, color: AppColors.primaryGold, size: 28),
            SizedBox(height: 6),
            Text(
              'إضافة صور',
              style: TextStyle(color: AppColors.textWhite, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imageThumb(int index) {
    final isCover = index == 0;
    final uri = _images[index];
    return SizedBox(
      width: 110,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: AppImage(
              source: uri,
              fit: BoxFit.cover,
              fallbackIcon: Icons.broken_image,
            ),
          ),
          if (isCover)
            Positioned(
              top: 6,
              left: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primaryGold,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'الغلاف',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () => _removeImage(index),
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close,
                    color: AppColors.textWhite, size: 14),
              ),
            ),
          ),
          if (!isCover)
            Positioned(
              bottom: 4,
              right: 4,
              child: GestureDetector(
                onTap: () => _setCover(index),
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.star,
                      color: AppColors.primaryGold, size: 14),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) => Text(
        text,
        style: const TextStyle(
          color: AppColors.primaryGold,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      );

  Widget _dropdownField({
    required String label,
    required IconData icon,
    required String? value,
    required List<String> options,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.textGray, fontSize: 13),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.cardDark,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.containerBorder),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: value,
              hint: Row(
                children: [
                  Icon(icon, color: AppColors.primaryGold, size: 18),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'اختر $label',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textGray,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
              dropdownColor: AppColors.cardDark,
              style: const TextStyle(color: AppColors.textWhite, fontSize: 14),
              items: [
                for (final option in options)
                  DropdownMenuItem<String>(
                    value: option,
                    child: Text(
                      option,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textWhite,
                        fontSize: 13,
                      ),
                    ),
                  ),
              ],
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _textField(
    TextEditingController ctrl,
    String label,
    IconData icon,
    String hint, {
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: ctrl,
      validator: validator,
      style: const TextStyle(color: AppColors.textWhite),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: AppColors.primaryGold),
        labelStyle: const TextStyle(color: AppColors.textGray),
        hintStyle: const TextStyle(color: AppColors.textGray),
        filled: true,
        fillColor: AppColors.cardDark,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.containerBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primaryGold),
        ),
      ),
    );
  }
}