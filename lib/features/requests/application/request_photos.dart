import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app/features/auth/application/current_user.dart';
import 'package:app/features/requests/data/request_photo_repository.dart';
import 'package:app/features/requests/domain/request_photo.dart';

/// The photos on one request, for whoever is asking.
///
/// The backend decides whether that is anybody at all, so this is safe to
/// watch from either side of a job without the screen knowing which side it
/// is on.
///
/// `autoDispose` because the links expire: coming back to a list later asks
/// again rather than showing pictures behind a link that has run out.
final requestPhotosProvider = FutureProvider.autoDispose
    .family<List<RequestPhoto>, String>((ref, requestId) async {
      final userId = ref.watch(currentUserIdProvider);
      if (userId == null) return const [];
      return ref.watch(requestPhotoRepositoryProvider).photosOf(requestId);
    });
