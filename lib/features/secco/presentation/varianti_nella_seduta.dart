import 'package:flutter/material.dart';

import '../../../core/utils/date_italiane.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../theme/colori_app.dart';
import '../../atleti/domain/abbina_atleta.dart';
import '../../atleti/domain/atleta.dart';
import '../domain/esercizio_secco.dart';
import '../domain/varianti_secco.dart';
import 'scelte_variante.dart' show cosaFaInBreve;

/// I nomi in una frase: «Rossi», «Rossi e Bianchi», «Rossi, Bianchi e Neri».
String elencoNomi(List<String> nomi) => switch (nomi.length) {
  0 => '',
  1 => nomi.first,
  _ => '${nomi.sublist(0, nomi.length - 1).join(', ')} e ${nomi.last}',
};

/// Sopra gli esercizi: chi ha segnato un dolore alla spalla nei giorni
/// prima della seduta e non ha ancora una variante o un esercizio che non
/// fa, con "Prepara la variante". Sparisce appena ne ha una. Stesso
/// riquadro della proposta per le sedute in acqua.
class AvvisoSpallaSecco extends StatelessWidget {
  const AvvisoSpallaSecco({
    required this.righe,
    required this.atleti,
    required this.doloranti,
    required this.onPrepara,
    super.key,
  });

  final List<EsercizioSeduta> righe;

  /// Gli atleti della seduta.
  final List<Atleta> atleti;

  /// Chi ha segnato il dolore alla spalla e quando (vedi `conDoloreSpalla`).
  final Map<String, DateTime> doloranti;
  final ValueChanged<Atleta> onPrepara;

  @override
  Widget build(BuildContext context) {
    final conVarianti = atletiConVarianti(righe);
    final proposte = [
      for (final a in atleti)
        if (doloranti[a.id] case final giorno?)
          if (!conVarianti.contains(a.id)) (atleta: a, giorno: giorno),
    ];
    if (proposte.isEmpty) return const SizedBox.shrink();

    final colori = context.colori;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s16),
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
          AppSpacing.s8,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final p in proposte) ...[
              Text(
                '${nomeBreve(p.atleta, atleti)} ha segnato un dolore alla '
                'spalla il ${giornoMese(p.giorno)}',
                style: AppTypography.corpo.copyWith(color: colori.testo),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => onPrepara(p.atleta),
                  child: const Text('Prepara la variante'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Il foglio che chiede per quale atleta è la variante di [riga]: gli
/// atleti della seduta, ognuno con quello che fa ora di questo esercizio
/// («come tutti», «variante: Extrarotazione», «non lo fa») e, in cima,
/// chi ha un dolore alla spalla. Restituisce l'atleta scelto.
Future<Atleta?> scegliAtletaPerVariante(
  BuildContext context, {
  required EsercizioSeduta riga,
  required List<EsercizioSeduta> righe,
  required Map<String, EsercizioSecco> esercizi,
  required List<Atleta> atleti,
  required Map<String, DateTime> doloranti,
}) {
  final ordinati = [
    ...atleti.where((a) => doloranti.containsKey(a.id)),
    ...atleti.where((a) => !doloranti.containsKey(a.id)),
  ];
  return showModalBottomSheet<Atleta>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) {
      final colori = sheetContext.colori;
      return SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.8,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.s16,
              0,
              AppSpacing.s16,
              AppSpacing.s16,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Variante per un atleta',
                  style: AppTypography.sezione.copyWith(color: colori.testo),
                ),
                Text(
                  esercizi[riga.esercizioId]?.nome ??
                      'Esercizio tolto dall\'elenco',
                  style: AppTypography.piccolo.copyWith(
                    color: colori.testoSecondario,
                  ),
                ),
                const SizedBox(height: AppSpacing.s8),
                if (ordinati.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.s16,
                    ),
                    child: Text(
                      'Non ci sono atleti in questa seduta.',
                      style: AppTypography.corpo.copyWith(
                        color: colori.testoSecondario,
                      ),
                    ),
                  ),
                for (final a in ordinati)
                  InkWell(
                    onTap: () => Navigator.of(sheetContext).pop(a),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        minHeight: AppSpacing.altezzaMinimaRiga,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.s8,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              nomeBreve(a, atleti),
                              style: AppTypography.corpoForte.copyWith(
                                color: colori.testo,
                              ),
                            ),
                            Text(
                              [
                                cosaFaInBreve(riga, a.id, righe, esercizi),
                                if (doloranti[a.id] case final giorno?)
                                  'dolore alla spalla il ${giornoMese(giorno)}',
                              ].join(' · '),
                              style: AppTypography.piccolo.copyWith(
                                color: colori.testoSecondario,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

/// Sotto un esercizio di tutti, una riga per chi fa altro: «Rossi:
/// Extrarotazione con elastico · 2 × 10, elastico giallo» o «Bianchi: non
/// lo fa». Un tocco apre le scelte per quell'atleta.
class SottoRigaVariante extends StatelessWidget {
  const SottoRigaVariante({
    required this.testo,
    required this.onTap,
    super.key,
  });

  final String testo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: AppSpacing.altezzaMinimaBersaglio,
        ),
        child: Padding(
          // Il testo sta sotto il nome dell'esercizio, dopo il numero.
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.s16 + 28,
            AppSpacing.s8,
            AppSpacing.s16,
            AppSpacing.s8,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.subdirectory_arrow_right,
                size: 18,
                color: colori.testoSecondario,
              ),
              const SizedBox(width: AppSpacing.s8),
              Expanded(
                child: Text(
                  testo,
                  style: AppTypography.piccolo.copyWith(
                    color: colori.testoSecondario,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
