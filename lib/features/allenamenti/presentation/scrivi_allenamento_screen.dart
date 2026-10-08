import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/utils/error_messages.dart';
import '../../../theme/app_layout.dart';
import '../../../theme/app_spacing.dart';
import '../../../widgets/app_scaffold.dart';
import '../../../widgets/error_banner.dart';
import '../application/passo_riferimento_provider.dart';
import '../data/serie_repository.dart';
import '../domain/allenamento.dart';
import '../domain/piano_salvataggio_testo.dart';
import '../domain/serie.dart';
import '../domain/testo_allenamento.dart';
import 'editor_testo_allenamento.dart';

/// Scrivere l'allenamento come su un foglio, una serie per riga (idea
/// presa dall'editor di Swimtraxx Hub): l'app capisce ogni riga mentre
/// la si scrive — senza AI, anche offline — e mostra accanto le serie,
/// i metri, la durata stimata e la forma della seduta.
///
/// Il testo **è** l'allenamento: si apre con le serie che ci sono già, e
/// "Salva" le rimette come sono scritte (toccando solo le righe che
/// cambiano, vedi [pianoSalvataggio]). Niente AI, nemmeno per la voce: il
/// dettato del browser finisce nel testo ([EditorTestoAllenamento]).
class ScriviAllenamentoScreen extends ConsumerStatefulWidget {
  const ScriviAllenamentoScreen({
    required this.allenamento,
    required this.serie,
    super.key,
  });

  final Allenamento allenamento;

  /// Le serie salvate ora, nell'ordine.
  final List<Serie> serie;

  @override
  ConsumerState<ScriviAllenamentoScreen> createState() =>
      _ScriviAllenamentoScreenState();
}

class _ScriviAllenamentoScreenState
    extends ConsumerState<ScriviAllenamentoScreen> {
  late final String _testoIniziale = testoDaSerie(widget.serie);
  late final _controller = TextEditingController(text: _testoIniziale)
    ..addListener(_aggiorna);
  final _editorKey = GlobalKey<EditorTestoAllenamentoState>();
  bool _salvataggio = false;
  bool _salvato = false;
  String? _errore;

  bool get _modificato => _controller.text != _testoIniziale;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _aggiorna() => setState(() {});

  Future<bool> _conferma(String titolo, String testo, String azione) async {
    final risposta = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(titolo),
        content: Text(testo),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annulla'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(azione),
          ),
        ],
      ),
    );
    return risposta ?? false;
  }

  Future<void> _salva() async {
    _editorKey.currentState?.ferma();
    final scritto = interpretaAllenamento(_controller.text);
    final nonCapite = scritto.righeNonCapite;
    if (nonCapite > 0 &&
        !await _conferma(
          nonCapite == 1
              ? 'Una riga non è stata capita'
              : '$nonCapite righe non sono state capite',
          'Sono quelle segnate in rosso: se salvi ora non diventano serie.',
          'Salva lo stesso',
        )) {
      return;
    }
    if (scritto.serie.isEmpty &&
        widget.serie.isNotEmpty &&
        !await _conferma(
          'Togliere tutte le serie?',
          "Nel testo non c'è più nessuna serie: salvando, l'allenamento "
              'resta vuoto.',
          'Togli tutte',
        )) {
      return;
    }
    if (!mounted) return;

    final piano = pianoSalvataggio(
      vecchie: widget.serie,
      nuove: scritto.serie,
      nuovoId: () => const Uuid().v4(),
    );
    setState(() {
      _salvataggio = true;
      _errore = null;
    });
    final repository = ref.read(serieRepositoryProvider);
    try {
      for (final a in piano.aggiorna) {
        final s = a.nuova;
        await repository.updateSerie(
          id: a.vecchia.id,
          ordine: a.ordine,
          blocco: s.blocco,
          ripetute: s.ripetute,
          distanzaM: s.distanzaM,
          durataS: s.durataS,
          stile: s.stile,
          esecuzione: s.esecuzione,
          zona: s.zona,
          passoObiettivoS: s.passoObiettivoS,
          recuperoS: s.recuperoS,
          ripartenzaS: s.ripartenzaS,
          attrezzatura: s.attrezzatura,
          note: s.note,
          piramide: (id: a.piramideId),
        );
      }
      for (final c in piano.crea) {
        final s = c.nuova;
        await repository.createSerie(
          allenamentoId: widget.allenamento.id,
          ordine: c.ordine,
          blocco: s.blocco,
          ripetute: s.ripetute,
          distanzaM: s.distanzaM,
          durataS: s.durataS,
          stile: s.stile,
          esecuzione: s.esecuzione,
          zona: s.zona,
          passoObiettivoS: s.passoObiettivoS,
          recuperoS: s.recuperoS,
          ripartenzaS: s.ripartenzaS,
          attrezzatura: s.attrezzatura,
          note: s.note,
          piramideId: c.piramideId,
        );
      }
      for (final s in piano.elimina) {
        await repository.deleteSerie(s.id);
      }
      if (!mounted) return;
      setState(() => _salvato = true);
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(
        () => _errore =
            'Salvataggio non finito: ${messaggioErrore(e)}. Riprova: le '
            'serie già salvate non si duplicano.',
      );
    } finally {
      if (mounted) setState(() => _salvataggio = false);
    }
  }

  Future<void> _esci() async {
    if (await _conferma(
          'Uscire senza salvare?',
          'Le modifiche al testo andranno perse.',
          'Esci',
        ) &&
        mounted) {
      setState(() => _salvato = true);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final scritto = interpretaAllenamento(_controller.text);
    final riferimento = ref.watch(
      passoRiferimentoProvider((
        clubId: widget.allenamento.clubId,
        gruppoId: widget.allenamento.gruppoId,
      )),
    );

    return PopScope(
      canPop: !_modificato || _salvato,
      onPopInvokedWithResult: (fatto, _) {
        if (!fatto) _esci();
      },
      child: AppScaffold(
        scrollabile: true,
        larghezzaMassima: AppLayout.larghezzaMassimaContenuto,
        appBar: AppBar(
          title: const Text("Scrivi l'allenamento"),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.s8),
              child: TextButton(
                onPressed: _modificato && !_salvataggio ? _salva : null,
                child: _salvataggio
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Salva'),
              ),
            ),
          ],
          bottom: BarraTotali(scritto: scritto, riferimento: riferimento),
        ),
        body: EditorTestoAllenamento(
          key: _editorKey,
          controller: _controller,
          scritto: scritto,
          riferimento: riferimento,
          sottoIlTesto: [
            if (_errore != null) ...[
              const SizedBox(height: AppSpacing.s12),
              ErrorBanner(messaggio: _errore!),
            ],
          ],
        ),
      ),
    );
  }
}
