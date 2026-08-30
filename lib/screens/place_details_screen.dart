import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../data/cart_store.dart';
import '../models/place_item_model.dart';
import '../utils/booking_dates.dart';
import '../widgets/app_image.dart';
import '../widgets/luxury_toast.dart';

/// Full details of one item: photo carousel + price + capacity + optional
/// info + features + a "حجز الآن" button that adds the item (with its chosen
/// day) to the cart. The button is hidden when [showBookButton] is false (the
/// dashboard preview).
class PlaceDetailsScreen extends StatefulWidget {
  final PlaceItem item;
  final bool showBookButton;

  const PlaceDetailsScreen({
    super.key,
    required this.item,
    this.showBookButton = true,
  });

  @override
  State<PlaceDetailsScreen> createState() => _PlaceDetailsScreenState();
}

class _PlaceDetailsScreenState extends State<PlaceDetailsScreen> {
  final PageController _pageController = PageController();
  int _activeImage = 0;

  /// The month currently shown in the date strip (first day of the month).
  DateTime _visibleMonth = DateTime(DateTime.now().year, DateTime.now().month);
  List<BookingDayOption> _days = const [];
  Set<String> _bookedKeys = const {};
  DateTime? _selectedDate;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _bookingsSub;

  @override
  void initState() {
    super.initState();
    _rebuildDays();
    _selectedDate = _firstAvailable(_days);
    _watchBookings();
  }

  bool get _canGoPrevious =>
      _visibleMonth.isAfter(DateTime(DateTime.now().year, DateTime.now().month));

  void _rebuildDays() {
    _days = monthBookingDays(_visibleMonth, bookedKeys: _bookedKeys);
  }

  void _changeMonth(int delta) {
    setState(() {
      _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + delta);
      _rebuildDays();
      final stillVisible = _selectedDate != null &&
          _days.any((d) => _isSameDay(d.date, _selectedDate!));
      if (!stillVisible) _selectedDate = _firstAvailable(_days);
    });
  }

  @override
  void dispose() {
    _bookingsSub?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  /// Listens to confirmed bookings for this item so days already reserved by
  /// other customers show as محجوز and cannot be selected.
  void _watchBookings() {
    try {
      _bookingsSub = FirebaseFirestore.instance
          .collection('bookings')
          .where('itemId', isEqualTo: widget.item.id)
          .snapshots()
          .listen(
        (snapshot) {
          final bookedKeys = <String>{};
          for (final doc in snapshot.docs) {
            final label = (doc.data()['date'] as String?) ?? '';
            final key = bookingDateKeyFromLabel(label);
            if (key != null) bookedKeys.add(key);
          }
          _applyBookings(bookedKeys);
        },
        onError: (Object _) {
          // Keep the last known availability on transient errors.
        },
      );
    } catch (_) {
      // Query failed (e.g. missing index) — days stay available.
    }
  }

  void _applyBookings(Set<String> bookedKeys) {
    setState(() {
      _bookedKeys = bookedKeys;
      final updated = monthBookingDays(_visibleMonth, bookedKeys: bookedKeys);
      _days = updated;
      final stillAvailable = _selectedDate != null &&
          updated.any((d) =>
              _isSameDay(d.date, _selectedDate!) && !d.isBooked && !d.isPast);
      if (!stillAvailable) _selectedDate = _firstAvailable(updated);
    });
  }

  DateTime? _firstAvailable(List<BookingDayOption> days) {
    for (final d in days) {
      if (!d.isBooked && !d.isPast) return d.date;
    }
    return null;
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final images = item.allImages;
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // App bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
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
                    Expanded(
                      child: Text(
                        item.name,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textWhite,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.favorite_border,
                      color: AppColors.primaryGold,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Photo carousel
              SizedBox(
                height: 280,
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: images.length,
                  onPageChanged: (index) =>
                      setState(() => _activeImage = index),
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () => _openFullscreen(context, images, index),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.primaryGold.withValues(alpha: 0.4),
                          ),
                        ),
                        child: AppImage(
                          source: images[index],
                          fit: BoxFit.cover,
                          fallbackIcon: item.defaultIcon,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),

              // Dots indicator + counter
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < images.length; i++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: i == _activeImage ? 22 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: i == _activeImage
                            ? AppColors.primaryGold
                            : AppColors.containerBorder,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),

              // Thumbnails row
              SizedBox(
                height: 56,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: images.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final selected = index == _activeImage;
                    return GestureDetector(
                      onTap: () {
                        _pageController.animateToPage(
                          index,
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeOut,
                        );
                      },
                      child: Container(
                        width: 56,
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: selected
                                ? AppColors.primaryGold
                                : AppColors.containerBorder,
                            width: selected ? 2 : 1,
                          ),
                        ),
                        child: AppImage(
                          source: images[index],
                          fit: BoxFit.cover,
                          fallbackIcon: Icons.image_outlined,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 18),

              // Title, rating & location
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: const TextStyle(
                        color: AppColors.textWhite,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          color: AppColors.primaryGold,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            item.location,
                            style: const TextStyle(
                              color: AppColors.textGray,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryGold.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.star,
                                color: AppColors.primaryGold,
                                size: 15,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                '${item.rating} (${item.reviews})',
                                style: const TextStyle(
                                  color: AppColors.textWhite,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Price
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          item.price,
                          style: const TextStyle(
                            color: AppColors.primaryGold,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (item.priceType != null) ...[
                          const SizedBox(width: 6),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 2),
                            child: Text(
                              '(${item.priceType})',
                              style: const TextStyle(
                                color: AppColors.textGray,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (item.description != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        item.description!,
                        style: const TextStyle(
                          color: AppColors.textGray,
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Select the day & date (month strip). The bar shows the whole
              // month from its first to last day; days booked by other
              // customers show a red "محجوز" badge and cannot be selected, and
              // the arrows move to the next/previous month across the years.
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _MonthDateBar(
                  month: _visibleMonth,
                  days: _days,
                  selectedDate: _selectedDate,
                  canGoPrevious: _canGoPrevious,
                  onPrevMonth: () => _changeMonth(-1),
                  onNextMonth: () => _changeMonth(1),
                  onSelect: (date) => setState(() => _selectedDate = date),
                ),
              ),

              // Key info chips (capacity etc.)
              if (item.capacity != null) ...[
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _InfoRow(
                    icon: Icons.people_outline,
                    label: 'السعة',
                    value: 'يتسع لـ ${item.capacity}',
                  ),
                ),
              ],

              // Optional structured info
              if (item.rooms != null)
                _infoPadding(
                  _InfoRow(icon: Icons.bed_outlined, label: 'عدد الغرف', value: '${item.rooms} غرف'),
                ),
              if (item.majlis != null)
                _infoPadding(
                  _InfoRow(icon: Icons.weekend_outlined, label: 'عدد المجالس', value: '${item.majlis} مجالس'),
                ),
              if (item.bathrooms != null)
                _infoPadding(
                  _InfoRow(icon: Icons.shower_outlined, label: 'دورات المياه', value: '${item.bathrooms}'),
                ),
              if (item.pool)
                _infoPadding(
                  _InfoRow(icon: Icons.pool_outlined, label: 'المسبح', value: 'متوفر'),
                ),
              if (item.kitchen)
                _infoPadding(
                  _InfoRow(icon: Icons.kitchen_outlined, label: 'المطبخ', value: 'متوفر'),
                ),
              if (item.parking)
                _infoPadding(
                  _InfoRow(icon: Icons.local_parking_outlined, label: 'المواقف', value: 'متوفرة'),
                ),
              if (item.checkIn != null || item.checkOut != null)
                _infoPadding(
                  _InfoRow(
                    icon: Icons.schedule_outlined,
                    label: 'أوقات الدخول والخروج',
                    value: '${item.checkIn ?? '—'} - ${item.checkOut ?? '—'}',
                  ),
                ),

              // Extra generic specs
              if (item.specs.isNotEmpty) ...[
                const SizedBox(height: 6),
                for (final entry in item.specs.entries)
                  _infoPadding(
                    _InfoRow(icon: Icons.check_circle_outline, label: entry.key, value: entry.value),
                  ),
              ],

              // Features
              if (item.features.isNotEmpty) ...[
                const SizedBox(height: 8),
                const _SectionTitle('الخدمات والمميزات'),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      for (final f in item.features)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.cardDark,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppColors.primaryGold.withValues(alpha: 0.5),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.check_circle,
                                color: AppColors.primaryGold,
                                size: 15,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                f,
                                style: const TextStyle(
                                  color: AppColors.textWhite,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // Book button (hidden in the dashboard preview)
              if (widget.showBookButton)
                Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGold,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 6,
                      shadowColor: AppColors.primaryGold.withValues(alpha: 0.4),
                    ),
                    onPressed: () => _addToCart(),
                    child: const Text(
                      'حجز الآن',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoPadding(Widget child) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        child: child,
      );

  Future<void> _addToCart() async {
    final selected = _selectedDate;
    if (selected == null) {
      showLuxuryToast(context, 'لا توجد أيام متاحة للحجز حالياً');
      return;
    }
    // Keep the original item id (single copy in the cart) but tag it with the
    // chosen day so the cart and the final booking request carry that date.
    final item = widget.item.copyWith(bookedDate: bookingDateLabel(selected));
    await CartStore.instance.add(item);
    if (!mounted) return;
    await showLuxuryToast(context, 'لقد تم اضافة حجزك بنجاح');
  }

  void _openFullscreen(
    BuildContext context,
    List<String> images,
    int initialIndex,
  ) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.95),
      builder: (_) => Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: _FullscreenGallery(
          images: images,
          index: initialIndex,
          defaultIcon: widget.item.defaultIcon,
        ),
      ),
    );
  }
}

class _FullscreenGallery extends StatefulWidget {
  final List<String> images;
  final int index;
  final IconData defaultIcon;

  const _FullscreenGallery({
    required this.images,
    required this.index,
    required this.defaultIcon,
  });

  @override
  State<_FullscreenGallery> createState() => _FullscreenGalleryState();
}

class _FullscreenGalleryState extends State<_FullscreenGallery> {
  late final PageController _controller;
  late int _current;

  @override
  void initState() {
    super.initState();
    _current = widget.index;
    _controller = PageController(initialPage: widget.index);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: PageView.builder(
            controller: _controller,
            itemCount: widget.images.length,
            onPageChanged: (i) => setState(() => _current = i),
            itemBuilder: (context, index) {
              return Center(
                child: InteractiveViewer(
                  maxScale: 4,
                  child: AppImage(
                    source: widget.images[index],
                    fit: BoxFit.contain,
                    fallbackIcon: widget.defaultIcon,
                  ),
                ),
              );
            },
          ),
        ),
        Positioned(
          top: 16,
          left: 16,
          child: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close, color: AppColors.textWhite, size: 26),
          ),
        ),
        Positioned(
          bottom: 20,
          right: 0,
          left: 0,
          child: Text(
            '${_current + 1}/${widget.images.length}',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textWhite,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
}

class _MonthDateBar extends StatelessWidget {
  final DateTime month;
  final List<BookingDayOption> days;
  final DateTime? selectedDate;
  final bool canGoPrevious;
  final VoidCallback onPrevMonth;
  final VoidCallback onNextMonth;
  final ValueChanged<DateTime> onSelect;

  const _MonthDateBar({
    required this.month,
    required this.days,
    required this.selectedDate,
    required this.canGoPrevious,
    required this.onPrevMonth,
    required this.onNextMonth,
    required this.onSelect,
  });

  bool _isSelected(DateTime day) {
    final sel = selectedDate;
    return sel != null &&
        day.year == sel.year &&
        day.month == sel.month &&
        day.day == sel.day;
  }

  bool _isToday(DateTime day) {
    final now = DateTime.now();
    return day.year == now.year && day.month == now.month && day.day == now.day;
  }

  String get _monthTitle => '${arabicMonthName(month.month)} ${month.year}';

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primaryGold.withValues(alpha: 0.4),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryGold.withValues(alpha: 0.12),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 4),
            child: Row(
              children: [
                IconButton(
                  tooltip: 'الشهر السابق',
                  onPressed: canGoPrevious ? onPrevMonth : null,
                  icon: Icon(
                    Icons.chevron_left,
                    color: canGoPrevious
                        ? AppColors.primaryGold
                        : AppColors.containerBorder,
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      const Text(
                        'اختر اليوم والتاريخ',
                        style: TextStyle(
                          color: AppColors.textGray,
                          fontSize: 10,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _monthTitle,
                        style: const TextStyle(
                          color: AppColors.primaryGold,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'الشهر التالي',
                  onPressed: onNextMonth,
                  icon: const Icon(
                    Icons.chevron_right,
                    color: AppColors.primaryGold,
                  ),
                ),
              ],
            ),
          ),
          const Divider(
            color: AppColors.containerBorder,
            height: 1,
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 88,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: days.length,
              separatorBuilder: (_, _) => const SizedBox(width: 6),
              itemBuilder: (context, index) => _dayCell(days[index]),
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _legendDot(AppColors.primaryGold),
                const SizedBox(width: 6),
                const Text(
                  'متاح',
                  style: TextStyle(color: AppColors.textGray, fontSize: 11),
                ),
                const SizedBox(width: 18),
                _legendDot(const Color(0xFFE57373)),
                const SizedBox(width: 6),
                const Text(
                  'محجوز من عميل آخر',
                  style: TextStyle(color: AppColors.textGray, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendDot(Color color) => Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: 0.35),
          border: Border.all(color: color, width: 1),
        ),
      );

  Widget _dayCell(BookingDayOption day) {
    final selected = _isSelected(day.date);
    final enabled = !day.isBooked && !day.isPast;
    final statusLabel = SizedBox(
      height: 13,
      child: day.isBooked
          ? const Text(
              'محجوز',
              style: TextStyle(
                color: Color(0xFFE57373),
                fontSize: 9,
                fontWeight: FontWeight.bold,
              ),
            )
          : day.isPast
              ? const Text(
                  'مضى',
                  style: TextStyle(color: AppColors.containerBorder, fontSize: 9),
                )
              : _isToday(day.date)
                  ? const Text(
                      'اليوم',
                      style: TextStyle(
                        color: AppColors.primaryGold,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : const SizedBox.shrink(),
    );
    return GestureDetector(
      onTap: enabled ? () => onSelect(day.date) : null,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            arabicShortDayName(day.date.weekday),
            style: TextStyle(
              color: enabled ? AppColors.textWhite : AppColors.textGray,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: day.isBooked
                  ? const Color(0xFFE57373).withValues(alpha: 0.15)
                  : selected
                      ? AppColors.primaryGold
                      : day.isPast
                          ? AppColors.cardDark
                          : AppColors.backgroundDark,
              border: Border.all(
                color: day.isBooked
                    ? const Color(0xFFE57373)
                    : selected
                        ? AppColors.primaryGold
                        : day.isPast
                            ? AppColors.containerBorder
                            : AppColors.primaryGold.withValues(alpha: 0.55),
                width: selected ? 2 : 1,
              ),
            ),
            child: Text(
              '${day.date.day}',
              style: TextStyle(
                color: day.isBooked
                    ? const Color(0xFFE57373)
                    : selected
                        ? Colors.black
                        : day.isPast
                            ? AppColors.containerBorder
                            : AppColors.textWhite,
                fontSize: 15,
                fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                decoration: day.isBooked ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
          const SizedBox(height: 3),
          statusLabel,
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 18,
            decoration: BoxDecoration(
              color: AppColors.primaryGold,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.primaryGold,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.containerBorder),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primaryGold.withValues(alpha: 0.15),
            ),
            child: Icon(icon, color: AppColors.primaryGold, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textGray,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                color: AppColors.textWhite,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
