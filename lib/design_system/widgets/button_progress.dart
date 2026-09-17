import 'package:material_ui/material_ui.dart';

import 'package:app/design_system/app_dimensions.dart';

/// Small spinner shown inside a button while its action is running.
class ButtonProgress extends StatelessWidget {
  const ButtonProgress({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox.square(
      dimension: AppIconSize.md,
      child: CircularProgressIndicator(strokeWidth: 2.5),
    );
  }
}
