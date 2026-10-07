import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../theme/colori_app.dart';
import '../../../theme/tokens_dominio.dart';
import '../../../widgets/app_text_field.dart';
import '../../../widgets/empty_state.dart';
import '../../atleti/application/atleti_providers.dart';
import '../../atleti/domain/atleta.dart';
import '../../home/area_atleta_home_screen.dart';
import '../../home/atleta/home_atleta_widgets.dart';
import '../application/benessere_providers.dart';
import '../domain/scheda_benessere.dart';
import 'card_benessere.dart';
import 'punteggio_widgets.dart';

/// Prontezza di oggi per ogni atleta del club che ha compilato, calcolata
/// con la sua eta' e il suo storico (il "suo solito").
final punteggiOggiClubProvider =
    Provider.family<Map<String, PunteggioBenessere>, String>((ref, clubId) {
      final oggi = ref.watch(schedeOggiClubProvider(clubId));
      final tutte = ref.watch(schedeBenessereClubProvider(clubId)).value ?? [];
      final atleti = {
        for (final a
            in ref
                    .watch(
                      atletiListProvider((
                        clubId: clubId,
                        includeInactive: true,
                      )),
                    )
                    .value ??
                const <Atleta>[])
          a.id: a,
      };
      return {
        for (final MapEntry(key: id, value: s) in oggi.entries)
          id: calcolaPunteggio(
            s,
            dataNascita: atleti[id]?.dataNascita,
            storico: tutte.where((x) => x.atletaId == id).toList(),
          ),
      };
    });

List<Atleta> _atletiDelGruppo(List<Atleta> atleti, String? gruppoId) =>
    gruppoId == null
    ? atleti
    : atleti.where((a) => a.gruppoId == gruppoId).toList();

/// Riquadro "Benessere di oggi" in cima all'elenco atleti dell'allenatore:
/// quanti hanno compilato la scheda e quanti sono da seguire o da
/// sentire. Al tocco apre [BenessereSquadraScreen].
class CardBenessereSquadra extends ConsumerWidget {
  const CardBenessereSquadra({
    required this.clubId,
    this.gruppoId,
    this.apribile = true,
    super.key,
  });

  final String clubId;
  final String? gruppoId;

  /// false dentro [BenessereSquadraScreen]: li' e' solo il riepilogo, e
  /// toccarlo non deve riaprire la stessa schermata.
  final bool apribile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colori = context.colori;
    final accento = context.dominio.evidenzaViola;
    final atleti = _atletiDelGruppo(
      ref
              .watch(
                atletiListProvider((clubId: clubId, includeInactive: false)),
              )
              .value ??
          const [],
      gruppoId,
    );
    final punteggi = ref.watch(punteggiOggiClubProvider(clubId));
    final compilate = atleti.where((a) => punteggi.containsKey(a.id)).toList();
    final daSentire = compilate
        .where((a) => punteggi[a.id]!.livello == 2)
        .length;
    final daSeguire = compilate
        .where((a) => punteggi[a.id]!.livello == 1)
        .length;
    final mancano = atleti.length - compilate.length;
    final media = compilate.isEmpty
        ? null
        : (compilate
                      .map((a) => punteggi[a.id]!.valore)
                      .reduce((x, y) => x + y) /
                  compilate.length)
              .round();

    return Premibile(
      etichetta:
          'Benessere di oggi: ${compilate.length} su ${atleti.length} '
          'schede compilate.${apribile ? ' Tocca per vedere la squadra.' : ''}',
      onTap: apribile
          ? () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) =>
                    BenessereSquadraScreen(clubId: clubId, gruppoId: gruppoId),
              ),
            )
          : null,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colori.superficie,
          borderRadius: BorderRadius.circular(AppRadius.pannello),
          border: Border.all(color: colori.linea),
        ),
        child: Row(
          children: [
            // Prontezza media della squadra fra chi ha compilato.
            if (media != null)
              Tooltip(
                message: 'Prontezza media di chi ha compilato oggi',
                child: AnelloPunteggio(
                  valore: media,
                  livello: media >= 60
                      ? 0
                      : media >= 40
                      ? 1
                      : 2,
                  dimensione: 52,
                ),
              )
            else
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: accento.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.favorite_outline, color: accento),
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Benessere di oggi',
                    style: AppTypography.corpoForte.copyWith(
                      color: colori.testo,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    atleti.isEmpty
                        ? 'Nessun atleta nel gruppo'
                        : '${compilate.length} su ${atleti.length} schede compilate',
                    style: AppTypography.etichetta.copyWith(
                      color: colori.testoSecondario,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      if (daSentire > 0)
                        _Conteggio(
                          testo: '$daSentire da sentire',
                          colore: colori.rosso,
                        ),
                      if (daSeguire > 0)
                        _Conteggio(
                          testo: '$daSeguire da seguire',
                          colore: colori.attenzione,
                        ),
                      if (mancano > 0)
                        _Conteggio(
                          testo: '$mancano non compilate',
                          colore: colori.testoSecondario,
                        ),
                      if (compilate.isNotEmpty &&
                          daSentire == 0 &&
                          daSeguire == 0)
                        _Conteggio(testo: 'Tutti ok', colore: colori.ok),
                    ],
                  ),
                ],
              ),
            ),
            if (apribile)
              Icon(Icons.chevron_right, color: colori.testoSecondario),
          ],
        ),
      ),
    );
  }
}

class _Conteggio extends StatelessWidget {
  const _Conteggio({required this.testo, required this.colore});

  final String testo;
  final Color colore;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: colore.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        testo,
        style: AppTypography.etichetta.copyWith(
          color: colore,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Cuoricino colorato accanto al nome nell'elenco atleti: lo stato della
/// scheda di oggi (grigio vuoto se non compilata).
class IndicatoreBenessere extends ConsumerWidget {
  const IndicatoreBenessere({
    required this.clubId,
    required this.atletaId,
    super.key,
  });

  final String clubId;
  final String atletaId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colori = context.colori;
    final p = ref.watch(punteggiOggiClubProvider(clubId))[atletaId];
    final (icona, colore, testo) = switch (p?.livello) {
      null => (
        Icons.favorite_border,
        colori.testoTenue,
        'Scheda benessere di oggi non compilata',
      ),
      0 => (Icons.favorite, colori.ok, 'Prontezza ${p!.valore}: pronto'),
      1 => (
        Icons.favorite,
        colori.attenzione,
        'Prontezza ${p!.valore}: da seguire',
      ),
      _ => (Icons.favorite, colori.rosso, 'Prontezza ${p!.valore}: da sentire'),
    };
    return Tooltip(
      message: testo,
      child: Semantics(
        label: testo,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Icon(icona, size: 20, color: colore),
        ),
      ),
    );
  }
}

/// La squadra vista dall'allenatore: prima chi e' da sentire, poi da
/// seguire, poi tutto ok, in fondo chi non ha compilato. Per ognuno la
/// scheda di oggi e gli ultimi 7 giorni; il tocco apre l'atleta.
class BenessereSquadraScreen extends ConsumerStatefulWidget {
  const BenessereSquadraScreen({
    required this.clubId,
    this.gruppoId,
    super.key,
  });

  final String clubId;
  final String? gruppoId;

  @override
  ConsumerState<BenessereSquadraScreen> createState() =>
      _BenessereSquadraScreenState();
}

class _BenessereSquadraScreenState
    extends ConsumerState<BenessereSquadraScreen> {
  String _ricerca = '';

  /// Vale con nome e cognome in qualsiasi ordine e anche solo in parte:
  /// "sofia bia" trova Bianchi Sofia.
  bool _corrisponde(Atleta a) {
    final parole = _ricerca.toLowerCase().split(RegExp(r'\s+'))
      ..removeWhere((p) => p.isEmpty);
    final nome = '${a.nome} ${a.cognome}'.toLowerCase();
    return parole.every(nome.contains);
  }

  @override
  Widget build(BuildContext context) {
    final clubId = widget.clubId;
    final gruppoId = widget.gruppoId;
    final colori = context.colori;
    final atleti = _atletiDelGruppo(
      ref
              .watch(
                atletiListProvider((clubId: clubId, includeInactive: false)),
              )
              .value ??
          const [],
      gruppoId,
    );
    final tutte = ref.watch(schedeBenessereClubProvider(clubId)).value ?? [];
    final oggi = ref.watch(schedeOggiClubProvider(clubId));
    final punteggi = ref.watch(punteggiOggiClubProvider(clubId));
    // Prima il livello piu' alto (rosso), poi il punteggio piu' basso; chi
    // non ha compilato in fondo.
    final ordinati = atleti.where(_corrisponde).toList()
      ..sort((a, b) {
        final pa = punteggi[a.id];
        final pb = punteggi[b.id];
        if (pa == null || pb == null) {
          if (pa == pb) return a.cognome.compareTo(b.cognome);
          return pa == null ? 1 : -1;
        }
        final l = pb.livello.compareTo(pa.livello);
        if (l != 0) return l;
        final v = pa.valore.compareTo(pb.valore);
        return v != 0 ? v : a.cognome.compareTo(b.cognome);
      });

    return Scaffold(
      appBar: AppBar(title: const Text('Benessere della squadra')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 880),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                CardBenessereSquadra(
                  clubId: clubId,
                  gruppoId: gruppoId,
                  apribile: false,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  etichetta: 'Cerca per nome o cognome',
                  suffixIcon: const Icon(Icons.search),
                  onChanged: (valore) => setState(() => _ricerca = valore),
                ),
                const SizedBox(height: 12),
                Text(
                  _ricerca.trim().isEmpty
                      ? 'Ordinati per Prontezza: prima chi è da sentire, in '
                            'fondo chi non ha ancora compilato. Tocca un atleta '
                            'per aprirlo.'
                      : ordinati.length == 1
                      ? '1 atleta trovato'
                      : '${ordinati.length} atleti trovati',
                  style: AppTypography.piccolo.copyWith(
                    color: colori.testoSecondario,
                  ),
                ),
                const SizedBox(height: 12),
                if (ordinati.isEmpty && atleti.isNotEmpty)
                  const EmptyState(
                    icona: Icons.search_off,
                    titolo: 'Nessun atleta trovato',
                    descrizione: 'Prova con un altro nome o cognome.',
                    azionePrincipale: 'Ho capito',
                  ),
                for (final (i, a) in ordinati.indexed) ...[
                  EntrataACascata(
                    indice: i,
                    child: _RigaAtleta(
                      atleta: a,
                      oggi: oggi[a.id],
                      punteggio: punteggi[a.id],
                      schede: tutte.where((s) => s.atletaId == a.id).toList(),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RigaAtleta extends StatelessWidget {
  const _RigaAtleta({
    required this.atleta,
    required this.oggi,
    required this.punteggio,
    required this.schede,
  });

  final Atleta atleta;
  final SchedaBenessere? oggi;
  final PunteggioBenessere? punteggio;
  final List<SchedaBenessere> schede;

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    final largo = MediaQuery.sizeOf(context).width >= 700;
    final iniziali =
        '${atleta.nome.isEmpty ? '' : atleta.nome[0]}'
        '${atleta.cognome.isEmpty ? '' : atleta.cognome[0]}';

    final p = punteggio;
    final intestazione = Row(
      children: [
        if (p != null)
          AnelloPunteggio(valore: p.valore, livello: p.livello, dimensione: 48)
        else
          CircleAvatar(
            radius: 24,
            backgroundColor: colori.superficieAlt,
            child: Text(
              iniziali.toUpperCase(),
              style: AppTypography.corpoForte.copyWith(
                color: colori.testoSecondario,
              ),
            ),
          ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                atleta.nomeCompleto,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.corpoForte.copyWith(color: colori.testo),
              ),
              if (p?.scartoDalSolito != null)
                Text(
                  p!.scartoDalSolito! >= -3
                      ? 'In linea con il suo solito (${p.mediaPersonale!.round()})'
                      : '${-p.scartoDalSolito!} sotto il suo solito '
                            '(${p.mediaPersonale!.round()})',
                  style: AppTypography.etichetta.copyWith(
                    color: p.scartoDalSolito! <= -10
                        ? colori.attenzione
                        : colori.testoSecondario,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        if (p != null)
          SemaforoAllerta(livello: p.livello)
        else
          Text(
            'Non compilata',
            style: AppTypography.etichetta.copyWith(
              color: colori.testoSecondario,
            ),
          ),
      ],
    );

    final dettaglio = oggi == null || p == null
        ? null
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              RiepilogoScheda(scheda: oggi!),
              const SizedBox(height: 10),
              MotiviPunteggio(punteggio: p, massimo: 3),
            ],
          );
    final storico = SizedBox(
      width: largo ? 220 : double.infinity,
      child: StoricoSettimana(schede: schede, compatto: true),
    );

    return Premibile(
      etichetta: 'Apri ${atleta.nomeCompleto}',
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => AtletaDashboardScreen(atleta: atleta),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colori.superficie,
          borderRadius: BorderRadius.circular(AppRadius.pannello),
          border: Border.all(color: colori.linea),
        ),
        child: largo
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        intestazione,
                        if (dettaglio != null) ...[
                          const SizedBox(height: 10),
                          dettaglio,
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  storico,
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  intestazione,
                  if (dettaglio != null) ...[
                    const SizedBox(height: 10),
                    dettaglio,
                  ],
                  const SizedBox(height: 8),
                  storico,
                ],
              ),
      ),
    );
  }
}
