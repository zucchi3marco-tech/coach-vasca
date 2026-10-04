// Rigenera la migrazione SQL con la libreria blocchi "di fabbrica" (quella
// che ogni nuovo club riceve alla creazione) a partire dal file Excel.
//
// Uso:
//   dart run tool/genera_seed_libreria.dart [file.xlsx] [file_output.sql]
//
// Senza argomenti: legge `libreria_blocchi_nuoto_pallanuoto.xlsx` nella
// radice del progetto e scrive una nuova migrazione con timestamp in
// `supabase/migrations/`. Il comando da lanciare per applicarla (sul
// progetto Supabase reale, come ogni altra migrazione) viene stampato
// alla fine — non viene eseguito da questo script.
//
// Da rilanciare solo quando il file Excel della libreria "di fabbrica"
// viene corretto o ampliato: il club del coach (e ogni altro club già
// esistente) si aggiorna invece con "Importa da Excel" nella schermata
// Libreria blocchi, non da qui.

import 'dart:io';

import 'package:coach_vasca/features/libreria_blocchi/application/excel_import.dart';

/// Club "modello", mai membro di nessun utente — vedi
/// `supabase/migrations/20261004000300_training_blocks.sql`.
const _clubModello = '00000000-0000-0000-0000-000000000001';

String _sqlText(String? s) {
  if (s == null) return 'null';
  return "'${s.replaceAll("'", "''")}'";
}

String _sqlInt(int? i) => i?.toString() ?? 'null';

String _bloccoSql(BloccoImportato b) {
  final buffer = StringBuffer();
  buffer.writeln('with b as (');
  buffer.writeln('  insert into public.training_blocks (');
  buffer.writeln(
    '    club_id, codice, sport, fase, obiettivo, zone_coinvolte, titolo,',
  );
  buffer.writeln(
    '    descrizione, stile_principale, livelli, attrezzi, metri_totali,',
  );
  buffer.writeln('    durata_stimata_min, note, stato, fonte, importato_il');
  buffer.writeln('  )');
  buffer.writeln('  values (');
  buffer.writeln(
    "    '$_clubModello', ${_sqlText(b.codice)}, ${_sqlText(b.sport)},",
  );
  buffer.writeln(
    '    ${_sqlText(b.fase)}, ${_sqlText(b.obiettivo)}, ${_sqlText(b.zoneCoinvolte)},',
  );
  buffer.writeln(
    '    ${_sqlText(b.titolo)}, ${_sqlText(b.descrizione)}, ${_sqlText(b.stilePrincipale)},',
  );
  buffer.writeln(
    '    ${_sqlText(b.livelli)}, ${_sqlText(b.attrezzi)}, ${_sqlInt(b.metriTotali)},',
  );
  buffer.writeln(
    '    ${_sqlInt(b.durataStimataMin)}, ${_sqlText(b.note)}, ${_sqlText(b.stato)},',
  );
  buffer.writeln("    ${_sqlText(b.fonte)}, now()");
  buffer.writeln('  )');
  buffer.writeln('  returning id');
  buffer.writeln(')');
  buffer.writeln('insert into public.training_block_parti (');
  buffer.writeln(
    '  blocco_id, club_id, ordine, giri, ripetizioni, distanza_m, durata_s,',
  );
  buffer.writeln(
    '  stile, esercizio, zona, esecuzione, recupero_s, attrezzi, note',
  );
  buffer.writeln(')');
  for (var i = 0; i < b.parti.length; i++) {
    final p = b.parti[i];
    buffer.write(i == 0 ? 'select ' : 'union all select ');
    buffer.write(
      "id, '$_clubModello', ${p.ordine}, ${p.giri}, ${p.ripetizioni}, ",
    );
    buffer.write(
      '${_sqlInt(p.distanzaM)}, ${_sqlInt(p.durataS)}, ${_sqlText(p.stile)}, ',
    );
    buffer.write(
      '${_sqlText(p.esercizio)}, ${_sqlText(p.zona)}, ${_sqlText(p.esecuzione)}, ',
    );
    buffer.write(
      '${_sqlInt(p.recuperoS)}, ${_sqlText(p.attrezzi)}, ${_sqlText(p.note)}',
    );
    buffer.writeln(' from b');
  }
  buffer.writeln(';');
  return buffer.toString();
}

void main(List<String> args) {
  final pathExcel = args.isNotEmpty
      ? args[0]
      : 'libreria_blocchi_nuoto_pallanuoto.xlsx';
  final file = File(pathExcel);
  if (!file.existsSync()) {
    stderr.writeln('File non trovato: $pathExcel');
    exitCode = 1;
    return;
  }

  final parsed = parseLibreriaExcel(file.readAsBytesSync());
  if (parsed.errori.isNotEmpty) {
    stderr.writeln(
      '${parsed.errori.length} errori nel file, nessuna migrazione generata:',
    );
    for (final e in parsed.errori) {
      stderr.writeln('  $e');
    }
    exitCode = 1;
    return;
  }

  final adesso = DateTime.now().toUtc();
  final timestamp =
      '${adesso.year}${adesso.month.toString().padLeft(2, '0')}'
      '${adesso.day.toString().padLeft(2, '0')}${adesso.hour.toString().padLeft(2, '0')}'
      '${adesso.minute.toString().padLeft(2, '0')}${adesso.second.toString().padLeft(2, '0')}';
  final nomeFile = args.length > 1
      ? args[1]
      : 'supabase/migrations/${timestamp}_libreria_blocchi_seme.sql';

  final sql = StringBuffer();
  sql.writeln(
    '-- ============================================================',
  );
  sql.writeln(
    '-- Libreria blocchi "di fabbrica" (club modello), rigenerata da',
  );
  sql.writeln('-- $pathExcel con tool/genera_seed_libreria.dart.');
  sql.writeln(
    '-- ${parsed.blocchi.length} blocchi, ${parsed.blocchi.fold<int>(0, (t, b) => t + b.parti.length)} parti.',
  );
  sql.writeln('--');
  sql.writeln(
    '-- Sostituisce la copia precedente: i club già esistenti non sono',
  );
  sql.writeln(
    '-- toccati (si aggiornano con "Importa da Excel" nell\'app), solo i',
  );
  sql.writeln(
    '-- club creati DOPO questa migrazione partiranno dal contenuto nuovo.',
  );
  sql.writeln(
    '-- ============================================================',
  );
  sql.writeln();
  sql.writeln(
    "delete from public.training_block_parti where club_id = '$_clubModello';",
  );
  sql.writeln(
    "delete from public.training_blocks where club_id = '$_clubModello';",
  );
  sql.writeln();
  for (final b in parsed.blocchi) {
    sql.writeln(_bloccoSql(b));
    sql.writeln();
  }

  File(nomeFile).writeAsStringSync(sql.toString());
  stdout.writeln('Scritto $nomeFile (${parsed.blocchi.length} blocchi).');
  stdout.writeln();
  stdout.writeln('Per applicarla al progetto Supabase reale:');
  stdout.writeln('  supabase db query --file $nomeFile --linked');
}
