/// The two ways to use the app. A person can use both; the *active* role
/// decides which part of the app they see.
///
/// Admin is intentionally not a role here: admin tools never ship inside the
/// mobile app.
enum AppRole { customer, provider }
