import 'package:material_ui/material_ui.dart';

import 'package:app/features/requests/domain/service_category.dart';
import 'package:app/l10n/app_localizations.dart';

/// How a [ServiceCategory] looks and reads. Kept out of the domain enum so
/// the domain stays free of UI and translations.
extension ServiceCategoryDisplay on ServiceCategory {
  IconData get icon => switch (this) {
    ServiceCategory.handyman => Icons.handyman_outlined,
    ServiceCategory.cleaning => Icons.cleaning_services_outlined,
    ServiceCategory.moving => Icons.local_shipping_outlined,
    ServiceCategory.car => Icons.directions_car_outlined,
    ServiceCategory.pets => Icons.pets_outlined,
    ServiceCategory.beauty => Icons.content_cut_outlined,
    ServiceCategory.renovation => Icons.format_paint_outlined,
    ServiceCategory.other => Icons.more_horiz,
  };

  String label(AppLocalizations l10n) => switch (this) {
    ServiceCategory.handyman => l10n.categoryHandyman,
    ServiceCategory.cleaning => l10n.categoryCleaning,
    ServiceCategory.moving => l10n.categoryMoving,
    ServiceCategory.car => l10n.categoryCar,
    ServiceCategory.pets => l10n.categoryPets,
    ServiceCategory.beauty => l10n.categoryBeauty,
    ServiceCategory.renovation => l10n.categoryRenovation,
    ServiceCategory.other => l10n.categoryOther,
  };
}
