// Le pagine vere del sito FIN Lombardia lette il 27 ottobre 2026 (stagione
// 2026-2027), ridotte al contenuto: senza intestazione, script e menu.
// Servono a vedere che il lettore capisce il sito com'è oggi e che il
// controllo «il sito è cambiato» non scatta sulle pagine buone.

/// L'elenco dei campionati 2026-2027 (18 gironi).
const paginaElencoVera = r'''
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
Campionati trovati: 18                </span>
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
<tr class="campionato-header-row"><td colspan="2"><i class="bi bi-award-fill me-2 text-warning"></i>Allieve invernale (F)</td></tr>                                <tr class="clickable-row" onclick="window.location='PN-Incontri.php?CMPid=266';">
<td class="fw-semibold text-dark">
<i class="bi bi-diagram-2 me-1 text-primary opacity-75"></i>
Qualificazioni                                                                            </td>
<td class="text-secondary fw-medium">
Girone 1                                    </td>
</tr>
<tr class="campionato-header-row"><td colspan="2"><i class="bi bi-award-fill me-2 text-warning"></i>Allievi (M)</td></tr>                                <tr class="clickable-row" onclick="window.location='PN-Incontri.php?CMPid=260';">
<td class="fw-semibold text-dark">
<i class="bi bi-diagram-2 me-1 text-primary opacity-75"></i>
Qualificazioni                                                                            </td>
<td class="text-secondary fw-medium">
Coppa Lombardia                                    </td>
</tr>
<tr class="clickable-row" onclick="window.location='PN-Incontri.php?CMPid=261';">
<td class="fw-semibold text-dark">
</td>
<td class="text-secondary fw-medium">
Girone 1                                    </td>
</tr>
<tr class="clickable-row" onclick="window.location='PN-Incontri.php?CMPid=262';">
<td class="fw-semibold text-dark">
</td>
<td class="text-secondary fw-medium">
Girone 2                                    </td>
</tr>
<tr class="clickable-row" onclick="window.location='PN-Incontri.php?CMPid=263';">
<td class="fw-semibold text-dark">
</td>
<td class="text-secondary fw-medium">
Girone 3                                    </td>
</tr>
<tr class="clickable-row" onclick="window.location='PN-Incontri.php?CMPid=264';">
<td class="fw-semibold text-dark">
</td>
<td class="text-secondary fw-medium">
Girone 4                                    </td>
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
<tr class="clickable-row" onclick="window.location='PN-Incontri.php?CMPid=252';">
<td class="fw-semibold text-dark">
</td>
<td class="text-secondary fw-medium">
Girone 3                                    </td>
</tr>
<tr class="clickable-row" onclick="window.location='PN-Incontri.php?CMPid=253';">
<td class="fw-semibold text-dark">
</td>
<td class="text-secondary fw-medium">
Girone 4                                    </td>
</tr>
<tr class="campionato-header-row"><td colspan="2"><i class="bi bi-award-fill me-2 text-warning"></i>Juniores A  preliminary round (M)</td></tr>                                <tr class="clickable-row" onclick="window.location='PN-Incontri.php?CMPid=248';">
<td class="fw-semibold text-dark">
<i class="bi bi-diagram-2 me-1 text-primary opacity-75"></i>
Qualificazioni                                                                            </td>
<td class="text-secondary fw-medium">
Girone 5                                    </td>
</tr>
<tr class="clickable-row" onclick="window.location='PN-Incontri.php?CMPid=247';">
<td class="fw-semibold text-dark">
</td>
<td class="text-secondary fw-medium">
Girone 6                                    </td>
</tr>
<tr class="campionato-header-row"><td colspan="2"><i class="bi bi-award-fill me-2 text-warning"></i>Ragazzi (M/F)</td></tr>                                <tr class="clickable-row" onclick="window.location='PN-Incontri.php?CMPid=254';">
<td class="fw-semibold text-dark">
<i class="bi bi-diagram-2 me-1 text-primary opacity-75"></i>
Qualificazioni                                                                            </td>
<td class="text-secondary fw-medium">
Girone 1                                    </td>
</tr>
<tr class="clickable-row" onclick="window.location='PN-Incontri.php?CMPid=255';">
<td class="fw-semibold text-dark">
</td>
<td class="text-secondary fw-medium">
Girone 2                                    </td>
</tr>
<tr class="clickable-row" onclick="window.location='PN-Incontri.php?CMPid=256';">
<td class="fw-semibold text-dark">
</td>
<td class="text-secondary fw-medium">
Girone 3                                    </td>
</tr>
<tr class="clickable-row" onclick="window.location='PN-Incontri.php?CMPid=257';">
<td class="fw-semibold text-dark">
</td>
<td class="text-secondary fw-medium">
Girone 4                                    </td>
</tr>
<tr class="clickable-row" onclick="window.location='PN-Incontri.php?CMPid=258';">
<td class="fw-semibold text-dark">
</td>
<td class="text-secondary fw-medium">
Girone 5                                    </td>
</tr>
<tr class="clickable-row" onclick="window.location='PN-Incontri.php?CMPid=259';">
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

/// Ragazzi (M/F), Qualificazioni, Girone 6 (CMPid 259).
const paginaGironeVera = r'''
<div class="container-fluid px-4 my-4" style="max-width: 1100px;">
<div class="card card-custom p-3 mb-4">
<div class="d-flex align-items-center justify-content-between">
<h5 class="fw-bold text-dark mb-0">Ragazzi (M/F) - Qualificazioni - Girone 6</h5>
<span class="badge bg-light text-dark border font-monospace px-3 py-2 fs-6">
Stagione: 2026-2027                </span>
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
CANOTTIERI MILANO                                    </td>
<td class="text-center font-monospace fw-bold text-primary fs-6">
3                                    </td>
<td class="text-center font-monospace text-secondary">1</td>
<td class="text-center font-monospace text-success fw-semibold">1</td>
<td class="text-center font-monospace text-warning fw-semibold">0</td>
<td class="text-center font-monospace text-danger fw-semibold">0</td>
<td class="text-center font-monospace text-secondary">11</td>
<td class="text-center font-monospace text-secondary">3</td>
<td class="text-center font-monospace fw-bold text-success">
+8                                    </td>
</tr>
<tr>
<td class="fw-semibold text-dark">
<span class="text-secondary small font-monospace me-2">2.</span>
AN BRESCIA TEAM 2                                    </td>
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
<tr>
<td class="fw-semibold text-dark">
<span class="text-secondary small font-monospace me-2">3.</span>
PALLANUOTO MONZA                                    </td>
<td class="text-center font-monospace fw-bold text-primary fs-6">
0                                    </td>
<td class="text-center font-monospace text-secondary">1</td>
<td class="text-center font-monospace text-success fw-semibold">0</td>
<td class="text-center font-monospace text-warning fw-semibold">0</td>
<td class="text-center font-monospace text-danger fw-semibold">1</td>
<td class="text-center font-monospace text-secondary">3</td>
<td class="text-center font-monospace text-secondary">11</td>
<td class="text-center font-monospace fw-bold text-danger">
-8                                    </td>
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
<tr class="giornata-header-row"><td colspan="6"><i class="bi bi-flag-fill me-2"></i>1ª Giornata (Andata)</td></tr>                                <tr class="clickable-row" onclick="window.location='PN-Incontri-mod.php?INCid=6537';">
<td>
<div class="fw-bold text-dark">
CANOTTIERI MILANO                                            <span class="text-muted font-monospace mx-1">—</span>
PALLANUOTO MONZA                                        </div>
<div class="small text-secondary text-truncate" style="max-width: 450px;">
<i class="bi bi-geo-alt me-1 text-danger opacity-75"></i>CANOTTIERI MILANO                                            </div>
</td>
<td class="text-center font-monospace small text-secondary">
<i class="bi bi-clock me-1 text-primary opacity-75"></i>17:00                                                                            </td>
<td class="small text-secondary">
domenica 25/10/2026                                    </td>
<td class="text-center">
<span class="badge font-monospace px-2 py-1 fs-6 bg-warning-subtle text-warning-emphasis border border-warning-subtle fw-normal" title="Stato: Risultato GUG">
11 - 3                                            </span>
</td>
<td class="small text-secondary">
<i class="bi bi-person-badge me-1 text-muted"></i>Pusineri                                                                            </td>
</tr>
<tr class="giornata-header-row"><td colspan="6"><i class="bi bi-flag-fill me-2"></i>2ª Giornata (Andata)</td></tr>                                <tr class="clickable-row" onclick="window.location='PN-Incontri-mod.php?INCid=6538';">
<td>
<div class="fw-bold text-dark">
CANOTTIERI MILANO                                            <span class="text-muted font-monospace mx-1">—</span>
AN BRESCIA TEAM 2                                        </div>
<div class="small text-secondary text-truncate" style="max-width: 450px;">
<i class="bi bi-geo-alt me-1 text-danger opacity-75"></i>CANOTTIERI MILANO                                            </div>
</td>
<td class="text-center font-monospace small text-secondary">
<i class="bi bi-clock me-1 text-primary opacity-75"></i>17:00                                                                            </td>
<td class="small text-secondary">
domenica 15/11/2026                                    </td>
<td class="text-center">
<span class="badge bg-light text-secondary border font-monospace px-2 py-1 fw-normal" title="Stato: Incontro da disputare">
da disputare
</span>
</td>
<td class="small text-secondary">
-                                    </td>
</tr>
<tr class="giornata-header-row"><td colspan="6"><i class="bi bi-flag-fill me-2"></i>3ª Giornata (Andata)</td></tr>                                <tr class="clickable-row" onclick="window.location='PN-Incontri-mod.php?INCid=6539';">
<td>
<div class="fw-bold text-dark">
AN BRESCIA TEAM 2                                            <span class="text-muted font-monospace mx-1">—</span>
PALLANUOTO MONZA                                        </div>
<div class="small text-secondary text-truncate" style="max-width: 450px;">
<i class="bi bi-geo-alt me-1 text-danger opacity-75"></i>CENTRO NATATORIO COMUNALE MOMPIANO                                            </div>
</td>
<td class="text-center font-monospace small text-secondary">
<i class="bi bi-clock me-1 text-primary opacity-75"></i>19:30                                                                            </td>
<td class="small text-secondary">
domenica 29/11/2026                                    </td>
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
