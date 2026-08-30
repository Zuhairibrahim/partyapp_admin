/// Helpers for building the customer-facing booking date strip. Days are shown
/// as deterministic labels like "السبت - 5/10/2026". Availability is decided by
/// matching a machine-friendly date key against the dates already booked in the
/// shared `bookings` collection, so days reserved by other customers show as
/// booked ("محجوز") and cannot be selected.
library;

const List<String> _arabicDayNames = [
  'الأحد',
  'الاثنين',
  'الثلاثاء',
  'الأربعاء',
  'الخميس',
  'الجمعة',
  'السبت',
];

const List<String> _arabicShortDayNames = [
  'أحد',
  'اثنين',
  'ثلاثاء',
  'أربعاء',
  'خميس',
  'جمعة',
  'سبت',
];

const List<String> _arabicMonthNames = [
  'يناير',
  'فبراير',
  'مارس',
  'أبريل',
  'مايو',
  'يونيو',
  'يوليو',
  'أغسطس',
  'سبتمبر',
  'أكتوبر',
  'نوفمبر',
  'ديسمبر',
];

/// Arabic weekday name for [weekday] (1 = الأحد ... 7 = السبت).
String arabicDayName(int weekday) => _arabicDayNames[weekday - 1];

/// Short Arabic weekday label used inside the day strip cells.
String arabicShortDayName(int weekday) => _arabicShortDayNames[weekday - 1];

/// Arabic Gregorian month name (1 = يناير ... 12 = ديسمبر).
String arabicMonthName(int month) => _arabicMonthNames[month - 1];

/// Display label, e.g. "السبت - 5/10/2026". Stored on bookings so the
/// dashboard sees the chosen day too.
String bookingDateLabel(DateTime day) =>
    '${arabicDayName(day.weekday)} - ${day.day}/${day.month}/${day.year}';

/// Machine-friendly key (d/m/yyyy) used to compare availability regardless of
/// the weekday prefix in [bookingDateLabel].
String bookingDateKey(DateTime day) => '${day.day}/${day.month}/${day.year}';

/// Extracts the (day/month/year) part of a stored [bookingDateLabel], or null
/// for legacy labels without a " - " separator (old "اليوم" bookings).
String? bookingDateKeyFromLabel(String label) {
  final idx = label.lastIndexOf(' - ');
  if (idx == -1) return null;
  final key = label.substring(idx + 3).trim();
  return key.isEmpty ? null : key;
}

/// One day inside the booking date strip.
class BookingDayOption {
  final DateTime date;
  final String label;
  final bool isBooked;

  /// True when the day is before today, so it can't be selected.
  final bool isPast;

  const BookingDayOption({
    required this.date,
    required this.label,
    required this.isBooked,
    this.isPast = false,
  });
}

/// The next [count] days starting today, each marked booked when its date key
/// is present in [bookedKeys]. Kept for compatibility and simple callers.
List<BookingDayOption> nextBookingDays({
  int count = 14,
  Set<String> bookedKeys = const {},
  DateTime? today,
}) {
  final now = today ?? DateTime.now();
  return List.generate(count, (index) {
    final day = DateTime(now.year, now.month, now.day + index);
    return BookingDayOption(
      date: day,
      label: bookingDateLabel(day),
      isBooked: bookedKeys.contains(bookingDateKey(day)),
    );
  });
}

/// All days of [month] from the 1st to the last day (28-31). Days are marked
/// booked from [bookedKeys]; days strictly before [today] are marked past so
/// they can't be selected. The strip always starts from the beginning of the
/// month, and once it runs out the caller moves to the next month (and so on
/// across every year).
List<BookingDayOption> monthBookingDays(
  DateTime month, {
  Set<String> bookedKeys = const {},
  DateTime? today,
}) {
  final ref = DateTime(month.year, month.month);
  final daysInMonth = DateTime(ref.year, ref.month + 1, 0).day;
  final now = today ?? DateTime.now();
  final startOfToday = DateTime(now.year, now.month, now.day);
  return List.generate(daysInMonth, (index) {
    final day = DateTime(ref.year, ref.month, index + 1);
    return BookingDayOption(
      date: day,
      label: bookingDateLabel(day),
      isBooked: bookedKeys.contains(bookingDateKey(day)),
      isPast: day.isBefore(startOfToday),
    );
  });
}

/// The month (1st) after [month].
DateTime nextMonth(DateTime month) => DateTime(month.year, month.month + 1);

/// The month (1st) before [month].
DateTime previousMonth(DateTime month) => DateTime(month.year, month.month - 1);