import 'package:coach_vasca/features/campionati/data/pagine_fin_demo.dart';
import 'package:coach_vasca/features/campionati/domain/campionato_fin.dart';
import 'package:coach_vasca/features/campionati/domain/lettore_fin.dart';
import 'package:flutter_test/flutter_test.dart';

// Pezzi delle pagine vere di finlombardia.net dopo il cambio del 19 ottobre
// 2026, con la loro forma esatta e squadre, piscine e arbitri inventati.
const _elencoNuovo = '''
<nav class="navbar navbar-expand-lg navbar-light bg-white border-bottom sticky-top shadow-sm">
    <div class="container-fluid px-4">
        <div class="page-header-title text-uppercase my-1 me-auto ms-3 text-truncate">
            <i class="bi bi-dribbble me-2 text-warning"></i>Campionati Regionali Pallanuoto 2026-2027            </div>
    </div>
</nav>
<div class="container-fluid px-4 my-4" style="max-width: 900px;">
    <div class="card card-custom p-3 mb-4">
        <div class="d-flex align-items-center justify-content-between flex-wrap gap-2">
            <div class="d-flex align-items-center gap-3">
                <label class="fw-bold text-dark small text-uppercase mb-0"><i class="bi bi-calendar-range me-1 text-primary"></i>Stagione:</label>
                <div class="dropdown">
                    <button class="btn btn-sm btn-outline-secondary dropdown-toggle rounded-pill px-3 fw-semibold" type="button" id="dropStagione" data-bs-toggle="dropdown" aria-expanded="false">
                        2026-2027                        </button>
                    <ul class="dropdown-menu shadow-sm border-0 rounded-3" aria-labelledby="dropStagione">
                        <li><a class="dropdown-item fw-medium" href="?Stagione=2023-2024">2023-2024</a></li>
                        <li><a class="dropdown-item fw-medium" href="?Stagione=2024-2025">2024-2025</a></li>
                        <li><a class="dropdown-item fw-medium" href="?Stagione=2025-2026">2025-2026</a></li>
                        <li><a class="dropdown-item fw-medium" href="?Stagione=2026-2027">2026-2027</a></li>
                    </ul>
                </div>
            </div>
            <span class="badge bg-light text-dark border font-monospace px-3 py-2 fs-6">
                Campionati trovati: 5                </span>
        </div>
    </div>
    <div class="card card-custom overflow-hidden">
        <div class="table-responsive">
            <table class="table table-custom align-middle mb-0">
                <thead>
                    <tr>
                        <th style="width: 40%;">Fase</th>
                        <th style="width: 30%;">Girone</th>
                                                </tr>
                </thead>
                <tbody>
                    <tr class="campionato-header-row"><td colspan="2"><i class="bi bi-award-fill me-2 text-warning"></i>Allievi (M)</td></tr>                                <tr class="clickable-row" onclick="window.location='PN-Incontri.php?CMPid=260';">
                                <td class="fw-semibold text-dark">
                                                                                <i class="bi bi-diagram-2 me-1 text-primary opacity-75"></i>
                                        Qualificazioni                                                                            </td>

                                <td class="text-secondary fw-medium">
                                    -                                    </td>

                                                                </tr>
                        <tr class="campionato-header-row"><td colspan="2"><i class="bi bi-award-fill me-2 text-warning"></i>Esordienti (M/F)</td></tr>                                <tr class="clickable-row" onclick="window.location='PN-Incontri.php?CMPid=250';">
                                <td class="fw-semibold text-dark">
                                                                                <i class="bi bi-diagram-2 me-1 text-primary opacity-75"></i>
                                        Qualificazioni                                                                            </td>

                                <td class="text-secondary fw-medium">
                                    Girone 1                                    </td>

                                                                </tr>
                                                        <tr class="clickable-row" onclick="window.location='PN-Incontri.php?CMPid=251';">
                                <td class="fw-semibold text-dark">
                                                                        </td>

                                <td class="text-secondary fw-medium">
                                    Girone 2                                    </td>

                                                                </tr>
                        <tr class="campionato-header-row"><td colspan="2"><i class="bi bi-award-fill me-2 text-warning"></i>Juniores A  preliminary round (M)</td></tr>                                <tr class="clickable-row" onclick="window.location='PN-Incontri.php?CMPid=248';">
                                <td class="fw-semibold text-dark">
                                                                                <i class="bi bi-diagram-2 me-1 text-primary opacity-75"></i>
                                        Fase1                                                                            </td>

                                <td class="text-secondary fw-medium">
                                    Girone5                                    </td>

                                                                </tr>
                                                        <tr class="clickable-row" onclick="window.location='PN-Incontri.php?CMPid=247';">
                                <td class="fw-semibold text-dark">
                                                                        </td>

                                <td class="text-secondary fw-medium">
                                    Girone 6                                    </td>

                                                                </tr>
                                                                    </tbody>
            </table>
        </div>
    </div>
</div>
''';

const _gironeNuovo = '''
<nav class="navbar navbar-expand-lg navbar-light bg-white border-bottom sticky-top shadow-sm">
    <div class="container-fluid px-4">
        <div class="page-header-title text-uppercase my-1 me-auto ms-3 text-truncate">
            <i class="bi bi-dribbble me-2 text-warning"></i>Campionati Regionali Pallanuoto 2025-2026            </div>
    </div>
</nav>
<div class="container-fluid px-4 my-4" style="max-width: 1100px;">
    <div class="card card-custom p-3 mb-4">
        <div class="d-flex align-items-center justify-content-between">
            <h5 class="fw-bold text-dark mb-0">Cadetti  (M) - Fase1 - Girone1</h5>
            <span class="badge bg-light text-dark border font-monospace px-3 py-2 fs-6">
                Stagione: 2025-2026                </span>
        </div>
    </div>
    <div class="card card-custom overflow-hidden mb-4">
        <div class="p-3 border-bottom bg-light d-flex align-items-center justify-content-between">
            <h6 class="fw-bold text-dark mb-0"><i class="bi bi-trophy me-2 text-warning"></i>Classifica Generale</h6>
        </div>
        <div class="table-responsive">
            <table class="table table-custom align-middle mb-0">
                <thead>
                    <tr>
                        <th>Squadra</th>
                        <th class="text-center" style="width: 70px;">Punti</th>
                        <th class="text-center" style="width: 65px;">G</th>
                        <th class="text-center" style="width: 65px;">V</th>
                        <th class="text-center" style="width: 65px;">N</th>
                        <th class="text-center" style="width: 65px;">P</th>
                        <th class="text-center" style="width: 75px;">GF</th>
                        <th class="text-center" style="width: 75px;">GS</th>
                        <th class="text-center" style="width: 80px;">Diff</th>
                    </tr>
                </thead>
                <tbody>
                                                    <tr>
                            <td class="fw-semibold text-dark">
                                <span class="text-secondary small font-monospace me-2">1.</span>
                                Onde Verdi                                    </td>
                            <td class="text-center font-monospace fw-bold text-primary fs-6">
                                6                                    </td>
                            <td class="text-center font-monospace text-secondary">2</td>
                            <td class="text-center font-monospace text-success fw-semibold">2</td>
                            <td class="text-center font-monospace text-warning fw-semibold">0</td>
                            <td class="text-center font-monospace text-danger fw-semibold">0</td>
                            <td class="text-center font-monospace text-secondary">56</td>
                            <td class="text-center font-monospace text-secondary">12</td>
                            <td class="text-center font-monospace fw-bold text-success">
                                +44                                    </td>
                        </tr>
                                                    <tr>
                            <td class="fw-semibold text-dark">
                                <span class="text-secondary small font-monospace me-2">2.</span>
                                Rari Nantes Sud-Est                                    </td>
                            <td class="text-center font-monospace fw-bold text-primary fs-6">
                                0                                    </td>
                            <td class="text-center font-monospace text-secondary">2</td>
                            <td class="text-center font-monospace text-success fw-semibold">0</td>
                            <td class="text-center font-monospace text-warning fw-semibold">0</td>
                            <td class="text-center font-monospace text-danger fw-semibold">2</td>
                            <td class="text-center font-monospace text-secondary">12</td>
                            <td class="text-center font-monospace text-secondary">56</td>
                            <td class="text-center font-monospace fw-bold text-danger">
                                -44                                    </td>
                        </tr>
                                                    <tr>
                            <td class="fw-semibold text-dark">
                                <span class="text-secondary small font-monospace me-2">3.</span>
                                N.C. RIVIERA 2                                    </td>
                            <td class="text-center font-monospace fw-bold text-primary fs-6">
                                0                                    </td>
                            <td class="text-center font-monospace text-secondary">0</td>
                            <td class="text-center font-monospace text-success fw-semibold">0</td>
                            <td class="text-center font-monospace text-warning fw-semibold">0</td>
                            <td class="text-center font-monospace text-danger fw-semibold">0</td>
                            <td class="text-center font-monospace text-secondary">0</td>
                            <td class="text-center font-monospace text-secondary">0</td>
                            <td class="text-center font-monospace fw-bold text-success">
                                0                                    </td>
                        </tr>
                                            </tbody>
            </table>
        </div>
    </div>
    <div class="card card-custom overflow-hidden">
        <div class="p-3 border-bottom bg-light">
            <h6 class="fw-bold text-dark mb-0"><i class="bi bi-calendar-event me-2 text-primary"></i>Calendario Gare</h6>
        </div>
        <div class="table-responsive">
            <table class="table table-custom align-middle mb-0">
                <thead>
                    <tr>
                        <th>Incontro / Impianto</th>
                        <th style="width: 110px;" class="text-center">Orario</th>
                        <th style="width: 170px;">Data Gara</th>
                        <th style="width: 120px;" class="text-center">Risultato</th>
                        <th style="width: 150px;">Arbitro</th>
                                                </tr>
                </thead>
                <tbody>
                    <tr class="giornata-header-row"><td colspan="6"><i class="bi bi-flag-fill me-2"></i>1ª Giornata (Andata)</td></tr>                                <tr class="clickable-row" onclick="window.location='PN-Incontri-mod.php?INCid=6316';">
                                <!-- SQUADRE + IMPIANTO (A CAPO) -->
                                <td>
                                    <div class="fw-bold text-dark">
                                        Onde Verdi                                            <span class="text-muted font-monospace mx-1">—</span>
                                        Rari Nantes Sud-Est                                        </div>
                                                                                <div class="small text-secondary text-truncate" style="max-width: 450px;">
                                            <i class="bi bi-geo-alt me-1 text-danger opacity-75"></i>MB-Comunale del Parco                                            </div>
                                                                        </td>
                                <!-- ORARIO -->
                                <td class="text-center font-monospace small text-secondary">
                                                                                <i class="bi bi-clock me-1 text-primary opacity-75"></i>19.30                                                                            </td>
                                <!-- DATA GARA -->
                                <td class="small text-secondary">
                                    domenica 3/5/2026                                    </td>
                                <!-- RISULTATO (BADGE DIVERSIFICATO PER STATO) -->
                                <td class="text-center">
                                                                                <span class="badge font-monospace px-2 py-1 fs-6 bg-success-subtle text-success border border-success-subtle fw-bold" title="Stato: Omologato CRL">
                                            29 - 4                                            </span>
                                                                        </td>
                                <!-- ARBITRO -->
                                <td class="small text-secondary">
                                    <i class="bi bi-person-badge me-1 text-muted"></i>Verdi                                                                            </td>
                                <!-- AZIONE EDIT -->
                                                                </tr>
                                                        <tr class="clickable-row" onclick="window.location='PN-Incontri-mod.php?INCid=6317';">
                                <td>
                                    <div class="fw-bold text-dark">
                                        N.C. RIVIERA 2                                            <span class="text-muted font-monospace mx-1">—</span>
                                        Riposo                                        </div>
                                                                        </td>
                                <td class="text-center font-monospace small text-secondary">
                                    -                                    </td>
                                <td class="small text-secondary">
                                    -                                    </td>
                                <td class="text-center">
                                                                                <span class="badge bg-light text-secondary border font-monospace px-2 py-1 fw-normal" title="Stato: Incontro da disputare">
                                            da disputare
                                        </span>
                                                                        </td>
                                <td class="small text-secondary">
                                    -                                    </td>
                                                                </tr>
                    <tr class="giornata-header-row"><td colspan="6"><i class="bi bi-flag-fill me-2"></i>2ª Giornata (Andata)</td></tr>                                <tr class="clickable-row" onclick="window.location='PN-Incontri-mod.php?INCid=6318';">
                                <td>
                                    <div class="fw-bold text-dark">
                                        Rari Nantes Sud-Est                                            <span class="text-muted font-monospace mx-1">—</span>
                                        N.C. RIVIERA 2                                        </div>
                                                                                <div class="small text-secondary text-truncate" style="max-width: 450px;">
                                            <i class="bi bi-geo-alt me-1 text-danger opacity-75"></i>BG-Piscine di Dalmine                                            </div>
                                                                        </td>
                                <td class="text-center font-monospace small text-secondary">
                                                                                <i class="bi bi-clock me-1 text-primary opacity-75"></i>18:45                                                                            </td>
                                <td class="small text-secondary">
                                    sabato 9/5/2026                                    </td>
                                <td class="text-center">
                                                                                <span class="badge bg-warning-subtle text-warning border font-monospace px-2 py-1 fw-normal" title="Stato: Rinviata">
                                            rinviata
                                        </span>
                                                                        </td>
                                <td class="small text-secondary">
                                    -                                    </td>
                                                                </tr>
                                                        <tr class="clickable-row" onclick="window.location='PN-Incontri-mod.php?INCid=6319';">
                                <td>
                                    <div class="fw-bold text-dark">
                                        N.C. RIVIERA 2                                            <span class="text-muted font-monospace mx-1">—</span>
                                        Onde Verdi                                        </div>
                                                                                <div class="small text-secondary text-truncate" style="max-width: 450px;">
                                            <i class="bi bi-geo-alt me-1 text-danger opacity-75"></i>PISCINA COMUNALE DALMINE                                            </div>
                                                                        </td>
                                <td class="text-center font-monospace small text-secondary">
                                                                                <i class="bi bi-clock me-1 text-primary opacity-75"></i>00:00                                                                            </td>
                                <td class="small text-secondary">
                                    domenica 17/5/2026                                    </td>
                                <td class="text-center">
                                                                                <span class="badge bg-light text-secondary border font-monospace px-2 py-1 fw-normal" title="Stato: Incontro da disputare">
                                            da disputare
                                        </span>
                                                                        </td>
                                <td class="small text-secondary">
                                    -                                    </td>
                                                                </tr>
                                                                    </tbody>
            </table>
        </div>
    </div>
</div>
''';

// La forma di prima (fino al 19 ottobre 2026): si legge ancora, nel caso il
// sito torni indietro o una copia salvata sul telefono sia di allora.
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
    test('legge stagione, stagioni e gironi: il campionato sta nella riga '
        'sopra, la fase solo sulla prima riga', () {
      final elenco = leggiElencoFin(_elencoNuovo);
      expect(elenco.stagione, '2026-2027');
      expect(elenco.stagioni, [
        '2023-2024',
        '2024-2025',
        '2025-2026',
        '2026-2027',
      ]);
      expect([for (final v in elenco.voci) v.cmpId], [260, 250, 251, 248, 247]);

      // Un girone unico: il sito scrive "-" al posto del girone.
      final allievi = elenco.voci.first;
      expect(allievi.campionato, 'Allievi (M)');
      expect(allievi.fase, 'Qualificazioni');
      expect(allievi.girone, '');
      expect(allievi.faseEGirone, 'Qualificazioni');

      // La seconda riga di un campionato ha la fase vuota: vale quella sopra.
      final secondo = elenco.voci[2];
      expect(secondo.campionato, 'Esordienti (M/F)');
      expect(secondo.faseEGirone, 'Qualificazioni · Girone 2');

      expect(elenco.voci[3].campionato, 'Juniores A preliminary round (M)');
      expect(elenco.voci[3].faseEGirone, 'Fase 1 · Girone 5');
      expect(elenco.voci[4].faseEGirone, 'Fase 1 · Girone 6');
      expect(elenco.perCampionato.keys, [
        'Allievi (M)',
        'Esordienti (M/F)',
        'Juniores A preliminary round (M)',
      ]);
    });
  });

  group('pagina di un girone', () {
    test('legge titolo, stagione e classifica senza la posizione nel nome', () {
      final girone = leggiGironeFin(_gironeNuovo, cmpId: 244);
      expect(girone.stagione, '2025-2026');
      expect(girone.titolo, 'Cadetti (M) - Fase1 - Girone1');
      expect(
        [for (final r in girone.classifica) r.squadra],
        ['Onde Verdi', 'Rari Nantes Sud-Est', 'N.C. RIVIERA 2'],
      );
      final primi = girone.classifica.first;
      expect(
        [
          primi.posizione,
          primi.punti,
          primi.giocate,
          primi.vinte,
          primi.pareggiate,
          primi.perse,
          primi.golFatti,
          primi.golSubiti,
          primi.differenza,
        ],
        [1, 6, 2, 2, 0, 0, 56, 12, 44],
      );
      expect(girone.classifica[1].differenza, -44);
      expect(girone.rigaDi('n.c. riviera 2')?.posizione, 3);
    });

    test('legge il calendario: squadre e piscina nella stessa cella, «da '
        'disputare», il riposo e l\'orario non deciso', () {
      final girone = leggiGironeFin(_gironeNuovo, cmpId: 244);
      expect(
        [for (final g in girone.giornate) g.nome],
        ['1ª Giornata (Andata)', '2ª Giornata (Andata)'],
      );
      final primo = girone.giornate.first.incontri.first;
      expect(primo.casa, 'Onde Verdi');
      expect(primo.ospite, 'Rari Nantes Sud-Est');
      expect(primo.piscina, 'MB-Comunale del Parco');
      expect(primo.ora, '19:30');
      expect(primo.data, DateTime(2026, 5, 3));
      expect((primo.golCasa, primo.golOspite), (29, 4));
      expect(primo.arbitro, 'Verdi');

      final riposo = girone.giornate.first.incontri[1];
      expect(riposo.riposo, isTrue);
      expect(riposo.piscina, isNull);
      expect(riposo.ora, isNull);
      expect(riposo.data, isNull);
      expect(riposo.dataTesto, isNull);
      expect(riposo.risultatoTesto, isNull);
      expect(riposo.arbitro, isNull);

      final rinviata = girone.giornate[1].incontri.first;
      expect(rinviata.ora, '18:45');
      expect(rinviata.giocato, isFalse);
      expect(rinviata.risultatoTesto, 'rinviata');

      // «da disputare» non è un risultato; "00:00" è l'orario da decidere.
      final daGiocare = girone.giornate[1].incontri[1];
      expect(daGiocare.giocato, isFalse);
      expect(daGiocare.risultatoTesto, isNull);
      expect(daGiocare.ora, isNull);
      expect(daGiocare.data, DateTime(2026, 5, 17));
      expect(daGiocare.piscina, 'PISCINA COMUNALE DALMINE');

      expect(girone.incontriDi('N.C. Riviera 2'), hasLength(3));
      // Il prossimo salta il riposo e la rinviata.
      expect(girone.prossimoDi('N.C. Riviera 2'), same(daGiocare));
    });

    test('senza classifica le squadre si prendono dal calendario', () {
      final soloCalendario = _gironeNuovo.replaceAll(
        RegExp(
          r'<div class="card card-custom overflow-hidden mb-4">.*?</table>',
          dotAll: true,
        ),
        '',
      );
      final girone = leggiGironeFin(soloCalendario, cmpId: 244);
      expect(girone.classifica, isEmpty);
      expect(girone.squadre, [
        'N.C. RIVIERA 2',
        'Onde Verdi',
        'Rari Nantes Sud-Est',
      ]);
    });
  });

  group('elenco dei campionati, forma di prima', () {
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

  group('pagina di un girone, forma di prima', () {
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
