import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/services/services.dart';
import '../../../core/state/state.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';

/// "Unduh semua dataku" — bukan mockup terpisah di desain (dirujuk lewat
/// baris di Pengaturan). Isi data disusun [DataExportBuilder]; isi jurnal
/// SENGAJA tidak disertakan (terenkripsi di perangkat, CLAUDE.md aturan #5).
class EksporDataScreen extends StatefulWidget {
  const EksporDataScreen({super.key});

  @override
  State<EksporDataScreen> createState() => _EksporDataScreenState();
}

class _EksporDataScreenState extends State<EksporDataScreen> {
  String? _json;

  @override
  void initState() {
    super.initState();
    _susun();
  }

  Future<void> _susun() async {
    final scope = AppScope.of(context);
    final uid = scope.auth.uid;
    if (uid == null) return;
    final data = await DataExportBuilder(userRepository: scope.userRepository, prefs: scope.prefs)
        .build(uid: uid, note: AppStrings.of(scope.language.language).profil.exportNote);
    if (!mounted) return;
    setState(() => _json = const JsonEncoder.withIndent('  ').convert(data));
  }

  @override
  Widget build(BuildContext context) {
    final t = context.s.profil;
    return Scaffold(
      backgroundColor: AppColors.latar,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.arrow_back_rounded, color: AppColors.teksSekunder),
                  ),
                  Text(t.downloadData, style: AppTextStyles.subtitle.copyWith(fontSize: 15)),
                ],
              ),
            ),
            Expanded(
              child: _json == null
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primer))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t.exportIntro,
                            style: AppTextStyles.body.copyWith(fontSize: 13),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(AppSpacing.md),
                            decoration: BoxDecoration(
                              color: AppColors.permukaan,
                              border: Border.all(color: AppColors.garis),
                              borderRadius: BorderRadius.circular(AppRadius.lg),
                            ),
                            child: SelectableText(
                              _json!,
                              style: AppTextStyles.caption.copyWith(fontSize: 11, fontFamily: 'monospace', height: 1.5, color: AppColors.teksSekunder),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                        ],
                      ),
                    ),
            ),
            if (_json != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.lg),
                child: RiungButton(
                  label: t.exportCopy,
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: _json!));
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.exportCopied)));
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
