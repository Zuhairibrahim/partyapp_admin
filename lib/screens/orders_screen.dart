import 'package:flutter/material.dart';

import 'package:partyapp_admin/core/constants/app_colors.dart';
import 'package:partyapp_admin/data/booking_store.dart';
import 'package:partyapp_admin/data/customer_store.dart';
import 'package:partyapp_admin/models/booking_model.dart';
import 'package:partyapp_admin/models/customer_profile.dart';

/// قسم الطلبات: يستقبل طلبات الحجز من كل العملاء (كل طلب يحمل معرّف عميل
/// مستقل). يعرض بطاقة لكل عميل بالاسم الثلاثي ورقم الهاتف؛ والضغط على العميل
/// يفتح "صندوقه" الذي يضم كل طلباته المفعّلة من طرف واحد.
class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  List<Booking> _bookings = const [];
  Map<String, CustomerProfile> _profiles = const {};
  bool _loading = true;
  String _filter = 'all';

  static const List<({String id, String label})> _filters = [
    (id: 'all', label: 'كل الطلبات'),
    (id: 'pending', label: 'جاري الانتظار'),
    (id: 'processing', label: 'جاري تلبية طلبك'),
    (id: 'approved', label: 'تم قبول طلبك بنجاح'),
    (id: 'completed', label: 'تم تنفيذ الطلب'),
    (id: 'rejected', label: 'تم رفض الطلب'),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final bookings = await BookingStore.instance.reload();
    final profilesAll = await CustomerStore.instance.loadAll();
    final profiles = {
      for (final p in profilesAll) p.customerId: p,
    };
    if (!mounted) return;
    setState(() {
      _bookings = bookings
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      _profiles = profiles;
      _loading = false;
    });
  }

  int get _pendingCount =>
      _bookings.where((b) => b.status == BookingStatus.pending).length;

  /// Groups bookings by customer; only keeps customers with at least one
  /// booking matching the active filter.
  List<_CustomerGroup> get _groups {
    final byCustomer = <String, List<Booking>>{};
    for (final b in _bookings) {
      if (_filter != 'all' && b.status.name != _filter) continue;
      byCustomer.putIfAbsent(b.customerId, () => []).add(b);
    }
    final groups = [
      for (final entry in byCustomer.entries)
        _CustomerGroup(
          customerId: entry.key,
          profile: _profiles[entry.key],
          bookings: entry.value,
        ),
    ];
    groups.sort((a, b) {
      final aLatest =
          a.bookings.map((x) => x.createdAt).reduce((x, y) => x.compareTo(y) >= 0 ? x : y);
      final bLatest =
          b.bookings.map((x) => x.createdAt).reduce((x, y) => x.compareTo(y) >= 0 ? x : y);
      return bLatest.compareTo(aLatest);
    });
    return groups;
  }

  @override
  Widget build(BuildContext context) {
    final groups = _groups;
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.arrow_forward_ios,
                      color: AppColors.textWhite,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.receipt_long_outlined,
                    color: AppColors.primaryGold,
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'قسم الطلبات',
                      style: TextStyle(
                        color: AppColors.textWhite,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGold.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.primaryGold.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Text(
                      '${_bookings.length} طلب',
                      style: const TextStyle(
                        color: AppColors.primaryGold,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'كل عميل مستقل، اضغط على العميل لفتح صندوق طلباته',
                  style: TextStyle(color: AppColors.textGray, fontSize: 12),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  if (_pendingCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryGold,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$_pendingCount بانتظار الموافقة',
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: AppColors.cardDark,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.containerBorder),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _filter,
                        dropdownColor: AppColors.cardDark,
                        style: const TextStyle(
                          color: AppColors.textWhite,
                          fontSize: 13,
                        ),
                        items: [
                          for (final f in _filters)
                            DropdownMenuItem(
                              value: f.id,
                              child: Text(f.label),
                            ),
                        ],
                        onChanged: (v) {
                          if (v == null) return;
                          setState(() => _filter = v);
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primaryGold,
                      ),
                    )
                  : groups.isEmpty
                      ? const _EmptyOrders()
                      : RefreshIndicator(
                          color: AppColors.primaryGold,
                          onRefresh: _load,
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                            itemCount: groups.length,
                            itemBuilder: (context, index) =>
                                _CustomerCard(group: groups[index]),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CustomerGroup {
  final String customerId;
  final CustomerProfile? profile;
  final List<Booking> bookings;

  const _CustomerGroup({
    required this.customerId,
    required this.profile,
    required this.bookings,
  });

  String get displayName =>
      profile?.name ?? 'عميل ${customerId.length > 9 ? customerId.substring(0, 9) : customerId}';

  int get pendingCount =>
      bookings.where((b) => b.status == BookingStatus.pending).length;
}

/// A single customer card: name, phone and order summary. Tapping opens the
/// customer's own inbox (CustomerInboxScreen) with every one of their orders.
class _CustomerCard extends StatelessWidget {
  final _CustomerGroup group;

  const _CustomerCard({required this.group});

  @override
  Widget build(BuildContext context) {
    final latest = group.bookings.first;
    final initial = group.profile == null
        ? '؟'
        : group.profile!.name.trim().characters.first.toUpperCase();
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.primaryGold.withValues(alpha: 0.5),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CustomerInboxScreen(
                customerId: group.customerId,
                profile: group.profile,
                bookings: group.bookings,
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.primaryGold, AppColors.lightGold],
                    ),
                  ),
                  child: Text(
                    initial,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        group.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textWhite,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text.rich(
                        TextSpan(
                          children: [
                            const WidgetSpan(
                              alignment: PlaceholderAlignment.middle,
                              child: Icon(
                                Icons.phone_iphone,
                                color: AppColors.primaryGold,
                                size: 12,
                              ),
                            ),
                            const WidgetSpan(child: SizedBox(width: 4)),
                            TextSpan(
                              text: group.profile?.phone ?? '—',
                              style: const TextStyle(
                                color: AppColors.textGray,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        textDirection: TextDirection.ltr,
                        textAlign: TextAlign.left,
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          _chip(
                            icon: Icons.receipt_long_outlined,
                            text: '${group.bookings.length} طلب',
                          ),
                          if (group.pendingCount > 0)
                            _chip(
                              icon: Icons.schedule,
                              text: '${group.pendingCount} بانتظار',
                              filled: true,
                            ),
                          _chip(
                            icon: Icons.event,
                            text: latest.date == 'اليوم'
                                ? 'آخر طلب: اليوم'
                                : 'آخر طلب: ${latest.date}',
                          ),
                        ],
                      ),
                    ],
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
      ),
    );
  }

  Widget _chip({
    required IconData icon,
    required String text,
    bool filled = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: filled
            ? AppColors.primaryGold
            : AppColors.primaryGold.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: filled ? Colors.black : AppColors.primaryGold, size: 12),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: filled ? Colors.black : AppColors.primaryGold,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

/// صندوق العميل: كل بيانات طلبات عميل واحد، مع قائمة منسدلة لتغيير حالة كل
/// طلب من داخل الداشبورد.
class CustomerInboxScreen extends StatefulWidget {
  final String customerId;
  final CustomerProfile? profile;
  final List<Booking> bookings;

  const CustomerInboxScreen({
    super.key,
    required this.customerId,
    required this.profile,
    required this.bookings,
  });

  @override
  State<CustomerInboxScreen> createState() => _CustomerInboxScreenState();
}

class _CustomerInboxScreenState extends State<CustomerInboxScreen> {
  List<Booking>? _bookings;

  @override
  void initState() {
    super.initState();
    _bookings = widget.bookings;
  }

  Future<void> _refresh() async {
    final all = await BookingStore.instance.reload();
    if (!mounted) return;
    setState(() {
      _bookings = all
          .where((b) => b.customerId == widget.customerId)
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    });
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.profile;
    final bookings = _bookings ?? const <Booking>[];
    final initial = profile == null
        ? '؟'
        : profile.name.trim().characters.first.toUpperCase();
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.arrow_forward_ios,
                      color: AppColors.textWhite,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.inbox_outlined,
                    color: AppColors.primaryGold,
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'صندوق العميل',
                      style: TextStyle(
                        color: AppColors.textWhite,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGold.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.primaryGold.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Text(
                      '${bookings.length} طلب',
                      style: const TextStyle(
                        color: AppColors.primaryGold,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.cardDark,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.primaryGold.withValues(alpha: 0.5),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppColors.primaryGold, AppColors.lightGold],
                      ),
                    ),
                    child: Text(
                      initial,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profile?.name ?? widget.customerId,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textWhite,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          profile?.phone ?? 'رقم الهاتف غير مسجل',
                          textDirection: TextDirection.ltr,
                          textAlign: TextAlign.left,
                          style: const TextStyle(
                            color: AppColors.textGray,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 2),
            Expanded(
              child: bookings.isEmpty
                  ? const _EmptyOrders()
                  : RefreshIndicator(
                      color: AppColors.primaryGold,
                      onRefresh: _refresh,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
                        itemCount: bookings.length,
                        itemBuilder: (context, index) => _OrderCard(
                          booking: bookings[index],
                          onChanged: _refresh,
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Booking booking;
  final Future<void> Function() onChanged;

  const _OrderCard({required this.booking, required this.onChanged});

  (IconData, Color) get _status => switch (booking.status) {
        BookingStatus.approved => (
            Icons.check_circle,
            const Color(0xFF4CAF50),
          ),
        BookingStatus.rejected => (
            Icons.cancel,
            const Color(0xFFE57373),
          ),
        BookingStatus.completed => (
            Icons.verified,
            AppColors.primaryGold,
          ),
        BookingStatus.processing => (
            Icons.local_shipping_outlined,
            const Color(0xFF42A5F5),
          ),
        BookingStatus.pending => (
            Icons.schedule,
            AppColors.primaryGold,
          ),
      };

  @override
  Widget build(BuildContext context) {
    final (icon, color) = _status;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.containerBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  booking.itemName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textWhite,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Icon(icon, color: color, size: 20),
            ],
          ),
          const Divider(
            color: AppColors.containerBorder,
            height: 16,
          ),
          Wrap(
            spacing: 14,
            runSpacing: 6,
            children: [
              _meta(Icons.category_outlined, booking.itemCategory),
              _meta(Icons.event, booking.date),
              _meta(Icons.location_on, booking.location),
              if (booking.totalPrice > 0)
                _meta(
                  Icons.attach_money,
                  'ريال ${_formatPrice(booking.totalPrice)}',
                ),
            ],
          ),
          if (booking.services.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'الخدمات: ${booking.services.join('، ')}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textGray,
                fontSize: 11,
              ),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  booking.statusLabel,
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'تغيير الحالة:',
                style: TextStyle(color: AppColors.textGray, fontSize: 12),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: AppColors.backgroundDark,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.primaryGold.withValues(alpha: 0.4),
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<BookingStatus>(
                    value: booking.status,
                    dropdownColor: AppColors.cardDark,
                    style: const TextStyle(
                      color: AppColors.textWhite,
                      fontSize: 12,
                    ),
                    items: [
                      for (final s in BookingStatus.values)
                        DropdownMenuItem(
                          value: s,
                          child: Text(s.label),
                        ),
                    ],
                    onChanged: (s) async {
                      if (s == null || s == booking.status) return;
                      await BookingStore.instance.updateStatus(booking.id, s);
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('تم تحديث حالة الطلب إلى "${s.label}"'),
                          backgroundColor: AppColors.primaryGold,
                        ),
                      );
                      await onChanged();
                    },
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _meta(IconData icon, String text) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.primaryGold, size: 13),
          const SizedBox(width: 3),
          Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.textGray, fontSize: 11),
          ),
        ],
      );

  static String _formatPrice(int value) {
    final digits = value.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }
}

class _EmptyOrders extends StatelessWidget {
  const _EmptyOrders();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(
            Icons.inbox_outlined,
            color: AppColors.textGray,
            size: 56,
          ),
          SizedBox(height: 14),
          Text(
            'لا توجد طلبات بعد',
            style: TextStyle(
              color: AppColors.textWhite,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'طلبات الحجز من العملاء ستظهر هنا',
            style: TextStyle(
              color: AppColors.textGray,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}