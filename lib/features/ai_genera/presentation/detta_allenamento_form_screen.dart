import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/dettatura/dettatura_vocale.dart';
import '../../../core/dettatura/testo_con_prefisso.dart';
import '../../../core/utils/error_messages.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../theme/colori_app.dart';
import '../../../widgets/app_scaffold.dart';
import '../../../widgets/app_select.dart';
import '../../../widgets/app_text_field.dart';
import '../../../widgets/attesa_ai_hint.dart';
import '../../../widgets/form_group.dart';
import '../../../widgets/primary_button.dart';
import '../../allenamenti/domain/allenamento.dart';
import '../../allenamenti/presentation/allenamento_detail_screen.dart';
import '../../gruppi/application/gruppi_providers.dart';
import '../data/generazione_ai_repository.dart';
import '../data/generazioni_ai_repository.dart';
import 'scheda_generata_screen.dart';
import 'storico_generazioni_screen.dart';

/// Alternativa al form "Genera con AI" (`GeneraAllenamentoFormScreen`): il
/// coach detta a voce l'allenamento, invece di scegliere volume/focus/
/// regimi da un form, e Gemini lo trascrive nella stessa scheda
/// strutturata ([SchedaGenerata]) — stessa Edge Function nel senso di
/// isolare la chiave del provider lato server, stessa schermata di
/// anteprima/conferma ([SchedaGenerataScreen]).
///
/// Il riconoscimento vocale è gratuito (Web Speech API del browser) ma
/// disponibile solo su Chrome/Edge: altrove il campo resta scrivibile a
/// mano (`_MicrofonoNonDisponibile`), la dettatura è un di più, non un
/// requisito per usare la schermata.
class DettaAllenamentoFormScreen extends ConsumerStatefulWidget {
  const DettaAllenamentoFormScreen({
    required this.clubId,
    this.dataPredefinita,
    super.key,
  });

  final String clubId;
  final DateTime? dataPredefinita;

  @override
  ConsumerState<DettaAllenamentoFormScreen> createState() =>
      _DettaAllenamentoFormScreenState();
}

class _DettaAllenamentoFormScreenState
    extends ConsumerState<DettaAllenamentoFormScreen> {
  final _testoController = TextEditingController();
  String? _gruppoId;
  bool _generazioneInCorso = false;
  String? _erroreMicrofono;

  DettatoreVocale? _dettatore;
  bool _inAscolto = false;

  /// Cosa c'era già scritto nel campo prima di premere il microfono
  /// (testo digitato a mano, o rimasto da una dettatura precedente): un
  /// prefisso fisso su cui si affianca il testo della sessione corrente,
  /// che `DettatoreVocale` ricostruisce sempre per intero ad ogni
  /// aggiornamento (mai da sommare qui) — vedi `dettatura_vocale_web.dart`.
  String _prefisso = '';

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
    // Riparte da quello che c'è già nel campo (compresi eventuali ritocchi
    // fatti a mano fra una dettatura e l'altra): resta fisso per tutta la
    // sessione, il testo dettato si affianca ma non lo sovrascrive.
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

  @override
  Widget build(BuildContext context) {
    final gruppi = ref.watch(gruppiListProvider(widget.clubId)).value ?? [];
    final colori = context.colori;
    final microfonoDisponibile = DettatoreVocale.disponibile;

    return AppScaffold(
      scrollabile: true,
      appBar: AppBar(
        title: const Text('Detta allenamento'),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => StoricoGenerazioniScreen(clubId: widget.clubId),
              ),
            ),
            icon: const Icon(Icons.history, size: 20),
            label: const Text('Storico'),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Parla come faresti a bordo vasca: "riscaldamento 400 misti, '
            'poi 8 volte 100 stile libero soglia con 20 secondi di '
            'recupero, poi 200 defaticamento". Rivedi il testo prima di '
            'generare: puoi correggerlo a mano.',
            style: AppTypography.piccolo.copyWith(
              color: colori.testoSecondario,
            ),
          ),
          const SizedBox(height: AppSpacing.s16),
          FormGroup(
            titolo: 'Gruppo',
            campi: [
              AppSelect<String?>(
                etichetta: 'Gruppo',
                value: _gruppoId,
                hint: 'Tutti gli atleti',
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('Tutti gli atleti'),
                  ),
                  for (final g in gruppi)
                    DropdownMenuItem(value: g.id, child: Text(g.nome)),
                ],
                onChanged: (value) => setState(() => _gruppoId = value),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s16),
          if (!microfonoDisponibile) ...[
            _AvvisoMicrofonoNonDisponibile(colori: colori),
            const SizedBox(height: AppSpacing.s12),
          ],
          FormGroup(
            titolo: 'Dettatura',
            isUltimo: true,
            campi: [
              AppTextField(
                etichetta: microfonoDisponibile
                    ? 'Testo dettato (modificabile)'
                    : 'Descrivi l\'allenamento',
                controller: _testoController,
                maxLines: 8,
                aiuto: microfonoDisponibile
                    ? null
                    : 'Il microfono non è disponibile su questo browser: '
                          'scrivi qui la descrizione.',
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
          const SizedBox(height: AppSpacing.s24),
          PrimaryButton(
            label: _generazioneInCorso ? 'Sto generando...' : 'Genera',
            isLoading: _generazioneInCorso,
            onPressed: _generazioneInCorso ? null : _conferma,
          ),
          if (_generazioneInCorso) const AttesaAiHint(),
        ],
      ),
    );
  }

  Future<void> _conferma() async {
    final testo = _testoController.text.trim();
    if (testo.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Detta o scrivi prima l\'allenamento')),
      );
      return;
    }
    _dettatore?.ferma();

    final Map<String, String> nomiGruppi = {
      for (final g in ref.read(gruppiListProvider(widget.clubId)).value ?? [])
        g.id: g.nome,
    };
    final nomeGruppo = nomiGruppi[_gruppoId];

    setState(() => _generazioneInCorso = true);

    final parametriStorico = {
      'modalita': 'dettatura',
      'testo': testo,
      'gruppo': ?nomeGruppo,
    };

    try {
      final scheda = await ref
          .read(generazioneAiRepositoryProvider)
          .generaDaDettatura(testo: testo, gruppo: nomeGruppo);

      // Lo storico e' un di piu' per rivedere/migliorare i prompt: un suo
      // fallimento non deve mai bloccare una generazione riuscita.
      String? generazioneId;
      try {
        generazioneId = await ref
            .read(generazioniAiRepositoryProvider)
            .registraGenerazione(
              clubId: widget.clubId,
              parametri: parametriStorico,
              esito: 'successo',
              scheda: scheda.toMap(),
            );
      } catch (_) {}

      if (!mounted) return;
      final allenamentoSalvato = await Navigator.of(context).push<Allenamento>(
        MaterialPageRoute(
          builder: (_) => SchedaGenerataScreen(
            scheda: scheda,
            clubId: widget.clubId,
            gruppoId: _gruppoId,
            dataIniziale: widget.dataPredefinita,
            generazioneId: generazioneId,
          ),
        ),
      );
      if (allenamentoSalvato != null && mounted) {
        await Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) =>
                AllenamentoDetailScreen(allenamento: allenamentoSalvato),
          ),
        );
      }
    } catch (e) {
      try {
        await ref
            .read(generazioniAiRepositoryProvider)
            .registraGenerazione(
              clubId: widget.clubId,
              parametri: parametriStorico,
              esito: 'errore',
              messaggioErrore: e.toString(),
            );
      } catch (_) {}
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Errore nella dettatura: ${messaggioErrore(e)}'),
          duration: const Duration(seconds: 6),
          action: SnackBarAction(label: 'Riprova', onPressed: _conferma),
        ),
      );
    } finally {
      if (mounted) setState(() => _generazioneInCorso = false);
    }
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
              'trasformata in una scheda.',
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
