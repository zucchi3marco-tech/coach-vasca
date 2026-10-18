import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/error_messages.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../theme/colori_app.dart';
import '../../../widgets/app_select.dart';
import '../../../widgets/app_text_field.dart';
import '../../../widgets/error_banner.dart';
import '../../../widgets/form_group.dart';
import '../../../widgets/primary_button.dart';
import '../../../widgets/secondary_button.dart';
import '../../auth/presentation/avviso_solo_allenatori.dart';
import '../../auth/presentation/riscatta_invito_screen.dart';
import '../../configurazione/application/configurazione_providers.dart';
import '../../configurazione/domain/stato_configurazione.dart';
import '../application/current_club_provider.dart';
import '../data/club_repository.dart';
import 'entra_con_codice_staff_screen.dart';

const _sportOptions = [('nuoto', 'Nuoto'), ('pallanuoto', 'Pallanuoto')];

/// Mostrato quando l'utente autenticato non e' ancora membro di nessun
/// club: crea il primo club (diventandone owner tramite il trigger DB). E'
/// il passo 1 della configurazione guidata: squadre, allenatori, atleti e
/// codici seguono in `ConfigurazioneGuidataScreen`.
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

  String? _sport;

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
    if (_sport == null) {
      setState(() => _errorMessage = 'Scegli lo sport praticato dal club');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final club = await ref
          .read(clubRepositoryProvider)
          .createClub(
            nome: _nomeController.text.trim(),
            citta: _cittaController.text.trim(),
            sport: _sport,
            categorie: const [],
          );
      // Le squadre, gli allenatori, gli atleti e i codici seguono nella
      // configurazione guidata: va segnata in corso prima che il club
      // compaia, altrimenti HomeScreen mostrerebbe la vecchia schermata
      // delle squadre.
      ref.read(configurazioneInCorsoProvider.notifier).inizia(club.id);
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
                    'Passo ${PassoConfigurazione.club.numero} di '
                    '${PassoConfigurazione.totale}',
                    style: AppTypography.etichetta.copyWith(
                      color: context.colori.testoSecondario,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.s4),
                  Text(
                    'Crea il tuo club',
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.s4),
                  Text(
                    'Ne sarai il responsabile. Poi ti guidiamo fra squadre, '
                    'allenatori, atleti e codici.',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.s16),
                  // Qui arriva chiunque abbia un account senza club, anche
                  // un atleta entrato con Google o registrato dalla strada
                  // sbagliata: col codice si collega all'account già aperto.
                  AvvisoSoloAllenatori(
                    testo:
                        'Crea un club solo se sei l\'allenatore responsabile. '
                        'Se sei un atleta non crearlo: entra nel club della '
                        'tua squadra con il codice dell\'allenatore.',
                    onSonoAtleta: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const RiscattaInvitoScreen(),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s12),
                  // Un allenatore o un assistente invitato dal responsabile
                  // di un club che c'è già non ne crea uno nuovo.
                  SecondaryButton(
                    label: 'Ho un codice da allenatore',
                    icon: Icons.vpn_key_outlined,
                    onPressed: _isSubmitting
                        ? null
                        : () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const EntraConCodiceStaffScreen(),
                            ),
                          ),
                  ),
                  const SizedBox(height: AppSpacing.s24),
                  FormGroup(
                    titolo: 'Il club',
                    isUltimo: true,
                    campi: [
                      AppTextField(
                        etichetta: 'Nome del club',
                        controller: _nomeController,
                        validator: (value) =>
                            (value == null || value.trim().isEmpty)
                            ? 'Inserisci un nome'
                            : null,
                      ),
                      AppTextField(
                        etichetta: 'Città (facoltativo)',
                        controller: _cittaController,
                      ),
                      AppSelect<String?>(
                        etichetta: 'Sport',
                        value: _sport,
                        hint: 'Scegli lo sport',
                        items: [
                          for (final (valore, etichetta) in _sportOptions)
                            DropdownMenuItem(
                              value: valore,
                              child: Text(etichetta),
                            ),
                        ],
                        onChanged: (value) => setState(() => _sport = value),
                      ),
                    ],
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
