import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/services/services.dart';

/// Umpan balik "Pulihkan pembelian" yang sama di Paywall, onboarding, dan
/// Langganan — restore tidak boleh berakhir tanpa kabar ke user.
void showRestoreOutcome(BuildContext context, RestoreOutcome outcome) {
  final t = context.s.toko;
  final message = switch (outcome) {
    RestoreOutcome.restored => t.restoreDone,
    RestoreOutcome.none => t.restoreNone,
    RestoreOutcome.failed => t.restoreFailed,
    RestoreOutcome.otherAccount => t.restoreOtherAccount,
  };
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
