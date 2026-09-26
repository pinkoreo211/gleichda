import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app/features/provider/application/provider_profile_providers.dart';
import 'package:app/features/verification/data/document_picker.dart';
import 'package:app/features/verification/data/verification_repository.dart';
import 'package:app/features/verification/domain/provider_document.dart';

/// What this provider is asked for, next to what they have handed in.
///
/// Empty when there is no provider profile — a customer has nothing to
/// prove. `autoDispose` so reopening the screen asks again: the team may
/// have decided something since it was last built.
final myVerificationProvider =
    FutureProvider.autoDispose<VerificationChecklist>((ref) async {
      final profile = await ref.watch(myProviderProfileProvider.future);
      if (profile == null) return const VerificationChecklist([]);

      final repository = ref.watch(verificationRepositoryProvider);
      // Both sides of the list, asked for together rather than one after the
      // other, because neither depends on the other.
      final (requirements, documents) = await (
        repository.myRequirements(),
        repository.myDocuments(),
      ).wait;

      return VerificationChecklist.from(
        requirements: requirements,
        documents: documents,
      );
    });

/// Which document type is being uploaded right now, or null.
///
/// One at a time: the screen disables the others while a file is on its
/// way, so a provider cannot start three uploads and wonder which failed.
class DocumentUpload extends Notifier<ProviderDocumentType?> {
  @override
  ProviderDocumentType? build() => null;

  /// Picks a file for [type] and hands it in.
  ///
  /// Returns true when something was actually uploaded, false when the
  /// person backed out of the picker. Throws [AppFailure] on errors, which
  /// the screen turns into a message.
  Future<bool> pickAndSubmit({
    required ProviderDocumentType type,
    required DocumentSource source,
  }) async {
    if (state != null) return false;

    final profile = await ref.read(myProviderProfileProvider.future);
    if (profile == null) return false;

    final file = await ref.read(documentPickerProvider).pick(source);
    if (file == null) return false;

    state = type;
    try {
      await ref
          .read(verificationRepositoryProvider)
          .submit(providerId: profile.id, type: type, file: file);
    } finally {
      state = null;
    }

    // The list and the status badge both changed, so both are re-read
    // rather than patched in place from what the app assumes happened.
    ref.invalidate(myVerificationProvider);
    ref.invalidate(myProviderProfileProvider);
    return true;
  }
}

final documentUploadProvider =
    NotifierProvider.autoDispose<DocumentUpload, ProviderDocumentType?>(
      DocumentUpload.new,
    );
