import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/error_messages.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../widgets/app_scaffold.dart';
import '../../../widgets/error_banner.dart';
import '../../../widgets/primary_button.dart';
import '../../../widgets/secondary_button.dart';
import '../data/eventi_partita_repository.dart';
import '../domain/evento_partita.dart';
import '../domain/partita.dart';
import 'selettore_giocatore_partita.dart';
import 'squalifiche_partita.dart';

enum _PassoEspulsione { giocatore, dettagli }

/// Sostituisce il vecchio dialog "Registra espulsione": la stessa griglia
/// di bersagli usata per il tiro, ma per entrambe le squadre — un
/// giocatore avversario si identifica solo dal numero di calottina, non
/// abbiamo la sua rubrica.
class RegistraEspulsioneScreen extends ConsumerStatefulWidget {
  const RegistraEspulsioneScreen({
    required this.partita,
    required this.convocati,
    required this.eventi,
    super.key,
  });

  final Partita partita;
  final List<ConvocatoConAtleta> convocati;
  final List<EventoPartita> eventi;

  @override
  ConsumerState<RegistraEspulsioneScreen> createState() =>
      _RegistraEspulsioneScreenState();
}

class _RegistraEspulsioneScreenState
    extends ConsumerState<RegistraEspulsioneScreen> {
  _PassoEspulsione _passo = _PassoEspulsione.giocatore;
  String? _atletaId;
  int? _numeroAvversario;
  bool? _daRigore;
  int? _periodo;
  bool _isSubmitting = false;
  String? _errore;

  bool get _puoTornareIndietro => _passo != _PassoEspulsione.giocatore;

  void _indietro() {
    setState(() => _passo = _PassoEspulsione.giocatore);
  }

  Future<void> _salva() async {
    setState(() {
      _isSubmitting = true;
      _errore = null;
    });
    try {
      await ref
          .read(eventiPartitaRepositoryProvider)
          .registraEspulsione(
            partitaId: widget.partita.id,
            atletaId: _atletaId,
            numeroCalottinaAvversario: _numeroAvversario,
            periodo: _periodo,
            espulsioneDaRigore: _daRigore ?? false,
          );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) setState(() => _errore = messaggioErrore(e));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final squalificati = calcolaSqualificati(widget.eventi);

    return PopScope(
      canPop: !_puoTornareIndietro,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _puoTornareIndietro) _indietro();
      },
      child: AppScaffold(
        appBar: AppBar(
          title: const Text('Registra espulsione'),
          leading: _puoTornareIndietro
              ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: _indietro,
                )
              : null,
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.s16),
            child: switch (_passo) {
              _PassoEspulsione.giocatore => SingleChildScrollView(
                child: SelettoreGiocatorePartita(
                  partita: widget.partita,
                  convocati: widget.convocati,
                  mostraAvversari: true,
                  disqualificati: squalificati,
                  onSelezionatoNostro: (id) {
                    setState(() {
                      _atletaId = id;
                      _numeroAvversario = null;
                      _passo = _PassoEspulsione.dettagli;
                    });
                  },
                  onSelezionatoAvversario: (n) {
                    setState(() {
                      _numeroAvversario = n;
                      _atletaId = null;
                      _passo = _PassoEspulsione.dettagli;
                    });
                  },
                ),
              ),
              _PassoEspulsione.dettagli => _PassoDettagli(
                daRigore: _daRigore,
                onDaRigore: (v) => setState(() => _daRigore = v),
                tracciaTempo: widget.partita.tracciaTempo,
                periodo: _periodo,
                onPeriodo: (v) => setState(() => _periodo = v),
                errore: _errore,
                isSubmitting: _isSubmitting,
                onSalva: _daRigore == null ? null : _salva,
              ),
            },
          ),
        ),
      ),
    );
  }
}

class _PassoDettagli extends StatelessWidget {
  const _PassoDettagli({
    required this.daRigore,
    required this.onDaRigore,
    required this.tracciaTempo,
    required this.periodo,
    required this.onPeriodo,
    required this.errore,
    required this.isSubmitting,
    required this.onSalva,
  });

  final bool? daRigore;
  final ValueChanged<bool> onDaRigore;
  final bool tracciaTempo;
  final int? periodo;
  final ValueChanged<int?> onPeriodo;
  final String? errore;
  final bool isSubmitting;
  final VoidCallback? onSalva;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('È a fallo da rigore?', style: AppTypography.sezione),
          const SizedBox(height: AppSpacing.s8),
          Text(
            'Nega un\'occasione da gol netta: la terza in partita per lo '
            'stesso giocatore lo esclude dal resto della gara.',
            style: AppTypography.piccolo,
          ),
          const SizedBox(height: AppSpacing.s12),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: AppSpacing.altezzaMinimaBersaglioVasca,
                  child: daRigore == true
                      ? PrimaryButton(
                          label: 'Sì',
                          onPressed: () => onDaRigore(true),
                        )
                      : SecondaryButton(
                          label: 'Sì',
                          onPressed: () => onDaRigore(true),
                        ),
                ),
              ),
              const SizedBox(width: AppSpacing.spazioBersagli),
              Expanded(
                child: SizedBox(
                  height: AppSpacing.altezzaMinimaBersaglioVasca,
                  child: daRigore == false
                      ? PrimaryButton(
                          label: 'No',
                          onPressed: () => onDaRigore(false),
                        )
                      : SecondaryButton(
                          label: 'No',
                          onPressed: () => onDaRigore(false),
                        ),
                ),
              ),
            ],
          ),
          if (tracciaTempo) ...[
            const SizedBox(height: AppSpacing.s24),
            Text('Tempo', style: AppTypography.sezione),
            const SizedBox(height: AppSpacing.s12),
            Wrap(
              spacing: AppSpacing.spazioBersagli,
              runSpacing: AppSpacing.spazioBersagli,
              children: [
                for (var t = 1; t <= 4; t++)
                  SizedBox(
                    height: AppSpacing.altezzaMinimaBersaglioVasca,
                    child: periodo == t
                        ? PrimaryButton(
                            label: 'Tempo $t',
                            expanded: false,
                            onPressed: () => onPeriodo(t),
                          )
                        : SecondaryButton(
                            label: 'Tempo $t',
                            expanded: false,
                            onPressed: () => onPeriodo(t),
                          ),
                  ),
              ],
            ),
          ],
          if (errore != null) ...[
            const SizedBox(height: AppSpacing.s16),
            ErrorBanner(messaggio: errore!),
          ],
          const SizedBox(height: AppSpacing.s24),
          PrimaryButton(
            label: 'Salva',
            onPressed: onSalva,
            isLoading: isSubmitting,
          ),
        ],
      ),
    );
  }
}
