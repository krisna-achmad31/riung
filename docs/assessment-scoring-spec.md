# Riung — Assessment Scoring Spec v1.0
*Engineering spec: how the 17-question onboarding quiz produces the 7 saboteur activity scores.*

## Core concept
All 7 saboteurs exist in every user (CBT: everyone has every thought pattern). The quiz measures **activity level (0–100%)** per saboteur, not presence/absence. Highest-scoring accomplice = **active saboteur** (targets missions, mini-game, initial taming). Si Hakim is always displayed as boss regardless of rank.

## Question roles
- **Scoring questions (measure monsters):** Q3, Q4, Q5, Q6, Q7, Q8, Q9, Q10, Q11, Q12, Q13, Q14
- **Config questions (no scoring):** Q1 tahap hidup → persona (pelajar/pekerja); Q2 usia → persona refinement; Q15 tujuan → personalizes "cara Riung membantu" + paywall pitch; Q16 menit/hari → default session length; Q17 waktu check-in → notification schedule

## Point mapping (per option)
Single-select: chosen option's points apply. Multi-select: every checked option's points apply. Frequency scales: 0/1/2/3 by intensity.

| Q | Type | Option → points |
|---|---|---|
| Q3 isi kepala | multi | takut hasil→Waswas+2 · hidup orang lain→Cermin+2 · bingung mulai→Kabut+2 · nyalahin diri→Hakim+2 · keadaan nggak berpihak→Meronta+2 · susah tidur→Waswas+1 |
| Q4 kecemasan | freq | →Waswas 0/1/2/3 |
| Q5 prokrastinasi | single | langsung→0 · buka HP→Kabut+2 · bingung nggak mulai→Kabut+3 · panik menit terakhir→Waswas+1,Kabut+1 |
| Q6 medsos | single | terhibur→0 · kosong/kebuang→Kabut+1 · minder→Cermin+3 · kesel sama diri→Hakim+2 |
| Q7 pemicu stres | multi (context) | tugas/ujian→Waswas+1 · beban kerja→Waswas+1 · komuter→Kabut+1 · ekspektasi ortu→Cermin+1,Hakim+1 · pertemanan→Cermin+1 · keuangan→Waswas+1 · percintaan→Meronta+1 · masa depan→Waswas+1,Kabut+1 |
| Q8 tidur | single | nyenyak→0 · kadang kebangun→+1 Waswas · susah mulai (overthinking)→Waswas+2 · begadang→Kabut+2 |
| Q9 kritik batin | single | sudah berusaha→0 · harusnya lebih baik→Sempurna+3 · aku nggak becus→Hakim+3 · yang penting selesai→0 |
| Q10 takut gagal | freq | →Mengelak 0/1/2/3 (option 4 "nggak pernah kumulai"→Mengelak+3,Kabut+1) |
| Q11 coping | multi | scroll lupa waktu→Kabut+2 · game/maraton→Mengelak+1,Kabut+1 · makan/jajan→+1 Mengelak · dipendam→Mengelak+2 · cerita teman→0 · olahraga→0 · jurnal→0 · meditasi→0 |
| Q12 perbandingan | single | terpacu→0 · biasa→0 · tertinggal jauh→Cermin+3 · mempertanyakan hidup→Cermin+2,Hakim+1 |
| Q13 rencana gagal | single | kenapa selalu aku→Meronta+3 · salah sama caraku→Hakim+2 · cari jalan lain→0 · nggak usah coba lagi→Mengelak+2 |
| Q14 menghakimi diri | single | berdamai→0 · kadang→Hakim+1 · keras standar tinggi→Sempurna+2,Hakim+1 · sangat keras nggak pernah puas→Sempurna+3,Hakim+2 |

## Signal count per saboteur (≥2 required — satisfied)
Waswas: Q3,Q4,Q5,Q7,Q8 · Kabut: Q3,Q5,Q7,Q8,Q11 · Cermin: Q3,Q6,Q7,Q12 · Sempurna: Q9,Q14 · Mengelak: Q10,Q11,Q13 · Meronta: Q3,Q7,Q13 · Hakim: Q3,Q6,Q7,Q9,Q12,Q13,Q14

## Normalization
score(m) = round( rawPoints(m) / maxPossiblePoints(m) × 100 )
maxPossiblePoints computed from the mapping above (multi-select counts all m-relevant options as checkable). Display: Hakim separated as "Sang Bos"; accomplices ranked desc. Active saboteur = argmax(accomplices).

## Notes
- Weights are v1 heuristics — tune via Remote Config after real funnel data; keep the mapping table in one config file, never hardcoded per-screen.
- Result copy must stay traceable: no percentage shown that can't be recomputed from answers.
- This is a wellness self-reflection profile, NOT a clinical instrument — disclaimer stays on the result screen.
