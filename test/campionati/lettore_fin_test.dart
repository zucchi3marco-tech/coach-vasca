import 'package:coach_vasca/features/campionati/data/pagine_fin_demo.dart';
import 'package:coach_vasca/features/campionati/domain/campionato_fin.dart';
import 'package:coach_vasca/features/campionati/domain/lettore_fin.dart';
import 'package:flutter_test/flutter_test.dart';

// Pezzi delle pagine vere di finlombardia.net (ottobre 2026), con la loro
// forma esatta e squadre, piscine e arbitri inventati.
const _elenco = '''
<nav class="navbar navbar-expand-lg navbar-light bg-light">
    <h1 class="navbar me-auto ms-3">CAMPIONATI REGIONALI PALLANUOTO 2025-2026</h1>
</nav>
<form>
    <div>
        <label for='dropdownMenuLink' class="col-sm-3 col-form-label ms-2">Stagione</label>
        <div class="dropdown mb-3 ms-2">
            <a class="btn btn-secondary dropdown-toggle" href="#" role="button" id="dropdownMenuLink" data-bs-toggle="dropdown">
                2025-2026                    </a>
            <ul class="dropdown-menu" aria-labelledby="dropdownMenuLink">
                <li><a class="dropdown-item" href="?Stagione=2024-2025">2024-2025</a></li>
                <li><a class="dropdown-item" href="?Stagione=2025-2026">2025-2026</a></li>
                <li><a class="dropdown-item" href="?Stagione=2026-2027">2026-2027</a></li>
            </ul>
        </div>
    </div>
</form>
<table class="table table-borderless table-hover table-sm">
    <thead>
        <tr>
            <th scope="col">Campionato</th>
            <th scope="col">Fase</th>
            <th scope="col">Girone</th>
                            </tr>
    </thead>
    <tbody>
            <!-- riga vuota tra campionati se cambia campionato  -->
            <tr class="border-bottom"><td> </td></tr>
            <!-- riga con campionato  -->
            <tr style="cursor:pointer" onclick="window.location = 'PN-Incontri.php?CMPid=244'">
                <td> Cadetti   (M)                        </td>
                <!-- fase e girone -->
                <td>Fase1</td>
                <td class="text-center text-nowrap">Girone1</td>
            </tr>
            <tr class="border-bottom"><td> </td></tr>
            <tr style="cursor:pointer" onclick="window.location = 'PN-Incontri.php?CMPid=229'">
                <td> Campionato Allievi  (M)                        </td>
                <td>Fase 1</td>
                <td class="text-center text-nowrap">Girone 1</td>
            </tr>
            <tr style="cursor:pointer" onclick="window.location = 'PN-Incontri.php?CMPid=230'">
                <td>                         </td>
                <td>Fase 1</td>
                <td class="text-center text-nowrap">Girone 2</td>
            </tr>
            <tr style="cursor:pointer" onclick="window.location = 'PN-Incontri.php?CMPid=206'">
                <td>                         </td>
                <td>Qualificazioni</td>
                <td class="text-center text-nowrap">Girone 1</td>
            </tr>
    </tbody>
</table>
''';

const _elencoVuoto = '''
<h1 class="navbar me-auto ms-3">CAMPIONATI REGIONALI PALLANUOTO 2026-2027</h1>
<a class="btn btn-secondary dropdown-toggle" href="#" role="button" id="dropdownMenuLink" data-bs-toggle="dropdown">
    2026-2027                    </a>
<ul class="dropdown-menu">
    <li><a class="dropdown-item" href="?Stagione=2025-2026">2025-2026</a></li>
    <li><a class="dropdown-item" href="?Stagione=2026-2027">2026-2027</a></li>
</ul>
<table class="table table-borderless table-hover table-sm">
    <thead><tr><th scope="col">Campionato</th><th scope="col">Fase</th><th scope="col">Girone</th></tr></thead>
    <tbody>
                    </tbody>
</table>
''';

const _girone = '''
<h1 class="navbar me-auto ms-3">CAMPIONATI REGIONALI PALLANUOTO 2025-2026</h1>
<div class="container mt-2" style="max-width: 900px;">
    <p class="text-center fs-3 fw-bold text-secondary mt-5">Esordienti (M/F) - Qualificazioni - Girone 1</p>
    <!-- tabella con classifica -->
                <table class="table">
            <thead class="table-light border-light">
                <tr>
                    <th></th>
                    <th>Punti</th>
                    <th>Giocate</th>
                    <th>Vinte</th>
                    <th>Paregg.</th>
                    <th>Perse</th>
                    <th>Gol fatti</th>
                    <th>Gol subiti</th>
                    <th>Diff. reti</th>
                </tr>
            </thead>
            <tbody class="border-top-0">
                                        <tr class="text-center">
                        <td class="text-start">Onde Verdi</td>
                        <td>7</td>
                        <td>3</td>
                        <td>2</td>
                        <td>1</td>
                        <td>0</td>
                        <td>40</td>
                        <td>12</td>
                        <td>28</td>
                    </tr>
                                        <tr class="text-center">
                        <td class="text-start">Rari Nantes Sud-Est</td>
                        <td>3</td>
                        <td>3</td>
                        <td>1</td>
                        <td>0</td>
                        <td>2</td>
                        <td>18</td>
                        <td>31</td>
                        <td>-13</td>
                    </tr>
                                        <tr class="text-center">
                        <td class="text-start">PN Riviera  2</td>
                        <td>1</td>
                        <td>2</td>
                        <td>0</td>
                        <td>1</td>
                        <td>1</td>
                        <td>9</td>
                        <td>24</td>
                        <td>-15</td>
                    </tr>
            </tbody>
        </table>
    <!-- tabella con elenco incontri -->
    <table class="table table-borderless table-sm">
        <tbody>
                <!-- codice php per formattare i campi della riga-->
                <tr class="border-top"><td class="fst-italic">1a giornata </td> <td></td> <td></td> <td></td> <td></td></tr>
                <tr>
                    <td class="fw-bold text-nowrap">Onde Verdi - Rari Nantes Sud-Est</td>
                    <td class="text-nowrap">CO- Piscina del Lago</td>
                    <td class="text-start">16.30</td>
                    <td class="text-nowrap">sabato 15/11/2025</td>
                    <td class="text-center text-nowrap fw-bold">14-7</td>
                    <td class="text-center">Verdi</td>
                    <!-- opzione modifica se non è user e siamo nella stagione di default -->
                </tr>
                <tr>
                    <td class="fw-bold text-nowrap">PN Riviera 2 - Onde Verdi</td>
                    <td class="text-nowrap">LO - Piscina Comunale </td>
                    <td class="text-start">12.00</td>
                    <td class="text-nowrap">domenica 16/11/2025</td>
                    <td class="text-center text-nowrap fw-bold">5-5</td>
                    <td class="text-center">.</td>
                </tr>
                <tr class="border-top"><td class="fst-italic">2a giornata </td> <td></td> <td></td> <td></td> <td></td></tr>
                <tr>
                    <td class="fw-bold text-nowrap">Rari Nantes Sud-Est - PN Riviera 2</td>
                    <td class="text-nowrap">BG-Piscine di Dalmine</td>
                    <td class="text-start">18.45</td>
                    <td class="text-nowrap">sabato 22/11/2025</td>
                    <td class="text-center text-nowrap fw-bold">rinviata</td>
                    <td class="text-center"></td>
                </tr>
                <tr>
                    <td class="fw-bold text-nowrap">Onde Verdi - PN Riviera 2</td>
                    <td class="text-nowrap">MB-Comunale</td>
                    <td class="text-start">9.00</td>
                    <td class="text-nowrap">sabato 29/11/2025</td>
                    <td class="text-center text-nowrap fw-bold"></td>
                    <td class="text-center"></td>
                </tr>
                <tr class="border-top"><td class="fst-italic">3a giornata </td> <td></td> <td></td> <td></td> <td></td></tr>
                <tr>
                    <td class="fw-bold text-nowrap">PN Riviera 2 - riposo</td>
                    <td class="text-nowrap"></td>
                    <td class="text-start"></td>
                    <td class="text-nowrap"></td>
                    <td class="text-center text-nowrap fw-normal"></td>
                    <td class="text-center"></td>
                </tr>
                        </tbody>
    </table>
</div>
''';

void main() {
  group('elenco dei campionati', () {
    test('legge stagione, stagioni e gironi, anche le righe senza nome', () {
      final elenco = leggiElencoFin(_elenco);
      expect(elenco.stagione, '2025-2026');
      expect(elenco.stagioni, ['2024-2025', '2025-2026', '2026-2027']);
      expect([for (final v in elenco.voci) v.cmpId], [244, 229, 230, 206]);
      final cadetti = elenco.voci.first;
      expect(cadetti.campionato, 'Cadetti (M)');
      expect(cadetti.fase, 'Fase 1');
      expect(cadetti.girone, 'Girone 1');
      // Le righe successive ereditano il campionato.
      expect(elenco.voci[2].campionato, 'Campionato Allievi (M)');
      expect(elenco.voci[3].faseEGirone, 'Qualificazioni · Girone 1');
      expect(elenco.perCampionato.keys, [
        'Cadetti (M)',
        'Campionato Allievi (M)',
      ]);
      expect(elenco.perCampionato['Campionato Allievi (M)'], hasLength(3));
    });

    test('una stagione non ancora pubblicata è vuota', () {
      final elenco = leggiElencoFin(_elencoVuoto);
      expect(elenco.stagione, '2026-2027');
      expect(elenco.voci, isEmpty);
    });
  });

  group('pagina di un girone', () {
    test('legge la classifica', () {
      final girone = leggiGironeFin(_girone, cmpId: 210);
      expect(girone.stagione, '2025-2026');
      expect(girone.titolo, 'Esordienti (M/F) - Qualificazioni - Girone 1');
      expect(girone.classifica, hasLength(3));
      final primi = girone.classifica.first;
      expect(primi.posizione, 1);
      expect(primi.squadra, 'Onde Verdi');
      expect(
        [
          primi.punti,
          primi.giocate,
          primi.vinte,
          primi.pareggiate,
          primi.perse,
          primi.golFatti,
          primi.golSubiti,
          primi.differenza,
        ],
        [7, 3, 2, 1, 0, 40, 12, 28],
      );
      // Spazi doppi tolti; il nome si riconosce anche scritto diverso.
      expect(girone.classifica[2].squadra, 'PN Riviera 2');
      expect(girone.rigaDi('pn riviera 2')?.posizione, 3);
      expect(girone.classifica[1].differenza, -13);
    });

    test('legge il calendario con risultati, rinvii e partite da giocare', () {
      final girone = leggiGironeFin(_girone, cmpId: 210);
      expect(
        [for (final g in girone.giornate) g.nome],
        ['1a giornata', '2a giornata', '3a giornata'],
      );
      final primo = girone.giornate.first.incontri.first;
      expect(primo.casa, 'Onde Verdi');
      // Il trattino dentro un nome non divide le squadre.
      expect(primo.ospite, 'Rari Nantes Sud-Est');
      expect(primo.piscina, 'CO- Piscina del Lago');
      expect(primo.ora, '16:30');
      expect(primo.data, DateTime(2025, 11, 15));
      expect((primo.golCasa, primo.golOspite), (14, 7));
      expect(primo.arbitro, 'Verdi');
      expect(girone.giornate.first.incontri[1].arbitro, isNull);

      final rinviata = girone.giornate[1].incontri.first;
      expect(rinviata.giocato, isFalse);
      expect(rinviata.risultatoTesto, 'rinviata');

      final daGiocare = girone.giornate[1].incontri[1];
      expect(daGiocare.giocato, isFalse);
      expect(daGiocare.risultatoTesto, isNull);
      expect(daGiocare.ora, '09:00');

      final riposo = girone.giornate[2].incontri.single;
      expect(riposo.riposo, isTrue);
      expect(riposo.data, isNull);

      expect(girone.incontriDi('PN Riviera 2'), hasLength(4));
      // Il prossimo salta la rinviata.
      expect(girone.prossimoDi('PN Riviera 2'), same(daGiocare));
    });

    test('senza classifica le squadre si prendono dal calendario', () {
      final soloCalendario = _girone.replaceAll(
        RegExp(r'<table class="table">.*?</table>', dotAll: true),
        '',
      );
      final girone = leggiGironeFin(soloCalendario, cmpId: 210);
      expect(girone.classifica, isEmpty);
      expect(girone.squadre, [
        'Onde Verdi',
        'PN Riviera 2',
        'Rari Nantes Sud-Est',
      ]);
    });
  });

  test('le pagine della demo si leggono come quelle vere', () {
    final elenco = leggiElencoFin(paginaElencoDemoFin());
    expect(elenco.stagione, stagioneDemoFin);
    expect(elenco.voci, hasLength(4));
    expect(elenco.voci[2].campionato, 'Under 14 (M)');

    final girone = leggiGironeFin(
      paginaGironeDemoFin(229, oggi: DateTime(2026, 10, 20)),
      cmpId: 229,
    );
    expect(girone.classifica, hasLength(6));
    expect(girone.giornate, hasLength(5));
    expect(girone.rigaDi(squadraDemoFin), isNotNull);
    // Al 20 ottobre si sono giocate le prime due giornate (3 e 17).
    expect(girone.rigaDi(squadraDemoFin)!.giocate, 2);
    expect(girone.prossimoDi(squadraDemoFin)?.data, DateTime(2026, 10, 31));
    for (final g in girone.giornate) {
      expect(g.incontri, hasLength(3));
    }
  });

  test('stessaSquadra ignora maiuscole e spazi', () {
    expect(stessaSquadra(' NC  Monza', 'nc monza'), isTrue);
    expect(stessaSquadra('NC Monza', 'NC Monza 2'), isFalse);
  });
}
