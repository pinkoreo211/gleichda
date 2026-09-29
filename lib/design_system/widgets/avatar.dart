import 'package:material_ui/material_ui.dart';

import 'package:app/features/profile/domain/user_profile.dart';

/// The face next to a name.
///
/// Falls back in two steps, because both fallbacks say something different.
/// A picture that failed to load, or none at all, shows the person's
/// initials — still them. No name either, and it shows a plain silhouette:
/// the app does not know who this is, and says so rather than printing a
/// letter that stands for nothing.
class Avatar extends StatelessWidget {
  const Avatar({
    super.key,
    this.imageUrl,
    this.name,
    this.size = AppAvatarSize.md,
  });

  final String? imageUrl;
  final String? name;
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final url = imageUrl?.trim() ?? '';
    final initials = initialsOf(name);

    return SizedBox.square(
      dimension: size,
      child: ClipOval(
        child: ColoredBox(
          color: theme.colorScheme.surfaceContainerHighest,
          child: url.isEmpty
              ? _Placeholder(initials: initials, size: size)
              : Image.network(
                  url,
                  fit: BoxFit.cover,
                  // A picture that will not load must not leave a hole:
                  // the initials are there for exactly this.
                  errorBuilder: (context, _, _) =>
                      _Placeholder(initials: initials, size: size),
                  loadingBuilder: (context, child, progress) => progress == null
                      ? child
                      : _Placeholder(initials: initials, size: size),
                ),
        ),
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.initials, required this.size});

  final String initials;
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (initials.isEmpty) {
      return Icon(
        Icons.person_outline,
        size: size * 0.55,
        color: theme.colorScheme.onSurfaceVariant,
      );
    }
    return Center(
      child: Text(
        initials,
        style: TextStyle(
          // Scaled to the circle rather than to a text style, so one
          // widget works at every size it is used in.
          fontSize: size * 0.38,
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

/// The sizes an avatar appears in, so two lists never disagree by a pixel.
abstract final class AppAvatarSize {
  /// In a dense list row.
  static const double sm = 36;

  /// On a card.
  static const double md = 48;

  /// At the top of a profile.
  static const double lg = 96;
}
