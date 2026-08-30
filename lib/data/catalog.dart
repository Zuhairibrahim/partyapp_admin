import 'package:flutter/material.dart';

import '../models/place_item_model.dart';

/// Definition of one category with its listing items, subtitle and icon.
class CategoryCatalog {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final List<PlaceItem> items;

  const CategoryCatalog({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.items,
  });
}

/// The customer starts with a clean slate: the home sections keep their
/// layout, but no built-in sample services ship with the app. Real services
/// are added from the dashboard into each section and appear here instantly
/// (merged in [PlaceStore.forCategory]).
const List<CategoryCatalog> _catalogs = [
  CategoryCatalog(
    id: 'halls',
    title: 'القاعات',
    subtitle: 'الباقات والخدمات',
    icon: Icons.home_work_outlined,
    items: [],
  ),
  CategoryCatalog(
    id: 'chalets',
    title: 'الشاليهات',
    subtitle: 'الباقات والخدمات',
    icon: Icons.holiday_village_outlined,
    items: [],
  ),
  CategoryCatalog(
    id: 'salons',
    title: 'الصالات',
    subtitle: 'الباقات والخدمات',
    icon: Icons.meeting_room_outlined,
    items: [],
  ),
  CategoryCatalog(
    id: 'parks',
    title: 'المنتزه',
    subtitle: 'الباقات والخدمات',
    icon: Icons.park_outlined,
    items: [],
  ),
  CategoryCatalog(
    id: 'photographers',
    title: 'المصورين',
    subtitle: 'الباقات والخدمات',
    icon: Icons.photo_camera_outlined,
    items: [],
  ),
  CategoryCatalog(
    id: 'photography',
    title: 'التصوير',
    subtitle: 'الباقات والخدمات',
    icon: Icons.camera_alt_outlined,
    items: [],
  ),
  CategoryCatalog(
    id: 'dj',
    title: 'الدي جي',
    subtitle: 'الباقات والخدمات',
    icon: Icons.music_note_outlined,
    items: [],
  ),
  CategoryCatalog(
    id: 'video',
    title: 'الفيديو',
    subtitle: 'الباقات والخدمات',
    icon: Icons.videocam_outlined,
    items: [],
  ),
  CategoryCatalog(
    id: 'dresses',
    title: 'الفساتين',
    subtitle: 'الباقات والخدمات',
    icon: Icons.checkroom_outlined,
    items: [],
  ),
  CategoryCatalog(
    id: 'lighting',
    title: 'الإضاءات',
    subtitle: 'الباقات والخدمات',
    icon: Icons.highlight_outlined,
    items: [],
  ),
  CategoryCatalog(
    id: 'decoration',
    title: 'الزينة',
    subtitle: 'الباقات والخدمات',
    icon: Icons.auto_awesome_outlined,
    items: [],
  ),
  CategoryCatalog(
    id: 'kousha',
    title: 'الكوشة',
    subtitle: 'الباقات والخدمات',
    icon: Icons.local_florist_outlined,
    items: [],
  ),
  CategoryCatalog(
    id: 'organizers',
    title: 'منظمي الحفلة',
    subtitle: 'الباقات والخدمات',
    icon: Icons.event_available_outlined,
    items: [],
  ),
  CategoryCatalog(
    id: 'female_security',
    title: 'حراسة نسائية',
    subtitle: 'الباقات والخدمات',
    icon: Icons.verified_user_outlined,
    items: [],
  ),
  CategoryCatalog(
    id: 'water_distribution',
    title: 'توزيع الماء',
    subtitle: 'الباقات والخدمات',
    icon: Icons.water_drop_outlined,
    items: [],
  ),
  CategoryCatalog(
    id: 'bakhoor',
    title: 'البخور',
    subtitle: 'الباقات والخدمات',
    icon: Icons.air_outlined,
    items: [],
  ),
];

CategoryCatalog catalogFor(String id) {
  return _catalogs.firstWhere(
    (c) => c.id == id,
    orElse: () => _catalogs.first,
  );
}

/// All catalog categories, used by the admin dashboard to list categories
/// and to show built-in catalog items alongside admin-added ones.
List<CategoryCatalog> get allCatalogs => List.unmodifiable(_catalogs);