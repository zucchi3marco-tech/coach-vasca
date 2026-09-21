import 'package:flutter/material.dart';

import '../../theme/colori_app.dart';
import '../../theme/tokens_dominio.dart';

/// Le voci della barra di navigazione dell'allenatore. "Schemi tattici" è
/// di pallanuoto: per il nuoto non compare; l'ultima voce è "Partite" per
/// la pallanuoto e "Gare" per il nuoto (sport nullo, cioè club vecchi
/// senza sport: pallanuoto). Un'unica lista alimenta barra, tour e corpo
/// delle tab, così restano sempre allineati.
enum VoceHome { atleti, allenamenti, schemi, stagioni, eventi }

List<VoceHome> vociHome(String? sport) => [
  VoceHome.atleti,
  VoceHome.allenamenti,
  if (sport != 'nuoto') VoceHome.schemi,
  VoceHome.stagioni,
  VoceHome.eventi,
];

typedef DestinazioneHome = ({
  IconData icona,
  IconData iconaSelezionata,
  String etichetta,
  String guida,
});

DestinazioneHome destinazioneHome(VoceHome voce, String? sport) =>
    switch (voce) {
      VoceHome.atleti => (
        icona: Icons.groups_outlined,
        iconaSelezionata: Icons.groups,
        etichetta: 'Atleti',
        guida:
            'L\'elenco dei tuoi atleti: profili, personal best, presenze e '
            'carico di lavoro.',
      ),
      VoceHome.allenamenti => (
        icona: Icons.calendar_month_outlined,
        iconaSelezionata: Icons.calendar_month,
        etichetta: 'Allenamenti',
        guida:
            'Pianifica le sedute con le loro serie, e segna le presenze a '
            'bordo vasca.',
      ),
      VoceHome.schemi => (
        icona: Icons.sports_outlined,
        iconaSelezionata: Icons.sports,
        etichetta: 'Schemi tattici',
        guida:
            'Pallanuoto: disegna gli schemi sulla lavagna tattica, anche in '
            'più passi, e condividili con gli atleti.',
      ),
      VoceHome.stagioni => (
        icona: Icons.event_note_outlined,
        iconaSelezionata: Icons.event_note,
        etichetta: 'Stagioni',
        guida:
            'Una stagione per gruppo (o per tutto il club) con il suo '
            'calendario: si aggiungono le partite o le gare toccando un '
            'giorno.',
      ),
      VoceHome.eventi when sport == 'nuoto' => (
        icona: Icons.emoji_events_outlined,
        iconaSelezionata: Icons.emoji_events,
        etichetta: 'Gare',
        guida:
            'Le gare della stagione in corso, con gli atleti iscritti e i '
            'loro risultati.',
      ),
      VoceHome.eventi => (
        icona: Icons.sports_handball_outlined,
        iconaSelezionata: Icons.sports_handball,
        etichetta: 'Partite',
        guida:
            'Le partite della stagione in corso: distinta, eventi dal vivo, '
            'referti e statistiche di squadra.',
      ),
    };

/// Colore della voce quando è selezionata (tavolozza "evidenza", vedi
/// DESIGN.md "Dove spendere l'audacia"): Atleti resta sul colore d'azione,
/// l'ancora neutra; le altre hanno un colore vivace ciascuna.
Color coloreVoceHome(BuildContext context, VoceHome voce) => switch (voce) {
  VoceHome.atleti => context.colori.azione,
  VoceHome.allenamenti => context.dominio.evidenzaCiano,
  VoceHome.schemi => context.dominio.evidenzaViola,
  VoceHome.stagioni => context.dominio.evidenzaVerde,
  VoceHome.eventi => context.dominio.evidenzaAmbra,
};
