import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/error_messages.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../widgets/app_select.dart';
import '../../../widgets/app_text_field.dart';
import '../../../widgets/error_banner.dart';
import '../../../widgets/primary_button.dart';
import '../../gruppi/data/gruppi_repository.dart';
import '../application/current_club_provider.dart';
import '../data/club_repository.dart';

const _categorieNuoto = [
  'Es.C',
  'Es.B',
  'Es.A',
  'Ragazzi',
  'Juniores',
  'Cadetti',
  'Assoluti',
  'Amatori',
];

const _categoriePallanuoto = [
  'U10',
  'U11',
  'U12',
  'U13',
  'U14',
  'U15',
  'U16',
  'U17',
  'U18',
  'U20',
  'Prima squadra',
];

const _sportOptions = [
  ('nuoto', 'Nuoto'),
  ('pallanuoto', 'Pallanuoto'),
  ('nuoto_pallanuoto', 'Nuoto e Pallanuoto'),
];

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

  String? _sport;
  final Set<String> _categorieSelezionate = {};

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
            categorie: _categorieSelezionate.toList(),
          );
      // Un gruppo di allenamento gia' pronto per ciascuna categoria scelta,
      // cosi' l'allenatore salta l'onboarding gruppi se le ha gia'
      // indicate qui (puo' comunque rinominarli/aggiungerne altri dopo).
      // Un eventuale fallimento qui (la coda offline copre la rete) non
      // deve bloccare la creazione del club appena riuscita.
      try {
        final gruppiRepository = ref.read(gruppiRepositoryProvider);
        final categorieOrdinate = _categorieDisponibili
            .where(_categorieSelezionate.contains)
            .toList();
        for (var i = 0; i < categorieOrdinate.length; i++) {
          await gruppiRepository.createGruppo(
            clubId: club.id,
            nome: categorieOrdinate[i],
            ordine: i + 1,
          );
        }
      } catch (_) {}
      ref.invalidate(currentClubProvider);
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = messaggioErrore(e));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  List<String> get _categorieDisponibili => switch (_sport) {
    'nuoto' => _categorieNuoto,
    'pallanuoto' => _categoriePallanuoto,
    'nuoto_pallanuoto' => [..._categorieNuoto, ..._categoriePallanuoto],
    _ => const [],
  };

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
                  const SizedBox(height: AppSpacing.s16),
                  AppSelect<String?>(
                    etichetta: 'Sport',
                    value: _sport,
                    hint: 'Scegli lo sport',
                    items: [
                      for (final (valore, etichetta) in _sportOptions)
                        DropdownMenuItem(value: valore, child: Text(etichetta)),
                    ],
                    onChanged: (value) => setState(() {
                      _sport = value;
                      _categorieSelezionate.clear();
                    }),
                  ),
                  if (_categorieDisponibili.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.s16),
                    Text(
                      'Categorie allenate (facoltativo)',
                      style: AppTypography.etichetta,
                    ),
                    const SizedBox(height: AppSpacing.s8),
                    Wrap(
                      spacing: AppSpacing.s8,
                      runSpacing: AppSpacing.s8,
                      children: [
                        for (final categoria in _categorieDisponibili)
                          FilterChip(
                            label: Text(categoria),
                            selected: _categorieSelezionate.contains(categoria),
                            onSelected: (selezionata) => setState(() {
                              if (selezionata) {
                                _categorieSelezionate.add(categoria);
                              } else {
                                _categorieSelezionate.remove(categoria);
                              }
                            }),
                          ),
                      ],
                    ),
                  ],
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
