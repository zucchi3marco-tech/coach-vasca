import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/utils/date_italiane.dart';
import '../../../core/utils/error_messages.dart';
import '../../../core/utils/giorni.dart';
import '../../../core/utils/pace_format.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../theme/colori_app.dart';
import '../../../widgets/app_scaffold.dart';
import '../../../widgets/danger_button.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/error_banner.dart';
import '../../../widgets/loading_skeleton.dart';
import '../../../widgets/pool_card.dart';
import '../../../widgets/section_header.dart';
import '../../../widgets/testata_pagina.dart';
import '../../../widgets/tonal_chip.dart';
import '../../atleti/application/atleti_providers.dart';
import '../../atleti/domain/abbina_atleta.dart';
import '../../atleti/domain/atleta.dart';
import '../../benessere/application/benessere_providers.dart';
import '../../export/export_actions.dart';
import '../../gruppi/application/gruppi_providers.dart';
import '../../libreria_blocchi/data/training_blocks_repository.dart';
import '../../presenze/presentation/presenze_screen.dart';
import '../../secco/presentation/seduta_secco_screen.dart';
import '../application/allenamenti_providers.dart';
import '../application/passo_riferimento_provider.dart';
import '../data/allenamenti_repository.dart';
import '../data/copia_serie.dart';
import '../data/duplicazione_settimana_service.dart';
import '../data/serie_repository.dart';
import '../domain/allenamento.dart';
import '../domain/durata_serie.dart';
import '../domain/riordino_serie.dart';
import '../domain/serie.dart';
import '../domain/testo_allenamento.dart';
import '../domain/variante_spalla.dart';
import '../domain/volume_allenamento.dart';
import 'allenamento_form_screen.dart';
import 'avviso_seduta_aperta.dart';
import 'banner_modifica.dart';
import 'card_com_e_andata.dart';
import 'com_e_andata_screen.dart';
import 'duplica_allenamento_dialog.dart';
import 'grafico_intensita.dart';
import 'pannello_aggiungi_serie.dart';
import 'riepilogo_volumi.dart';
import 'momento_parallelo.dart';
import 'riga_gruppo_piramide.dart';
import 'nota_serie.dart';
import 'per_chi_serie.dart';
import 'riga_serie.dart';
import 'scheda_bordo_vasca_screen.dart';
import 'scrivi_allenamento_screen.dart';
import 'serie_form_screen.dart';
import 'serie_labels.dart';

class AllenamentoDetailScreen extends ConsumerStatefulWidget {
  const AllenamentoDetailScreen({required this.allenamento, super.key});

  final Allenamento allenamento;

  @override
  ConsumerState<AllenamentoDetailScreen> createState() =>
      _AllenamentoDetailScreenState();
}

class _AllenamentoDetailScreenState
    extends ConsumerState<AllenamentoDetailScreen> {
  String _bloccoRapido = 'principale';

  void _errore(Object e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(messaggioErrore(e))));
  }

  int _ordineSuccessivo() {
    final serie =
        ref.read(serieListProvider(widget.allenamento.id)).value ?? const [];
    return serie.fold<int>(0, (m, s) => s.ordine > m ? s.ordine : m) + 1;
  }

  /// Gli atleti di cui parlano le serie "per chi" (vedi
  /// [atletiDellAllenamento]).
  List<Atleta> _atleti() => atletiDellAllenamento(
    ref
            .read(
              atletiListProvider((
                clubId: widget.allenamento.clubId,
                includeInactive: true,
              )),
            )
            .value ??
        const [],
    gruppoId: widget.allenamento.gruppoId,
    serie: ref.read(serieListProvider(widget.allenamento.id)).value ?? const [],
  );

  void _apriSerieCompleta({required Serie? serie}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SerieFormScreen(
          allenamentoId: widget.allenamento.id,
          ordineSuccessivo: _ordineSuccessivo(),
          serie: serie,
          atleti: _atleti(),
        ),
      ),
    );
  }

  void _apriScriviAllenamento() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ScriviAllenamentoScreen(
          allenamento: widget.allenamento,
          serie:
              ref.read(serieListProvider(widget.allenamento.id)).value ??
              const [],
          atleti: _atleti(),
        ),
      ),
    );
  }

  void _apriPannello() {
    mostraPannelloAggiungiSerie(
      context,
      bloccoIniziale: _bloccoRapido,
      onBloccoCambiato: (b) => _bloccoRapido = b,
      aggiungiRapida: _aggiungiRapida,
      onScrivi: _apriScriviAllenamento,
      onSerieCompleta: () => _apriSerieCompleta(serie: null),
      atleti: _atleti(),
    );
  }

  /// Una riga rapida può interpretarsi in più serie (piramide: una
  /// distanza diversa per serie, vedi [leggiRigaSerie]): l'ordine si
  /// calcola una sola volta prima del giro, non ad ogni iterazione — il
  /// provider locale potrebbe non essersi ancora aggiornato fra una
  /// creazione e la successiva. Più di una serie dalla stessa riga
  /// condividono un `piramideId`, per restare raggruppate in un'unica
  /// riga visiva (vedi `raggruppaPerPiramide`).
  Future<void> _aggiungiRapida(List<SerieScritta> parsedList) async {
    try {
      final repository = ref.read(serieRepositoryProvider);
      final piramideId = parsedList.length > 1 ? const Uuid().v4() : null;
      var ordine = _ordineSuccessivo();
      for (final parsed in parsedList) {
        await repository.createSerie(
          allenamentoId: widget.allenamento.id,
          ordine: ordine,
          blocco: parsed.blocco,
          ripetute: parsed.ripetute,
          distanzaM: parsed.distanzaM,
          durataS: parsed.durataS,
          stile: parsed.stile,
          esecuzione: parsed.esecuzione,
          zona: parsed.zona,
          passoObiettivoS: parsed.passoObiettivoS,
          recuperoS: parsed.recuperoS,
          ripartenzaS: parsed.ripartenzaS,
          attrezzatura: parsed.attrezzatura,
          note: parsed.note,
          piramideId: piramideId,
          destinatari: parsed.destinatari,
        );
        ordine++;
      }
    } catch (e) {
      _errore(e);
      rethrow;
    }
  }

  Future<void> _aggiornaSerie(Serie s, {int? ordine, String? blocco}) {
    return ref
        .read(serieRepositoryProvider)
        .updateSerie(
          id: s.id,
          ordine: ordine ?? s.ordine,
          blocco: blocco ?? s.blocco,
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
        );
  }

  /// Riscrive il numero d'ordine solo delle serie che cambiano (nessun
  /// campo "Ordine" da compilare a mano, vedi SerieFormScreen).
  Future<void> _scriviOrdine(List<Serie> ordinate) async {
    try {
      for (final c in cambiDiOrdine(ordinate)) {
        await _aggiornaSerie(c.serie, ordine: c.ordine);
      }
    } catch (e) {
      _errore(e);
    }
  }

  /// `gruppi` è già nell'ordine mostrato a schermo (una serie normale è
  /// un gruppo da sola, una piramide un gruppo di più righe, vedi
  /// `raggruppaPerPiramide`); `newIndex` arriva già corretto da
  /// `onReorderItem`. Spostare un gruppo lo muove intero, come un solo
  /// elemento dell'elenco.
  Future<void> _riordinaGruppi(List<List<Serie>> gruppi, int da, int a) {
    final riordinati = spostaSerie(gruppi, da, a);
    return _scriviOrdine([for (final g in riordinati) ...g]);
  }

  Future<void> _azioneGruppo(
    List<List<Serie>> gruppi,
    int index,
    AzioneSerie azione,
  ) async {
    final gruppo = gruppi[index];
    switch (azione) {
      case AzioneSerie.su:
        await _riordinaGruppi(gruppi, index, index - 1);
      case AzioneSerie.giu:
        await _riordinaGruppi(gruppi, index, index + 1);
      case AzioneSerie.cambiaBlocco:
        final scelto = await _scegliBlocco(gruppo.first.blocco);
        if (scelto == null || scelto == gruppo.first.blocco) return;
        try {
          for (final s in gruppo) {
            await _aggiornaSerie(s, blocco: scelto);
          }
        } catch (e) {
          _errore(e);
        }
      case AzioneSerie.duplica:
        await _duplicaGruppo(gruppi, index);
      case AzioneSerie.salvaComeBlocco:
        await _salvaComeBlocco(gruppo);
      case AzioneSerie.elimina:
        await _eliminaGruppo(gruppi, index);
    }
  }

  Future<String?> _scegliBlocco(String attuale) {
    return showModalBottomSheet<String>(
      context: context,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.all(AppSpacing.s16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sposta in',
              style: AppTypography.sezione.copyWith(
                color: sheetContext.colori.testo,
              ),
            ),
            const SizedBox(height: AppSpacing.s12),
            Wrap(
              spacing: AppSpacing.s8,
              runSpacing: AppSpacing.s8,
              children: [
                for (final b in ordineBlocchi)
                  TonalChip(
                    etichetta: labelBlocco(b),
                    selezionato: b == attuale,
                    onSelezionato: (_) => Navigator.of(sheetContext).pop(b),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// La copia (tutte le righe del gruppo, con un nuovo `piramideId`
  /// condiviso se è una piramide) va subito dopo l'originale: le righe
  /// successive slittano di conseguenza. Le nuove righe si creano con un
  /// ordine provvisorio (in fondo), poi `_scriviOrdine` riscrive tutto
  /// l'elenco nell'ordine finale voluto, toccando solo chi deve cambiare.
  Future<void> _duplicaGruppo(List<List<Serie>> gruppi, int index) async {
    final gruppo = gruppi[index];
    // Un momento in parallelo si copia con le sue piramidi e i suoi "2x";
    // un gruppo normale è una piramide o un "2x" da solo.
    final momento = gruppo.first.momentoId == null ? null : const Uuid().v4();
    final piramidi = <String, String>{};
    String? nuovoPiramideId(Serie s) {
      if (momento == null) {
        return gruppo.length > 1
            ? piramidi.putIfAbsent('', () => const Uuid().v4())
            : null;
      }
      return s.piramideId == null
          ? null
          : piramidi.putIfAbsent(s.piramideId!, () => const Uuid().v4());
    }

    try {
      final repository = ref.read(serieRepositoryProvider);
      final nuove = <Serie>[];
      var ordineProvvisorio = _ordineSuccessivo();
      for (final s in gruppo) {
        nuove.add(
          await repository.copiaSerie(
            s,
            allenamentoId: s.allenamentoId,
            ordine: ordineProvvisorio,
            piramideId: nuovoPiramideId(s),
            momentoId: momento,
          ),
        );
        ordineProvvisorio++;
      }
      await _scriviOrdine([
        for (var i = 0; i <= index; i++) ...gruppi[i],
        ...nuove,
        for (var i = index + 1; i < gruppi.length; i++) ...gruppi[i],
      ]);
    } catch (e) {
      _errore(e);
    }
  }

  /// "Salva come blocco": crea subito un blocco in bozza in libreria con
  /// le righe del gruppo (una piramide intera diventa un blocco a più
  /// parti) — da approvare poi nella schermata "Libreria blocchi".
  Future<void> _salvaComeBlocco(List<Serie> gruppo) async {
    final titolo = gruppo.length > 1
        ? '${gruppo.map((s) => s.distanzaM ?? s.durataS).join('-')} ${labelStile(gruppo.first.stile)}'
        : '${labelVolumeSerie(gruppo.first)} ${labelStile(gruppo.first.stile)}';
    try {
      await ref
          .read(trainingBlocksRepositoryProvider)
          .salvaSerieComeBlocco(
            clubId: widget.allenamento.clubId,
            codice: 'M-${DateTime.now().millisecondsSinceEpoch}',
            sport: 'entrambi',
            titolo: titolo,
            serieGruppo: gruppo,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Salvato in libreria come bozza: da approvare nella schermata "Libreria blocchi".',
            ),
          ),
        );
      }
    } catch (e) {
      _errore(e);
    }
  }

  Future<void> _eliminaGruppo(List<List<Serie>> gruppi, int index) async {
    final gruppo = gruppi[index];
    final piramide = gruppo.length > 1;
    final momento = eMomento(gruppo);
    final prima = gruppo.first;
    final conferma = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          momento
              ? 'Eliminare il lavoro in parallelo?'
              : piramide
              ? 'Eliminare la piramide?'
              : 'Elimina serie',
        ),
        content: Text(
          momento
              ? 'Eliminare tutte le ${gruppo.length} serie, di tutte le '
                    "colonne? L'operazione non si può annullare."
              : piramide
              ? 'Eliminare le ${gruppo.length} distanze di questa piramide '
                    '(${gruppo.map((s) => s.distanzaM).join('-')})? '
                    "L'operazione non si può annullare."
              : 'Eliminare ${labelVolumeSerie(prima)} '
                    '${labelStile(prima.stile)}? '
                    "L'operazione non si può annullare.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annulla'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Elimina'),
          ),
        ],
      ),
    );
    if (conferma != true) return;
    try {
      final repository = ref.read(serieRepositoryProvider);
      for (final s in gruppo) {
        await repository.deleteSerie(s.id);
      }
      // Il numero d'ordine non deve avere buchi: la prossima serie
      // aggiunta prende lunghezza+1.
      final restanti = [
        for (var i = 0; i < gruppi.length; i++)
          if (i != index) ...gruppi[i],
      ];
      await _scriviOrdine(restanti);
    } catch (e) {
      _errore(e);
    }
  }

  /// La variante con le gambe per chi ha un dolore alla spalla (vedi
  /// [pianoVarianteSpalla]): dopo la conferma, l'atleta esce dalle serie
  /// con la palla o le braccia e ne riceve una copia con le gambe, subito
  /// dopo. Si modifica poi come le altre serie.
  Future<void> _preparaVariante(Atleta atleta, List<Atleta> atleti) async {
    final serie =
        ref.read(serieListProvider(widget.allenamento.id)).value ?? const [];
    final piano = pianoVarianteSpalla(
      serie,
      atletaId: atleta.id,
      ruolo: atleta.ruolo,
    );
    if (piano.vuoto) return;
    final nome = nomeBreve(atleta, atleti);
    final toccate = [
      for (final e in piano.esclusioni) e.serie,
      ...piano.inGambe,
    ]..sort((a, b) => a.ordine.compareTo(b.ordine));
    final conferma = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final colori = dialogContext.colori;
        return AlertDialog(
          title: Text('Variante per $nome'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Queste serie le fa con le gambe, stessa distanza o durata:',
                style: AppTypography.corpo.copyWith(color: colori.testo),
              ),
              const SizedBox(height: AppSpacing.s8),
              for (final s in toccate)
                Text(
                  '${s.ordine}. ${titoloSerie(s)}',
                  style: AppTypography.numerica(AppTypography.corpoForte)
                      .copyWith(color: colori.testo),
                ),
              const SizedBox(height: AppSpacing.s8),
              Text(
                'Poi le cambi come le altre serie.',
                style: AppTypography.piccolo.copyWith(
                  color: colori.testoSecondario,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Annulla'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Prepara la variante'),
            ),
          ],
        );
      },
    );
    if (conferma != true || !mounted) return;
    final messaggero = ScaffoldMessenger.of(context);
    try {
      final repository = ref.read(serieRepositoryProvider);
      // Le serie aggiornate, per riscrivere l'ordine senza riportarle
      // com'erano.
      final aggiornate = <String, Serie>{};
      Future<void> aggiorna(
        Serie s, {
        Destinatari? destinatari,
        bool gambe = false,
      }) async {
        aggiornate[s.id] = await repository.updateSerie(
          id: s.id,
          ordine: s.ordine,
          blocco: s.blocco,
          ripetute: s.ripetute,
          distanzaM: s.distanzaM,
          durataS: s.durataS,
          stile: gambe && s.esecuzione != 'braccia' && s.esecuzione != 'pull'
              ? 'libero'
              : s.stile,
          esecuzione: gambe ? 'gambe' : s.esecuzione,
          zona: s.zona,
          passoObiettivoS: s.passoObiettivoS,
          recuperoS: s.recuperoS,
          ripartenzaS: s.ripartenzaS,
          attrezzatura: gambe ? null : s.attrezzatura,
          note: s.note,
          destinatari: destinatari,
        );
      }

      for (final e in piano.esclusioni) {
        await aggiorna(e.serie, destinatari: e.destinatari);
      }
      for (final s in piano.inGambe) {
        await aggiorna(s, gambe: true);
      }
      final nuove = <int, List<Serie>>{};
      var ordine = _ordineSuccessivo();
      for (final MapEntry(key: indice, value: copie) in piano.nuove.entries) {
        // I segnaposto dei gruppi ("g3") diventano id veri.
        final gruppi = <String, String>{};
        for (final c in copie) {
          final piramideId = c.piramideId == null
              ? null
              : gruppi.putIfAbsent(c.piramideId!, () => const Uuid().v4());
          (nuove[indice] ??= []).add(
            await repository.createSerie(
              allenamentoId: widget.allenamento.id,
              ordine: ordine++,
              blocco: c.blocco,
              ripetute: c.ripetute,
              distanzaM: c.distanzaM,
              durataS: c.durataS,
              stile: c.stile,
              esecuzione: c.esecuzione,
              zona: c.zona,
              recuperoS: c.recuperoS,
              passoObiettivoS: c.passoObiettivoS,
              ripartenzaS: c.ripartenzaS,
              attrezzatura: c.attrezzatura,
              note: c.note,
              piramideId: piramideId,
              recuperoDopoS: c.recuperoDopoS,
              destinatari: c.destinatari,
              momentoId: c.momentoId,
            ),
          );
        }
      }
      final gruppi = raggruppaPerPiramide(serie);
      await _scriviOrdine([
        for (final (i, gruppo) in gruppi.indexed) ...[
          for (final s in gruppo) aggiornate[s.id] ?? s,
          ...?nuove[i],
        ],
      ]);
      messaggero.showSnackBar(
        SnackBar(content: Text('Variante pronta per $nome')),
      );
    } catch (e) {
      _errore(e);
    }
  }

  /// Copia l'allenamento (anche per un'altra squadra) e apre la copia,
  /// pronta da modificare.
  Future<void> _duplica(Allenamento allenamento) async {
    final gruppi =
        ref.read(gruppiListProvider(allenamento.clubId)).value ?? const [];
    final dove = await chiediDoveDuplicare(
      context,
      allenamento: allenamento,
      gruppi: gruppi,
    );
    if (dove == null || !mounted) return;
    final messaggero = ScaffoldMessenger.of(context);
    final navigatore = Navigator.of(context);
    try {
      final copia = await ref
          .read(duplicazioneSettimanaServiceProvider)
          .copiaAllenamento(
            allenamento,
            data: dove.data,
            gruppoId: dove.gruppoId,
          );
      final squadra = gruppi
          .where((g) => g.id == dove.gruppoId)
          .firstOrNull
          ?.nome;
      messaggero.showSnackBar(
        SnackBar(
          content: Text(
            squadra == null
                ? 'Allenamento copiato: ora puoi modificarlo'
                : 'Copiato per $squadra: ora puoi modificarlo',
          ),
        ),
      );
      await navigatore.pushReplacement(
        MaterialPageRoute(
          builder: (_) => AllenamentoDetailScreen(allenamento: copia),
        ),
      );
    } catch (e) {
      _errore(e);
    }
  }

  Future<void> _eliminaAllenamento(Allenamento allenamento) async {
    final conferma = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminare l\'allenamento?'),
        content: const Text(
          'Verranno eliminate per sempre anche le serie e le presenze '
          'registrate per questo allenamento.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Annulla'),
          ),
          DangerButton(
            label: 'Elimina',
            expanded: false,
            onPressed: () => Navigator.of(dialogContext).pop(true),
          ),
        ],
      ),
    );
    if (conferma != true) return;
    try {
      await ref
          .read(allenamentiRepositoryProvider)
          .deleteAllenamento(allenamento.id);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      _errore(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final allenamento = widget.allenamento;
    // Una seduta a secco ha esercizi invece delle serie: la sua schermata,
    // da qualunque elenco la si apra.
    if (allenamento.secco) return SedutaSeccoScreen(allenamento: allenamento);
    final serieAsync = ref.watch(serieListProvider(allenamento.id));
    final Map<String, String> nomiGruppi = {
      for (final g
          in ref.watch(gruppiListProvider(allenamento.clubId)).value ?? [])
        g.id: g.nome,
    };
    final nomeGruppo = nomiGruppi[allenamento.gruppoId];
    final colori = context.colori;
    final titolo = allenamento.titolo != null && allenamento.titolo!.isNotEmpty
        ? allenamento.titolo!
        : 'Allenamento';
    final serieCaricate = serieAsync.value ?? const <Serie>[];
    final riferimento = ref.watch(
      passoRiferimentoProvider((
        clubId: allenamento.clubId,
        gruppoId: allenamento.gruppoId,
      )),
    );
    final atleti = atletiDellAllenamento(
      ref
              .watch(
                atletiListProvider((
                  clubId: allenamento.clubId,
                  includeInactive: true,
                )),
              )
              .value ??
          const [],
      gruppoId: allenamento.gruppoId,
      serie: serieCaricate,
    );
    String? perChi(Destinatari d) => labelPerChi(d, atleti);
    // I metri del gruppo (un giocatore di movimento) e, se ci sono serie
    // per ruolo, quelli dei portieri a parte.
    final metri = volumeDi(serieDelGruppo(serieCaricate)).metri;
    final portieri = haSerieDiRuolo(serieCaricate)
        ? volumeDi(serieDeiPortieri(serieCaricate))
        : null;

    // Le due cose che si fanno a bordo vasca stanno in vista nella
    // testata (prima erano nel menu ⋮); "Aggiungi serie" resta il "+".
    final testata = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TestataPagina(
          occhiello: [quandoEsteso(allenamento.data), ?nomeGruppo].join(' · '),
          titolo: titolo,
          numeri: serieCaricate.isEmpty
              ? const []
              : [
                  NumeroTestata(
                    valore: formattaMetri(metri),
                    etichetta: 'Metri',
                  ),
                  if (portieri case final p? when !p.vuoto)
                    NumeroTestata(
                      valore: p.metri > 0
                          ? formattaMetri(p.metri)
                          : formattaTempoLavoro(p.secondi),
                      etichetta: p.metri > 0 ? 'Metri portieri' : 'Portieri',
                    ),
                  NumeroTestata(
                    valore: '${raggruppaPerPiramide(serieCaricate).length}',
                    etichetta: 'Serie',
                  ),
                  NumeroTestata(
                    valore:
                        "${minutiSeduta(serieCaricate, riferimento: riferimento)}'",
                    etichetta: 'Durata stimata',
                  ),
                ],
          azioni: [
            AzioneTestata(
              icona: Icons.pool,
              etichetta: 'Bordo vasca',
              principale: true,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      SchedaBordoVascaScreen(allenamento: allenamento),
                ),
              ),
            ),
            AzioneTestata(
              icona: Icons.how_to_reg_outlined,
              etichetta: 'Presenze',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => PresenzeScreen(allenamento: allenamento),
                ),
              ),
            ),
          ],
        ),
        BannerModifica(allenamento: allenamento),
        if (allenamento.note != null && allenamento.note!.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.s12),
          PoolCard(child: _NoteCompatte(allenamento.note!)),
        ],
        _AvvisoSpalla(
          allenamento: allenamento,
          serie: serieCaricate,
          atleti: atleti,
          onPrepara: (atleta) => _preparaVariante(atleta, atleti),
        ),
        const SizedBox(height: AppSpacing.s16),
      ],
    );

    return AppScaffold(
      appBar: AppBar(
        title: const Text('Allenamento'),
        actions: [
          IconButton(
            tooltip: "Scrivi l'allenamento",
            icon: const Icon(Icons.edit_note),
            onPressed: _apriScriviAllenamento,
          ),
          IconButton(
            tooltip: 'Esporta',
            icon: const Icon(Icons.ios_share),
            onPressed: () => mostraMenuExport(
              context,
              titoloDocumento: titolo,
              clubId: allenamento.clubId,
              nomiGruppi: nomiGruppi,
              nomiAtleti: {for (final a in atleti) a.id: nomeBreve(a, atleti)},
              caricaDati: () async => [
                (
                  allenamento,
                  await ref
                      .read(serieRepositoryProvider)
                      .fetchPerAllenamento(allenamento.id),
                ),
              ],
            ),
          ),
          PopupMenuButton<VoidCallback>(
            icon: const Icon(Icons.more_vert),
            tooltip: 'Altre azioni',
            onSelected: (azione) => azione(),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => AllenamentoFormScreen(
                      clubId: allenamento.clubId,
                      allenamento: allenamento,
                    ),
                  ),
                ),
                child: const _VoceMenu(
                  icona: Icons.edit_outlined,
                  etichetta: 'Modifica data, titolo e note',
                ),
              ),
              PopupMenuItem(
                value: () => _duplica(allenamento),
                child: const _VoceMenu(
                  icona: Icons.copy_all_outlined,
                  etichetta: 'Duplica',
                ),
              ),
              PopupMenuItem(
                value: () => _eliminaAllenamento(allenamento),
                child: const _VoceMenu(
                  icona: Icons.delete_outline,
                  etichetta: 'Elimina',
                ),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab-dettaglio-allenamento',
        onPressed: _apriPannello,
        tooltip: 'Aggiungi serie',
        child: const Icon(Icons.add),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Un collega ha aperta la stessa seduta, o l'ha cambiata intanto.
          AvvisoSedutaAperta(
            allenamentoId: widget.allenamento.id,
            clubId: widget.allenamento.clubId,
          ),
          Expanded(
            child: serieAsync.when(
              data: (serie) {
                if (serie.isEmpty) {
                  return ListView(
                    children: [
                      testata,
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.s8),
                        child: EmptyState(
                          icona: Icons.pool_outlined,
                          titolo: 'Nessuna serie',
                          descrizione:
                              'Scrivilo tutto come su un foglio, una serie per '
                              'riga, oppure aggiungi una serie alla volta con +.',
                          azionePrincipale: "Scrivi l'allenamento",
                          onAzionePrincipale: _apriScriviAllenamento,
                          azioneSecondaria: 'Aggiungi una serie',
                          onAzioneSecondaria: _apriPannello,
                        ),
                      ),
                    ],
                  );
                }
                // Testata e riepilogo stanno DENTRO l'elenco (header): scorrono
                // via e le serie occupano lo schermo. Una piramide (più righe
                // con lo stesso piramideId) è un solo elemento dell'elenco, non
                // una per distanza — si trascina, duplica ed elimina insieme.
                // Un momento in parallelo è un elemento solo, con le colonne.
                final gruppi = raggruppaPerMomento(serie);
                return ReorderableListView.builder(
                  buildDefaultDragHandles: false,
                  padding: const EdgeInsets.only(bottom: 88),
                  header: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      testata,
                      TitoloSezione('Serie', conteggio: gruppi.length),
                      Padding(
                        padding: const EdgeInsets.only(
                          left: 4,
                          bottom: AppSpacing.s12,
                        ),
                        // La forma e le zone della seduta del gruppo: il lavoro
                        // dei portieri e le varianti si leggono nell'elenco.
                        child: RiepilogoVolumi(
                          serie: serieDelGruppo(serie),
                          mostraTotale: false,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.s16),
                        child: GraficoIntensita(
                          serie: serieDelGruppo(serie),
                          riferimento: riferimento,
                        ),
                      ),
                      // Solo per una seduta di oggi o già passata.
                      CardComEAndata(
                        allenamento: allenamento,
                        serie: serie,
                        onSegna: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                ComEAndataScreen(allenamento: allenamento),
                          ),
                        ),
                      ),
                    ],
                  ),
                  itemCount: gruppi.length,
                  onReorderItem: (da, a) => _riordinaGruppi(gruppi, da, a),
                  itemBuilder: (context, index) {
                    final gruppo = gruppi[index];
                    final maniglia = ReorderableDragStartListener(
                      index: index,
                      child: Icon(
                        Icons.drag_indicator,
                        color: colori.testoSecondario,
                      ),
                    );
                    final riga = eMomento(gruppo)
                        ? RigaMomento(
                            gruppo: gruppo,
                            primo: index == 0,
                            ultimo: index == gruppi.length - 1,
                            maniglia: maniglia,
                            riferimento: riferimento,
                            nome: (d) => perChi(d) ?? 'Tutti',
                            onApri: (s) => _apriSerieCompleta(serie: s),
                            onAzione: (azione) =>
                                _azioneGruppo(gruppi, index, azione),
                          )
                        : gruppo.length == 1
                        ? RigaSerie(
                            serie: gruppo.single,
                            primo: index == 0,
                            ultimo: index == gruppi.length - 1,
                            maniglia: maniglia,
                            perChi: perChi(gruppo.single.destinatari),
                            onApri: () =>
                                _apriSerieCompleta(serie: gruppo.single),
                            onAzione: (azione) =>
                                _azioneGruppo(gruppi, index, azione),
                          )
                        : RigaGruppoPiramide(
                            gruppo: gruppo,
                            primo: index == 0,
                            ultimo: index == gruppi.length - 1,
                            maniglia: maniglia,
                            perChi: perChi,
                            onAzione: (azione) =>
                                _azioneGruppo(gruppi, index, azione),
                          );
                    return Padding(
                      key: ValueKey(gruppo.first.id),
                      padding: const EdgeInsets.only(bottom: AppSpacing.s8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          riga,
                          if (gruppo.last.recuperoDopoS case final secondi?)
                            Padding(
                              padding: const EdgeInsets.only(
                                top: AppSpacing.s8,
                              ),
                              child: RecuperoFraSerie(secondi),
                            ),
                        ],
                      ),
                    );
                  },
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.all(AppSpacing.s16),
                child: LoadingSkeletonList(righe: 5),
              ),
              error: (error, _) => Padding(
                padding: const EdgeInsets.all(AppSpacing.s16),
                child: ErrorBanner(
                  messaggio: 'Non è stato possibile caricare le serie.',
                  suggerimento:
                      'Riprova. Se l\'errore continua, chiudi e riapri l\'app.',
                  dettaglioTecnico: messaggioErrore(error),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Chi del gruppo ha segnato un dolore alla spalla negli ultimi giorni e
/// in questa seduta ha del lavoro con la palla o con le braccia: per
/// ognuno la proposta di fare quelle serie con le gambe. Solo per le
/// sedute di oggi e in programma; sparisce una volta preparata la
/// variante (l'atleta non fa più quelle serie).
class _AvvisoSpalla extends ConsumerWidget {
  const _AvvisoSpalla({
    required this.allenamento,
    required this.serie,
    required this.atleti,
    required this.onPrepara,
  });

  final Allenamento allenamento;
  final List<Serie> serie;
  final List<Atleta> atleti;
  final ValueChanged<Atleta> onPrepara;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final oggi = DateTime.now();
    if (serie.isEmpty || soloData(allenamento.data).isBefore(soloData(oggi))) {
      return const SizedBox.shrink();
    }
    final delGruppo = [
      for (final a in atleti)
        if (a.attivo &&
            (allenamento.gruppoId == null ||
                a.gruppoId == allenamento.gruppoId))
          a,
    ];
    final schede =
        ref.watch(schedeBenessereClubProvider(allenamento.clubId)).value ??
        const [];
    final doloranti = conDoloreSpalla(schede, {
      for (final a in delGruppo) a.id,
    }, oggi: oggi);
    final proposte = [
      for (final a in delGruppo)
        if (doloranti[a.id] case final giorno?)
          if (pianoVarianteSpalla(serie, atletaId: a.id, ruolo: a.ruolo)
              case final piano when !piano.vuoto)
            (atleta: a, giorno: giorno, serie: piano.serieToccate),
    ];
    if (proposte.isEmpty) return const SizedBox.shrink();

    final colori = context.colori;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.s12),
      child: Container(
        decoration: BoxDecoration(
          color: colori.attenzioneTenue,
          borderRadius: BorderRadius.circular(AppRadius.pannello),
          border: Border(left: BorderSide(color: colori.attenzione, width: 3)),
        ),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.s16,
          AppSpacing.s12,
          AppSpacing.s8,
          AppSpacing.s12,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final p in proposte)
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${nomeBreve(p.atleta, atleti)}: dolore alla spalla '
                      '(${traQuanto(p.giorno).toLowerCase()}). '
                      '${p.serie == 1 ? 'Una serie con la palla o le braccia' : '${p.serie} serie con la palla o le braccia'} '
                      'le può fare con le gambe.',
                      style: AppTypography.corpo.copyWith(color: colori.testo),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s8),
                  TextButton(
                    onPressed: () => onPrepara(p.atleta),
                    child: const Text('Prepara la variante'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

/// Le note libere dell'allenamento su due righe, con "Mostra tutto".
class _NoteCompatte extends StatefulWidget {
  const _NoteCompatte(this.testo);

  final String testo;

  @override
  State<_NoteCompatte> createState() => _NoteCompatteState();
}

class _NoteCompatteState extends State<_NoteCompatte> {
  bool _aperte = false;

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    return GestureDetector(
      onTap: () => setState(() => _aperte = !_aperte),
      child: Text(
        widget.testo,
        maxLines: _aperte ? null : 2,
        overflow: _aperte ? TextOverflow.visible : TextOverflow.ellipsis,
        style: AppTypography.piccolo.copyWith(color: colori.testoSecondario),
      ),
    );
  }
}

class _VoceMenu extends StatelessWidget {
  const _VoceMenu({required this.icona, required this.etichetta});

  final IconData icona;
  final String etichetta;

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    return Row(
      children: [
        Icon(icona, size: 20, color: colori.testoSecondario),
        const SizedBox(width: AppSpacing.s12),
        Text(
          etichetta,
          style: AppTypography.corpo.copyWith(color: colori.testo),
        ),
      ],
    );
  }
}
