import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/assessment_draft.dart';

/// Account-scoped, encrypted device storage. Free text never enters API/cache.
class AssessmentDraftStore {
  AssessmentDraftStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();
  final FlutterSecureStorage _storage;
  String _key(String uid) => 'assessment_draft_v1_$uid';

  Future<AssessmentDraft?> read(String uid) async {
    final raw = await _storage.read(key: _key(uid));
    if (raw == null) return null;
    try {
      return AssessmentDraft.fromMap(
        (jsonDecode(raw) as Map).cast<String, dynamic>(),
      );
    } on FormatException {
      return null;
    } on TypeError {
      return null;
    }
  }

  Future<void> save(String uid, AssessmentDraft draft) =>
      _storage.write(key: _key(uid), value: jsonEncode(draft.toMap()));
  Future<void> clear(String uid) => _storage.delete(key: _key(uid));
}
