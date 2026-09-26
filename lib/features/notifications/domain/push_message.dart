/// What kind of thing a notification is about.
///
/// The names match `notification_kind` in the database. A kind this app
/// does not know is not guessed at — it simply opens nothing special.
enum PushKind {
  bookingReceived('booking_received'),
  requestAccepted('request_accepted'),
  appointmentAgreed('appointment_agreed'),
  providerOnTheWay('provider_on_the_way'),
  jobCompleted('job_completed'),
  jobConfirmed('job_confirmed'),
  chatMessage('chat_message');

  const PushKind(this.dbName);

  final String dbName;

  static PushKind? fromName(String? name) {
    for (final kind in PushKind.values) {
      if (kind.dbName == name) return kind;
    }
    return null;
  }
}

/// A notification the person tapped.
///
/// Only the two things the app needs to open the right screen. The title
/// and the text were written by the sender and are already on screen by
/// the time this arrives; repeating them here would serve nothing.
class PushMessage {
  const PushMessage({this.kind, this.contactId});

  final PushKind? kind;

  /// The job it is about. Null when the notification was about nothing in
  /// particular, and then tapping it just opens the app.
  final String? contactId;

  bool get opensAJob => contactId != null && contactId!.isNotEmpty;

  /// Built from an FCM data payload, whose values are always strings.
  static PushMessage fromData(Map<String, dynamic> data) {
    final contact = data['contact_id'];
    return PushMessage(
      kind: PushKind.fromName(data['kind'] as String?),
      contactId: switch (contact) {
        final String id when id.isNotEmpty => id,
        _ => null,
      },
    );
  }
}
