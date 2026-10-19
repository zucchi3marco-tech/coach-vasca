/// Le pagine del sito FIN nella modalità demo, dove il server non c'è:
/// stessa forma delle pagine vere (vedi `lettore_fin.dart`), squadre
/// inventate. Il girone di prova ha la squadra della demo, "PN Riviera",
/// con le partite già giocate prima di [oggi] e le altre da giocare.
const stagioneDemoFin = '2026-2027';
const squadraDemoFin = 'PN Riviera';

String paginaElencoDemoFin() {
  // Come il sito: la fase solo sulla prima riga di un campionato.
  const campionati = [
    ('Under 12 (M/F)', [(228, 'Fase 1', 'Girone 1')]),
    ('Under 14 (M)', [(229, 'Fase 1', 'Girone 1'), (230, '', 'Girone 2')]),
    ('Under 16 (F)', [(231, 'Fase1', 'Girone1')]),
  ];
  final righe = StringBuffer();
  for (final (campionato, gironi) in campionati) {
    righe.write(
      '<tr class="campionato-header-row"><td colspan="2"><i class="bi bi-award-fill me-2 text-warning"></i>$campionato</td></tr>',
    );
    for (final (id, fase, girone) in gironi) {
      righe.write('''
                                <tr class="clickable-row" onclick="window.location='PN-Incontri.php?CMPid=$id';">
                                    <td class="fw-semibold text-dark">
                                            $fase                                    </td>
                                    <td class="text-secondary fw-medium">
                                        $girone                                    </td>
                                </tr>
''');
    }
  }
  return '''
<html><body>
<div class="page-header-title text-uppercase my-1 me-auto ms-3 text-truncate">
    <i class="bi bi-dribbble me-2 text-warning"></i>Campionati Regionali Pallanuoto $stagioneDemoFin            </div>
<label class="fw-bold text-dark small text-uppercase mb-0">Stagione:</label>
<div class="dropdown">
    <button class="btn btn-sm btn-outline-secondary dropdown-toggle rounded-pill px-3 fw-semibold" type="button" id="dropStagione" data-bs-toggle="dropdown" aria-expanded="false">
        $stagioneDemoFin                        </button>
    <ul class="dropdown-menu shadow-sm border-0 rounded-3" aria-labelledby="dropStagione">
        <li><a class="dropdown-item fw-medium" href="?Stagione=2025-2026">2025-2026</a></li>
        <li><a class="dropdown-item fw-medium" href="?Stagione=2026-2027">2026-2027</a></li>
    </ul>
</div>
<table class="table table-custom align-middle mb-0">
<thead><tr><th style="width: 40%;">Fase</th><th style="width: 30%;">Girone</th></tr></thead>
<tbody>
$righe</tbody></table>
</body></html>
''';
}

String paginaGironeDemoFin(int cmpId, {DateTime? oggi}) {
  final adesso = oggi ?? DateTime.now();
  const squadre = [
    squadraDemoFin,
    'Delfini Ravenna',
    'Nuoto Club Cesena',
    'Rari Nantes Rimini',
    'Sportiva Faenza',
    'Pallanuoto Ferrara',
  ];
  // Un girone all'italiana: 5 giornate di andata, un sabato ogni due,
  // dal 3 ottobre 2026.
  final giornate = <(String, List<(String, String, DateTime, String?)>)>[];
  final rotazione = [...squadre];
  for (var g = 0; g < squadre.length - 1; g++) {
    final data = DateTime(2026, 10, 3 + 14 * g);
    final incontri = <(String, String, DateTime, String?)>[];
    for (var i = 0; i < squadre.length ~/ 2; i++) {
      final casa = rotazione[i];
      final ospite = rotazione[squadre.length - 1 - i];
      final giocata = data.isBefore(
        DateTime(adesso.year, adesso.month, adesso.day),
      );
      // Risultati fissi e credibili: dipendono solo dai nomi.
      final golCasa = 6 + (casa.length * 3 + g) % 9;
      final golOspite = 5 + (ospite.length * 2 + i) % 8;
      incontri.add((
        casa,
        ospite,
        data,
        giocata ? '$golCasa - $golOspite' : null,
      ));
    }
    giornate.add(('${g + 1}ª Giornata (Andata)', incontri));
    // Rotazione del metodo "a cerchio": la prima squadra resta ferma.
    rotazione.insert(1, rotazione.removeLast());
  }

  final punti = {
    for (final s in squadre) s: [0, 0, 0, 0, 0, 0, 0],
  };
  for (final (_, incontri) in giornate) {
    for (final (casa, ospite, _, risultato) in incontri) {
      if (risultato == null) continue;
      final gol = [for (final g in risultato.split('-')) int.parse(g.trim())];
      void conta(String s, int fatti, int subiti) {
        final r = punti[s]!;
        r[1]++;
        if (fatti > subiti) {
          r[0] += 3;
          r[2]++;
        } else if (fatti == subiti) {
          r[0] += 1;
          r[3]++;
        } else {
          r[4]++;
        }
        r[5] += fatti;
        r[6] += subiti;
      }

      conta(casa, gol[0], gol[1]);
      conta(ospite, gol[1], gol[0]);
    }
  }
  final ordine = [...squadre]
    ..sort((a, b) {
      final pa = punti[a]!, pb = punti[b]!;
      final perPunti = pb[0].compareTo(pa[0]);
      if (perPunti != 0) return perPunti;
      return (pb[5] - pb[6]).compareTo(pa[5] - pa[6]);
    });

  final classifica = StringBuffer();
  for (final (posizione, s) in ordine.indexed) {
    final r = punti[s]!;
    final differenza = r[5] - r[6];
    classifica.write('''
                                <tr>
                                    <td class="fw-semibold text-dark">
                                        <span class="text-secondary small font-monospace me-2">${posizione + 1}.</span>
                                        $s                                    </td>
                                    <td class="text-center font-monospace fw-bold text-primary fs-6">
                                        ${r[0]}                                    </td>
                                    <td class="text-center font-monospace text-secondary">${r[1]}</td>
                                    <td class="text-center font-monospace text-success fw-semibold">${r[2]}</td>
                                    <td class="text-center font-monospace text-warning fw-semibold">${r[3]}</td>
                                    <td class="text-center font-monospace text-danger fw-semibold">${r[4]}</td>
                                    <td class="text-center font-monospace text-secondary">${r[5]}</td>
                                    <td class="text-center font-monospace text-secondary">${r[6]}</td>
                                    <td class="text-center font-monospace fw-bold text-success">
                                        ${differenza > 0 ? '+' : ''}$differenza                                    </td>
                                </tr>
''');
  }
  const giorni = [
    '',
    'lunedi',
    'martedi',
    'mercoledi',
    'giovedi',
    'venerdi',
    'sabato',
    'domenica',
  ];
  final calendario = StringBuffer();
  for (final (nome, incontri) in giornate) {
    calendario.write(
      '<tr class="giornata-header-row"><td colspan="6"><i class="bi bi-flag-fill me-2"></i>$nome</td></tr>',
    );
    for (final (casa, ospite, data, risultato) in incontri) {
      final piscina = casa == squadraDemoFin
          ? 'RN-Piscina Comunale Bulgarelli'
          : 'Piscina della squadra di casa';
      final badge = risultato == null
          ? '<span class="badge bg-light text-secondary border font-monospace px-2 py-1 fw-normal" title="Stato: Incontro da disputare">\n'
                '                                                da disputare\n'
                '                                            </span>'
          : '<span class="badge font-monospace px-2 py-1 fs-6 bg-success-subtle text-success border border-success-subtle fw-bold" title="Stato: Omologato CRL">\n'
                '                                                $risultato                                            </span>';
      calendario.write('''
                                <tr class="clickable-row" onclick="window.location='PN-Incontri-mod.php?INCid=1';">
                                    <td>
                                        <div class="fw-bold text-dark">
                                            $casa                                            <span class="text-muted font-monospace mx-1">—</span>
                                            $ospite                                        </div>
                                        <div class="small text-secondary text-truncate" style="max-width: 450px;">
                                            <i class="bi bi-geo-alt me-1 text-danger opacity-75"></i>$piscina                                            </div>
                                    </td>
                                    <td class="text-center font-monospace small text-secondary">
                                        <i class="bi bi-clock me-1 text-primary opacity-75"></i>15.00                                    </td>
                                    <td class="small text-secondary">
                                        ${giorni[data.weekday]} ${data.day}/${data.month}/${data.year}                                    </td>
                                    <td class="text-center">
                                        $badge
                                    </td>
                                    <td class="small text-secondary">
                                        -                                    </td>
                                </tr>
''');
    }
  }
  final titolo = switch (cmpId) {
    228 => 'Under 12 (M/F) - Fase 1 - Girone 1',
    230 => 'Under 14 (M) - Fase 1 - Girone 2',
    231 => 'Under 16 (F) - Fase1 - Girone1',
    _ => 'Under 14 (M) - Fase 1 - Girone 1',
  };
  return '''
<html><body>
<div class="page-header-title text-uppercase my-1 me-auto ms-3 text-truncate">
    <i class="bi bi-dribbble me-2 text-warning"></i>Campionati Regionali Pallanuoto $stagioneDemoFin            </div>
<div class="container-fluid px-4 my-4" style="max-width: 1100px;">
<div class="card card-custom p-3 mb-4">
    <div class="d-flex align-items-center justify-content-between">
        <h5 class="fw-bold text-dark mb-0">$titolo</h5>
        <span class="badge bg-light text-dark border font-monospace px-3 py-2 fs-6">
            Stagione: $stagioneDemoFin                </span>
    </div>
</div>
<div class="card card-custom overflow-hidden mb-4">
    <div class="p-3 border-bottom bg-light d-flex align-items-center justify-content-between">
        <h6 class="fw-bold text-dark mb-0"><i class="bi bi-trophy me-2 text-warning"></i>Classifica Generale</h6>
    </div>
    <div class="table-responsive">
        <table class="table table-custom align-middle mb-0">
            <thead><tr>
                <th>Squadra</th><th class="text-center">Punti</th><th class="text-center">G</th><th class="text-center">V</th><th class="text-center">N</th><th class="text-center">P</th><th class="text-center">GF</th><th class="text-center">GS</th><th class="text-center">Diff</th>
            </tr></thead>
            <tbody>
$classifica            </tbody>
        </table>
    </div>
</div>
<div class="card card-custom overflow-hidden">
    <div class="p-3 border-bottom bg-light">
        <h6 class="fw-bold text-dark mb-0"><i class="bi bi-calendar-event me-2 text-primary"></i>Calendario Gare</h6>
    </div>
    <div class="table-responsive">
        <table class="table table-custom align-middle mb-0">
            <thead><tr>
                <th>Incontro / Impianto</th><th class="text-center">Orario</th><th>Data Gara</th><th class="text-center">Risultato</th><th>Arbitro</th>
            </tr></thead>
            <tbody>
$calendario            </tbody>
        </table>
    </div>
</div>
</div>
</body></html>
''';
}
