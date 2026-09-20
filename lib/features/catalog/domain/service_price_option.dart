import 'package:app/features/catalog/domain/service_category.dart'
    show pickTranslation;

/// One priced variant of a service, e.g. "bis 50 m²" for a flat clean.
///
/// Example MVP prices: the binding price is agreed with the provider once
/// booking exists.
class ServicePriceOption {
  const ServicePriceOption({
    required this.id,
    required this.name,
    required this.priceCents,
    this.nameEn,
    this.description,
    this.currency = 'EUR',
    this.unit,
    this.durationMinutes,
  });

  final String id;
  final String name;
  final String? nameEn;
  final String? description;

  /// Whole cents, never a decimal: 4999 is EUR 49,99.
  final int priceCents;

  final String currency;

  /// What the price refers to, e.g. "pauschal" or "pro Stunde".
  final String? unit;

  final int? durationMinutes;

  String nameFor(String languageCode) =>
      pickTranslation(name, nameEn, languageCode) ?? name;

  static ServicePriceOption fromJson(Map<String, dynamic> json) =>
      ServicePriceOption(
        id: json['id'] as String,
        name: json['name'] as String? ?? '',
        nameEn: json['name_en'] as String?,
        description: json['description'] as String?,
        priceCents: (json['price_cents'] as num?)?.toInt() ?? 0,
        currency: json['currency'] as String? ?? 'EUR',
        unit: json['unit'] as String?,
        durationMinutes: (json['duration_minutes'] as num?)?.toInt(),
      );
}
