import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../logic/meditation_catalog.dart';
import 'meditasi_detail_screen.dart';

/// Pencarian meditasi — daftar hasil, atau state kosong persis
/// `design/Meditasi.dc.html` § Pencarian tidak ada hasil.
class MeditasiSearchScreen extends StatefulWidget {
  const MeditasiSearchScreen({super.key});

  @override
  State<MeditasiSearchScreen> createState() => _MeditasiSearchScreenState();
}

class _MeditasiSearchScreenState extends State<MeditasiSearchScreen> {
  final _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _useSuggestion(String text) {
    _controller.value = TextEditingValue(text: text, selection: TextSelection.collapsed(offset: text.length));
    setState(() => _query = text);
  }

  @override
  Widget build(BuildContext context) {
    final results = _query.isEmpty
        ? const <MeditationSession>[]
        : MeditationCatalog.all.where((s) => context.s.meditasi.session(s.id).title.toLowerCase().contains(_query.toLowerCase())).toList();

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
                    icon: const Icon(Icons.arrow_back, color: AppColors.teksSekunder),
                  ),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 11),
                      decoration: BoxDecoration(
                        color: AppColors.kartu,
                        border: Border.all(color: AppColors.garis),
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.search, size: 17, color: AppColors.teksRedup),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: TextField(
                              controller: _controller,
                              autofocus: true,
                              style: AppTextStyles.chipLabel.copyWith(color: AppColors.teksUtama, fontSize: 14),
                              cursorColor: AppColors.primer,
                              decoration: InputDecoration(isDense: true, border: InputBorder.none, hintText: context.s.meditasi.searchHint),
                              onChanged: (v) => setState(() => _query = v),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _query.isEmpty
                  ? const SizedBox.shrink()
                  : results.isEmpty
                      ? _EmptyResult(query: _query, onSuggestion: _useSuggestion)
                      : ListView(
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                          children: [
                            for (final session in results)
                              _ResultRow(
                                session: session,
                                onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => MeditasiDetailScreen(session: session)),
                                ),
                              ),
                          ],
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({required this.session, required this.onTap});

  final MeditationSession session;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.permukaan,
            border: Border.all(color: AppColors.garis),
            borderRadius: BorderRadius.circular(AppRadius.xl),
          ),
          child: Row(
            children: [
              Icon(session.icon, size: 20, color: session.color),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: Text(context.s.meditasi.session(session.id).title, style: AppTextStyles.chipLabel.copyWith(color: AppColors.teksUtama, fontSize: 14))),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyResult extends StatelessWidget {
  const _EmptyResult({required this.query, required this.onSuggestion});

  final String query;
  final ValueChanged<String> onSuggestion;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Opacity(
              opacity: 0.75,
              child: SizedBox(
                width: 110,
                height: 116,
                child: RiungMonster(monsterId: 'kabut', state: MonsterVisualState.jinak, size: 110),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(context.s.meditasi.searchEmptyTitle, style: AppTextStyles.display.copyWith(fontSize: 18)),
            const SizedBox(height: AppSpacing.sm),
            Text(
              context.s.meditasi.searchEmptyBody(query),
              textAlign: TextAlign.center,
              style: AppTextStyles.body.copyWith(fontSize: 13),
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              alignment: WrapAlignment.center,
              children: [
                for (final suggestion in context.s.meditasi.searchSuggestions)
                  GestureDetector(
                    onTap: () => onSuggestion(suggestion),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(AppRadius.pill), border: Border.all(color: AppColors.garis)),
                      child: Text(suggestion, style: AppTextStyles.chipLabel.copyWith(color: AppColors.teksSekunder, fontSize: 12)),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
