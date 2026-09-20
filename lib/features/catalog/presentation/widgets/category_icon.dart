import 'package:material_ui/material_ui.dart';

/// Maps a category's icon key from the database to a drawn icon.
///
/// The database stores a short key rather than anything Flutter-specific, so
/// the two stay independent. A key this app does not know yet — a category
/// added after the installed version shipped — falls back to a neutral icon
/// instead of rendering nothing.
IconData iconForCategory(String key) => switch (key) {
  'handyman' => Icons.handyman_outlined,
  'cleaning' => Icons.cleaning_services_outlined,
  'moving' => Icons.local_shipping_outlined,
  'car' => Icons.directions_car_outlined,
  'pets' => Icons.pets_outlined,
  'beauty' => Icons.content_cut_outlined,
  'renovation' => Icons.format_paint_outlined,
  'garden' => Icons.grass_outlined,
  _ => Icons.more_horiz,
};
