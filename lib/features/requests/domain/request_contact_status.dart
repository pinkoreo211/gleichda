/// Where a request stands with one provider — first their answer, then the
/// job that follows from a yes.
///
/// One value, not two: an answer and a job status would be two names for
/// the same fact, and two facts drift apart. Only the backend ever changes
/// it; the app shows what it is told.
enum RequestContactStatus {
  /// Reached the provider, not answered yet.
  sent('sent'),
  declined('declined'),

  // --- A job, from here on. ---
  accepted('accepted'),
  scheduled('scheduled'),
  onTheWay('on_the_way'),
  inProgress('in_progress'),
  completed('completed'),
  customerConfirmed('customer_confirmed'),
  cancelled('cancelled');

  const RequestContactStatus(this.dbValue);

  /// Spelled out rather than derived from the name: the database uses
  /// snake_case and Dart uses camelCase, and guessing between them is how
  /// a status silently stops matching.
  final String dbValue;

  static RequestContactStatus? fromDb(String? value) {
    for (final status in values) {
      if (status.dbValue == value) return status;
    }
    return null;
  }

  /// Whether the provider still has to make up their mind. Only an open
  /// request may be answered — the backend enforces the same rule.
  bool get isOpen => this == RequestContactStatus.sent;

  /// Whether somebody said yes and there is work to follow.
  bool get isJob => switch (this) {
    RequestContactStatus.sent ||
    RequestContactStatus.declined ||
    RequestContactStatus.cancelled => false,
    _ => true,
  };

  /// How far along the job is, used to draw the steps. Everything that is
  /// not a running job sits at zero.
  int get step => switch (this) {
    RequestContactStatus.accepted => 0,
    RequestContactStatus.scheduled => 1,
    RequestContactStatus.onTheWay => 2,
    RequestContactStatus.inProgress => 3,
    RequestContactStatus.completed => 4,
    RequestContactStatus.customerConfirmed => 5,
    _ => 0,
  };

  bool get isFinished => this == RequestContactStatus.customerConfirmed;
}
