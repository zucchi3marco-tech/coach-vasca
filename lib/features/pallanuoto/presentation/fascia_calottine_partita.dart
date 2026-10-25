import 'package:flutter/material.dart';

import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../theme/colori_app.dart';
import '../../../widgets/cap_badge.dart';
import '../domain/partita.dart';
import 'selettore_giocatore_partita.dart';

/// Fascia di calottine ai bordi dello schermo: sinistra = squadra di casa
/// (badge bianchi), destra = squadra fuori casa (badge blu), sempre
/// visibili. In stato di riposo ([attiva] false) i numeri si vedono ma non
/// sono toccabili; [attiva] true li evidenzia e li rende bersagli (per il
/// tiro, solo il lato nostro tramite [soloNostra]). Due colonne leggermente
/// sfalsate (non una sola colonna verticale) perché con rose fino a 15
/// giocatori una singola colonna non ci sta nell'altezza dello schermo in
/// orizzontale, a bordo vasca, senza dover scorrere durante l'azione.
class FasciaCalottinePartita extends StatelessWidget {
  const FasciaCalottinePartita({
    required this.partita,
    required this.casa,
    required this.convocati,
    required this.attiva,
    required this.disqualificati,
    required this.conteggiFalli,
    required this.onSelezionato,
    this.soloNostra = false,
    this.atletaEscluso,
    super.key,
  });

  /// true = fascia della squadra di casa (sinistra, badge bianchi), false =
  /// fascia della squadra fuori casa (destra, badge blu).
  final bool casa;
  final Partita partita;
  final List<ConvocatoConAtleta> convocati;
  final bool attiva;
  final Set<GiocatorePartitaId> disqualificati;
  final Map<GiocatorePartitaId, int> conteggiFalli;
  final ValueChanged<GiocatorePartitaId> onSelezionato;

  /// Quando true, solo questa fascia risponde al tocco se è quella nostra
  /// (usato per il tiro: solo un nostro giocatore può tirare).
  final bool soloNostra;

  /// Un nostro giocatore che qui non si può scegliere (chi ha segnato,
  /// quando si sceglie l'assist).
  final String? atletaEscluso;

  bool get _eNostra => (partita.nostraSquadra == 'casa') == casa;

  _BadgeCalottina _badge(int n, bool toccabile, double lato) {
    final atletaPerNumero = {
      for (final c in convocati) c.giocatore.numeroCalottina: c.atleta,
    };
    return _BadgeCalottina(
      numero: n,
      lato: lato,
      colore: casa ? CapColore.bianca : CapColore.blu,
      attivo:
          toccabile &&
          (_eNostra
              ? atletaPerNumero[n] != null &&
                    atletaPerNumero[n]!.id != atletaEscluso
              : true),
      squalificato: disqualificati.contains(
        _eNostra
            ? NostroGiocatoreId(atletaPerNumero[n]?.id ?? '')
            : AvversarioGiocatoreId(n),
      ),
      conteggioFalli:
          conteggiFalli[_eNostra
              ? NostroGiocatoreId(atletaPerNumero[n]?.id ?? '')
              : AvversarioGiocatoreId(n)] ??
          0,
      onTap: () {
        if (_eNostra) {
          final atleta = atletaPerNumero[n];
          if (atleta != null) onSelezionato(NostroGiocatoreId(atleta.id));
        } else {
          onSelezionato(AvversarioGiocatoreId(n));
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final toccabile = attiva && (!soloNostra || _eNostra);
    final numeri = [for (var n = 1; n <= partita.numeroMaxConvocati; n++) n];

    // Tutte le calottine devono stare nello schermo senza scorrere
    // (segnalazione del coach 2026-10-25, prima partita U16): con poca
    // altezza si passa a 3 o 4 colonne e le calottine si rimpiccioliscono,
    // mai sotto il bersaglio minimo da dito.
    return LayoutBuilder(
      builder: (context, vincoli) {
        final (:colonne, :lato) = misuraFascia(
          numeri.length,
          vincoli.maxHeight,
        );
        final righe = [
          for (var i = 0; i < numeri.length; i += colonne)
            numeri.sublist(i, (i + colonne).clamp(0, numeri.length)),
        ];
        final griglia = Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final (r, riga) in righe.indexed) ...[
              if (r > 0) const SizedBox(height: _spazio),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final (c, n) in riga.indexed) ...[
                    if (c > 0) const SizedBox(width: AppSpacing.s4),
                    _badge(n, toccabile, lato),
                  ],
                  // L'ultima riga incompleta resta allineata a sinistra.
                  for (var c = riga.length; c < colonne; c++) ...[
                    const SizedBox(width: AppSpacing.s4),
                    SizedBox(width: lato),
                  ],
                ],
              ),
            ],
          ],
        );
        // Solo se lo schermo è davvero troppo basso anche per la misura
        // più piccola: meglio scorrere che tagliare dei numeri.
        return Center(child: SingleChildScrollView(child: griglia));
      },
    );
  }
}

const _spazio = AppSpacing.s8;

/// Quante colonne e quanto grande ogni calottina perché [quante] calottine
/// stiano in [altezza]: la misura piena da bordo vasca se ci stanno, poi
/// più colonne, poi più piccole fino al bersaglio minimo (48).
({int colonne, double lato}) misuraFascia(int quante, double altezza) {
  const massimo = AppSpacing.altezzaMinimaBersaglioVasca;
  const minimo = AppSpacing.altezzaMinimaBersaglio;
  if (!altezza.isFinite) return (colonne: 2, lato: massimo);
  double lato(int colonne) {
    final righe = (quante / colonne).ceil();
    return ((altezza - (righe - 1) * _spazio) / righe).clamp(0, massimo);
  }

  // Le colonne in più rubano larghezza al campo: se ne aggiunge una solo
  // quando le calottine si possono fare più grandi.
  var migliore = (colonne: 2, lato: lato(2));
  for (final colonne in [3, 4]) {
    if (migliore.lato >= massimo) break;
    final l = lato(colonne);
    if (l > migliore.lato) migliore = (colonne: colonne, lato: l);
  }
  return migliore.lato >= minimo
      ? migliore
      : (colonne: migliore.colonne, lato: minimo);
}

class _BadgeCalottina extends StatelessWidget {
  const _BadgeCalottina({
    required this.numero,
    required this.lato,
    required this.colore,
    required this.attivo,
    required this.squalificato,
    required this.conteggioFalli,
    required this.onTap,
  });

  final int numero;

  /// Il lato del bersaglio (vedi misuraFascia).
  final double lato;
  final CapColore colore;
  final bool attivo;
  final bool squalificato;
  final int conteggioFalli;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    if (squalificato) {
      // Nero puro, non il token "testo": deve restare la casella piu'
      // scura sullo schermo anche quando il resto passa al tema scuro.
      return SizedBox(
        width: lato,
        height: lato,
        child: const DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.black,
            shape: BoxShape.circle,
          ),
        ),
      );
    }

    final badge = Center(
      child: CapBadge(numero: numero, colore: colore),
    );

    return SizedBox(
      width: lato,
      height: lato,
      child: Opacity(
        opacity: attivo ? 1 : 0.5,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Material(
              color: Colors.transparent,
              shape: const CircleBorder(),
              child: InkWell(
                onTap: attivo ? onTap : null,
                customBorder: const CircleBorder(),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: attivo
                        ? Border.all(color: colori.azione, width: 2)
                        : null,
                  ),
                  child: badge,
                ),
              ),
            ),
            if (conteggioFalli == 1 || conteggioFalli == 2)
              Positioned(
                top: -2,
                right: -2,
                child: Text(
                  '$conteggioFalli',
                  style: AppTypography.etichetta.copyWith(
                    color: colori.rosso,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
