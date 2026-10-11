package api

// Allowlists mirrored from the app (riung/lib). Request values outside these
// sets are rejected, so stored ids always mean something to the app.
var (
	// The seven saboteurs (assessment, monsters).
	saboteurIDs = set("cermin", "hakim", "kabut", "mengelak", "meronta", "sempurna", "waswas")
	// features/profil/logic/avatar_catalog.dart
	avatarIDs = set("av1", "av2", "av3", "av4", "av5", "av6")
	// features/onboarding/logic/onboarding_controller.dart _personaByQ1
	personas = set("pelajar", "mahasiswa", "pekerja", "lainnya")
	locales  = set("id", "en")
	// Public content kinds served by GET /v1/content/{kind}.
	contentKinds = set("saboteurs", "affirmations", "research_facts", "meditations", "sleep_stories", "betterme_lessons")
)

func set(values ...string) map[string]bool {
	m := make(map[string]bool, len(values))
	for _, v := range values {
		m[v] = true
	}
	return m
}
