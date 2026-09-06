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
import 'campo_tiro.dart';
import 'eventi_labels.dart';
import 'selettore_giocatore_partita.dart';
import 'squalifiche_partita.dart';

enum _PassoTiro { campo, giocatore, esito }

/// Sostituisce il vecchio dialog "Registra tiro" (menu a tendina): il
/// tocco sul campo disegnato è l'input (DESIGN.md sezione 9, "nessun
/// form"), seguito dalla griglia di bersagli per l'atleta e dall'esito.
class RegistraTiroScreen extends ConsumerStatefulWidget {
  const RegistraTiroScreen({
    required this.partita,
    required this.convocati,
    required this.eventi,
    super.key,
  });

  final Partita partita;
  final List<ConvocatoConAtleta> convocati;
  final List<EventoPartita> eventi;

  @override
  ConsumerState<RegistraTiroScreen> createState() =>
      _RegistraTiroScreenState();
}

class _RegistraTiroScreenState extends ConsumerState<RegistraTiroScreen> {
  _PassoTiro _passo = _PassoTiro.campo;
  double? _posX;
  double? _posY;
  String? _atletaId;
  String? _esito;
  String _contesto = 'azione';
  int? _periodo;
  bool _isSubmitting = false;
  String? _errore;

  List<(String, String)> get _opzioniEsito =>
      widget.partita.dettaglioTiro == 'dettagliato'
      ? esitiTiroDettagliato
      : esitiTiroSemplice;

  bool get _puoTornareIndietro => _passo != _PassoTiro.campo;

  void _indietro() {
    setState(() {
      _passo = switch (_passo) {
        _PassoTiro.campo => _PassoTiro.campo,
        _PassoTiro.giocatore => _PassoTiro.campo,
        _PassoTiro.esito => _PassoTiro.giocatore,
      };
    });
  }

  Future<void> _salva() async {
    setState(() {
      _isSubmitting = true;
      _errore = null;
    });
    try {
      await ref
          .read(eventiPartitaRepositoryProvider)
          .registraTiro(
            partitaId: widget.partita.id,
            atletaId: _atletaId!,
            esito: _esito!,
            periodo: _periodo,
            contestoTiro: _contesto,
            posX: _posX,
            posY: _posY,
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
          title: const Text('Registra tiro'),
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
              _PassoTiro.campo => _PassoCampo(
                onTocca: (x, y) {
                  setState(() {
                    _posX = x;
                    _posY = y;
                    _passo = _PassoTiro.giocatore;
                  });
                },
              ),
              _PassoTiro.giocatore => SingleChildScrollView(
                child: SelettoreGiocatorePartita(
                  partita: widget.partita,
                  convocati: widget.convocati,
                  disqualificati: squalificati,
                  onSelezionatoNostro: (id) {
                    setState(() {
                      _atletaId = id;
                      _passo = _PassoTiro.esito;
                    });
                  },
                ),
              ),
              _PassoTiro.esito => _PassoEsito(
                opzioniEsito: _opzioniEsito,
                esito: _esito,
                onEsito: (v) => setState(() => _esito = v),
                contesto: _contesto,
                onContesto: (v) => setState(() => _contesto = v),
                tracciaTempo: widget.partita.tracciaTempo,
                periodo: _periodo,
                onPeriodo: (v) => setState(() => _periodo = v),
                errore: _errore,
                isSubmitting: _isSubmitting,
                onSalva: _esito == null ? null : _salva,
              ),
            },
          ),
        ),
      ),
    );
  }
}

class _PassoCampo extends StatelessWidget {
  const _PassoCampo({required this.onTocca});

  final void Function(double x, double y) onTocca;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Tocca il punto del campo da cui è partito il tiro',
          style: AppTypography.sezione,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.s16),
        CampoTiro(onTocca: onTocca),
      ],
    );
  }
}

class _PassoEsito extends StatelessWidget {
  const _PassoEsito({
    required this.opzioniEsito,
    required this.esito,
    required this.onEsito,
    required this.contesto,
    required this.onContesto,
    required this.tracciaTempo,
    required this.periodo,
    required this.onPeriodo,
    required this.errore,
    required this.isSubmitting,
    required this.onSalva,
  });

  final List<(String, String)> opzioniEsito;
  final String? esito;
  final ValueChanged<String> onEsito;
  final String contesto;
  final ValueChanged<String> onContesto;
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
          Text('Esito', style: AppTypography.sezione),
          const SizedBox(height: AppSpacing.s12),
          _RigaBersagli(
            opzioni: opzioniEsito,
            selezionato: esito,
            onSelezionato: onEsito,
          ),
          const SizedBox(height: AppSpacing.s24),
          Text('Contesto', style: AppTypography.sezione),
          const SizedBox(height: AppSpacing.s12),
          _RigaBersagli(
            opzioni: contestiTiro,
            selezionato: contesto,
            onSelezionato: onContesto,
          ),
          if (tracciaTempo) ...[
            const SizedBox(height: AppSpacing.s24),
            Text('Tempo', style: AppTypography.sezione),
            const SizedBox(height: AppSpacing.s12),
            _RigaBersagli(
              opzioni: [for (var t = 1; t <= 4; t++) ('$t', 'Tempo $t')],
              selezionato: periodo?.toString(),
              onSelezionato: (v) => onPeriodo(int.parse(v)),
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

class _RigaBersagli extends StatelessWidget {
  const _RigaBersagli({
    required this.opzioni,
    required this.selezionato,
    required this.onSelezionato,
  });

  final List<(String, String)> opzioni;
  final String? selezionato;
  final ValueChanged<String> onSelezionato;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.spazioBersagli,
      runSpacing: AppSpacing.spazioBersagli,
      children: [
        for (final (valore, etichetta) in opzioni)
          SizedBox(
            height: AppSpacing.altezzaMinimaBersaglioVasca,
            child: selezionato == valore
                ? PrimaryButton(
                    label: etichetta,
                    expanded: false,
                    onPressed: () => onSelezionato(valore),
                  )
                : SecondaryButton(
                    label: etichetta,
                    expanded: false,
                    onPressed: () => onSelezionato(valore),
                  ),
          ),
      ],
    );
  }
}
