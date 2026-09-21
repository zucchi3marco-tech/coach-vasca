import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/error_messages.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../theme/colori_app.dart';
import '../../../widgets/app_text_field.dart';
import '../../../widgets/error_banner.dart';
import '../../../widgets/primary_button.dart';
import '../../../widgets/secondary_button.dart';
import '../../club/application/current_club_provider.dart';
import '../data/gruppi_repository.dart';

/// Mostrata al primo accesso di un club senza ancora nessun gruppo di
/// allenamento (FASE 10, ultimo punto): l'allenatore deve crearne almeno
/// uno prima di continuare. Nessuna AppBar propria: e' incorporata nel
/// body di HomeScreen, sotto la barra fissa in alto con il menu "Esci"
/// (stesso pattern di AreaAtletaHomeScreen).
class GruppiOnboardingScreen extends ConsumerStatefulWidget {
  const GruppiOnboardingScreen({required this.clubId, super.key});

  final String clubId;

  @override
  ConsumerState<GruppiOnboardingScreen> createState() =>
      _GruppiOnboardingScreenState();
}

class _GruppiOnboardingScreenState
    extends ConsumerState<GruppiOnboardingScreen> {
  final List<TextEditingController> _controller = [TextEditingController()];
  bool _isSubmitting = false;
  String? _errore;

  @override
  void dispose() {
    for (final c in _controller) {
      c.dispose();
    }
    super.dispose();
  }

  void _aggiungiRiga() =>
      setState(() => _controller.add(TextEditingController()));

  void _rimuoviRiga(int indice) {
    setState(() => _controller.removeAt(indice).dispose());
  }

  Future<void> _continua() async {
    final nomi = _controller
        .map((c) => c.text.trim())
        .where((n) => n.isNotEmpty)
        .toList();
    if (nomi.isEmpty) {
      setState(() => _errore = 'Aggiungi almeno un gruppo');
      return;
    }
    setState(() {
      _isSubmitting = true;
      _errore = null;
    });
    try {
      final repository = ref.read(gruppiRepositoryProvider);
      // Se il club pratica un solo sport, il gruppo lo eredita subito
      // (evita di richiederlo di nuovo in fase di registrazione via
      // codice di gruppo — FASE 13, punto 2). Per un club "nuoto e
      // pallanuoto" resta null: ambiguo finche' non lo si precisa a
      // mano (non richiesto qui per non appesantire l'onboarding).
      final clubSport = ref.read(currentClubProvider).value?.sport;
      final gruppoSport = clubSport == 'nuoto' || clubSport == 'pallanuoto'
          ? clubSport
          : null;
      for (var i = 0; i < nomi.length; i++) {
        await repository.createGruppo(
          clubId: widget.clubId,
          nome: nomi[i],
          ordine: i + 1,
          sport: gruppoSport,
        );
      }
      // Non serve navigare da qui: HomeScreen osserva gruppiListProvider e
      // passa da sola alla schermata di scelta gruppo appena i gruppi
      // creati arrivano.
    } catch (e) {
      if (mounted) setState(() => _errore = messaggioErrore(e));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.s16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Crea i gruppi di allenamento',
              style: AppTypography.titoloXl.copyWith(color: colori.testo),
            ),
            const SizedBox(height: AppSpacing.s8),
            Text(
              'Servono per organizzare atleti e allenamenti per gruppo (es. '
              '"U14", "Agonisti"). Ne puoi aggiungere altri in qualsiasi '
              'momento.',
              style: AppTypography.piccolo.copyWith(
                color: colori.testoSecondario,
              ),
            ),
            const SizedBox(height: AppSpacing.s24),
            for (var i = 0; i < _controller.length; i++) ...[
              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      etichetta: 'Nome gruppo',
                      controller: _controller[i],
                    ),
                  ),
                  if (_controller.length > 1)
                    IconButton(
                      icon: Icon(Icons.close, color: colori.testoSecondario),
                      tooltip: 'Rimuovi',
                      onPressed: () => _rimuoviRiga(i),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.s12),
            ],
            SecondaryButton(
              label: 'Aggiungi un altro gruppo',
              onPressed: _aggiungiRiga,
            ),
            if (_errore != null) ...[
              const SizedBox(height: AppSpacing.s12),
              ErrorBanner(messaggio: _errore!),
            ],
            const SizedBox(height: AppSpacing.s24),
            PrimaryButton(
              label: 'Continua',
              isLoading: _isSubmitting,
              onPressed: _isSubmitting ? null : _continua,
            ),
          ],
        ),
      ),
    );
  }
}
