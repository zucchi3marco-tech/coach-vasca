import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/navigation/barra_club_providers.dart';
import '../../core/navigation/navigator_key.dart';
import '../../core/segnalazioni/dispositivo.dart';
import '../../core/segnalazioni/schermata_app.dart';
import '../../core/versione/versione_app.dart';
import '../atleti/application/current_atleta_provider.dart';
import '../club/application/current_club_provider.dart';
import '../gruppi/application/gruppi_providers.dart';
import '../gruppi/application/selezione_gruppo_provider.dart';
import '../segnalazioni/domain/segnalazione.dart';
import 'voci_home.dart';

/// Il menu (o il riquadro della rete) impiega un attimo a sparire: la
/// schermata si fa dopo, così mostra la pagina e non il menu.
const _attesaChiusura = Duration(milliseconds: 350);

/// Vero se la home dell'allenatore sta mostrando le sue schede (Atleti,
/// Allenamenti...): non è un atleta, ha un club, una squadra scelta e almeno
/// una squadra. Decide anche se il menu ☰ offre «Cambia gruppo» e «Rivedi la
/// guida», e se «Scrivimi» dice la scheda invece del titolo della pagina.
bool homeConSchede(WidgetRef ref) {
  final areaAtleta = ref.read(currentAtletaProvider).value != null;
  final club = areaAtleta ? null : ref.read(currentClubProvider).value;
  if (club == null) return false;
  final gruppi = ref.read(gruppiListProvider(club.id)).value ?? const [];
  return gruppi.isNotEmpty && ref.read(selezioneGruppoProvider) != null;
}

/// Quello che «Scrivimi» allega da solo: la schermata dove si era, la
/// pagina (sulla home, la scheda), la versione, lo schermo e il browser.
/// Si prepara prima di aprire la pagina di «Scrivimi», che la coprirebbe.
/// Chi la chiama deve aver appena chiuso il menu o il riquadro da cui parte
/// (l'attesa per farli sparire dallo schermo è qui dentro).
Future<ContestoSegnalazione> contestoSegnalazione(
  WidgetRef ref,
  String? sport, {
  required bool conSchede,
}) async {
  await Future<void>.delayed(_attesaChiusura);
  final schermata = await ref.read(catturaSchermataProvider)();
  String? pagina;
  if (conSchede && osservatorePagine.soloLaPrima) {
    final voci = vociHome(sport);
    final voce = voci[ref.read(tabHomeProvider).clamp(0, voci.length - 1)];
    pagina = 'Home, scheda ${destinazioneHome(voce, sport).etichettaBreve}';
  } else {
    pagina = osservatorePagine.titoloPaginaInCima();
  }
  String? schermo;
  final contesto = contestoNavigatorApp();
  if (contesto != null && contesto.mounted) {
    final misura = MediaQuery.sizeOf(contesto);
    final scala = MediaQuery.textScalerOf(contesto).scale(10) / 10;
    schermo =
        '${misura.width.round()}×${misura.height.round()}'
        '${scala == 1 ? '' : ', testo ${scala.toStringAsFixed(1)}x'}';
  }
  return ContestoSegnalazione(
    versione: VersioneApp.corrente.compatta,
    pagina: pagina,
    dispositivo: descrizioneDispositivo(),
    schermo: schermo,
    schermata: schermata,
  );
}
