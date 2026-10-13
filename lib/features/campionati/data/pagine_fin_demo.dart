/// Le pagine del sito FIN nella modalità demo, dove il server non c'è:
/// stessa forma delle pagine vere (vedi `lettore_fin.dart`), squadre
/// inventate. Il girone di prova ha la squadra della demo, "PN Riviera",
/// con le partite già giocate prima di [oggi] e le altre da giocare.
const stagioneDemoFin = '2026-2027';
const squadraDemoFin = 'PN Riviera';

String paginaElencoDemoFin() {
  const voci = [
    (228, 'Under 12 (M/F)', 'Fase 1', 'Girone 1'),
    (229, 'Under 14 (M)', 'Fase 1', 'Girone 1'),
    (230, '', 'Fase 1', 'Girone 2'),
    (231, 'Under 16 (F)', 'Fase1', 'Girone1'),
  ];
  final righe = StringBuffer();
  for (final (id, campionato, fase, girone) in voci) {
    righe.write('''
                    <tr style="cursor:pointer" onclick="window.location = 'PN-Incontri.php?CMPid=$id'">
                        <td> $campionato                        </td>
                        <td>$fase</td>
                        <td class="text-center text-nowrap">$girone</td>
                    </tr>
''');
  }
  return '''
<html><body>
<h1 class="navbar me-auto ms-3">CAMPIONATI REGIONALI PALLANUOTO $stagioneDemoFin</h1>
<a class="btn btn-secondary dropdown-toggle" href="#" role="button" id="dropdownMenuLink" data-bs-toggle="dropdown">
    $stagioneDemoFin                    </a>
<ul class="dropdown-menu">
    <li><a class="dropdown-item" href="?Stagione=2025-2026">2025-2026</a></li>
    <li><a class="dropdown-item" href="?Stagione=2026-2027">2026-2027</a></li>
</ul>
<table class="table table-borderless table-hover table-sm"><tbody>
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
        giocata ? '$golCasa-$golOspite' : null,
      ));
    }
    giornate.add(('${g + 1}a giornata', incontri));
    // Rotazione del metodo "a cerchio": la prima squadra resta ferma.
    rotazione.insert(1, rotazione.removeLast());
  }

  final punti = {
    for (final s in squadre) s: [0, 0, 0, 0, 0, 0, 0],
  };
  for (final (_, incontri) in giornate) {
    for (final (casa, ospite, _, risultato) in incontri) {
      if (risultato == null) continue;
      final gol = risultato.split('-').map(int.parse).toList();
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
  for (final s in ordine) {
    final r = punti[s]!;
    classifica.write('''
                        <tr class="text-center">
                            <td class="text-start">$s</td>
                            <td>${r[0]}</td>
                            <td>${r[1]}</td>
                            <td>${r[2]}</td>
                            <td>${r[3]}</td>
                            <td>${r[4]}</td>
                            <td>${r[5]}</td>
                            <td>${r[6]}</td>
                            <td>${r[5] - r[6]}</td>
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
      '<tr class="border-top"><td class="fst-italic">$nome </td> <td></td> <td></td> <td></td> <td></td></tr>\n',
    );
    for (final (casa, ospite, data, risultato) in incontri) {
      final piscina = casa == squadraDemoFin
          ? 'RN-Piscina Comunale Bulgarelli'
          : 'Piscina della squadra di casa';
      calendario.write('''
                    <tr>
                        <td class="fw-bold text-nowrap">$casa - $ospite</td>
                        <td class="text-nowrap">$piscina</td>
                        <td class="text-start">15.00</td>
                        <td class="text-nowrap">${giorni[data.weekday]} ${data.day}/${data.month}/${data.year}</td>
                        <td class="text-center text-nowrap fw-bold">${risultato ?? ''}</td>
                        <td class="text-center">${risultato == null ? '' : '.'}</td>
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
<h1 class="navbar me-auto ms-3">CAMPIONATI REGIONALI PALLANUOTO $stagioneDemoFin</h1>
<div class="container mt-2">
<p class="text-center fs-3 fw-bold text-secondary mt-5">$titolo</p>
<table class="table">
<thead class="table-light border-light"><tr>
<th></th><th>Punti</th><th>Giocate</th><th>Vinte</th><th>Paregg.</th><th>Perse</th><th>Gol fatti</th><th>Gol subiti</th><th>Diff. reti</th>
</tr></thead>
<tbody class="border-top-0">
$classifica</tbody>
</table>
<table class="table table-borderless table-sm"><tbody>
$calendario</tbody></table>
</div>
</body></html>
''';
}
