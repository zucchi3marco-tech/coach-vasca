import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../theme/app_typography.dart';
import '../../../theme/colori_app.dart';
import '../domain/scheda_benessere.dart';

/// Colore del livello: verde pronto, giallo da seguire, rosso da sentire.
Color coloreLivello(BuildContext context, int livello) => switch (livello) {
  0 => context.colori.ok,
  1 => context.colori.attenzione,
  _ => context.colori.rosso,
};

/// Anello 0-100 con il numero al centro, che si riempie all'apparire.
class AnelloPunteggio extends StatelessWidget {
  const AnelloPunteggio({
    required this.valore,
    required this.livello,
    this.dimensione = 64,
    super.key,
  });

  final int valore;
  final int livello;
  final double dimensione;

  @override
  Widget build(BuildContext context) {
    final colore = coloreLivello(context, livello);
    final traccia = context.colori.linea;
    final ridotto = MediaQuery.disableAnimationsOf(context);
    return Semantics(
      label: 'Prontezza $valore su 100',
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: ridotto ? valore / 100 : 0, end: valore / 100),
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeOutCubic,
        builder: (context, t, _) => SizedBox(
          width: dimensione,
          height: dimensione,
          child: CustomPaint(
            painter: _AnelloPainter(t: t, colore: colore, traccia: traccia),
            child: Center(
              child: Text(
                '${(t * 100).round()}',
                style: AppTypography.numerica(
                  AppTypography.corpoForte.copyWith(
                    color: context.colori.testo,
                    fontSize: dimensione * 0.32,
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AnelloPainter extends CustomPainter {
  _AnelloPainter({
    required this.t,
    required this.colore,
    required this.traccia,
  });

  final double t;
  final Color colore;
  final Color traccia;

  @override
  void paint(Canvas canvas, Size size) {
    final spessore = size.width * 0.1;
    final rect = (Offset.zero & size).deflate(spessore / 2);
    canvas.drawArc(
      rect,
      0,
      2 * math.pi,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = spessore
        ..color = traccia,
    );
    canvas.drawArc(
      rect,
      -math.pi / 2,
      2 * math.pi * t,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = spessore
        ..strokeCap = StrokeCap.round
        ..color = colore,
    );
  }

  @override
  bool shouldRepaint(_AnelloPainter old) =>
      old.t != t || old.colore != colore || old.traccia != traccia;
}

/// I motivi del punteggio, come righe "cosa · punti".
class MotiviPunteggio extends StatelessWidget {
  const MotiviPunteggio({required this.punteggio, this.massimo, super.key});

  final PunteggioBenessere punteggio;

  /// Quanti motivi mostrare al massimo (null = tutti).
  final int? massimo;

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    final motivi = massimo == null
        ? punteggio.motivi
        : punteggio.motivi.take(massimo!).toList();
    if (motivi.isEmpty) {
      return Row(
        children: [
          Icon(Icons.check_circle_outline, size: 16, color: colori.ok),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'Nessun segnale: sonno, energia, muscoli, stress e umore a posto.',
              style: AppTypography.etichetta.copyWith(
                color: colori.testoSecondario,
              ),
            ),
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final m in motivi)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                Icon(
                  m.critico ? Icons.error_outline : Icons.remove_circle_outline,
                  size: 16,
                  color: m.critico ? colori.rosso : colori.attenzione,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    m.testo,
                    style: AppTypography.etichetta.copyWith(
                      color: colori.testo,
                    ),
                  ),
                ),
                if (m.punti != 0)
                  Text(
                    '${m.punti}',
                    style: AppTypography.numerica(
                      AppTypography.etichetta.copyWith(
                        color: colori.testoSecondario,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

/// "Come si calcola la Prontezza": la spiegazione per l'allenatore (e
/// per l'atleta curioso), con le fonti.
Future<void> mostraSpiegazionePunteggio(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) {
      final colori = context.colori;
      Widget paragrafo(IconData icona, String titolo, String testo) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: colori.azioneTenue,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icona, size: 20, color: colori.azione),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titolo,
                    style: AppTypography.corpoForte.copyWith(
                      color: colori.testo,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    testo,
                    style: AppTypography.piccolo.copyWith(
                      color: colori.testoSecondario,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        builder: (context, scroll) => ListView(
          controller: scroll,
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
          children: [
            Text(
              'Come si calcola la Prontezza',
              style: AppTypography.titolo.copyWith(
                color: colori.testo,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Un numero da 0 a 100 per capire in un attimo chi è pronto e chi '
              'va sentito prima di entrare in acqua. Non è una diagnosi: è un '
              'invito a parlarne con l\'atleta.',
              style: AppTypography.corpo.copyWith(
                color: colori.testoSecondario,
              ),
            ),
            const SizedBox(height: 20),
            paragrafo(
              Icons.fact_check_outlined,
              '1. Base: il questionario',
              'Qualità del sonno, energia, muscoli, stress e umore, da 1 a 5 '
                  '(5 = meglio). È il questionario di McLean (2010), il più '
                  'usato negli sport di squadra. Ogni gradino vale 20 punti: '
                  'tutte "normale" (3) = 60, tutte "bene" (4) = 80, tutte al '
                  'massimo = 100.',
            ),
            paragrafo(
              Icons.bedtime_outlined,
              '2. Ore di sonno',
              '−5 punti per ogni mezz\'ora sotto l\'obiettivo (al massimo −25). '
                  'L\'obiettivo è 8 ore per i minorenni e 7 per gli adulti: '
                  'sotto le 8 ore, nei ragazzi, il rischio di infortunio quasi '
                  'raddoppia. Meno di 5 ore = semaforo rosso.',
            ),
            paragrafo(
              Icons.healing_outlined,
              '3. Dolori',
              '−3 punti per ogni punto di intensità (dolore 6/10 = −18). La '
                  'spalla pesa un po\' di più (×1,2): nella pallanuoto è la sede '
                  'di circa metà degli infortuni, quasi sempre da sovraccarico. '
                  'Dolore da 7/10 in su = semaforo rosso.',
            ),
            paragrafo(
              Icons.sick_outlined,
              '4. Malattia',
              'Febbre −30 (e semaforo rosso), ogni altro sintomo −10.',
            ),
            paragrafo(
              Icons.traffic_outlined,
              'Il semaforo',
              'Verde "Pronto" da 60 in su, giallo "Da seguire" 40-59, rosso '
                  '"Da sentire" sotto 40.',
            ),
            paragrafo(
              Icons.person_search_outlined,
              'Rispetto al suo solito',
              'Ogni atleta risponde a modo suo: per questo il punteggio di oggi '
                  'si confronta anche con le sue ultime 4 settimane (servono '
                  'almeno 5 schede). Se è sotto il suo solito di oltre 1,5 '
                  'deviazioni standard (e di almeno 10 punti), il semaforo '
                  'sale di un livello anche con un numero buono.',
            ),
            const SizedBox(height: 8),
            Text(
              'Fonti: McLean et al. 2010 (questionario di benessere); Saw, Main '
              'e Gastin 2016 (le misure soggettive seguono la risposta '
              'all\'allenamento meglio di molte oggettive); Milewski et al. '
              '2014 (sonno e infortuni negli adolescenti); revisioni '
              'sull\'epidemiologia degli infortuni nella pallanuoto.',
              style: AppTypography.etichetta.copyWith(
                color: colori.testoTenue,
                height: 1.4,
              ),
            ),
          ],
        ),
      );
    },
  );
}
