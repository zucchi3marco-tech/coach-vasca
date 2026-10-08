import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/date_italiane.dart';
import '../../../core/utils/error_messages.dart';
import '../../../theme/app_layout.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../theme/colori_app.dart';
import '../../../widgets/app_scaffold.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/error_banner.dart';
import '../../../widgets/loading_skeleton.dart';
import '../../../widgets/testata_pagina.dart';
import '../../../widgets/tonal_chip.dart';
import '../../allenamenti/application/allenamenti_providers.dart';
import '../../allenamenti/domain/allenamento.dart';
import '../../atleti/application/atleti_providers.dart';
import '../../gruppi/application/gruppi_providers.dart';
import '../../home/area_atleta_home_screen.dart';
import '../../stagioni/application/stagioni_providers.dart';
import '../../stagioni/domain/stagione.dart';
import '../application/presenze_providers.dart';
import '../domain/presenze_stagione.dart';

enum _Periodo { stagione, treMesi, mese }

/// Le presenze di un gruppo nel tempo (idea presa da Swimtraxx Hub): in
/// testata la media, gli allenamenti fatti e quanti vengono in media;
/// sotto una riga per atleta con un segno per allenamento, la
/// percentuale e le presenze di fila. Il periodo è la stagione in corso
/// del gruppo, o gli ultimi tre mesi o l'ultimo mese.
class PresenzeStagioneScreen extends ConsumerStatefulWidget {
  const PresenzeStagioneScreen({
    required this.clubId,
    this.gruppoId,
    super.key,
  });

  final String clubId;

  /// Il gruppo scelto in alto; null = tutti gli atleti.
  final String? gruppoId;

  @override
  ConsumerState<PresenzeStagioneScreen> createState() =>
      _PresenzeStagioneScreenState();
}

class _PresenzeStagioneScreenState
    extends ConsumerState<PresenzeStagioneScreen> {
  /// Null finché non si sceglie: la stagione se c'è, altrimenti tre mesi.
  _Periodo? _periodo;

  @override
  Widget build(BuildContext context) {
    final clubId = widget.clubId;
    final gruppoId = widget.gruppoId;
    final atletiAsync = ref.watch(
      atletiListProvider((clubId: clubId, includeInactive: false)),
    );
    final allenamenti = ref.watch(allenamentiListProvider(clubId)).value ?? [];
    final presenze = ref.watch(presenzeClubProvider(clubId)).value ?? [];
    final stagioni = ref.watch(stagioniListProvider(clubId)).value ?? [];
    final nomeSquadra = ref.watch(
      nomeSquadraProvider((clubId: clubId, gruppoId: gruppoId)),
    );

    final stagione = stagioneCorrenteDiGruppo(stagioni, gruppoId);
    final periodo =
        _periodo ?? (stagione != null ? _Periodo.stagione : _Periodo.treMesi);
    final oggi = DateTime.now();
    final dal = switch (periodo) {
      _Periodo.stagione when stagione != null => stagione.dataInizio,
      _Periodo.mese => oggi.subtract(const Duration(days: 30)),
      _ => oggi.subtract(const Duration(days: 90)),
    };

    return AppScaffold(
      larghezzaMassima: AppLayout.larghezzaMassimaCruscotto,
      appBar: AppBar(title: const Text('Presenze')),
      body: atletiAsync.when(
        loading: () => const LoadingSkeletonList(righe: 6),
        error: (errore, _) => ErrorBanner(
          messaggio: 'Non è stato possibile caricare gli atleti.',
          suggerimento: 'Riprova. Se continua, chiudi e riapri l\'app.',
          dettaglioTecnico: messaggioErrore(errore),
        ),
        data: (atleti) {
          final risultato = presenzeStagione(
            allenamenti: allenamenti,
            presenze: presenze,
            atleti: [
              for (final a in atleti)
                if (gruppoId == null || a.gruppoId == gruppoId) a,
            ],
            gruppoId: gruppoId,
            dal: dal,
          );
          final media = risultato.media;
          final presentiMedi = risultato.presentiMedi;
          return ListView(
            padding: const EdgeInsets.only(bottom: AppSpacing.s32),
            children: [
              TestataPagina(
                occhiello: nomeSquadra,
                titolo: 'Presenze',
                sottotitolo: 'Da ${dataEstesa(dal)} a oggi',
                numeri: [
                  NumeroTestata(
                    valore: media == null ? '—' : '${media.round()}%',
                    etichetta: 'Presenze',
                  ),
                  NumeroTestata(
                    valore: '${risultato.allenamenti.length}',
                    etichetta: 'Allenamenti',
                  ),
                  NumeroTestata(
                    valore: presentiMedi == null
                        ? '—'
                        : presentiMedi.toStringAsFixed(1).replaceAll('.', ','),
                    etichetta: 'Presenti in media',
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.s16),
              Wrap(
                spacing: AppSpacing.s8,
                runSpacing: AppSpacing.s8,
                children: [
                  if (stagione != null)
                    TonalChip(
                      // "Stagione agonistica 2026/27" non diventa
                      // "Stagione Stagione agonistica...".
                      etichetta:
                          stagione.nome.toLowerCase().startsWith('stagione')
                          ? stagione.nome
                          : 'Stagione ${stagione.nome}',
                      selezionato: periodo == _Periodo.stagione,
                      onSelezionato: (_) =>
                          setState(() => _periodo = _Periodo.stagione),
                    ),
                  TonalChip(
                    etichetta: 'Ultimi 3 mesi',
                    selezionato: periodo == _Periodo.treMesi,
                    onSelezionato: (_) =>
                        setState(() => _periodo = _Periodo.treMesi),
                  ),
                  TonalChip(
                    etichetta: 'Ultimo mese',
                    selezionato: periodo == _Periodo.mese,
                    onSelezionato: (_) =>
                        setState(() => _periodo = _Periodo.mese),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.s16),
              if (risultato.righe.isEmpty)
                EmptyState(
                  icona: Icons.groups_outlined,
                  titolo: 'Nessun atleta in questo gruppo',
                  descrizione:
                      'Aggiungi gli atleti dalla scheda Atleti: qui vedrai '
                      'le loro presenze allenamento per allenamento.',
                  azionePrincipale: 'Torna agli atleti',
                  onAzionePrincipale: () => Navigator.of(context).pop(),
                )
              else if (risultato.allenamenti.isEmpty)
                EmptyState(
                  icona: Icons.event_busy_outlined,
                  titolo: 'Nessun allenamento in questo periodo',
                  descrizione:
                      'Scegli un periodo più lungo, o segna le presenze '
                      'del prossimo allenamento.',
                  azionePrincipale: periodo == _Periodo.mese
                      ? 'Guarda gli ultimi 3 mesi'
                      : 'Torna agli atleti',
                  onAzionePrincipale: periodo == _Periodo.mese
                      ? () => setState(() => _periodo = _Periodo.treMesi)
                      : () => Navigator.of(context).pop(),
                )
              else ...[
                const _Legenda(),
                const SizedBox(height: AppSpacing.s8),
                _Griglia(risultato: risultato),
              ],
            ],
          );
        },
      ),
    );
  }
}

Color? _coloreStato(StatoPresenza stato, ColoriApp colori) => switch (stato) {
  StatoPresenza.presente => colori.ok,
  StatoPresenza.giustificato => colori.attenzione,
  StatoPresenza.assente => colori.testoTenue,
  StatoPresenza.nonSegnato => colori.linea,
  StatoPresenza.nonSuo => null,
};

class _Legenda extends StatelessWidget {
  const _Legenda();

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    return Wrap(
      spacing: AppSpacing.s16,
      runSpacing: AppSpacing.s4,
      children: [
        for (final (stato, etichetta) in const [
          (StatoPresenza.presente, 'Presente'),
          (StatoPresenza.giustificato, 'Giustificato'),
          (StatoPresenza.assente, 'Assente'),
          (StatoPresenza.nonSegnato, 'Non segnata'),
        ])
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: _coloreStato(stato, colori),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: AppSpacing.s4),
              Text(
                etichetta,
                style: AppTypography.etichetta.copyWith(color: colori.testo),
              ),
            ],
          ),
      ],
    );
  }
}

/// Una riga per atleta: nome, un segno per allenamento, percentuale e
/// presenze di fila. Sopra, i mesi.
class _Griglia extends StatelessWidget {
  const _Griglia({required this.risultato});

  final PresenzeStagione risultato;

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    final stretto = MediaQuery.sizeOf(context).width < 600;
    final larghezzaNome = stretto ? 96.0 : 180.0;
    final etichetta = AppTypography.etichetta.copyWith(
      color: colori.testoSecondario,
    );

    Widget colonne({
      required Widget nome,
      required Widget striscia,
      required Widget percentuale,
      required Widget diFila,
    }) => Row(
      children: [
        SizedBox(width: larghezzaNome, child: nome),
        const SizedBox(width: AppSpacing.s8),
        Expanded(child: striscia),
        const SizedBox(width: AppSpacing.s8),
        SizedBox(width: 44, child: percentuale),
        SizedBox(width: 48, child: diFila),
      ],
    );

    return Container(
      padding: const EdgeInsets.all(AppSpacing.s12),
      decoration: BoxDecoration(
        color: colori.superficie,
        borderRadius: BorderRadius.circular(AppRadius.pannello),
        border: Border.all(color: colori.linea),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          colonne(
            nome: Text('Atleta', style: etichetta),
            striscia: SizedBox(
              height: 18,
              child: CustomPaint(
                painter: _MesiPainter(
                  allenamenti: risultato.allenamenti,
                  stile: etichetta,
                ),
              ),
            ),
            percentuale: Text(
              '%',
              textAlign: TextAlign.right,
              style: etichetta,
            ),
            diFila: Text(
              'Di fila',
              textAlign: TextAlign.right,
              style: etichetta,
            ),
          ),
          const SizedBox(height: AppSpacing.s4),
          for (final riga in risultato.righe)
            _RigaAtleta(riga: riga, stretto: stretto, colonne: colonne),
        ],
      ),
    );
  }
}

class _RigaAtleta extends StatelessWidget {
  const _RigaAtleta({
    required this.riga,
    required this.stretto,
    required this.colonne,
  });

  final RigaPresenze riga;
  final bool stretto;
  final Widget Function({
    required Widget nome,
    required Widget striscia,
    required Widget percentuale,
    required Widget diFila,
  })
  colonne;

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    final atleta = riga.atleta;
    final percentuale = riga.percentuale;
    final nome = stretto && atleta.nome.isNotEmpty
        ? '${atleta.cognome} ${atleta.nome[0]}.'
        : '${atleta.cognome} ${atleta.nome}';
    final testoPercentuale = percentuale == null
        ? '—'
        : '${percentuale.round()}%';
    return Semantics(
      button: true,
      label:
          '$nome: presenze $testoPercentuale, ${riga.diFila} di fila. '
          'Apri la scheda',
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.pannello),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => AtletaDashboardScreen(atleta: atleta),
          ),
        ),
        child: ExcludeSemantics(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.s8),
            child: colonne(
              nome: Text(
                nome,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.corpo.copyWith(color: colori.testo),
              ),
              striscia: SizedBox(
                height: 22,
                child: CustomPaint(
                  painter: _StrisciaPainter(
                    colori: [
                      for (final s in riga.stati) _coloreStato(s, colori),
                    ],
                  ),
                ),
              ),
              percentuale: Text(
                testoPercentuale,
                textAlign: TextAlign.right,
                style: AppTypography.numerica(AppTypography.corpoForte)
                    .copyWith(color: colori.testo),
              ),
              diFila: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(
                    Icons.local_fire_department,
                    size: 18,
                    color: riga.diFila > 0
                        ? colori.attenzione
                        : colori.testoTenue,
                  ),
                  Text(
                    '${riga.diFila}',
                    style: AppTypography.numerica(AppTypography.piccolo)
                        .copyWith(color: colori.testo),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Un rettangolino per allenamento, nell'ordine; nessuno per quelli di
/// un altro gruppo (colore null), che restano un buco.
class _StrisciaPainter extends CustomPainter {
  _StrisciaPainter({required this.colori});

  final List<Color?> colori;

  @override
  void paint(Canvas canvas, Size size) {
    if (colori.isEmpty) return;
    final larghezza = size.width / colori.length;
    final spazio = larghezza >= 4 ? 1.0 : 0.0;
    for (var i = 0; i < colori.length; i++) {
      final colore = colori[i];
      if (colore == null) continue;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(i * larghezza, 0, larghezza - spazio, size.height),
          const Radius.circular(1.5),
        ),
        Paint()..color = colore,
      );
    }
  }

  @override
  bool shouldRepaint(_StrisciaPainter vecchio) =>
      !_stessaLista(vecchio.colori, colori);
}

bool _stessaLista(List<Color?> a, List<Color?> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

/// I mesi sopra le strisce, all'altezza del primo allenamento di
/// ciascuno; quelli che non ci stanno si saltano.
class _MesiPainter extends CustomPainter {
  _MesiPainter({required this.allenamenti, required this.stile});

  final List<Allenamento> allenamenti;
  final TextStyle stile;

  @override
  void paint(Canvas canvas, Size size) {
    if (allenamenti.isEmpty) return;
    final larghezza = size.width / allenamenti.length;
    var fineUltima = double.negativeInfinity;
    int? meseUltimo;
    for (var i = 0; i < allenamenti.length; i++) {
      final mese = allenamenti[i].data.month;
      if (mese == meseUltimo) continue;
      meseUltimo = mese;
      final testo = TextPainter(
        text: TextSpan(text: mesiBrevi[mese - 1], style: stile),
        textDirection: TextDirection.ltr,
      )..layout();
      final x = i * larghezza;
      if (x < fineUltima + 4 || x + testo.width > size.width) continue;
      testo.paint(canvas, Offset(x, 0));
      fineUltima = x + testo.width;
    }
  }

  @override
  bool shouldRepaint(_MesiPainter vecchio) =>
      vecchio.allenamenti != allenamenti || vecchio.stile != stile;
}
