/// When the customer needs the service.
///
/// [onDate] carries the chosen day in [ServiceRequest.preferredDate]; the
/// other values need no extra data. Real scheduling against a provider's
/// calendar comes with booking.
enum RequestTiming {
  asap,
  today,
  tomorrow,
  onDate;

  static RequestTiming byName(String? name) =>
      name == null ? asap : (RequestTiming.values.asNameMap()[name] ?? asap);
}
