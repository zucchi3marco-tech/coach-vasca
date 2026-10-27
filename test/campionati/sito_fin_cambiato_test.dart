import 'package:coach_vasca/features/campionati/data/pagine_fin_demo.dart';
import 'package:coach_vasca/features/campionati/domain/lettore_fin.dart';
import 'package:flutter_test/flutter_test.dart';

import 'pagine_fin_vere.dart';

void main() {
  group('il sito FIN com\'è oggi (stagione 2026-2027)', () {
    test('l\'elenco si legge tutto', () {
      final elenco = leggiElencoFin(paginaElencoVera);
      expect(elenco.stagione, '2026-2027');
      expect(elenco.stagioni.last, '2026-2027');
      expect(elenco.voci, hasLength(18));
      final u14 = elenco.voci.singleWhere((v) => v.cmpId == 259);
      expect(u14.campionato, 'Ragazzi (M/F)');
      expect(u14.faseEGirone, 'Qualificazioni · Girone 6');
      expect(
        elenco.voci.singleWhere((v) => v.cmpId == 260).girone,
        'Coppa Lombardia',
      );
      expect(elenco.nonTuttoLetto, isFalse);
    });

    test('il girone si legge tutto', () {
      final girone = leggiGironeFin(paginaGironeVera, cmpId: 259);
      expect(girone.stagione, '2026-2027');
      expect(girone.titolo, 'Ragazzi (M/F) - Qualificazioni - Girone 6');
      expect(
        [for (final r in girone.classifica) r.squadra],
        ['CANOTTIERI MILANO', 'AN BRESCIA TEAM 2', 'PALLANUOTO MONZA'],
      );
      expect(girone.rigaDi('CANOTTIERI MILANO')!.punti, 3);
      expect(girone.giornate, hasLength(3));
      final prima = girone.giornate.first.incontri.single;
      expect(prima.casa, 'CANOTTIERI MILANO');
      expect(prima.ospite, 'PALLANUOTO MONZA');
      expect(prima.data, DateTime(2026, 10, 25));
      expect(prima.ora, '17:00');
      expect((prima.golCasa, prima.golOspite), (11, 3));
      expect(prima.arbitro, 'Pusineri');
      expect(girone.nonTuttoLetto, isFalse);
    });

    test('senza classifica (non ancora uscita) non è un sito cambiato', () {
      final soloCalendario = paginaGironeVera.replaceAll(
        RegExp(
          r'<table[^>]*>\s*<thead>\s*<tr>\s*<th>Squadra.*?</table>',
          dotAll: true,
        ),
        '',
      );
      final girone = leggiGironeFin(soloCalendario, cmpId: 259);
      expect(girone.classifica, isEmpty);
      expect(girone.giornate, hasLength(3));
      expect(girone.nonTuttoLetto, isFalse);
    });

    test('le pagine della demo non sembrano un sito cambiato', () {
      expect(leggiElencoFin(paginaElencoDemoFin()).nonTuttoLetto, isFalse);
      expect(
        leggiGironeFin(paginaGironeDemoFin(229), cmpId: 229).nonTuttoLetto,
        isFalse,
      );
    });
  });

  group('una stagione o un girone non ancora pubblicati', () {
    test('elenco vuoto: «Campionati trovati: 0», niente da segnalare', () {
      final vuoto = paginaElencoVera
          .replaceAll(
            RegExp(r'<tbody>.*</tbody>', dotAll: true),
            '<tbody></tbody>',
          )
          .replaceAll('Campionati trovati: 18', 'Campionati trovati: 0');
      final elenco = leggiElencoFin(vuoto);
      expect(elenco.voci, isEmpty);
      expect(elenco.stagione, '2026-2027');
      expect(elenco.nonTuttoLetto, isFalse);
    });

    test('girone con la sola intestazione: niente da segnalare', () {
      const pagina =
          '<h5>Allievi (M) - Fase 2 - Girone 1</h5>'
          '<span>Stagione: 2026-2027</span>';
      final girone = leggiGironeFin(pagina, cmpId: 300);
      expect(girone.classifica, isEmpty);
      expect(girone.giornate, isEmpty);
      expect(girone.nonTuttoLetto, isFalse);
    });
  });

  group('il sito cambia forma', () {
    test('i gironi non si aprono più con onclick: elenco vuoto, segnalato', () {
      final cambiato = paginaElencoVera.replaceAll(
        "onclick=\"window.location='PN-Incontri.php?CMPid=",
        "data-href=\"PN-Incontri.php?CMPid=",
      );
      final elenco = leggiElencoFin(cambiato);
      expect(elenco.voci, isEmpty);
      expect(elenco.nonTuttoLetto, isTrue);
    });

    test('collegamenti spariti ma «Campionati trovati: 18»: segnalato', () {
      final cambiato = paginaElencoVera.replaceAll(RegExp(r'CMPid=\d+'), '');
      final elenco = leggiElencoFin(cambiato);
      expect(elenco.voci, isEmpty);
      expect(elenco.nonTuttoLetto, isTrue);
    });

    test('una riga del girone in una forma nuova: gli altri si leggono', () {
      // La prima riga dei gironi Allievi perde la cella della fase.
      final cambiato = paginaElencoVera.replaceFirstMapped(
        RegExp(r'(CMPid=261.*?>)\s*<td[^>]*>.*?</td>', dotAll: true),
        (m) => m[1]!,
      );
      final elenco = leggiElencoFin(cambiato);
      expect(elenco.voci, hasLength(17));
      expect(elenco.nonTuttoLetto, isTrue);
    });

    test('nessuna stagione sulla pagina: segnalato', () {
      final cambiato = paginaElencoVera
          .replaceAll(RegExp(r'\d{4}-\d{4}'), '')
          .replaceAll('Stagione', '');
      expect(leggiElencoFin(cambiato).nonTuttoLetto, isTrue);
    });

    test('la classifica perde una colonna: segnalato', () {
      final cambiato = paginaGironeVera.replaceAll(
        RegExp(
          r'<td class="text-center font-monospace fw-bold text-(success|danger)">'
          r'\s*[+-]?\d+\s*</td>',
        ),
        '',
      );
      final girone = leggiGironeFin(cambiato, cmpId: 259);
      expect(girone.classifica, isEmpty);
      expect(girone.nonTuttoLetto, isTrue);
    });

    test('le squadre divise in un altro modo: partite perse, segnalato', () {
      final cambiato = paginaGironeVera.replaceAll('>—<', '>vs<');
      final girone = leggiGironeFin(cambiato, cmpId: 259);
      expect(girone.giornate, isEmpty);
      expect(girone.classifica, hasLength(3));
      expect(girone.nonTuttoLetto, isTrue);
    });

    test('tabelle sparite ma date sulla pagina: segnalato', () {
      final cambiato = paginaGironeVera
          .replaceAll(RegExp(r'</?(table|thead|tbody|tr)[^>]*>'), '')
          .replaceAllMapped(
            RegExp(r'<(/?)t[dh]([^>]*)>'),
            (m) => '<${m[1]}div${m[2]}>',
          );
      final girone = leggiGironeFin(cambiato, cmpId: 259);
      expect(girone.classifica, isEmpty);
      expect(girone.giornate, isEmpty);
      expect(girone.nonTuttoLetto, isTrue);
    });

    test('una pagina che non dice niente: segnalato', () {
      final girone = leggiGironeFin('<div>Caricamento…</div>', cmpId: 259);
      expect(girone.nonTuttoLetto, isTrue);
    });
  });
}
