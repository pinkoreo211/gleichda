final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

/// Quick plausibility check before asking the backend. The backend still
/// validates the address itself.
bool isPlausibleEmailAddress(String value) => _emailPattern.hasMatch(value);
