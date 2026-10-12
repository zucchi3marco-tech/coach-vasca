/// Vocabolario condiviso fra la lista eventi partita, le schermate di
/// registrazione (campo disegnato) e le clip del video: un solo posto per
/// le etichette, cosi' restano identiche ovunque compaiano.
library;

import 'package:flutter/material.dart';

import '../domain/evento_partita.dart';

const esitiTiroSemplice = [('gol', 'Gol'), ('non_gol', 'Non gol')];
const esitiTiroDettagliato = [
  ('gol', 'Gol'),
  ('parato', 'Parato'),
  ('palo_fuori', 'Palo/fuori'),
];
const esitiSuperiorita = [('gol', 'Gol'), ('non_gol', 'Non gol')];
const contestiTiro = [
  ('azione', 'Azione'),
  ('superiorita', 'Superiorità'),
  ('rigore', 'Rigore'),
];

/// Il valore dell'esito "gol in controfuga" nei bottoni dell'esito (in
/// modalità completa): si salva come esito gol con contesto controfuga.
const golInControfuga = 'gol_controfuga';

/// Gli esiti di un tiro in modalità completa: lo stesso elenco con, dopo
/// il gol, il gol in controfuga — un tocco solo, senza un passo in più.
List<(String, String)> conControfuga(List<(String, String)> esiti) => [
  for (final esito in esiti) ...[
    esito,
    if (esito.$1 == 'gol') (golInControfuga, 'Gol in controfuga'),
  ],
];

String etichettaContesto(String contesto) {
  switch (contesto) {
    case 'superiorita':
      return 'superiorità';
    case 'rigore':
      return 'rigore';
    case 'controfuga':
      return 'controfuga';
    default:
      return '';
  }
}

String etichettaEsito(String? esito) {
  switch (esito) {
    case 'gol':
      return 'Gol';
    case 'non_gol':
      return 'Non gol';
    case 'parato':
      return 'Parato';
    case 'palo_fuori':
      return 'Palo/fuori';
    default:
      return 'In corso';
  }
}

/// La riga di un evento ("Tiro — Rossi Marco — Gol (superiorità) ·
/// assist Bianchi Luca (T2)"), uguale nella cronologia e fra le clip del
/// video. [nome] dà il nome di un nostro atleta dal suo id.
String descriviEvento(EventoPartita e, String Function(String? id) nome) {
  final tempo = e.periodo != null ? ' (T${e.periodo})' : '';
  switch (e.tipo) {
    case 'tiro':
      final contesto = etichettaContesto(e.contestoTiro);
      final suffisso = contesto.isEmpty ? '' : ' ($contesto)';
      final assist = e.assistDi != null && e.esito == 'gol'
          ? ' · assist ${nome(e.assistDi)}'
          : '';
      final chi = e.squadra == 'nostra'
          ? 'Tiro — ${nome(e.atletaId)}'
          : 'Tiro avversario';
      return '$chi — ${etichettaEsito(e.esito)}$suffisso$assist$tempo';
    case 'espulsione':
      final chi = e.atletaId != null
          ? nome(e.atletaId)
          : 'Avversario n. ${e.numeroCalottinaAvversario}';
      final rigore = e.espulsioneDaRigore ? ' (fallo da rigore)' : '';
      final guadagnata = e.guadagnataDa == null
          ? ''
          : e.espulsioneDaRigore
          ? ' · rigore guadagnato da ${nome(e.guadagnataDa)}'
          : ' · guadagnata da ${nome(e.guadagnataDa)}';
      return 'Espulsione — $chi$rigore$guadagnata$tempo';
    case 'superiorita':
      final squadra = e.squadra == 'nostra' ? 'nostra' : 'avversaria';
      return 'Superiorità $squadra — ${etichettaEsito(e.esito)}$tempo';
    case 'palla_persa' || 'palla_recuperata':
      final cosa = e.tipo == 'palla_persa' ? 'Palla persa' : 'Palla recuperata';
      final chi = e.atletaId != null ? nome(e.atletaId) : 'squadra';
      return '$cosa — $chi$tempo';
    default:
      return e.tipo;
  }
}

IconData iconaEvento(EventoPartita e) {
  switch (e.tipo) {
    case 'tiro':
      return Icons.sports_handball_outlined;
    case 'espulsione':
      return Icons.warning_amber_outlined;
    case 'superiorita':
      return e.squadra == 'nostra' ? Icons.trending_up : Icons.trending_down;
    case 'palla_persa':
      return Icons.remove_circle_outline;
    case 'palla_recuperata':
      return Icons.add_circle_outline;
    default:
      return Icons.circle_outlined;
  }
}
