import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/dettatura/dettatura_vocale.dart';
import '../../../core/dettatura/testo_con_prefisso.dart';
import '../../../core/utils/error_messages.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../theme/colori_app.dart';
import '../../../widgets/app_text_field.dart';
import '../../../widgets/attesa_ai_hint.dart';
import '../../../widgets/error_banner.dart';
import '../../../widgets/primary_button.dart';
import '../../ai_genera/application/corsie_service.dart';
import '../../ai_genera/data/generazione_ai_repository.dart';
import '../../ai_genera/data/generazioni_ai_repository.dart';
import '../../ai_genera/domain/scheda_generata.dart';
import '../../gruppi/application/gruppi_providers.dart';
import '../domain/allenamento.dart';
import '../domain/testo_allenamento.dart';

/// Le serie proposte dall'AI scritte come righe del testo
/// dell'allenamento: la ripartenza è la più veloce fra le corsie, il
/// dettaglio per corsia finisce nella nota (vedi [risolviRipartenza]).
String testoDaSerieDettate(List<SerieGenerata> serie) =>
    testoDaSerie(serie.map(_scritta).toList());

SerieScritta _scritta(SerieGenerata s) {
  final r = risolviRipartenza(s.ripartenzePerCorsia, s.note);
  return SerieScritta(
    blocco: s.blocco,
    ripetute: s.ripetute,
    distanzaM: s.distanzaM,
    stile: s.stile,
    esecuzione: s.esecuzione,
    zona: s.zona,
    recuperoS: s.recuperoS,
    ripartenzaS: r.ripartenzaS,
    attrezzatura: s.attrezzatura,
    note: r.note,
  );
}

/// "Detta o descrivi a parole": quello che si scrive a mano lo legge
/// l'app da sola, mentre una frase detta ("riscaldamento 400 misti, poi
/// 8 volte 100 soglia con 20 di recupero") la trasforma l'AI — la stessa
/// Edge Function `detta-allenamento` di prima. Torna le righe da
/// aggiungere in fondo al testo, `null` se si chiude.
Future<String?> mostraDettaSerie(
  BuildContext context, {
  required Allenamento allenamento,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => DettaSerieSheet(allenamento: allenamento),
  );
}

class DettaSerieSheet extends ConsumerStatefulWidget {
  const DettaSerieSheet({required this.allenamento, super.key});

  final Allenamento allenamento;

  @override
  ConsumerState<DettaSerieSheet> createState() => _DettaSerieSheetState();
}

class _DettaSerieSheetState extends ConsumerState<DettaSerieSheet> {
  final _testoController = TextEditingController();
  bool _inCorso = false;
  String? _errore;

  DettatoreVocale? _dettatore;
  bool _inAscolto = false;
  String _prefisso = '';
  String? _erroreMicrofono;

  @override
  void dispose() {
    _dettatore?.dispose();
    _testoController.dispose();
    super.dispose();
  }

  void _alternaAscolto() {
    if (_inAscolto) {
      _dettatore?.ferma();
      return;
    }
    setState(() => _erroreMicrofono = null);
    _prefisso = _testoController.text.trim();
    _dettatore = DettatoreVocale(
      onTrascrizione: (testoSessione) {
        if (!mounted) return;
        final testo = testoConPrefisso(_prefisso, testoSessione);
        _testoController
          ..text = testo
          ..selection = TextSelection.collapsed(offset: testo.length);
      },
      onErrore: (messaggio) {
        if (!mounted) return;
        setState(() => _erroreMicrofono = messaggio);
      },
      onFine: () {
        if (!mounted) return;
        setState(() => _inAscolto = false);
      },
    );
    setState(() => _inAscolto = true);
    _dettatore!.avvia();
  }

  Future<void> _trasforma() async {
    final testo = _testoController.text.trim();
    if (testo.isEmpty) {
      setState(() => _errore = 'Detta o scrivi prima le serie');
      return;
    }
    _dettatore?.ferma();
    setState(() {
      _inCorso = true;
      _errore = null;
    });

    final allenamento = widget.allenamento;
    final gruppi = ref.read(gruppiListProvider(allenamento.clubId));
    final nomeGruppo = allenamento.gruppoId == null
        ? null
        : gruppi.value
              ?.where((g) => g.id == allenamento.gruppoId)
              .firstOrNull
              ?.nome;

    try {
      final scheda = await ref
          .read(generazioneAiRepositoryProvider)
          .generaDaDettatura(
            testo: testo,
            clubId: allenamento.clubId,
            gruppo: nomeGruppo,
          );
      try {
        await ref
            .read(generazioniAiRepositoryProvider)
            .registraGenerazione(
              clubId: allenamento.clubId,
              parametri: {
                'modalita': 'dettatura',
                'testo': testo,
                'gruppo': ?nomeGruppo,
                'allenamentoId': allenamento.id,
              },
              esito: 'successo',
              scheda: scheda.toMap(),
            );
      } catch (_) {}
      if (!mounted) return;
      if (scheda.serie.isEmpty) {
        setState(
          () => _errore = 'Non ho trovato serie in quello che hai detto',
        );
        return;
      }
      Navigator.of(context).pop(testoDaSerieDettate(scheda.serie));
    } catch (e) {
      if (!mounted) return;
      setState(() => _errore = messaggioErrore(e));
    } finally {
      if (mounted) setState(() => _inCorso = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    final microfono = DettatoreVocale.disponibile;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.s16,
        0,
        AppSpacing.s16,
        AppSpacing.s16 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Detta o descrivi a parole',
              style: AppTypography.sezione.copyWith(color: colori.testo),
            ),
            const SizedBox(height: AppSpacing.s8),
            Text(
              microfono
                  ? 'Come lo diresti a bordo vasca: "riscaldamento 400 misti, '
                        'poi 8 volte 100 soglia con 20 di recupero". Le serie '
                        'si aggiungono in fondo al testo, da controllare.'
                  : 'Il microfono qui non c\'è (funziona su Chrome): '
                        'descrivi le serie a parole, le trasformo io. Si '
                        'aggiungono in fondo al testo, da controllare.',
              style: AppTypography.piccolo.copyWith(
                color: colori.testoSecondario,
              ),
            ),
            const SizedBox(height: AppSpacing.s16),
            AppTextField(
              etichetta: microfono ? 'Testo dettato (modificabile)' : 'Serie',
              controller: _testoController,
              maxLines: 5,
            ),
            if (microfono) ...[
              const SizedBox(height: AppSpacing.s12),
              Center(
                child: IconButton.filled(
                  iconSize: 32,
                  padding: const EdgeInsets.all(AppSpacing.s16),
                  style: IconButton.styleFrom(
                    backgroundColor: _inAscolto ? colori.rosso : colori.azione,
                  ),
                  icon: Icon(
                    _inAscolto ? Icons.stop : Icons.mic,
                    color: colori.azioneInk,
                  ),
                  tooltip: _inAscolto
                      ? 'Ferma la dettatura'
                      : 'Inizia a dettare',
                  onPressed: _inCorso ? null : _alternaAscolto,
                ),
              ),
              if (_inAscolto)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.s8),
                  child: Text(
                    'Sto ascoltando...',
                    textAlign: TextAlign.center,
                    style: AppTypography.piccolo.copyWith(
                      color: colori.testoSecondario,
                    ),
                  ),
                ),
              if (_erroreMicrofono != null)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.s8),
                  child: Text(
                    _erroreMicrofono!,
                    textAlign: TextAlign.center,
                    style: AppTypography.piccolo.copyWith(color: colori.rosso),
                  ),
                ),
            ],
            if (_errore != null) ...[
              const SizedBox(height: AppSpacing.s12),
              ErrorBanner(messaggio: _errore!),
            ],
            const SizedBox(height: AppSpacing.s16),
            PrimaryButton(
              label: _inCorso ? 'Sto leggendo...' : 'Trasforma in serie',
              isLoading: _inCorso,
              onPressed: _inCorso ? null : _trasforma,
            ),
            if (_inCorso) const AttesaAiHint(),
          ],
        ),
      ),
    );
  }
}
