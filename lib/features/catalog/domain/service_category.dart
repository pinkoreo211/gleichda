/// One top-level area of the catalog, e.g. "Reinigung".
///
/// Loaded from the backend, never hard-coded: adding a category is an insert
/// in the database, not an app release. The app therefore must not assume a
/// fixed number of them.
class ServiceCategory {
  const ServiceCategory({
    required this.id,
    required this.slug,
    required this.name,
    this.nameEn,
    this.description,
    this.descriptionEn,
    this.iconKey = 'other',
    this.imageUrl,
  });

  final String id;

  /// Stable key. Used in links and by code; the display name may change.
  final String slug;

  /// German, the launch market's language.
  final String name;

  /// English, falling back to [name] when the translation is missing.
  final String? nameEn;

  final String? description;
  final String? descriptionEn;

  /// Which icon the app draws. Unknown keys fall back to a neutral icon, so
  /// a category added in the database never renders blank.
  final String iconKey;

  final String? imageUrl;

  String nameFor(String languageCode) =>
      pickTranslation(name, nameEn, languageCode) ?? name;

  String? descriptionFor(String languageCode) =>
      pickTranslation(description, descriptionEn, languageCode);

  static ServiceCategory fromJson(Map<String, dynamic> json) => ServiceCategory(
    id: json['id'] as String,
    slug: json['slug'] as String? ?? '',
    name: json['name'] as String? ?? '',
    nameEn: json['name_en'] as String?,
    description: json['description'] as String?,
    descriptionEn: json['description_en'] as String?,
    iconKey: json['icon'] as String? ?? 'other',
    imageUrl: json['image_url'] as String?,
  );
}

/// Returns the English text when the interface is English and a translation
/// exists, otherwise the German original.
///
/// Catalog content lives in the database rather than in the translation
/// files, so it carries its own translations. German is always present;
/// English is optional.
String? pickTranslation(String? german, String? english, String languageCode) {
  if (languageCode == 'en' && english != null && english.isNotEmpty) {
    return english;
  }
  return german;
}
