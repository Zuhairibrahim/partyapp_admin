import 'package:flutter/material.dart';

/// One selectable section the admin can add an item to. `id` matches the
/// customer app's home-screen catalog ids so items land in the right list.
class AdminSection {
  final String id;
  final String title;
  final IconData icon;

  const AdminSection(this.id, this.title, this.icon);
}

const List<AdminSection> adminSections = [
  AdminSection('halls', 'القاعات', Icons.home_work_outlined),
  AdminSection('chalets', 'الشاليهات', Icons.holiday_village_outlined),
  AdminSection('parks', 'المنتزه', Icons.park_outlined),
  AdminSection('salons', 'الصالات', Icons.meeting_room_outlined),
  AdminSection('photographers', 'المصورين', Icons.photo_camera_outlined),
  AdminSection('photography', 'التصوير', Icons.camera_alt_outlined),
  AdminSection('dresses', 'الفساتين', Icons.checkroom_outlined),
  AdminSection('lighting', 'الإضاءات', Icons.highlight_outlined),
  AdminSection('decoration', 'الزينة', Icons.auto_awesome_outlined),
  AdminSection('kousha', 'الكوشة', Icons.local_florist_outlined),
  AdminSection('organizers', 'منظمي الحفلة', Icons.event_available_outlined),
  AdminSection('female_security', 'حراسة نسائية', Icons.verified_user_outlined),
  AdminSection('water_distribution', 'توزيع الماء', Icons.water_drop_outlined),
  AdminSection('bakhoor', 'البخور', Icons.air_outlined),
];
