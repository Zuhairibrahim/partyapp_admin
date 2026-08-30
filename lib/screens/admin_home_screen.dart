import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';

import 'package:partyapp_admin/core/constants/app_colors.dart';
import 'package:partyapp_admin/data/booking_store.dart';
import 'package:partyapp_admin/data/catalog.dart';
import 'package:partyapp_admin/models/booking_model.dart';
import 'package:partyapp_admin/models/place_item_model.dart';
import 'package:partyapp_admin/screens/place_details_screen.dart';

import '../data/admin_sections.dart';
import '../data/shared_store.dart';
import 'add_item_screen.dart';
import 'admin_pin_screen.dart';
import 'featured_screen.dart';
import 'orders_screen.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  List<PlaceItem> _items = const [];
  bool _loading = true;
  int _pendingOrders = 0;

  @override
  void initState() {
    super.initState();
    _load();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    final bookings = await BookingStore.instance.reload();
    if (!mounted) return;
    setState(() {
      _pendingOrders =
          bookings.where((b) => b.status == BookingStatus.pending).length;
    });
  }

  Future<void> _openOrders() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const OrdersScreen()),
    );
    await _loadOrders();
  }

  Future<void> _load() async {
    final items = await DashboardStore.instance.reload();
    if (!mounted) return;
    setState(() {
      _items = items;
      _loading = false;
    });
  }

  Future<void> _openAdd() async {
    final added = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const AddItemScreen()),
    );
    if (added == true) _load();
  }

  Future<void> _openEdit(PlaceItem item) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => AddItemScreen(initial: item)),
    );
    if (changed == true) _load();
  }

  Future<void> _openPreview(PlaceItem item) {
    return Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PlaceDetailsScreen(item: item, showBookButton: false),
      ),
    );
  }

  Future<void> _remove(PlaceItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.cardDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'حذف العنصر',
          style: TextStyle(color: AppColors.primaryGold),
        ),
        content: Text(
          'هل تريد حذف "${item.name}" من تطبيق العميل؟',
          style: const TextStyle(color: AppColors.textWhite),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('إلغاء', style: TextStyle(color: AppColors.textGray)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE57373),
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('حذف', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final ok = await DashboardStore.instance.remove(item.id);
    if (ok) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: Column(
          children: [
            _header(),
            _statsRow(),
            _ordersEntry(),
            _featuredEntry(),
            const SizedBox(height: 6),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.primaryGold))
                  : _items.isEmpty
                      ? _emptyState()
                      : _itemsList(),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primaryGold,
        foregroundColor: Colors.black,
        onPressed: _openAdd,
        icon: const Icon(Icons.add),
        label: const Text(
          'إضافة عنصر',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.cardDark,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.primaryGold.withValues(alpha: 0.5),
              ),
            ),
            child: const Icon(Icons.dashboard,
                color: AppColors.primaryGold, size: 26),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'داشبورد حفلة',
                  style: TextStyle(
                    color: AppColors.textWhite,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'لوحة تحكم إدارة العناصر',
                  style: TextStyle(color: AppColors.textGray, fontSize: 12),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'قفل الداشبورد',
            onPressed: _lock,
            icon: const Icon(Icons.lock_outline, color: AppColors.primaryGold),
          ),
        ],
      ),
    );
  }

  void _lock() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AdminPinScreen()),
      (route) => false,
    );
  }

  Widget _statsRow() {
    final catalogTotal = allCatalogs.fold<int>(
      0,
      (sum, c) => sum + c.items.length,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _statCard(
            icon: Icons.category_outlined,
            value: '${adminSections.length}',
            label: 'الأقسام',
          ),
          const SizedBox(width: 10),
          _statCard(
            icon: Icons.inventory_2_outlined,
            value: '${_items.length}',
            label: 'عناصر مضافة',
          ),
          const SizedBox(width: 10),
          _statCard(
            icon: Icons.storefront_outlined,
            value: '$catalogTotal',
            label: 'عناصر الدليل',
          ),
        ],
      ),
    );
  }

  Widget _ordersEntry() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
      child: GestureDetector(
        onTap: _openOrders,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.cardDark,
            borderRadius: BorderRadius.circular(14),
            border:
                Border.all(color: AppColors.primaryGold.withValues(alpha: 0.5)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryGold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.receipt_long_outlined,
                  color: AppColors.primaryGold,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'قسم الطلبات',
                      style: TextStyle(
                        color: AppColors.textWhite,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'استقبال طلبات الحجز من كل العملاء',
                      style: TextStyle(color: AppColors.textGray, fontSize: 12),
                    ),
                  ],
                ),
              ),
              if (_pendingOrders > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGold,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$_pendingOrders بانتظار الموافقة',
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              const SizedBox(width: 8),
              const Icon(
                Icons.arrow_back_ios_new,
                color: AppColors.primaryGold,
                size: 14,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openFeatured() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const FeaturedScreen()),
    );
  }

  Widget _featuredEntry() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
      child: GestureDetector(
        onTap: _openFeatured,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.cardDark,
            borderRadius: BorderRadius.circular(14),
            border:
                Border.all(color: AppColors.primaryGold.withValues(alpha: 0.5)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryGold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.workspace_premium_outlined,
                  color: AppColors.primaryGold,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'قسم المقدمين المميزون',
                      style: TextStyle(
                        color: AppColors.textWhite,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'التحكم بالمقدمين الظاهرين في شريط "مقدمون مميزون" للعميل',
                      style: TextStyle(color: AppColors.textGray, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_back_ios_new,
                color: AppColors.primaryGold,
                size: 14,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statCard({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        decoration: BoxDecoration(
          color: AppColors.cardDark,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.containerBorder),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primaryGold, size: 20),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(
                color: AppColors.textWhite,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.textGray, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.inventory_2_outlined,
                color: AppColors.textGray, size: 64),
            SizedBox(height: 14),
            Text(
              'لا توجد عناصر مضافة بعد',
              style: TextStyle(color: AppColors.textWhite, fontSize: 16),
            ),
            SizedBox(height: 6),
            Text(
              'اضغط "إضافة عنصر" لإضافة أول عنصر إلى تطبيق العميل',
              style: TextStyle(color: AppColors.textGray, fontSize: 13),
            ),
          ],
        ),
      );

  Widget _itemsList() {
    final items = _items;
    return RefreshIndicator(
      color: AppColors.primaryGold,
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        itemCount: items.length,
        itemBuilder: (context, index) {
          return _itemCard(items[index]);
        },
      ),
    );
  }

  Widget _itemCard(PlaceItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.containerBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: AppColors.backgroundDark,
            ),
            child: _itemImage(item.mainImage),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textWhite,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.category,
                  style: const TextStyle(
                    color: AppColors.primaryGold,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.price,
                  style: const TextStyle(
                    color: AppColors.textGray,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'معاينة في تطبيق العميل',
            onPressed: () => _openPreview(item),
            icon: const Icon(Icons.visibility_outlined,
                color: AppColors.primaryGold),
          ),
          IconButton(
            tooltip: 'تعديل',
            onPressed: () => _openEdit(item),
            icon: const Icon(Icons.edit_outlined,
                color: AppColors.lightGold),
          ),
          IconButton(
            tooltip: 'حذف',
            onPressed: () => _remove(item),
            icon: const Icon(Icons.delete_outline,
                color: Color(0xFFE57373)),
          ),
        ],
      ),
    );
  }

  /// Renders an item's image whether it is a network URL, a base64 data URI,
  /// or a local path, falling back to a placeholder when it cannot be shown.
  /// (Some test items use plain http URLs, which Image.memory would fail on.)
  Widget _itemImage(String source) {
    final placeholder = const Icon(
      Icons.image_not_supported_outlined,
      color: AppColors.textGray,
    );
    if (source.startsWith('http://') || source.startsWith('https://')) {
      return Image.network(
        source,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => placeholder,
      );
    }
    if (source.startsWith('data:')) {
      try {
        return Image.memory(
          base64Decode(source.split(',').last),
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => placeholder,
        );
      } catch (_) {
        return placeholder;
      }
    }
    if (source.isNotEmpty) {
      return Image.file(
        File(source),
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => placeholder,
      );
    }
    return placeholder;
  }
}