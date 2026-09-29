/// Who someone is to the person on the other side of a job.
///
/// Deliberately small. A provider deciding whether to go to a stranger's
/// flat, and a customer deciding whether to let one in, need a name and a
/// face — not an email address and not a phone number. Those stay where
/// they are.
class UserProfile {
  const UserProfile({this.displayName, this.avatarUrl});

  /// What this person chose to be called. Null while they have set none,
  /// and then the app says so rather than inventing something.
  final String? displayName;

  /// A full address in the public avatars bucket, or null.
  final String? avatarUrl;

  bool get hasName => (displayName ?? '').trim().isNotEmpty;
  bool get hasAvatar => (avatarUrl ?? '').trim().isNotEmpty;

  /// The one or two letters to show while there is no picture.
  ///
  /// Built from the name the person chose, so it changes with it. Empty
  /// when there is no name either — then the screen shows a plain
  /// silhouette rather than a letter that stands for nothing.
  String get initials {
    final words = (displayName ?? '')
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList();
    if (words.isEmpty) return '';
    if (words.length == 1) return words.first.substring(0, 1).toUpperCase();
    return (words.first.substring(0, 1) + words.last.substring(0, 1))
        .toUpperCase();
  }

  UserProfile copyWith({String? displayName, String? avatarUrl}) => UserProfile(
    displayName: displayName ?? this.displayName,
    avatarUrl: avatarUrl ?? this.avatarUrl,
  );

  static UserProfile fromJson(Map<String, dynamic> json) => UserProfile(
    displayName: json['display_name'] as String?,
    avatarUrl: json['avatar_url'] as String?,
  );
}

/// Turns any name into the letters for an avatar, without needing a whole
/// profile. Used where a list already has the name and nothing else.
String initialsOf(String? name) => UserProfile(displayName: name).initials;
