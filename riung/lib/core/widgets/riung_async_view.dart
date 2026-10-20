import 'package:flutter/material.dart';

import 'riung_state_view.dart';

/// Muat data lewat [load] lalu tampilkan lewat [RiungStateView]:
/// skeleton saat menunggu, error + "Coba lagi" bila gagal, [empty] bila
/// [isEmpty] benar. Pengganti `FutureBuilder` di layar fitur.
class RiungAsyncView<T> extends StatefulWidget {
  const RiungAsyncView({
    super.key,
    required this.load,
    required this.builder,
    this.isEmpty,
    this.empty,
    this.loading,
    this.errorMessage,
  }) : assert(isEmpty == null || empty != null, 'isEmpty butuh widget empty');

  /// Dipanggil pertama kali setelah dependensi siap (boleh memakai
  /// `AppScope.of(context)`), dan lagi tiap "Coba lagi" / [RiungAsyncViewState.reload].
  final Future<T> Function() load;
  final Widget Function(BuildContext context, T data) builder;
  final bool Function(T data)? isEmpty;
  final Widget? empty;
  final Widget? loading;
  final String? errorMessage;

  @override
  State<RiungAsyncView<T>> createState() => RiungAsyncViewState<T>();
}

class RiungAsyncViewState<T> extends State<RiungAsyncView<T>> {
  late T _data;
  bool _hasData = false;
  Object? _error;
  bool _started = false;
  int _run = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    reload();
  }

  /// Muat ulang; hasil panggilan lama yang selesai belakangan diabaikan.
  Future<void> reload() async {
    final run = ++_run;
    if (_error != null) setState(() => _error = null);
    try {
      final data = await widget.load();
      if (!mounted || run != _run) return;
      setState(() {
        _data = data;
        _hasData = true;
      });
    } catch (error) {
      if (!mounted || run != _run) return;
      setState(() => _error = error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEmpty = widget.isEmpty;
    return RiungStateView(
      status: RiungStateView.statusOf(
        loading: !_hasData,
        error: _error,
        empty: _hasData && isEmpty != null && isEmpty(_data),
      ),
      onRetry: reload,
      empty: widget.empty,
      loading: widget.loading,
      errorMessage: widget.errorMessage,
      builder: (context) => widget.builder(context, _data),
    );
  }
}
