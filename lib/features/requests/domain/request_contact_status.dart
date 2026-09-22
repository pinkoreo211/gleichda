/// What a provider has answered to a request they received.
///
/// The names match the database enum exactly, so no translation layer sits
/// between app and backend. Only the backend ever changes a value; the app
/// shows what it is told.
enum RequestContactStatus {
  /// Reached the provider, not answered yet.
  sent,
  accepted,
  declined;

  static RequestContactStatus? fromDb(String? value) {
    for (final status in values) {
      if (status.name == value) return status;
    }
    return null;
  }

  /// Whether the provider still has to make up their mind. Only an open
  /// request may be answered — the backend enforces the same rule.
  bool get isOpen => this == RequestContactStatus.sent;
}
