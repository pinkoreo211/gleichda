import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:app/core/backend/supabase_providers.dart';
import 'package:app/core/errors/app_failure.dart';
import 'package:app/features/booking/domain/booking_draft.dart';
import 'package:app/features/booking/domain/provider_offer.dart';
import 'package:app/features/booking/domain/service_suggestion.dart';
import 'package:app/features/matching/domain/provider_match.dart';

/// Booking a verified provider at a price they listed.
///
/// Every call goes through a backend function. The phone never sends an
/// amount: it names the price option it wants and the server reads what
/// that costs. Throws [AppFailure] on errors.
abstract interface class BookingRepository {
  /// Catalog services that might match what the customer wrote.
  ///
  /// Empty means the backend found nothing convincing — then the app asks
  /// rather than guessing. A keyword match today, something cleverer later;
  /// either way the answer is real catalog entries.
  Future<List<ServiceSuggestion>> suggestServices(String text);

  /// Verified providers who offer [serviceId] in [city] and have priced it.
  Future<List<ProviderMatch>> bookableProviders({
    required String serviceId,
    String? city,
  });

  /// One provider's public details and their real price options for this
  /// service. Null when they no longer offer it.
  Future<ProviderOffer?> offerOf({
    required String providerId,
    required String serviceId,
  });

  /// Writes the request and hands it to the provider in one step.
  ///
  /// [priceId] is a price option, not an amount. The server checks that it
  /// belongs to that provider's offering of that service and takes the
  /// amount from there.
  Future<BookingResult> createBooking({
    required String description,
    required String serviceId,
    required String providerId,
    required String priceId,
    required DateTime wantedAt,
    String? address,
    String? postalCode,
    String? city,
  });
}

final bookingRepositoryProvider = Provider<BookingRepository>(
  (ref) => SupabaseBookingRepository(ref.watch(supabaseClientProvider)),
);

class SupabaseBookingRepository implements BookingRepository {
  SupabaseBookingRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<List<ServiceSuggestion>> suggestServices(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return const [];
    try {
      final rows = await _client.rpc<List<dynamic>>(
        'suggest_services_for_text',
        params: {'query': trimmed},
      );
      return [
        for (final row in rows.whereType<Map<String, dynamic>>())
          ServiceSuggestion.fromJson(row),
      ];
    } catch (error) {
      throw AppFailure.fromError(error);
    }
  }

  @override
  Future<List<ProviderMatch>> bookableProviders({
    required String serviceId,
    String? city,
  }) async {
    try {
      final rows = await _client.rpc<List<dynamic>>(
        'find_bookable_providers',
        params: {'target_service_id': serviceId, 'requested_city': city},
      );
      return [
        for (final row in rows.whereType<Map<String, dynamic>>())
          ProviderMatch.fromJson(row),
      ];
    } catch (error) {
      throw AppFailure.fromError(error);
    }
  }

  @override
  Future<ProviderOffer?> offerOf({
    required String providerId,
    required String serviceId,
  }) async {
    try {
      final rows = await _client.rpc<List<dynamic>>(
        'provider_offer',
        params: {
          'target_provider_id': providerId,
          'target_service_id': serviceId,
        },
      );
      return ProviderOffer.fromRows(
        rows.whereType<Map<String, dynamic>>().toList(),
      );
    } catch (error) {
      throw AppFailure.fromError(error);
    }
  }

  @override
  Future<BookingResult> createBooking({
    required String description,
    required String serviceId,
    required String providerId,
    required String priceId,
    required DateTime wantedAt,
    String? address,
    String? postalCode,
    String? city,
  }) async {
    try {
      final rows = await _client.rpc<List<dynamic>>(
        'create_booking',
        params: {
          'description': description.trim(),
          'target_service_id': serviceId,
          'target_provider_id': providerId,
          'price_option_id': priceId,
          // Sent as UTC so the stored moment means the same thing wherever
          // the two of them are.
          'wanted_at': wantedAt.toUtc().toIso8601String(),
          'booking_address': address,
          'booking_postal_code': postalCode,
          'booking_city': city,
        },
      );
      final row = rows.whereType<Map<String, dynamic>>().firstOrNull;
      if (row == null) throw AppFailure.unknown;
      return BookingResult(
        requestId: row['request_id'] as String,
        contactId: row['contact_id'] as String,
      );
    } catch (error) {
      throw AppFailure.fromError(error);
    }
  }
}
