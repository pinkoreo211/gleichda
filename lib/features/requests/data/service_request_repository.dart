import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:app/core/errors/app_failure.dart';
import 'package:app/features/requests/domain/service_request.dart';

/// Stores the requests a customer created.
///
/// Throws [AppFailure] on errors, so screens never see storage types.
abstract interface class ServiceRequestRepository {
  /// Newest first.
  Future<List<ServiceRequest>> myRequests(String userId);

  Future<void> save(String userId, ServiceRequest request);
}

/// Replaced with the real implementation in `main()` and with an in-memory
/// one in tests.
final serviceRequestRepositoryProvider = Provider<ServiceRequestRepository>(
  (ref) => throw UnimplementedError(
    'serviceRequestRepositoryProvider must be overridden',
  ),
);

/// Keeps requests on the device only.
///
/// Deliberately temporary: there is no backend table for requests yet, so
/// nothing is sent to providers. The stored JSON already uses the column
/// names the future table will have, so switching to Supabase replaces this
/// class without touching the screens.
class LocalServiceRequestRepository implements ServiceRequestRepository {
  LocalServiceRequestRepository(this._preferences);

  final SharedPreferencesWithCache _preferences;

  static String _key(String userId) => 'requests.$userId';

  @override
  Future<List<ServiceRequest>> myRequests(String userId) async {
    try {
      final stored = _preferences.getString(_key(userId));
      if (stored == null || stored.isEmpty) return const [];
      final decoded = jsonDecode(stored) as List;
      final requests = decoded
          .whereType<Map<String, dynamic>>()
          .map(ServiceRequest.fromJson)
          .toList();
      requests.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return requests;
    } catch (error) {
      // A corrupt entry must not break the screen.
      debugPrint('Could not read stored requests: $error');
      return const [];
    }
  }

  @override
  Future<void> save(String userId, ServiceRequest request) async {
    try {
      final existing = await myRequests(userId);
      final updated = [request, ...existing];
      await _preferences.setString(
        _key(userId),
        jsonEncode([for (final r in updated) r.toJson()]),
      );
    } catch (error) {
      throw AppFailure.fromError(error);
    }
  }
}
