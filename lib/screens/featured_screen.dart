import 'package:flutter/material.dart';
import 'package:partyapp_admin/core/constants/app_colors.dart';
import 'package:partyapp_admin/models/featured_provider.dart';
import 'package:partyapp_admin/widgets/app_image.dart';

import '../data/shared_store.dart';
import 'add_featured_screen.dart';

/// Lists every featured provider visible in the customer app's "مقدمون مميزون"
/// strip, with add / edit / delete actions. Whatever is here is exactly what
/// the customer app shows.
class FeaturedScreen extends StatefulWidget {
  const FeaturedScreen({super.key});

  @override
  State<FeaturedScreen> createState() => _FeaturedScreenState();
}

class _FeaturedScreenState extends State<FeaturedScreen> {
  List<FeaturedProvider> _items = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final items = await DashboardStore.instance.loadFeatured();
    if (!mounted) return;
    setState(() {
      _items = items;
      _loading = false;
    });
  }

  Future<void> _openAdd() async {
    final added = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const AddFeaturedScreen()),
    );
    if (added == true) _load();
  }

  Future<void> _openEdit(FeaturedProvider provider) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AddFeaturedScreen(initial: provider),
      ),
    );
    if (changed == true) _load();
  }

  Future<void> _remove(FeaturedProvider provider) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.cardDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'حذف المقدم المميز',
          style: TextStyle(color: AppColors.primaryGold),
        ),
        content: Text(
          'هل تريد إزالة "${provider.name}" من "مقدمون مميزون" في تطبيق العميل؟',
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
    final ok = await DashboardStore.instance.removeFeatured(provider.id);
    if (ok) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        foregroundColor: AppColors.textWhite,
        title: const Text(
          'مقدمون مميزون',
          style: TextStyle(color: AppColors.primaryGold),
        ),
      ),
      body: SafeArea(
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(
                    color: AppColors.primaryGold))
            : _items.isEmpty
                ? _emptyState()
                : RefreshIndicator(
                    color: AppColors.primaryGold,
                    onRefresh: _load,
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                      itemCount: _items.length,
                      itemBuilder: (context, index) =>
                          _providerCard(_items[index]),
                    ),
                  ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primaryGold,
        foregroundColor: Colors.black,
        onPressed: _openAdd,
        icon: const Icon(Icons.add),
        label: const Text(
          'إضافة مقدم',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _emptyState() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.workspace_premium_outlined,
                color: AppColors.textGray, size: 64),
            SizedBox(height: 14),
            Text(
              'لا يوجد مقدمون مميزون بعد',
              style: TextStyle(color: AppColors.textWhite, fontSize: 16),
            ),
            SizedBox(height: 6),
            Text(
              'اضغط "إضافة مقدم" ليظهر في قائمة "مقدمون مميزون" بتطبيق العميل',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textGray, fontSize: 13),
            ),
          ],
        ),
      );

  Widget _providerCard(FeaturedProvider provider) {
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
            child: AppImage(
              source: provider.image,
              fallbackIcon: Icons.workspace_premium_outlined,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  provider.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textWhite,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.star,
                        color: AppColors.primaryGold, size: 13),
                    const SizedBox(width: 3),
                    Text(
                      provider.rating.toStringAsFixed(1),
                      style: const TextStyle(
                        color: AppColors.primaryGold,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                if (provider.category != null) ...[
                  Text(
                    provider.category!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.primaryGold,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 2),
                ],
                Text(
                  provider.price,
                  style: const TextStyle(
                    color: AppColors.textGray,
                    fontSize: 12,
                  ),
                ),
                if (provider.capacity != null || provider.location != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    [
                      provider.capacity,
                      provider.location,
                    ].whereType<String>().join(' • '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textGray,
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            tooltip: 'تعديل',
            onPressed: () => _openEdit(provider),
            icon: const Icon(Icons.edit_outlined,
                color: AppColors.lightGold),
          ),
          IconButton(
            tooltip: 'حذف',
            onPressed: () => _remove(provider),
            icon: const Icon(Icons.delete_outline,
                color: Color(0xFFE57373)),
          ),
        ],
      ),
    );
  }
}