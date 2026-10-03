import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/models/models.dart';
import '../../../core/state/state.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../monster/screens/vault_screen.dart';
import '../logic/character_accessory.dart';
import '../logic/character_spec.dart';
import '../screens/kepribadian_hasil_screen.dart';
import '../screens/kepribadian_hub_screen.dart';
import '../screens/kepribadian_quiz_screen.dart';
import 'character_avatar.dart';

/// Kartu "Karaktermu" di Beranda: monster yang sedang dijinakkan (beserta
/// progresnya) dan tiga karakter hasil tes (tipe gaya Jung, temperamen,
/// gaya keterikatan) yang sedang dipakai. Tes yang belum diisi menampilkan
/// ajakan lembut untuk mengisinya.
class KarakterHomeCard extends StatefulWidget {
  const KarakterHomeCard({super.key});

  @override
  State<KarakterHomeCard> createState() => _KarakterHomeCardState();
}

class _KarakterHomeCardState extends State<KarakterHomeCard> {
  Future<void> _buka(Widget screen) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
    if (mounted) setState(() {}); // hasil/aksesori mungkin berubah
  }

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final t = context.s.kepribadian;
    final profile = scope.auth.profile;
    final monsterId = (profile != null && profile.dominantSaboteurs.isNotEmpty) ? profile.dominantSaboteurs.first : 'waswas';
    final progress = scope.monsterProgress.progressOf(monsterId) ?? MonsterProgress.initial(monsterId);
    final monsterColor = AppColors.monsterColors[monsterId] ?? AppColors.primer;
    return ValueListenableBuilder<int>(
      valueListenable: scope.prefs.personalityRevision,
      builder: (context, _, _) {
        final results = scope.prefs.personalityResults;
        final loadout = AccessoryLoadout(scope.prefs);
        return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.permukaan,
        border: Border.all(color: AppColors.garis),
        borderRadius: BorderRadius.circular(AppRadius.xxl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => _buka(const KepribadianHubScreen()),
            behavior: HitTestBehavior.opaque,
            child: Row(
              children: [
                Expanded(child: Text(t.homeTitle, style: AppTextStyles.chipLabel.copyWith(fontSize: 15, color: AppColors.teksUtama))),
                Text(t.homeSeeAll, style: AppTextStyles.caption.copyWith(fontSize: 12, color: AppColors.primer, fontWeight: FontWeight.w700)),
                const Icon(Icons.chevron_right, size: 18, color: AppColors.primer),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          GestureDetector(
            onTap: () => _buka(const VaultScreen()),
            behavior: HitTestBehavior.opaque,
            child: Row(
              children: [
                SizedBox(
                  width: 58,
                  height: 61,
                  child: RiungMonster(
                    monsterId: monsterId,
                    state: progress.state == MonsterState.tamed ? MonsterVisualState.jinak : MonsterVisualState.liar,
                    size: 58,
                    applyBossScale: false,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(t.homeMonsterLabel, style: AppTextStyles.caption.copyWith(fontSize: 10, letterSpacing: 0.4)),
                      const SizedBox(height: 2),
                      Text(context.s.common.monsterName(monsterId), style: AppTextStyles.chipLabel.copyWith(fontSize: 14, color: AppColors.teksUtama)),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        child: LinearProgressIndicator(
                          value: progress.progress / 100,
                          minHeight: 6,
                          backgroundColor: AppColors.latar,
                          valueColor: AlwaysStoppedAnimation(monsterColor),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(t.homeMonsterProgress(progress.progress), style: AppTextStyles.caption.copyWith(fontSize: 11)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Padding(padding: EdgeInsets.symmetric(vertical: AppSpacing.md), child: Divider(color: AppColors.garis, height: 1)),
          Row(
            children: [
              for (final test in PersonalityTest.values) ...[
                Expanded(
                  child: _CharacterTile(
                    test: test,
                    result: results[test],
                    accessories: loadout.of(test),
                    onTap: () => _buka(results[test] != null ? KepribadianHasilScreen(result: results[test]!) : KepribadianQuizScreen(test: test)),
                  ),
                ),
                if (test != PersonalityTest.values.last) const SizedBox(width: AppSpacing.sm),
              ],
            ],
          ),
        ],
      ),
        );
      },
    );
  }
}

class _CharacterTile extends StatelessWidget {
  const _CharacterTile({required this.test, required this.result, required this.accessories, required this.onTap});

  final PersonalityTest test;
  final PersonalityResult? result;
  final List<CharacterAccessory> accessories;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.s.kepribadian;
    final r = result;
    String value;
    Color? color;
    if (r == null) {
      value = t.homeTakeTest;
    } else {
      switch (test) {
        case PersonalityTest.jung:
          value = r.code;
        case PersonalityTest.temperament:
          value = t.temperament(r.code).name;
        case PersonalityTest.attachment:
          value = t.attachment(r.code).name;
      }
      color = CharacterSpec.fromResult(r).base;
    }
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          SizedBox(
            width: 64,
            height: 64,
            child: r == null
                ? Container(
                    decoration: BoxDecoration(color: AppColors.kartu, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.garis)),
                    alignment: Alignment.center,
                    child: const Icon(Icons.add_rounded, size: 26, color: AppColors.teksRedup),
                  )
                : CharacterAvatar(spec: CharacterSpec.fromResult(r), size: 64, accessories: accessories),
          ),
          const SizedBox(height: 4),
          Text(t.homeTestShort(test), style: AppTextStyles.caption.copyWith(fontSize: 10)),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: AppTextStyles.chipLabel.copyWith(fontSize: 12, color: color ?? AppColors.primer),
          ),
        ],
      ),
    );
  }
}
