import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderOrFamily;

import '../../core/sync/sync_engine.dart';
import '../allenamenti/application/allenamenti_providers.dart';
import '../atleti/application/atleti_providers.dart';
import '../atleti/application/personal_best_providers.dart';
import '../atleti/application/tempi_gara_providers.dart';
import '../benessere/application/benessere_providers.dart';
import '../carico/application/carico_providers.dart';
import '../gare/application/gara_iscritti_providers.dart';
import '../gare/application/gare_providers.dart';
import '../gruppi/application/gruppi_providers.dart';
import '../impegni/application/impegni_providers.dart';
import '../libreria_blocchi/application/libreria_blocchi_providers.dart';
import '../pallanuoto/application/pallanuoto_providers.dart';
import '../pallanuoto/application/schemi_tattici_providers.dart';
import '../pallanuoto/application/video_partita_providers.dart';
import '../presenze/application/presenze_providers.dart';
import '../referti/application/referti_providers.dart';
import '../secco/application/secco_providers.dart';
import '../stagioni/application/stagioni_providers.dart';
import '../tabelle_passi/application/tabelle_passi_providers.dart';
import '../test/application/test_club_providers.dart';
import '../test/application/test_providers.dart';

/// Le pagine che mostrano ogni tabella: dopo un conflitto si rileggono
/// dal server, così il telefono mostra la versione del collega e non più
/// la modifica che non è partita.
final Map<String, List<ProviderOrFamily>> _paginePerTabella = {
  'allenamenti': [allenamentiListProvider, volumiAllenamentiProvider],
  'serie': [serieListProvider, volumiAllenamentiProvider],
  'atleti': [atletiListProvider],
  'personal_best': [personalBestListProvider, personalBestClubProvider],
  'tempi_gara': [tempiGaraListProvider, tempiGaraPerGaraProvider],
  'schede_benessere': [
    schedeBenessereAtletaProvider,
    schedeBenessereClubProvider,
  ],
  'rpe_sedute': [rpeAtletaProvider, rpeClubProvider],
  'gara_iscritti': [garaIscrittiProvider],
  'gare': [gareListProvider],
  'impegni': [impegniListProvider],
  'gruppi': [gruppiListProvider],
  'training_blocks': [trainingBlocksListProvider],
  'training_block_parti': [trainingBlocksListProvider],
  'partite': [partiteListProvider],
  'distinta_giocatori': [distintaListProvider],
  'eventi_partita': [eventiPartitaListProvider],
  'schemi_tattici': [schemiTatticiListProvider],
  'video_partite': [videoPartitaProvider],
  'note_video': [videoPartitaProvider],
  'presenze': [
    presenzeListProvider,
    presenzePerAtletaProvider,
    presenzeClubProvider,
  ],
  'referti_partita': [refertoPerPartitaProvider, refertiDelClubProvider],
  'esercizi_secco': [eserciziSeccoProvider],
  'esercizi_seduta': [eserciziSedutaProvider],
  'programmi_secco': [programmiSeccoProvider],
  'serie_secco_fatte': [serieFatteAtletaProvider, serieFatteSedutaProvider],
  'stagioni': [stagioniListProvider],
  'tabelle_passi': [tabellePassiProvider],
  'test_club': [testClubProvider],
  'test_risultati': [risultatiTestClubProvider],
  'test_ingresso': [testListProvider],
};

/// Le tabelle che sanno quali pagine rileggere (per le prove).
Set<String> get tabelleConPagine => _paginePerTabella.keys.toSet();

/// Da ascoltare nella radice dell'app: a ogni conflitto rilegge le pagine
/// di quella tabella.
void rileggiDopoConflitto(WidgetRef ref) {
  ref.listen(ultimoConflittoProvider, (_, conflitto) {
    if (conflitto == null) return;
    for (final pagina
        in _paginePerTabella[conflitto.tabella] ?? const <ProviderOrFamily>[]) {
      ref.invalidate(pagina);
    }
  });
}
