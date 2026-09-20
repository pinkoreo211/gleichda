import 'package:app/features/catalog/domain/service_category.dart'
    show pickTranslation;
import 'package:app/features/catalog/domain/service_price_option.dart';

/// How a service is priced.
enum ServiceType {
  /// Listed prices the customer can book directly, once booking exists.
  fixedPrice,

  /// The customer describes the job and receives offers.
  quote;

  /// The database writes snake_case; the Dart names are camelCase, so this
  /// is the one place that translates between them.
  static ServiceType fromName(String? name) =>
      name == 'fixed_price' ? ServiceType.fixedPrice : ServiceType.quote;
}

/// One offering inside a category, e.g. "Wohnungsreinigung".
class Service {
  const Service({
    required this.id,
    required this.categoryId,
    required this.slug,
    required this.name,
    required this.serviceType,
    this.nameEn,
    this.shortDescription,
    this.shortDescriptionEn,
    this.description,
    this.descriptionEn,
    this.priceOptions = const [],
  });

  final String id;
  final String categoryId;
  final String slug;
  final String name;
  final String? nameEn;
  final String? shortDescription;
  final String? shortDescriptionEn;
  final String? description;
  final String? descriptionEn;
  final ServiceType serviceType;

  /// Loaded together with the service in one query. Empty for quote
  /// services, and possibly empty for a fixed-price service whose options
  /// have not been filled in yet.
  final List<ServicePriceOption> priceOptions;

  String nameFor(String languageCode) =>
      pickTranslation(name, nameEn, languageCode) ?? name;

  String? shortDescriptionFor(String languageCode) =>
      pickTranslation(shortDescription, shortDescriptionEn, languageCode);

  String? descriptionFor(String languageCode) =>
      pickTranslation(description, descriptionEn, languageCode) ??
      shortDescriptionFor(languageCode);

  /// The cheapest option, used for the "from EUR x" line. Null when there is
  /// nothing to show a price from, which is when the app says "Angebot".
  int? get lowestPriceCents => priceOptions.isEmpty
      ? null
      : priceOptions
            .map((option) => option.priceCents)
            .reduce((a, b) => a < b ? a : b);

  /// Whether the app should offer a price at all.
  bool get hasPrices =>
      serviceType == ServiceType.fixedPrice && priceOptions.isNotEmpty;

  static Service fromJson(Map<String, dynamic> json) {
    final options = (json['service_price_options'] as List?) ?? const [];
    return Service(
      id: json['id'] as String,
      categoryId: json['category_id'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      name: json['name'] as String? ?? '',
      nameEn: json['name_en'] as String?,
      shortDescription: json['short_description'] as String?,
      shortDescriptionEn: json['short_description_en'] as String?,
      description: json['description'] as String?,
      descriptionEn: json['description_en'] as String?,
      serviceType: ServiceType.fromName(json['service_type'] as String?),
      priceOptions: [
        for (final option in options.whereType<Map<String, dynamic>>())
          ServicePriceOption.fromJson(option),
      ],
    );
  }
}
