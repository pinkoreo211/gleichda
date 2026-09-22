import 'package:app/features/catalog/domain/service.dart';

/// One price a provider charges for one of their services, e.g.
/// "bis 50 m² — EUR 49,99".
class ProviderServicePrice {
  const ProviderServicePrice({
    required this.id,
    required this.name,
    required this.priceCents,
    this.description,
    this.currency = 'EUR',
    this.unit,
    this.durationMinutes,
    this.isActive = true,
    this.sortOrder = 0,
  });

  final String id;
  final String name;
  final String? description;

  /// Whole cents, never a decimal: 4999 is EUR 49,99.
  final int priceCents;

  final String currency;

  /// What the price refers to, e.g. "pro Auftrag".
  final String? unit;

  final int? durationMinutes;

  /// Deactivated prices stay for reference but are not offered.
  final bool isActive;

  final int sortOrder;

  static ProviderServicePrice fromJson(Map<String, dynamic> json) =>
      ProviderServicePrice(
        id: json['id'] as String,
        name: json['name'] as String? ?? '',
        description: json['description'] as String?,
        priceCents: (json['price_cents'] as num?)?.toInt() ?? 0,
        currency: json['currency'] as String? ?? 'EUR',
        unit: json['unit'] as String?,
        durationMinutes: (json['duration_minutes'] as num?)?.toInt(),
        isActive: json['is_active'] as bool? ?? true,
        sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
      );
}

/// One service a provider offers, together with their own prices for it.
///
/// The [service] is the central catalog entry, read-only here: a provider
/// prices their offering, never the catalog.
class ProviderServiceOffering {
  const ProviderServiceOffering({
    required this.id,
    required this.service,
    this.isActive = true,
    this.prices = const [],
  });

  /// The `provider_services` row id — what prices hang off.
  final String id;

  final Service service;
  final bool isActive;
  final List<ProviderServicePrice> prices;

  List<ProviderServicePrice> get activePrices => [
    for (final price in prices)
      if (price.isActive) price,
  ];

  /// The cheapest active price, for the "ab EUR x" line. Null when the
  /// provider has not priced this service — then the app says so instead of
  /// inventing a number.
  int? get lowestPriceCents {
    final active = activePrices;
    if (active.isEmpty) return null;
    return active
        .map((price) => price.priceCents)
        .reduce((a, b) => a < b ? a : b);
  }

  /// A fixed-price service without any price yet is worth nudging about; a
  /// quoted service is fine without one.
  bool get needsPrice =>
      service.serviceType == ServiceType.fixedPrice && activePrices.isEmpty;

  static ProviderServiceOffering fromJson(Map<String, dynamic> json) {
    final priceRows =
        (json['provider_service_prices'] as List?) ?? const <dynamic>[];
    return ProviderServiceOffering(
      id: json['id'] as String,
      service: Service.fromJson(json['services'] as Map<String, dynamic>),
      isActive: json['is_active'] as bool? ?? true,
      prices: [
        for (final row in priceRows.whereType<Map<String, dynamic>>())
          ProviderServicePrice.fromJson(row),
      ],
    );
  }
}
