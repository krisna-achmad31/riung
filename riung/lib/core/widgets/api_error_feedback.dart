import 'package:flutter/material.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import '../l10n/api_strings.dart';
import '../services/api/api_client.dart';

void showApiError(BuildContext context, ApiException error) {
  final english = Localizations.localeOf(context).languageCode == 'en';
  final message = apiErrorText(error.code, english: english);
  final id = error.requestId;
  ScaffoldMessenger.maybeOf(context)?.showSnackBar(
    SnackBar(
      content: Text(
        '$message${id == null ? '' : '\n${english ? 'Code' : 'Kode'}: $id'}',
      ),
    ),
  );
  try {
    FirebaseCrashlytics.instance.setCustomKey('api_error_code', error.code);
    if (id != null)
      FirebaseCrashlytics.instance.setCustomKey('api_request_id', id);
  } catch (_) {
    /* Firebase is optional in widget tests. */
  }
}
