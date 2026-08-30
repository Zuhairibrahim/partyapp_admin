import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:partyapp_admin/core/constants/app_colors.dart';
import 'package:partyapp_admin/data/governorates.dart';
import 'package:partyapp_admin/models/featured_provider.dart';
import 'package:partyapp_admin/widgets/app_image.dart';

import '../data/shared_store.dart';

/// Form to add (or edit) a featured provider shown in the customer app's
/// "مقدمون مميزون" strip: cover photo, name, rating, price and the details
/// that appear on the provider's details page (specialty, capacity, ...).
class AddFeaturedScreen extends StatefulWidget {
  /// When provided, the form is pre-filled and saving updates the provider
  /// instead of creating a new one.
  final FeaturedProvider? initial;

  const AddFeaturedScreen({super.key, this.initial});

  @override
  State<AddFeaturedScreen> createState() => _AddFeaturedScreenState();
}

class _AddFeaturedScreenState extends State<AddFeaturedScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _ratingCtrl;
  late final TextEditingController _categoryCtrl;
  late final TextEditingController _capacityCtrl;
  late final TextEditingController _priceTypeCtrl;
  late final TextEditingController _descriptionCtrl;
  late final TextEditingController _phoneCtrl;

  String? _governorate;

  final _picker = ImagePicker();
  String? _image;
  bool _saving = false;

  bool get _isEditing => widget.initial != null;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _nameCtrl = TextEditingController(text: initial?.name ?? '');
    _priceCtrl = TextEditingController(text: initial?.price ?? '');
    _ratingCtrl = TextEditingController(
      text: initial?.rating.toStringAsFixed(1) ?? '',
    );
    _categoryCtrl = TextEditingController(text: initial?.category ?? '');
    _capacityCtrl = TextEditingController(text: initial?.capacity ?? '');
    _priceTypeCtrl = TextEditingController(text: initial?.priceType ?? '');
    _descriptionCtrl = TextEditingController(text: initial?.description ?? '');
    _phoneCtrl = TextEditingController(text: initial?.phone ?? '');
    _governorate = initial?.location;
    _image = initial?.image;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _ratingCtrl.dispose();
    _categoryCtrl.dispose();
    _capacityCtrl.dispose();
    _priceTypeCtrl.dispose();
    _descriptionCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final file = await _picker.pickImage(source: ImageSource.gallery);
      if (file == null) return;
      final bytes = await file.readAsBytes();
      final compressed = await DashboardStore.compressAsync(bytes);
      final uri = DashboardStore.toDataUri(compressed);
      if (!mounted) return;
      setState(() => _image = uri);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر اختيار الصورة')),
      );
    }
  }

  double _parseRating(String value) {
    final n = double.tryParse(value.trim());
    return n == null ? 4.8 : n.clamp(0.0, 5.0);
  }

  Future<void> _save() async {
    if (_saving) return;
    if (!_formKey.currentState!.validate()) return;
    if (_image == null || _image!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء إضافة صورة على الأقل')),
      );
      return;
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    final provider = FeaturedProvider(
      id: _isEditing ? widget.initial!.id : 'f_$now',
      name: _nameCtrl.text.trim(),
      rating: _parseRating(_ratingCtrl.text),
      price: _priceCtrl.text.trim(),
      image: _image!,
      createdAt: _isEditing ? widget.initial!.createdAt : now,
      category: _categoryCtrl.text.trim().isEmpty ? null : _categoryCtrl.text.trim(),
      priceType: _priceTypeCtrl.text.trim().isEmpty ? null : _priceTypeCtrl.text.trim(),
      capacity: _capacityCtrl.text.trim().isEmpty ? null : _capacityCtrl.text.trim(),
      location: _governorate,
      description: _descriptionCtrl.text.trim().isEmpty ? null : _descriptionCtrl.text.trim(),
      phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
    );

    setState(() => _saving = true);
    final ok = _isEditing
        ? await DashboardStore.instance.updateFeatured(provider)
        : await DashboardStore.instance.addFeatured(provider);
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
          _isEditing ? 'تعديل المقدم المميز' : 'إضافة مقدم مميز',
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
                _sectionTitle('صورة الغلاف'),
                const SizedBox(height: 4),
                const Text(
                  'صورة المقدم كما ستظهر داخل قائمة "مقدمون مميزون" في تطبيق العميل',
                  style: TextStyle(color: AppColors.textGray, fontSize: 12),
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    height: 180,
                    width: double.infinity,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: AppColors.cardDark,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.primaryGold.withValues(alpha: 0.5),
                      ),
                    ),
                    child: _image == null
                        ? const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_a_photo,
                                color: AppColors.primaryGold,
                                size: 34,
                              ),
                              SizedBox(height: 8),
                              Text(
                                'اختيار صورة',
                                style: TextStyle(
                                  color: AppColors.textWhite,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          )
                        : Stack(
                            fit: StackFit.expand,
                            children: [
                              AppImage(
                                source: _image!,
                                fallbackIcon: Icons.broken_image,
                              ),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: GestureDetector(
                                  onTap: _pickImage,
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: const BoxDecoration(
                                      color: Colors.black54,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.edit,
                                      color: AppColors.textWhite,
                                      size: 16,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 20),

                _sectionTitle('بيانات المقدم'),
                const SizedBox(height: 10),
                _textField(_nameCtrl, 'الاسم', Icons.label,
                    'مثال: قاعة النور الملكية',
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'أدخل الاسم' : null),
                const SizedBox(height: 12),
                _textField(_categoryCtrl, 'التخصص', Icons.work_outline,
                    'مثال: قاعة أفراح، منظم حفلات'),
                const SizedBox(height: 12),
                _textField(_priceCtrl, 'السعر', Icons.attach_money,
                    'مثال: ريال 120,000',
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'أدخل السعر' : null),
                const SizedBox(height: 12),
                _textField(_priceTypeCtrl, 'نوع السعر', Icons.schedule_outlined,
                    'مثال: لكل ليلة، باقة كاملة'),
                const SizedBox(height: 12),
                _textField(_capacityCtrl, 'السعة', Icons.people_outline,
                    'مثال: 300 شخص'),
                const SizedBox(height: 12),
                _dropdownField(),
                const SizedBox(height: 12),
                _textField(_descriptionCtrl, 'الوصف', Icons.notes,
                    'وصف مختصر للخدمة...', maxLines: 3),
                const SizedBox(height: 12),
                _textField(_phoneCtrl, 'رقم التواصل', Icons.phone,
                    'مثال: 778066436'),
                const SizedBox(height: 12),
                _textField(_ratingCtrl, 'التقييم', Icons.star, 'مثال: 4.9',
                    validator: (v) {
                  if (v == null || v.trim().isEmpty) return null;
                  final n = double.tryParse(v.trim());
                  if (n == null || n < 0 || n > 5) {
                    return 'أدخل تقييماً بين 0 و 5';
                  }
                  return null;
                }),

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
                      _saving
                          ? 'جارٍ الحفظ...'
                          : (_isEditing ? 'حفظ التعديلات' : 'إضافة المقدم'),
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

  Widget _dropdownField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'المحافظة',
          style: TextStyle(color: AppColors.textGray, fontSize: 13),
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
              value: _governorate,
              hint: const Row(
                children: [
                  Icon(Icons.location_on,
                      color: AppColors.primaryGold, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'اختر المحافظة',
                    style: TextStyle(color: AppColors.textGray, fontSize: 13),
                  ),
                ],
              ),
              dropdownColor: AppColors.cardDark,
              style: const TextStyle(color: AppColors.textWhite, fontSize: 14),
              items: [
                for (final gov in kGovernorates)
                  DropdownMenuItem<String>(
                    value: gov,
                    child: Text(
                      gov,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textWhite,
                        fontSize: 13,
                      ),
                    ),
                  ),
              ],
              onChanged: (v) => setState(() => _governorate = v),
            ),
          ),
        ),
      ],
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

  Widget _textField(
    TextEditingController ctrl,
    String label,
    IconData icon,
    String hint, {
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: ctrl,
      validator: validator,
      maxLines: maxLines,
      style: const TextStyle(color: AppColors.textWhite),
      keyboardType: label.contains('السعر') ||
              label.contains('التقييم') ||
              label.contains('السعة')
          ? TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
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