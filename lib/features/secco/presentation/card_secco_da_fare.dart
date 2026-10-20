import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/date_italiane.dart';
import '../../../core/utils/giorni.dart';
import '../../../core/utils/gruppo_visibilita.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../theme/colori_app.dart';
import '../../../theme/tokens_dominio.dart';
import '../../allenamenti/application/allenamenti_providers.dart';
import '../../allenamenti/domain/allenamento.dart';
import '../../allenamenti/domain/prossimo_allenamento.dart';
import '../../atleti/domain/atleta.dart';
import '../../atleti/domain/squadre_atleta.dart';
import '../../carico/application/carico_providers.dart';
import '../../presenze/application/presenze_providers.dart';
import '../../presenze/domain/presenza.dart';
import '../application/secco_providers.dart';
import '../domain/serie_fatta.dart';
import 'seduta_secco_atleta_screen.dart';

/// Per quanti giorni dopo si propone di finire una seduta a secco
/// cominciata (come per l'RPE).
const giorniPerFinireSecco = 2;

/// Le sedute a secco da registrare: quelle di oggi e quelle degli ultimi
/// [giorniPerFinireSecco] giorni già cominciate. Non quelle finite (con
/// la risposta "quanto è stata dura?"), quelle in cui l'atleta è segnato
/// assente, né [prossimoId] (la scheda del prossimo allenamento la apre
/// già). Dalla più recente, con le serie fatte.
List<({Allenamento seduta, int serieFatte})> seduteSeccoDaFare({
  required List<Allenamento> allenamenti,
  required String? gruppoAtleta,
  required Set<String> assenti,
  required Set<String> finite,
  required List<SerieFatta> fatte,
  required String? prossimoId,
  required DateTime oggi,

  /// Le sedute a cui l'atleta è atteso (anche con l'altra squadra, nei
  /// suoi giorni): al posto di quelle del suo gruppo.
  bool Function(Allenamento a)? atteso,
}) {
  final giorno = soloData(oggi);
  final dal = aggiungiGiorni(giorno, -giorniPerFinireSecco);
  final perSeduta = <String, int>{};
  for (final f in fatte) {
    perSeduta[f.allenamentoId] = (perSeduta[f.allenamentoId] ?? 0) + 1;
  }
  final sedute = [
    for (final a in allenamenti)
      if (a.secco &&
          a.id != prossimoId &&
          !assenti.contains(a.id) &&
          !finite.contains(a.id) &&
          !soloData(a.data).isAfter(giorno) &&
          !soloData(a.data).isBefore(dal) &&
          (soloData(a.data) == giorno || (perSeduta[a.id] ?? 0) > 0) &&
          (atteso?.call(a) ??
              visibileNelGruppo(
                gruppoDelRecord: a.gruppoId,
                gruppoSelezionato: gruppoAtleta,
              )))
        (seduta: a, serieFatte: perSeduta[a.id] ?? 0),
  ]..sort((x, y) => y.seduta.data.compareTo(x.seduta.data));
  return sedute;
}

/// Nella home dell'atleta, sotto "Quanto è stato duro?": le sedute a
/// secco da registrare, con "Comincia" o "Continua". Senza sedute non
/// mostra niente.
class CardSeccoDaFare extends ConsumerWidget {
  const CardSeccoDaFare({required this.atleta, super.key});

  final Atleta atleta;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colori = context.colori;
    final viola = context.dominio.evidenzaViola;
    final allenamenti =
        ref.watch(allenamentiAtletaProvider(atleta.clubId)).value ??
        const <Allenamento>[];
    final oggi = DateTime.now();
    bool atteso(Allenamento a) => atleta.attesoA(a.gruppoId, a.data);
    final sedute = seduteSeccoDaFare(
      allenamenti: allenamenti,
      gruppoAtleta: atleta.gruppoId,
      atteso: atteso,
      assenti: {
        for (final p
            in ref.watch(presenzePerAtletaProvider(atleta.id)).value ??
                const [])
          if (!contaComePresente(p.stato)) p.allenamentoId,
      },
      finite: {
        for (final r
            in ref.watch(rpeAtletaProvider(atleta.id)).value ?? const [])
          if (r.eventoTipo == 'allenamento') r.eventoId,
      },
      fatte: ref.watch(serieFatteAtletaProvider(atleta.id)).value ?? const [],
      prossimoId: prossimoAllenamento([
        for (final a in allenamenti)
          if (atteso(a)) a,
      ], null)?.id,
      oggi: oggi,
    );
    if (sedute.isEmpty) return const SizedBox.shrink();

    String quando(DateTime d) => switch (giorniTra(oggi, d)) {
      0 => 'di oggi',
      -1 => 'di ieri',
      _ => 'di ${dataEstesa(d)}',
    };

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Container(
        decoration: BoxDecoration(
          color: colori.superficie,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colori.linea),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            for (final (i, s) in sedute.take(3).indexed) ...[
              if (i > 0) Divider(height: 1, color: colori.linea),
              InkWell(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => SedutaSeccoAtletaScreen(
                      allenamento: s.seduta,
                      atleta: atleta,
                    ),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: viola.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.fitness_center, color: viola),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Seduta a secco ${quando(s.seduta.data)}',
                              style: AppTypography.corpoForte.copyWith(
                                color: colori.testo,
                              ),
                            ),
                            Text(
                              [
                                s.seduta.titoloMostrato,
                                if (s.serieFatte > 0)
                                  '${s.serieFatte} serie fatte',
                              ].join(' · '),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.etichetta.copyWith(
                                color: colori.testoSecondario,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.s8),
                      Text(
                        s.serieFatte > 0 ? 'Continua' : 'Comincia',
                        style: AppTypography.corpoForte.copyWith(
                          color: colori.azione,
                        ),
                      ),
                      Icon(Icons.chevron_right, color: colori.azione),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
