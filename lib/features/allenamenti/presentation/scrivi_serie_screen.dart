import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/dettatura/dettatura_vocale.dart';
import '../../../core/dettatura/testo_con_prefisso.dart';
import '../../../core/utils/error_messages.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../theme/colori_app.dart';
import '../../../widgets/app_scaffold.dart';
import '../../../widgets/app_text_field.dart';
import '../../../widgets/error_banner.dart';
import '../../../widgets/form_group.dart';
import '../../../widgets/primary_button.dart';
import '../../../widgets/secondary_button.dart';
import '../../ai_genera/application/corsie_service.dart';
import '../../ai_genera/data/generazione_ai_repository.dart';
import '../../ai_genera/data/generazioni_ai_repository.dart';
import '../../ai_genera/domain/scheda_generata.dart';
import '../../gruppi/application/gruppi_providers.dart';
import '../data/serie_repository.dart';
import '../domain/allenamento.dart';
import 'serie_labels.dart';

/// Scrivi (o detta) più serie insieme, invece di comporle una per volta
/// dal form strutturato o riga per riga dal campo rapido (richiesta del
/// coach 2026-09-22: "così è più facile scrivere le serie e
/// modificarle, piuttosto che creare un allenamento da zero").
///
/// Stessa interpretazione di [DettaAllenamentoFormScreen] (stesso motore
/// di dettatura, stessa Edge Function `detta-allenamento`), ma qui il
/// risultato si AGGIUNGE a un allenamento che esiste già invece di
/// crearne uno nuovo: niente titolo/data da scegliere, solo le serie.
class ScriviSerieScreen extends ConsumerStatefulWidget {
  const ScriviSerieScreen({
    required this.allenamento,
    required this.ordineSuccessivo,
    super.key,
  });

  final Allenamento allenamento;

  /// Ordine da assegnare alla prima serie aggiunta: le successive
  /// continuano da qui, nell'ordine in cui sono state dettate.
  final int ordineSuccessivo;

  @override
  ConsumerState<ScriviSerieScreen> createState() => _ScriviSerieScreenState();
}

class _ScriviSerieScreenState extends ConsumerState<ScriviSerieScreen> {
  final _testoController = TextEditingController();
  bool _interpretazioneInCorso = false;
  bool _aggiuntaInCorso = false;
  String? _errore;
  SchedaGenerata? _anteprima;

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
        _aggiornaCampo(testoConPrefisso(_prefisso, testoSessione));
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

  void _aggiornaCampo(String testo) {
    _testoController
      ..text = testo
      ..selection = TextSelection.collapsed(offset: testo.length);
  }

  Future<void> _interpreta() async {
    final testo = _testoController.text.trim();
    if (testo.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Scrivi o detta prima le serie')),
      );
      return;
    }
    _dettatore?.ferma();
    setState(() {
      _interpretazioneInCorso = true;
      _errore = null;
    });

    final gruppi = ref.read(gruppiListProvider(widget.allenamento.clubId));
    final nomeGruppo = widget.allenamento.gruppoId == null
        ? null
        : gruppi.value
              ?.where((g) => g.id == widget.allenamento.gruppoId)
              .firstOrNull
              ?.nome;

    try {
      final scheda = await ref
          .read(generazioneAiRepositoryProvider)
          .generaDaDettatura(testo: testo, gruppo: nomeGruppo);
      try {
        await ref
            .read(generazioniAiRepositoryProvider)
            .registraGenerazione(
              clubId: widget.allenamento.clubId,
              parametri: {
                'modalita': 'dettatura',
                'testo': testo,
                'gruppo': ?nomeGruppo,
                'allenamentoId': widget.allenamento.id,
              },
              esito: 'successo',
              scheda: scheda.toMap(),
            );
      } catch (_) {}
      if (!mounted) return;
      setState(() => _anteprima = scheda);
    } catch (e) {
      if (!mounted) return;
      setState(() => _errore = messaggioErrore(e));
    } finally {
      if (mounted) setState(() => _interpretazioneInCorso = false);
    }
  }

  Future<void> _aggiungiSerie() async {
    final scheda = _anteprima;
    if (scheda == null) return;
    setState(() {
      _aggiuntaInCorso = true;
      _errore = null;
    });
    final serieRepository = ref.read(serieRepositoryProvider);
    var aggiunte = 0;
    try {
      for (final s in scheda.serie) {
        final risolto = risolviRipartenza(s.ripartenzePerCorsia, s.note);
        await serieRepository.createSerie(
          allenamentoId: widget.allenamento.id,
          ordine: widget.ordineSuccessivo + aggiunte,
          blocco: s.blocco,
          ripetute: s.ripetute,
          distanzaM: s.distanzaM,
          stile: s.stile,
          esecuzione: s.esecuzione,
          zona: s.zona,
          recuperoS: s.recuperoS,
          ripartenzaS: risolto.ripartenzaS,
          attrezzatura: s.attrezzatura,
          note: risolto.note,
        );
        aggiunte++;
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errore = aggiunte == 0
            ? messaggioErrore(e)
            : 'Aggiunte $aggiunte serie su ${scheda.serie.length}, poi: '
                  '${messaggioErrore(e)}';
      });
    } finally {
      if (mounted) setState(() => _aggiuntaInCorso = false);
    }
  }

  String _sottotitoloSerie(SerieGenerata s) {
    final parti = <String>[labelBlocco(s.blocco)];
    if (s.zona != null) parti.add('zona ${s.zona}');
    if (s.recuperoS != null) parti.add("rec ${s.recuperoS}''");
    if (s.attrezzatura != null && s.attrezzatura!.isNotEmpty) {
      parti.add(s.attrezzatura!);
    }
    return parti.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    final microfonoDisponibile = DettatoreVocale.disponibile;
    final anteprima = _anteprima;

    return AppScaffold(
      scrollabile: true,
      appBar: AppBar(title: const Text('Scrivi o detta le serie')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (anteprima == null) ...[
            Text(
              'Scrivi o detta più serie insieme, come faresti a bordo '
              'vasca: "riscaldamento 400 misti, poi 8 volte 100 stile '
              'libero soglia con 20 secondi di recupero". Si aggiungono '
              'a questo allenamento, dopo quelle già presenti.',
              style: AppTypography.piccolo.copyWith(
                color: colori.testoSecondario,
              ),
            ),
            const SizedBox(height: AppSpacing.s16),
            if (!microfonoDisponibile) ...[
              _AvvisoMicrofonoNonDisponibile(colori: colori),
              const SizedBox(height: AppSpacing.s12),
            ],
            FormGroup(
              titolo: 'Serie',
              isUltimo: true,
              campi: [
                AppTextField(
                  etichetta: microfonoDisponibile
                      ? 'Testo dettato (modificabile)'
                      : 'Descrivi le serie',
                  controller: _testoController,
                  maxLines: 8,
                ),
                if (microfonoDisponibile)
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton.filled(
                          iconSize: 36,
                          padding: const EdgeInsets.all(AppSpacing.s16),
                          style: IconButton.styleFrom(
                            backgroundColor: _inAscolto
                                ? colori.rosso
                                : colori.azione,
                          ),
                          icon: Icon(
                            _inAscolto ? Icons.stop : Icons.mic,
                            color: colori.azioneInk,
                          ),
                          tooltip: _inAscolto
                              ? 'Ferma la dettatura'
                              : 'Inizia a dettare',
                          onPressed: _alternaAscolto,
                        ),
                        const SizedBox(height: AppSpacing.s8),
                        if (_inAscolto)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.circle, size: 10, color: colori.rosso),
                              const SizedBox(width: AppSpacing.s8),
                              Text(
                                'Sto ascoltando...',
                                style: AppTypography.piccolo.copyWith(
                                  color: colori.testoSecondario,
                                ),
                              ),
                            ],
                          ),
                        if (_erroreMicrofono != null)
                          Padding(
                            padding: const EdgeInsets.only(top: AppSpacing.s8),
                            child: Text(
                              _erroreMicrofono!,
                              textAlign: TextAlign.center,
                              style: AppTypography.piccolo.copyWith(
                                color: colori.rosso,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
            if (_errore != null) ...[
              const SizedBox(height: AppSpacing.s12),
              ErrorBanner(messaggio: _errore!),
            ],
            const SizedBox(height: AppSpacing.s24),
            PrimaryButton(
              label: _interpretazioneInCorso ? 'Sto leggendo...' : 'Interpreta',
              isLoading: _interpretazioneInCorso,
              onPressed: _interpretazioneInCorso ? null : _interpreta,
            ),
          ] else ...[
            Text(
              '${anteprima.serie.length} serie interpretate. Controllale, '
              'poi «Aggiungi»: se qualcosa non torna, «Torna indietro» e '
              'correggi il testo.',
              style: AppTypography.piccolo.copyWith(
                color: colori.testoSecondario,
              ),
            ),
            const SizedBox(height: AppSpacing.s16),
            for (final s in anteprima.serie)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.s4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${s.ordine}. ${s.ripetute}×${s.distanzaM}m '
                      '${labelStile(s.stile)} ${labelEsecuzione(s.esecuzione)}',
                      style: AppTypography.corpoForte.copyWith(
                        color: colori.testo,
                      ),
                    ),
                    Text(
                      _sottotitoloSerie(s),
                      style: AppTypography.piccolo.copyWith(
                        color: colori.testoSecondario,
                      ),
                    ),
                  ],
                ),
              ),
            if (_errore != null) ...[
              const SizedBox(height: AppSpacing.s12),
              ErrorBanner(messaggio: _errore!),
            ],
            const SizedBox(height: AppSpacing.s24),
            PrimaryButton(
              label: _aggiuntaInCorso
                  ? 'Sto aggiungendo...'
                  : 'Aggiungi ${anteprima.serie.length} serie',
              isLoading: _aggiuntaInCorso,
              onPressed: _aggiuntaInCorso ? null : _aggiungiSerie,
            ),
            const SizedBox(height: AppSpacing.s8),
            SecondaryButton(
              label: 'Torna indietro e correggi il testo',
              onPressed: _aggiuntaInCorso
                  ? null
                  : () => setState(() => _anteprima = null),
            ),
          ],
        ],
      ),
    );
  }
}

class _AvvisoMicrofonoNonDisponibile extends StatelessWidget {
  const _AvvisoMicrofonoNonDisponibile({required this.colori});

  final ColoriApp colori;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s12),
      decoration: BoxDecoration(
        color: colori.superficieAlt,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colori.linea),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 20, color: colori.testoSecondario),
          const SizedBox(width: AppSpacing.s8),
          Expanded(
            child: Text(
              'Il microfono non è disponibile su questo browser (funziona '
              'su Chrome). Scrivi la descrizione qui sotto: verrà comunque '
              'trasformata in serie.',
              style: AppTypography.piccolo.copyWith(
                color: colori.testoSecondario,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
