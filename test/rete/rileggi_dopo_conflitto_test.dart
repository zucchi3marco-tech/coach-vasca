import 'package:coach_vasca/features/home/rileggi_dopo_conflitto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ogni tabella che va in coda sa quali pagine rileggere', () {
    // Le tabelle che i repository mettono in coda senza rete (le funzioni
    // del database e gli allenamenti generati non hanno conflitti).
    const inCoda = [
      'allenamenti',
      'serie',
      'atleti',
      'personal_best',
      'tempi_gara',
      'schede_benessere',
      'rpe_sedute',
      'gara_iscritti',
      'gare',
      'gruppi',
      'training_blocks',
      'training_block_parti',
      'partite',
      'distinta_giocatori',
      'eventi_partita',
      'schemi_tattici',
      'video_partite',
      'note_video',
      'presenze',
      'referti_partita',
      'esercizi_secco',
      'esercizi_seduta',
      'programmi_secco',
      'serie_secco_fatte',
      'stagioni',
      'tabelle_passi',
      'test_club',
      'test_risultati',
      'test_ingresso',
    ];
    expect(tabelleConPagine.containsAll(inCoda), isTrue);
  });
}
