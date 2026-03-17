import 'package:fitzone/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// Extension on BuildContext to easily access auto-generated localizations.
extension LocalizationExtension on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this)!;
}
