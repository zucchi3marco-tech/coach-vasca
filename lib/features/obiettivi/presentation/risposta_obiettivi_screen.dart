import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/date_italiane.dart';
import '../../../core/utils/error_messages.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../theme/colori_app.dart';
import '../../../widgets/app_scaffold.dart';
import '../../../widgets/error_banner.dart';
import '../../../widgets/primary_button.dart';
import '../../../widgets/section_header.dart';
import '../../atleti/domain/atleta.dart';
import '../data/obiettivi_repository.dart';
import '../domain/scheda_obiettivi.dart';

/// Una scheda obiettivi di un atleta. L'atleta risponde (e corregge
/// finché la scheda è aperta) e legge le due righe dell'allenatore;
/// l'allenatore ([perAllenatore]) legge le risposte e scrive il ritorno.
class RispostaObiettiviScreen extends ConsumerStatefulWidget {
  const RispostaObiettiviScreen({
    required this.scheda,
    required this.atleta,
    this.risposta,
    this.perAllenatore = false,
    super.key,
  });

  final SchedaObiettivi scheda;
  final Atleta atleta;

  /// Quella già mandata, se c'è.
  final RispostaObiettivi? risposta;
  final bool perAllenatore;

  @override
  ConsumerState<RispostaObiettiviScreen> createState() =>
      _RispostaObiettiviScreenState();
}

class _RispostaObiettiviScreenState
    extends ConsumerState<RispostaObiettiviScreen> {
  final _formKey = GlobalKey<FormState>();
  late final List<TextEditingController> _risposte;
  late final TextEditingController _ritorno;
  bool _salvataggio = false;
  String? _errore;

  bool get _puoRispondere => !widget.perAllenatore && !widget.scheda.chiusa;

  @override
  void initState() {
    super.initState();
    final date = widget.risposta?.risposte ?? const <String>[];
    _risposte = [
      for (var i = 0; i < widget.scheda.domande.length; i++)
        TextEditingController(text: i < date.length ? date[i] : ''),
    ];
    _ritorno = TextEditingController(text: widget.risposta?.ritorno ?? '');
  }

  @override
  void dispose() {
    for (final c in _risposte) {
      c.dispose();
    }
    _ritorno.dispose();
    super.dispose();
  }

  Future<void> _salva() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _salvataggio = true;
      _errore = null;
    });
    try {
      final repository = ref.read(obiettiviRepositoryProvider);
      if (widget.perAllenatore) {
        await repository.scriviRitorno(widget.risposta!.id, _ritorno.text);
      } else {
        await repository.rispondi(
          scheda: widget.scheda,
          atletaId: widget.atleta.id,
          risposte: [for (final c in _risposte) c.text],
        );
      }
      aggiornaObiettivi(ref);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.perAllenatore
                ? 'Salvato: ${widget.atleta.nome} lo legge sotto le sue '
                      'risposte'
                : widget.risposta == null
                ? 'Risposte mandate all\'allenatore'
                : 'Risposte corrette',
          ),
        ),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) setState(() => _errore = messaggioErrore(e));
    } finally {
      if (mounted) setState(() => _salvataggio = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    final scheda = widget.scheda;
    final risposta = widget.risposta;
    final ritorno = risposta?.ritorno;

    return AppScaffold(
      scrollabile: true,
      appBar: AppBar(
        title: Text(
          widget.perAllenatore
              ? '${widget.atleta.nome} ${widget.atleta.cognome}'
              : scheda.titolo,
        ),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              [
                if (widget.perAllenatore) scheda.titolo,
                if (risposta != null)
                  'mandata ${dataEstesa(risposta.inviataAt)}'
                else if (scheda.chiusa)
                  'scheda chiusa'
                else
                  'da compilare',
              ].join(' · '),
              style: AppTypography.piccolo.copyWith(
                color: colori.testoSecondario,
              ),
            ),
            const SizedBox(height: AppSpacing.s16),
            // Le due righe dell'allenatore, in cima per l'atleta.
            if (!widget.perAllenatore && ritorno != null) ...[
              _Ritorno(testo: ritorno, quando: risposta!.ritornoAt),
              const SizedBox(height: AppSpacing.s24),
            ],
            for (final (i, domanda) in scheda.domande.indexed) ...[
              Text(
                '${i + 1}. $domanda',
                style: AppTypography.corpoForte.copyWith(color: colori.testo),
              ),
              const SizedBox(height: AppSpacing.s8),
              if (_puoRispondere)
                TextFormField(
                  controller: _risposte[i],
                  minLines: 2,
                  maxLines: 6,
                  maxLength: lunghezzaMassimaRisposta,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    hintText: 'Scrivi qui la tua risposta',
                  ),
                )
              else
                Text(
                  (i < (risposta?.risposte.length ?? 0) &&
                          risposta!.risposte[i].trim().isNotEmpty)
                      ? risposta.risposte[i]
                      : '—',
                  style: AppTypography.corpo.copyWith(color: colori.testo),
                ),
              const SizedBox(height: AppSpacing.s16),
            ],
            if (!_puoRispondere && !widget.perAllenatore && risposta == null)
              Text(
                'La scheda è chiusa: non si risponde più.',
                style: AppTypography.piccolo.copyWith(
                  color: colori.testoSecondario,
                ),
              ),
            if (widget.perAllenatore) ...[
              const TitoloSezione(
                'Le tue due righe',
                spiegazione:
                    'L\'atleta le legge sotto le sue risposte e gli arriva '
                    'un avviso.',
              ),
              TextFormField(
                controller: _ritorno,
                minLines: 3,
                maxLines: 8,
                maxLength: lunghezzaMassimaRitorno,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText:
                      'Es. Bene il tiro: quest\'anno lavoriamo sulla '
                      'gamba.',
                ),
              ),
              const SizedBox(height: AppSpacing.s16),
            ],
            if (_errore != null) ...[
              ErrorBanner(messaggio: _errore!),
              const SizedBox(height: AppSpacing.s16),
            ],
            if (_puoRispondere || widget.perAllenatore)
              PrimaryButton(
                label: widget.perAllenatore
                    ? 'Salva'
                    : risposta == null
                    ? 'Manda all\'allenatore'
                    : 'Salva le correzioni',
                isLoading: _salvataggio,
                onPressed: _salvataggio ? null : _salva,
              ),
          ],
        ),
      ),
    );
  }
}

class _Ritorno extends StatelessWidget {
  const _Ritorno({required this.testo, required this.quando});

  final String testo;
  final DateTime? quando;

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s16),
      decoration: BoxDecoration(
        color: colori.azioneTenue,
        borderRadius: BorderRadius.circular(AppRadius.pannello),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            quando == null
                ? 'Dall\'allenatore'
                : 'Dall\'allenatore, ${dataEstesa(quando!)}',
            style: AppTypography.etichetta.copyWith(color: colori.azione),
          ),
          const SizedBox(height: AppSpacing.s4),
          Text(testo, style: AppTypography.corpo.copyWith(color: colori.testo)),
        ],
      ),
    );
  }
}
