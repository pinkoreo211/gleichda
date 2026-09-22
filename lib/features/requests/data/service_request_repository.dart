import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:app/core/backend/supabase_providers.dart';
import 'package:app/core/errors/app_failure.dart';
import 'package:app/features/requests/domain/request_timing.dart';
import 'package:app/features/requests/domain/service_request.dart';
import 'package:app/features/requests/domain/service_request_draft.dart';

/// The signed-in customer's service requests.
///
/// No user id is passed in: the backend's security rules already restrict
/// every read and write to the caller's own rows, and the id of a new
/// request is set by the server. Throws [AppFailure] on errors.
abstract interface class ServiceRequestRepository {
  /// Newest first.
  Future<List<ServiceRequest>> myRequests();

  /// Stores [draft] and returns the created request, including the id and
  /// creation time the server assigned.
  Future<ServiceRequest> create(ServiceRequestDraft draft);
}

final serviceRequestRepositoryProvider = Provider<ServiceRequestRepository>(
  (ref) => SupabaseServiceRequestRepository(ref.watch(supabaseClientProvider)),
);

class SupabaseServiceRequestRepository implements ServiceRequestRepository {
  SupabaseServiceRequestRepository(this._client);

  final SupabaseClient _client;

  static const _table = 'service_requests';

  /// The request plus the name and icon of its category, in one request.
  ///
  /// The AI columns are read back too: reading them is fine, only writing
  /// them is refused by the backend.
  ///
  /// `request_contacts(status)` is what each provider who received this
  /// request has answered. The backend returns only rows the customer may
  /// see, so another account's contacts can never appear here.
  static const _columns =
      '*, service_categories(id, slug, name, name_en, icon), services(*), '
      'request_contacts(status)';

  @override
  Future<List<ServiceRequest>> myRequests() async {
    try {
      final rows = await _client
          .from(_table)
          .select(_columns)
          .order('created_at', ascending: false);
      return [for (final row in rows) ServiceRequest.fromJson(row)];
    } catch (error) {
      throw AppFailure.fromError(error);
    }
  }

  @override
  Future<ServiceRequest> create(ServiceRequestDraft draft) async {
    try {
      // customer_id, id and the timestamps are deliberately absent: the
      // server sets them, and a client is not permitted to write them.
      final row = await _client
          .from(_table)
          .insert({
            'original_description': draft.description.trim(),
            'category_id': draft.category?.id,
            'service_id': draft.service?.id,
            'timing': draft.timing.name,
            'preferred_date': draft.timing == RequestTiming.onDate
                ? _asDate(draft.preferredDate)
                : null,
            'location_label': draft.locationLabel,
            // Empty is stored as null, so "not given" stays one thing in the
            // database instead of two.
            'city': _orNull(draft.city),
            'postal_code': _orNull(draft.postalCode),
          })
          .select(_columns)
          .single();
      return ServiceRequest.fromJson(row);
    } catch (error) {
      throw AppFailure.fromError(error);
    }
  }

  static String? _orNull(String value) =>
      value.trim().isEmpty ? null : value.trim();

  /// The column is a date, not a timestamp: "2026-09-20", no time zone, so
  /// a request for "tomorrow" means the same day everywhere.
  static String? _asDate(DateTime? date) => date == null
      ? null
      : '${date.year.toString().padLeft(4, '0')}-'
            '${date.month.toString().padLeft(2, '0')}-'
            '${date.day.toString().padLeft(2, '0')}';
}
