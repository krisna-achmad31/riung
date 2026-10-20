import 'package:flutter/material.dart';

import 'riung_error_widget.dart';
import 'riung_skeleton_list.dart';

/// State wajib layar data (CLAUDE.md "Definition of done"). Offline
/// ditangani global oleh `RiungOfflineBanner`.
enum RiungViewStatus { loading, error, empty, ready }

/// Satu-satunya cara layar fitur menampilkan loading/error/empty:
/// skeleton ([RiungSkeletonList]), [RiungErrorWidget] + "Coba lagi", dan
/// `RiungEmptyState` — dijaga `test/screen_state_contract_test.dart`.
/// Data yang dimuat sekali lewat Future → pakai `RiungAsyncView`.
class RiungStateView extends StatelessWidget {
  const RiungStateView({
    super.key,
    required this.status,
    required this.builder,
    this.onRetry,
    this.empty,
    this.loading,
    this.errorMessage,
  }) : assert(status != RiungViewStatus.empty || empty != null, 'status empty butuh widget empty');

  /// Status dari flag layar: error menang atas loading, loading atas empty.
  static RiungViewStatus statusOf({bool loading = false, Object? error, bool empty = false}) {
    if (error != null) return RiungViewStatus.error;
    if (loading) return RiungViewStatus.loading;
    if (empty) return RiungViewStatus.empty;
    return RiungViewStatus.ready;
  }

  final RiungViewStatus status;
  final WidgetBuilder builder;
  final VoidCallback? onRetry;

  /// Biasanya `RiungEmptyState` dengan copy dari strings fitur.
  final Widget? empty;

  /// Kosong → [RiungSkeletonList]. Ganti hanya bila bentuk layar jauh
  /// berbeda dari list kartu (tetap susun dari `RiungSkeleton`).
  final Widget? loading;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    final child = switch (status) {
      RiungViewStatus.loading => loading ?? const RiungSkeletonList(),
      RiungViewStatus.error => RiungErrorWidget(message: errorMessage, onRetry: onRetry),
      RiungViewStatus.empty => empty!,
      RiungViewStatus.ready => builder(context),
    };
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      child: KeyedSubtree(key: ValueKey(status), child: child),
    );
  }
}
