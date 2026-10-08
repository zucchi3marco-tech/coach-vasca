import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/utils/error_messages.dart';
import '../../../theme/app_layout.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../theme/colori_app.dart';
import '../../../theme/tokens_dominio.dart';
import '../../../widgets/app_scaffold.dart';
import '../../../widgets/error_banner.dart';
import '../../../widgets/secondary_button.dart';
import '../data/serie_repository.dart';
import '../domain/allenamento.dart';
import '../domain/durata_serie.dart';
import '../domain/piano_salvataggio_testo.dart';
import '../domain/riordino_serie.dart';
import '../domain/serie.dart';
import '../domain/testo_allenamento.dart';
import 'detta_serie_sheet.dart';
import 'grafico_intensita.dart';
import 'riepilogo_volumi.dart';
import 'serie_labels.dart';

/// Scrivere l'allenamento come su un foglio, una serie per riga (idea
/// presa dall'editor di Swimtraxx Hub): l'app capisce ogni riga mentre
/// la si scrive — senza AI, anche offline — e mostra accanto le serie,
/// i metri, la durata stimata e la forma della seduta.
///
/// Il testo **è** l'allenamento: si apre con le serie che ci sono già, e
/// "Salva" le rimette come sono scritte (toccando solo le righe che
/// cambiano, vedi [pianoSalvataggio]). L'AI resta per quello che si
/// detta a voce o si descrive a parole ([mostraDettaSerie]): torna righe
/// di testo, da controllare come le altre.
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

  Future<void> _detta() async {
    final righe = await mostraDettaSerie(
      context,
      allenamento: widget.allenamento,
    );
    if (righe == null || righe.isEmpty || !mounted) return;
    final prima = _controller.text.trimRight();
    final testo = prima.isEmpty ? righe : '$prima\n\n$righe';
    _controller.value = TextEditingValue(
      text: testo,
      selection: TextSelection.collapsed(offset: testo.length),
    );
  }

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

  /// La riga dove sta il cursore, per dire subito come è stata capita.
  RigaScritta? _rigaCorrente(AllenamentoScritto scritto) {
    final selezione = _controller.selection;
    if (!selezione.isValid) return null;
    final fine = selezione.baseOffset.clamp(0, _controller.text.length);
    final indice = '\n'.allMatches(_controller.text.substring(0, fine)).length;
    return indice < scritto.righe.length ? scritto.righe[indice] : null;
  }

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    final scritto = interpretaAllenamento(_controller.text);
    final corrente = _rigaCorrente(scritto);

    final editor = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Riepilogo(scritto: scritto),
        const SizedBox(height: AppSpacing.s16),
        Text(
          'Una serie per riga',
          style: AppTypography.etichetta.copyWith(
            color: colori.testoSecondario,
          ),
        ),
        const SizedBox(height: AppSpacing.s8),
        TextField(
          key: const Key('testo-allenamento'),
          controller: _controller,
          keyboardType: TextInputType.multiline,
          minLines: 10,
          maxLines: null,
          autocorrect: false,
          enableSuggestions: false,
          style: AppTypography.numerica(AppTypography.corpo)
              .copyWith(color: colori.testo),
          decoration: const InputDecoration(
            hintText:
                'Riscaldamento\n400 mi A1\n\nPrincipale\n2x\n'
                '4x100 sl B1 @1:40\n4x50 do r15\n\n200 sl sciolto',
            hintMaxLines: 9,
          ),
        ),
        if (corrente != null && corrente.tipo != TipoRiga.vuota)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.s8),
            child: Text(
              _comeCapita(corrente),
              style: AppTypography.piccolo.copyWith(
                color: corrente.tipo == TipoRiga.errore
                    ? colori.rosso
                    : colori.testoSecondario,
              ),
            ),
          ),
        const SizedBox(height: AppSpacing.s12),
        SecondaryButton(
          label: 'Detta o descrivi a parole',
          icon: Icons.mic_none_outlined,
          onPressed: _salvataggio ? null : _detta,
        ),
        if (_errore != null) ...[
          const SizedBox(height: AppSpacing.s12),
          ErrorBanner(messaggio: _errore!),
        ],
      ],
    );
    final anteprima = _Anteprima(scritto: scritto);

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
            IconButton(
              tooltip: 'Come si scrive',
              icon: const Icon(Icons.help_outline),
              onPressed: () => _mostraAiuto(context),
            ),
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
        ),
        body: LayoutBuilder(
          builder: (context, vincoli) {
            if (vincoli.maxWidth < 840) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  editor,
                  const SizedBox(height: AppSpacing.s24),
                  anteprima,
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: editor),
                const SizedBox(width: AppSpacing.s24),
                Expanded(child: anteprima),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// "8×100m Libero · B1 · rip 1:30" per la riga sotto il cursore.
String _comeCapita(RigaScritta riga) => switch (riga.tipo) {
  TipoRiga.vuota => '',
  TipoRiga.titolo => 'Inizia il blocco ${labelBlocco(riga.blocco!)}',
  TipoRiga.giri =>
    'Ripete ${riga.giri} volte le righe sotto, fino alla prima riga vuota',
  TipoRiga.errore => riga.problema!,
  TipoRiga.serie => [
    if (riga.serie.length > 1)
      titoloGruppo(riga.serie)
    else
      titoloSerie(riga.serie.single),
    ...dettagliSerie(riga.serie.first),
  ].join(' · '),
};

class _Riepilogo extends StatelessWidget {
  const _Riepilogo({required this.scritto});

  final AllenamentoScritto scritto;

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    final serie = scritto.serie;
    final numero = AppTypography.numerica(AppTypography.corpoForte)
        .copyWith(color: colori.testo);
    final etichetta = AppTypography.piccolo.copyWith(
      color: colori.testoSecondario,
    );
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s16),
      decoration: BoxDecoration(
        color: colori.superficie,
        borderRadius: BorderRadius.circular(AppRadius.pannello),
        border: Border.all(color: colori.linea),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '${formattaMetri(scritto.metri)} m',
                  style: numero,
                ),
                TextSpan(text: '   circa ', style: etichetta),
                TextSpan(text: "${minutiStimati(serie)}'", style: numero),
                TextSpan(text: '   ', style: etichetta),
                TextSpan(
                  text: '${raggruppaPerPiramide(serie).length}',
                  style: numero,
                ),
                TextSpan(text: ' serie', style: etichetta),
              ],
            ),
          ),
          if (serie.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.s12),
            GraficoIntensita(serie: serie),
          ],
        ],
      ),
    );
  }
}

/// Come è stato capito il testo, riga per riga: i titoli dei blocchi, i
/// "2x" con le serie che ripetono, le righe non capite in rosso.
class _Anteprima extends StatelessWidget {
  const _Anteprima({required this.scritto});

  final AllenamentoScritto scritto;

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    final righe = scritto.righe.where((r) => r.tipo != TipoRiga.vuota);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Come le ho capite',
          style: AppTypography.sezione.copyWith(color: colori.testo),
        ),
        const SizedBox(height: AppSpacing.s8),
        if (righe.isEmpty)
          Text(
            'Scrivi la prima serie, per esempio "400 sl A1": qui compare '
            'subito come la leggo.',
            style: AppTypography.piccolo.copyWith(
              color: colori.testoSecondario,
            ),
          ),
        for (final riga in righe) _RigaAnteprima(riga: riga),
      ],
    );
  }
}

class _RigaAnteprima extends StatelessWidget {
  const _RigaAnteprima({required this.riga});

  final RigaScritta riga;

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    switch (riga.tipo) {
      case TipoRiga.vuota:
        return const SizedBox.shrink();
      case TipoRiga.titolo:
        return Padding(
          padding: const EdgeInsets.only(
            top: AppSpacing.s12,
            bottom: AppSpacing.s4,
          ),
          child: Text(
            labelBlocco(riga.blocco!),
            style: AppTypography.corpoForte.copyWith(color: colori.testo),
          ),
        );
      case TipoRiga.giri:
        return Padding(
          padding: const EdgeInsets.only(top: AppSpacing.s8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.s8,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: colori.azioneTenue,
                  borderRadius: BorderRadius.circular(AppRadius.pillola),
                ),
                child: Text(
                  '${riga.giri}×',
                  style: AppTypography.numerica(AppTypography.etichetta)
                      .copyWith(color: colori.testo),
                ),
              ),
              const SizedBox(width: AppSpacing.s8),
              Text(
                'si ripete ${riga.giri} volte',
                style: AppTypography.piccolo.copyWith(
                  color: colori.testoSecondario,
                ),
              ),
            ],
          ),
        );
      case TipoRiga.errore:
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.s4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.error_outline, size: 20, color: colori.rosso),
              const SizedBox(width: AppSpacing.s8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      riga.testo.trim(),
                      style: AppTypography.corpo.copyWith(color: colori.testo),
                    ),
                    Text(
                      '${riga.problema}: non diventa una serie',
                      style: AppTypography.piccolo.copyWith(
                        color: colori.rosso,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      case TipoRiga.serie:
        final prima = riga.serie.first;
        final titolo = riga.serie.length > 1
            ? titoloGruppo(riga.serie)
            : titoloSerie(prima);
        final dettagli = dettagliSerie(prima);
        final coloreZona = context.dominio.colorePerZona(
          prima.zona,
          rispetto: colori.linea,
        );
        final dentroGiro = riga.giri > 1;
        return Container(
          margin: EdgeInsets.only(
            left: dentroGiro ? AppSpacing.s12 : 0,
            top: AppSpacing.s4,
          ),
          padding: const EdgeInsets.only(left: AppSpacing.s12),
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: coloreZona, width: 3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titolo,
                style: AppTypography.corpoForte.copyWith(color: colori.testo),
              ),
              if (dettagli.isNotEmpty)
                Text(
                  dettagli.join(' · '),
                  style: AppTypography.piccolo.copyWith(
                    color: colori.testoSecondario,
                  ),
                ),
              if (prima.note case final nota?)
                Text(
                  riga.paroleIgnote.isEmpty
                      ? 'Nota: $nota'
                      : 'Nota (parole non riconosciute): $nota',
                  style: AppTypography.piccolo.copyWith(
                    color: riga.paroleIgnote.isEmpty
                        ? colori.testoSecondario
                        : colori.attenzione,
                  ),
                ),
            ],
          ),
        );
    }
  }
}

void _mostraAiuto(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (context) {
      final colori = context.colori;
      final voci = <(String, String)>[
        ('400 sl', 'una distanza: 400 metri stile libero'),
        ('8x100', 'ripetute per distanza'),
        ("10'  3x5'  6x30''", 'serie a tempo'),
        ('50-100-200', 'piramide: una distanza dopo l\'altra'),
        ('2x(50-100) r15 r60', 'piramide a giri: recupero fra i giri'),
        ('2x  (da solo)', 'ripete le righe sotto fino alla riga vuota'),
        (
          'Riscaldamento',
          'titolo: apre il blocco (anche Principale, '
              'Defaticamento, Altro)',
        ),
        ('sl do ra df mi', 'stile'),
        (
          'gambe braccia pull tecnica remate tecnico-tattico a-secco',
          'esecuzione',
        ),
        ('A1 A2 B1 B2 C1 C2 C3 D', 'zona'),
        ('1:25', 'passo sui 100'),
        ('@1:30', 'ripartenza'),
        ('r15  r1:00', 'recupero'),
        ('pinne palette  [pinne corte]', 'attrezzi'),
        ('"testo"', 'nota; anche le parole che non conosco finiscono qui'),
      ];
      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.s16,
          0,
          AppSpacing.s16,
          AppSpacing.s24,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Come si scrive',
              style: AppTypography.sezione.copyWith(color: colori.testo),
            ),
            const SizedBox(height: AppSpacing.s8),
            Text(
              "Una serie per riga, le parole in qualsiasi ordine. Mentre "
              "scrivi, sotto il testo leggi come ho capito la riga.",
              style: AppTypography.piccolo.copyWith(
                color: colori.testoSecondario,
              ),
            ),
            const SizedBox(height: AppSpacing.s12),
            for (final (esempio, significato) in voci)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.s4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 150,
                      child: Text(
                        esempio,
                        style: AppTypography.numerica(AppTypography.corpoForte)
                            .copyWith(color: colori.testo),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.s12),
                    Expanded(
                      child: Text(
                        significato,
                        style: AppTypography.piccolo.copyWith(
                          color: colori.testoSecondario,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      );
    },
  );
}
