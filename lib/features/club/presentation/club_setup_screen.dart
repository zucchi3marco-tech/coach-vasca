import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/error_messages.dart';
import '../../../theme/app_spacing.dart';
import '../../../widgets/app_text_field.dart';
import '../../../widgets/error_banner.dart';
import '../../../widgets/primary_button.dart';
import '../application/current_club_provider.dart';
import '../data/club_repository.dart';

/// Mostrato quando l'utente autenticato non e' ancora membro di nessun
/// club: crea il primo club (diventandone owner tramite il trigger DB).
///
/// Nota: e' contenuto nel body di HomeScreen (che ha gia' Scaffold e
/// AppBar), quindi non usa AppScaffold per non annidare due Scaffold.
class ClubSetupScreen extends ConsumerStatefulWidget {
  const ClubSetupScreen({super.key});

  @override
  ConsumerState<ClubSetupScreen> createState() => _ClubSetupScreenState();
}

class _ClubSetupScreenState extends ConsumerState<ClubSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _cittaController = TextEditingController();

  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nomeController.dispose();
    _cittaController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      await ref
          .read(clubRepositoryProvider)
          .createClub(
            nome: _nomeController.text.trim(),
            citta: _cittaController.text.trim(),
          );
      ref.invalidate(currentClubProvider);
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = messaggioErrore(e));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.s24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Crea il tuo club',
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.s4),
                  Text(
                    'Sarai impostato automaticamente come owner.',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.s24),
                  AppTextField(
                    etichetta: 'Nome del club',
                    controller: _nomeController,
                    validator: (value) =>
                        (value == null || value.trim().isEmpty)
                        ? 'Inserisci un nome'
                        : null,
                  ),
                  const SizedBox(height: AppSpacing.s16),
                  AppTextField(
                    etichetta: 'Città (facoltativo)',
                    controller: _cittaController,
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: AppSpacing.s12),
                    ErrorBanner(messaggio: _errorMessage!),
                  ],
                  const SizedBox(height: AppSpacing.s24),
                  PrimaryButton(
                    label: 'Crea club',
                    isLoading: _isSubmitting,
                    onPressed: _isSubmitting ? null : _submit,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
