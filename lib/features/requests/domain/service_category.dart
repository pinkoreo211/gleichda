/// The service areas a customer can pick for a request.
///
/// The choice is always optional: customers describe their problem in their
/// own words, and a later AI step derives the concrete service from that
/// text. Adding a category here only widens what a customer *may* pick.
enum ServiceCategory {
  handyman,
  cleaning,
  moving,
  car,
  pets,
  beauty,
  renovation,
  other;

  static ServiceCategory? byName(String? name) =>
      name == null ? null : ServiceCategory.values.asNameMap()[name];
}
