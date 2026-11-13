import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show MissingPluginException;
import 'package:intl/intl.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/l10n/strings/journal_backup_strings.dart';
import '../../../core/services/journal_backup_codec.dart';
import '../../../core/state/state.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import 'jurnal_pin_recover_screen.dart';
import 'jurnal_pin_setup_screen.dart';
import 'jurnal_pin_unlock_screen.dart';

class JurnalBackupScreen extends StatefulWidget {
  const JurnalBackupScreen({super.key, this.returnAfterBackup = false});

  final bool returnAfterBackup;

  @override
  State<JurnalBackupScreen> createState() => _JurnalBackupScreenState();
}

class _JurnalBackupScreenState extends State<JurnalBackupScreen> {
  static final _lowercase = RegExp(r'\p{Ll}', unicode: true);
  static final _uppercase = RegExp(r'\p{Lu}', unicode: true);
  static final _number = RegExp(r'\p{Nd}', unicode: true);
  static final _symbol = RegExp(r'[\p{P}\p{S}]', unicode: true);

  bool _busy = false;

  bool _sameUser(String uid) => mounted && AppScope.of(context).auth.uid == uid;

  void _message(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<bool> _unlock(String uid, {required bool allowSetup}) async {
    final scope = AppScope.of(context);
    final hasPin = await scope.pinService.hasPin(uid);
    final pinBackup = !hasPin && !scope.auth.isAnonymous
        ? await scope.userRepository.getJournalPinBackup(uid)
        : null;
    if (!mounted || !_sameUser(uid)) return false;
    if (!hasPin && pinBackup == null && !allowSetup) {
      _message(context.s.journalBackup.backupPinRequired);
      return false;
    }
    if (!hasPin && pinBackup == null) {
      final confirmed = await _confirm(
        context.s.journalBackup.title,
        context.s.journalBackup.unlockRequired,
        context.s.common.lanjut,
      );
      if (!confirmed || !mounted || !_sameUser(uid)) return false;
    }
    final unlocked = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => hasPin
            ? const JurnalPinUnlockScreen()
            : pinBackup != null
            ? JurnalPinRecoverScreen(backup: pinBackup)
            : const JurnalPinSetupScreen(),
        fullscreenDialog: true,
      ),
    );
    return unlocked == true && _sameUser(uid);
  }

  Future<bool> _confirm(String title, String body, String action) async {
    final cancel = context.s.common.batal;
    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(title),
            content: Text(body),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: Text(action),
              ),
            ],
          ),
        ) ==
        true;
  }

  Future<void> _backup() async {
    final scope = AppScope.of(context);
    final uid = scope.auth.uid;
    if (_busy || uid == null) return;
    final t = context.s.journalBackup;
    setState(() => _busy = true);
    try {
      if (await scope.userRepository.journalEntryCount(uid) == 0) {
        _message(t.noEntries);
        return;
      }
      if (!_sameUser(uid) || !await _unlock(uid, allowSetup: false)) return;
      final password = await _askPassword(create: true);
      if (password == null || !_sameUser(uid)) return;
      final entries = await scope.userRepository.getJournalEntries(uid);
      final bytes = await JournalBackupCodec.encode(entries, password);
      if (!_sameUser(uid)) return;
      final date = DateTime.now();
      final saved = await FilePicker.saveFile(
        fileName:
            'riung-jurnal-${DateFormat('yyyyMMdd-HHmmss').format(date)}.riungjurnal',
        bytes: bytes,
      );
      if (saved == null) return;
      await scope.prefs.setJournalBackupSavedAt(uid, date);
      if (!mounted || !_sameUser(uid)) return;
      _message(t.saved);
      if (widget.returnAfterBackup) Navigator.pop(context, true);
    } on MissingPluginException {
      _message(t.pickerUnavailable);
    } catch (_) {
      _message(t.saveFailed);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _restore() async {
    final scope = AppScope.of(context);
    final uid = scope.auth.uid;
    if (_busy || uid == null) return;
    final t = context.s.journalBackup;
    setState(() => _busy = true);
    var error = t.openFailed;
    try {
      final files = await FilePicker.pickFiles();
      if (files.isEmpty || !_sameUser(uid)) return;
      final buffer = BytesBuilder(copy: false);
      await for (final chunk in files.single.readAsByteStream()) {
        if (buffer.length + chunk.length > JournalBackupCodec.maxBytes) {
          _message(t.fileTooLarge);
          return;
        }
        buffer.add(chunk);
      }
      if (!_sameUser(uid)) return;
      final bytes = buffer.takeBytes();
      final password = await _askPassword(create: false);
      if (password == null || !_sameUser(uid)) return;
      final entries = await JournalBackupCodec.decode(bytes, password);
      if (!mounted || !_sameUser(uid)) return;
      if (entries.isEmpty) {
        _message(t.noEntries);
        return;
      }
      final dates = entries.map((entry) => entry.createdAt.toLocal()).toList()
        ..sort();
      final format = DateFormat.yMMMd(context.s.dateLocale);
      final first = format.format(dates.first);
      final last = format.format(dates.last);
      final confirmed = await _confirm(
        t.restore,
        t.preview(entries.length, first == last ? first : '$first – $last'),
        t.restore,
      );
      if (!confirmed || !_sameUser(uid)) return;
      error = t.restoreFailed;
      if (!await _unlock(uid, allowSetup: true)) return;
      final added = await scope.userRepository.restoreJournalEntries(
        uid,
        entries,
      );
      if (_sameUser(uid)) _message(t.restored(added, entries.length - added));
    } on MissingPluginException {
      _message(t.pickerUnavailable);
    } catch (_) {
      _message(error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<String?> _askPassword({required bool create}) {
    final t = context.s.journalBackup;
    final common = context.s.common;
    final form = GlobalKey<FormState>();
    var password = '';
    return showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(create ? t.backup : t.restore),
        scrollable: true,
        content: Form(
          key: form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (create) ...[
                Text(t.passwordHint),
                const SizedBox(height: AppSpacing.md),
              ],
              _BackupPasswordField(
                label: t.password,
                autofocus: true,
                onChanged: (value) => password = value,
                validator: (value) {
                  if (password.trim().isEmpty) return t.passwordRequired;
                  if (create && password.trim().runes.length < 6) {
                    return t.passwordTooShort;
                  }
                  if (create &&
                      ![
                        _lowercase,
                        _uppercase,
                        _number,
                        _symbol,
                      ].every((pattern) => pattern.hasMatch(password))) {
                    return t.passwordMissingTypes;
                  }
                  return null;
                },
              ),
              if (create) ...[
                const SizedBox(height: AppSpacing.md),
                _BackupPasswordField(
                  label: t.confirmPassword,
                  validator: (value) =>
                      value == password ? null : t.passwordMismatch,
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(common.batal),
          ),
          FilledButton(
            onPressed: () {
              if (form.currentState!.validate()) {
                Navigator.pop(dialogContext, password);
              }
            },
            child: Text(common.lanjut),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final t = context.s.journalBackup;
    final uid = scope.auth.uid;
    final last = uid == null ? null : scope.prefs.journalBackupSavedAt(uid);
    return PopScope(
      canPop: !_busy,
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              children: [
                RiungGlassHeader(title: t.screenTitle),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.xl,
                    ),
                    children: [
                      Text(t.localOnly, style: AppTextStyles.title),
                      const SizedBox(height: AppSpacing.sm),
                      Text(t.intro, style: AppTextStyles.body),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        last == null
                            ? t.neverSaved
                            : t.lastSaved(
                                DateFormat.yMMMd(
                                  context.s.dateLocale,
                                ).format(last),
                              ),
                        style: AppTextStyles.caption,
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      RiungButton(
                        label: t.backup,
                        icon: Icons.save_alt_rounded,
                        onPressed: _busy || uid == null ? null : _backup,
                      ),
                      if (!widget.returnAfterBackup) ...[
                        const SizedBox(height: AppSpacing.sm),
                        RiungButton(
                          label: t.restore,
                          icon: Icons.upload_file_rounded,
                          variant: RiungButtonVariant.secondary,
                          onPressed: _busy || uid == null ? null : _restore,
                        ),
                      ],
                      if (_busy) ...[
                        const SizedBox(height: AppSpacing.lg),
                        const LinearProgressIndicator(),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BackupPasswordField extends StatefulWidget {
  const _BackupPasswordField({
    required this.label,
    required this.validator,
    this.autofocus = false,
    this.onChanged,
  });

  final String label;
  final FormFieldValidator<String> validator;
  final bool autofocus;
  final ValueChanged<String>? onChanged;

  @override
  State<_BackupPasswordField> createState() => _BackupPasswordFieldState();
}

class _BackupPasswordFieldState extends State<_BackupPasswordField> {
  static const _border = OutlineInputBorder(
    borderRadius: BorderRadius.all(Radius.circular(AppRadius.lg)),
    borderSide: BorderSide(color: AppColors.teksSekunder),
  );
  bool _hidden = true;

  @override
  Widget build(BuildContext context) {
    final t = context.s.journalBackup;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ExcludeSemantics(
          child: Text(
            widget.label,
            style: AppTextStyles.chipLabel.copyWith(color: AppColors.teksUtama),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Semantics(
          label: widget.label,
          child: TextFormField(
            autofocus: widget.autofocus,
            obscureText: _hidden,
            autocorrect: false,
            enableSuggestions: false,
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.primerLembut,
              enabledBorder: _border,
              focusedBorder: _border.copyWith(
                borderSide: const BorderSide(
                  color: AppColors.primerGelap,
                  width: 2,
                ),
              ),
              errorBorder: _border.copyWith(
                borderSide: const BorderSide(color: AppColors.error),
              ),
              focusedErrorBorder: _border.copyWith(
                borderSide: const BorderSide(color: AppColors.error, width: 2),
              ),
              suffixIcon: IconButton(
                tooltip: _hidden ? t.showPassword : t.hidePassword,
                icon: Icon(
                  _hidden
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
                onPressed: () => setState(() => _hidden = !_hidden),
              ),
            ),
            validator: widget.validator,
            onChanged: widget.onChanged,
          ),
        ),
      ],
    );
  }
}
