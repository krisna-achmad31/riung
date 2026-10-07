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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, 0),
          child: Column(
            children: [
              Row(
                children: [
                  RiungGlassIconButton(icon: Icons.chevron_left_rounded, onTap: () => Navigator.of(context).maybePop()),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: AppColors.permukaan,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppColors.garis, width: AppGlass.edgeWidth),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.search_rounded, size: 18, color: AppColors.teksRedup),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: _controller,
                              autofocus: true,
                              style: AppTextStyles.chipLabel.copyWith(color: AppColors.teksUtama, fontSize: 14, fontWeight: FontWeight.w600),
                              cursorColor: AppColors.primer,
                              decoration: InputDecoration(
                                isDense: true,
                                filled: false,
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                hintText: context.s.meditasi.searchHint,
                              ),
                              onChanged: (v) => setState(() => _query = v),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              Expanded(
                child: _query.isEmpty
                    ? const SizedBox.shrink()
                    : results.isEmpty
                        ? _EmptyResult(query: _query, onSuggestion: _useSuggestion)
                        : ListView(
                            padding: const EdgeInsets.only(top: AppSpacing.lg, bottom: AppSpacing.xxl),
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
    final monsterId = session.targetMonsterId;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: RiungGlassCard(
        onTap: onTap,
        radius: 24,
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(color: AppColors.monsterLembut[monsterId] ?? AppColors.kabutSage, borderRadius: BorderRadius.circular(16)),
              alignment: Alignment.center,
              child: RiungMonster(monsterId: monsterId, state: MonsterVisualState.jinak, size: 50, applyBossScale: false),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(context.s.meditasi.session(session.id).title, style: AppTextStyles.chipLabel.copyWith(color: AppColors.teksUtama, fontSize: 15))),
            const Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.teksRedup),
          ],
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
    final t = context.s.meditasi;
    return ListView(
      padding: const EdgeInsets.only(top: AppSpacing.xl),
      children: [
        Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [AppColors.garis, AppColors.garis.withValues(alpha: 0)])),
              ),
              const RiungMonster(monsterId: 'kabut', state: MonsterVisualState.jinak, size: 150),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(t.searchEmptyTitle, textAlign: TextAlign.center, style: AppTextStyles.title.copyWith(fontSize: 22)),
        const SizedBox(height: AppSpacing.md),
        Text(t.searchEmptyBody(query), textAlign: TextAlign.center, style: AppTextStyles.body.copyWith(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.teksSekunder)),
        const SizedBox(height: AppSpacing.lg),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final suggestion in t.searchSuggestions)
              RiungFilterChip(label: suggestion, selected: false, onTap: () => onSuggestion(suggestion)),
          ],
        ),
      ],
    );
  }
}
