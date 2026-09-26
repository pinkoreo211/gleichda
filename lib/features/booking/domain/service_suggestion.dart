import 'package:app/features/catalog/domain/service.dart';
import 'package:app/features/catalog/domain/service_category.dart'
    show pickTranslation;

/// A catalog service the backend thinks the customer might mean.
///
/// Today the backend matches keywords. Tomorrow it may read the text
/// properly, or look at a photo. Either way it hands back the same thing:
/// real services from the real catalog, never an invented one. The app
/// shows them as suggestions and lets the customer say no.
class ServiceSuggestion {
  const ServiceSuggestion({
    required this.serviceId,
    required this.slug,
    required this.name,
    required this.serviceType,
    required this.categorySlug,
    this.nameEn,
    this.shortDescription,
    this.shortDescriptionEn,
    this.categoryName,
  });

  final String serviceId;
  final String slug;
  final String name;
  final String? nameEn;
  final String? shortDescription;
  final String? shortDescriptionEn;
  final ServiceType serviceType;
  final String categorySlug;
  final String? categoryName;

  String nameFor(String languageCode) =>
      pickTranslation(name, nameEn, languageCode) ?? name;

  String? descriptionFor(String languageCode) =>
      pickTranslation(shortDescription, shortDescriptionEn, languageCode);

  static ServiceSuggestion fromJson(Map<String, dynamic> json) =>
      ServiceSuggestion(
        serviceId: json['service_id'] as String,
        slug: json['slug'] as String? ?? '',
        name: json['name'] as String? ?? '',
        nameEn: json['name_en'] as String?,
        shortDescription: json['short_description'] as String?,
        shortDescriptionEn: json['short_description_en'] as String?,
        serviceType: ServiceType.fromName(json['service_type'] as String?),
        categorySlug: json['category_slug'] as String? ?? '',
        categoryName: json['category_name'] as String?,
      );
}
