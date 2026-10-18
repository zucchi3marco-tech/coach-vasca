import '../../gruppi/domain/gruppo.dart';
import 'atleta.dart';

/// Lettura di un foglio (Excel o CSV) con gli atleti del club: Dart puro,
/// nessuna dipendenza da Flutter. Il file e' gia' una tabella di celle
/// (`String`, `int`, `double`, `bool`, `DateTime` o null); qui si trovano
/// le colonne, si leggono i valori e si decide per ogni riga se e' un
/// atleta nuovo, uno che c'e' gia' nell'app (da completare) o una riga che
/// resta fuori.

/// Il numero massimo di righe di dati in un foglio.
const maxRigheFoglioAtleti = 500;

/// I campi dell'atleta che il foglio puo' completare in chi c'e' gia'.
enum CampoAtleta {
  squadra('squadra'),
  ruolo('ruolo'),
  sesso('sesso'),
  tessera('tessera'),
  email('email del genitore'),
  telefono('telefono del genitore'),
  visitaMedica('visita medica'),
  note('note'),
  consenso('consenso privacy');

  const CampoAtleta(this.etichetta);

  /// Come lo dice un allenatore ("aggiungo squadra e tessera").
  final String etichetta;
}

/// Una riga del foglio scartata, con il motivo. [riga] e' il numero della
/// riga cosi' come si vede in Excel (la prima e' la 1).
class RigaEsclusa {
  const RigaEsclusa({required this.riga, required this.motivo});

  final int riga;
  final String motivo;
}

/// I valori letti da una riga valida del foglio.
class RigaFoglio {
  const RigaFoglio({
    required this.riga,
    required this.cognome,
    required this.nome,
    required this.dataNascita,
    this.squadra,
    this.squadraId,
    this.ruolo,
    this.sesso,
    this.tessera,
    this.email,
    this.telefono,
    this.visitaMedica,
    this.consenso = false,
    this.note,
    this.avvisi = const [],
  });

  final int riga;
  final String cognome;
  final String nome;
  final DateTime dataNascita;

  /// Il nome della squadra come sta nel foglio (null se la cella e' vuota).
  final String? squadra;

  /// L'id della squadra del club, se il nome combacia con una esistente.
  final String? squadraId;

  /// 'portiere' | 'movimento' | 'centroboa' | 'marcatore' | 'esterno'
  /// (solo pallanuoto).
  final String? ruolo;

  /// 'M' | 'F'.
  final String? sesso;
  final String? tessera;
  final String? email;
  final String? telefono;
  final DateTime? visitaMedica;
  final bool consenso;
  final String? note;

  /// Cose da guardare: la riga viene usata, ma un campo e' rimasto vuoto.
  final List<String> avvisi;

  /// Il nome della squadra c'e' ma non combacia con nessuna del club.
  bool get squadraSconosciuta => squadra != null && squadraId == null;

  /// L'id della squadra da usare: quella riconosciuta, oppure quella che il
  /// coach ha scelto per il nome sconosciuto. [mappa] ha per chiave
  /// `chiaveSquadra(nome)` e per valore l'id della squadra (null = senza).
  String? gruppoFinale(Map<String, String?> mappa) {
    if (squadraId != null) return squadraId;
    if (squadra == null) return null;
    return mappa[chiaveSquadra(squadra!)];
  }

  String get nomeCompleto => '$cognome $nome';
}

/// Un atleta del foglio che nell'app non c'e': da aggiungere.
class RigaNuova extends RigaFoglio {
  const RigaNuova({
    required super.riga,
    required super.cognome,
    required super.nome,
    required super.dataNascita,
    super.squadra,
    super.squadraId,
    super.ruolo,
    super.sesso,
    super.tessera,
    super.email,
    super.telefono,
    super.visitaMedica,
    super.consenso,
    super.note,
    super.avvisi,
  });
}

/// I valori finali dei campi che un atleta gia' nell'app riceve dal
/// foglio: per ognuno, quello che c'era (non toccato) oppure quello nuovo.
class Completamento {
  const Completamento({
    required this.campi,
    required this.gruppoId,
    required this.ruolo,
    required this.sesso,
    required this.tessera,
    required this.email,
    required this.telefono,
    required this.visitaMedica,
    required this.note,
    required this.consenso,
  });

  /// Cosa viene aggiunto (mai vuoto).
  final List<CampoAtleta> campi;
  final String? gruppoId;
  final String? ruolo;
  final String? sesso;
  final String? tessera;
  final String? email;
  final String? telefono;
  final DateTime? visitaMedica;
  final String? note;
  final bool consenso;
}

/// Un atleta del foglio che nell'app c'e' gia' (stesso cognome, nome e
/// data di nascita): non si duplica, si riempiono solo i campi vuoti.
class RigaGiaPresente extends RigaFoglio {
  const RigaGiaPresente({
    required super.riga,
    required super.cognome,
    required super.nome,
    required super.dataNascita,
    required this.atleta,
    super.squadra,
    super.squadraId,
    super.ruolo,
    super.sesso,
    super.tessera,
    super.email,
    super.telefono,
    super.visitaMedica,
    super.consenso,
    super.note,
    super.avvisi,
  });

  /// L'atleta cosi' com'e' nell'app.
  final Atleta atleta;

  /// I campi vuoti nell'app che il foglio riempie (puo' essere vuoto).
  List<CampoAtleta> campi(Map<String, String?> mappa) {
    final a = atleta;
    bool vuoto(String? v) => v == null || v.trim().isEmpty;
    return [
      if (a.gruppoId == null && gruppoFinale(mappa) != null)
        CampoAtleta.squadra,
      if (vuoto(a.ruolo) && ruolo != null) CampoAtleta.ruolo,
      if (vuoto(a.sesso) && sesso != null) CampoAtleta.sesso,
      if (vuoto(a.numeroTesseraFin) && tessera != null) CampoAtleta.tessera,
      if (vuoto(a.emailGenitore) && email != null) CampoAtleta.email,
      if (vuoto(a.telefonoGenitore) && telefono != null) CampoAtleta.telefono,
      if (a.visitaMedicaScadenza == null && visitaMedica != null)
        CampoAtleta.visitaMedica,
      if (vuoto(a.note) && note != null) CampoAtleta.note,
      if (!a.consensoPrivacyFirmato && consenso) CampoAtleta.consenso,
    ];
  }

  /// Quello da scrivere nell'atleta, o null se non c'e' niente da
  /// aggiungere. Non sovrascrive mai un valore gia' scritto nell'app.
  Completamento? completamento(Map<String, String?> mappa) {
    final c = campi(mappa);
    if (c.isEmpty) return null;
    final a = atleta;
    return Completamento(
      campi: c,
      gruppoId: c.contains(CampoAtleta.squadra)
          ? gruppoFinale(mappa)
          : a.gruppoId,
      ruolo: c.contains(CampoAtleta.ruolo) ? ruolo : a.ruolo,
      sesso: c.contains(CampoAtleta.sesso) ? sesso : a.sesso,
      tessera: c.contains(CampoAtleta.tessera) ? tessera : a.numeroTesseraFin,
      email: c.contains(CampoAtleta.email) ? email : a.emailGenitore,
      telefono: c.contains(CampoAtleta.telefono)
          ? telefono
          : a.telefonoGenitore,
      visitaMedica: c.contains(CampoAtleta.visitaMedica)
          ? visitaMedica
          : a.visitaMedicaScadenza,
      note: c.contains(CampoAtleta.note) ? note : a.note,
      consenso: c.contains(CampoAtleta.consenso)
          ? true
          : a.consensoPrivacyFirmato,
    );
  }
}

/// Il risultato della lettura del foglio.
class FoglioAtleti {
  const FoglioAtleti({
    this.colonneRiconosciute = const [],
    this.colonneNonUsate = const [],
    this.errore,
    this.avvisi = const [],
    this.nuovi = const [],
    this.giaPresenti = const [],
    this.escluse = const [],
    this.squadreSconosciute = const [],
  });

  /// I nomi (come li dice l'app) delle colonne capite.
  final List<String> colonneRiconosciute;

  /// I titoli del foglio che l'app non usa.
  final List<String> colonneNonUsate;

  /// Se c'e', non si importa niente: e' il messaggio da mostrare.
  final String? errore;

  /// Avvisi su tutto il file (es. nome e cognome in una colonna sola).
  final List<String> avvisi;

  final List<RigaNuova> nuovi;
  final List<RigaGiaPresente> giaPresenti;
  final List<RigaEsclusa> escluse;

  /// I nomi di squadra del foglio che il club non ha (una volta sola
  /// ciascuno). Il coach li abbina a una squadra o a "Senza squadra".
  final List<String> squadreSconosciute;

  bool get ok => errore == null;

  /// Quanti degli atleti gia' nell'app ricevono qualcosa dal foglio.
  int quantiDaCompletare(Map<String, String?> mappa) =>
      giaPresenti.where((r) => r.campi(mappa).isNotEmpty).length;
}

/// La chiave con cui si confrontano i nomi di squadra: minuscolo, senza
/// accenti, senza apostrofi, spazi ridotti a uno.
String chiaveSquadra(String nome) => _chiave(nome);

/// Il giorno come si scrive in Italia: 12/03/2012.
String dataIt(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/'
    '${d.month.toString().padLeft(2, '0')}/${d.year}';

// ---------------------------------------------------------------------------
// Testi

const _accenti = ['aàáâãäå', 'eèéêë', 'iìíîï', 'oòóôõö', 'uùúûü', 'cç', 'nñ'];

String _senzaAccenti(String s) {
  final b = StringBuffer();
  for (final c in s.split('')) {
    var sostituto = c;
    for (final g in _accenti) {
      if (g.substring(1).contains(c)) {
        sostituto = g[0];
        break;
      }
    }
    b.write(sostituto);
  }
  return b.toString();
}

/// Minuscolo, senza accenti, apostrofi ignorati, tutto cio' che non e'
/// lettera o cifra diventa uno spazio, spazi ridotti a uno.
String _chiave(String s) {
  final t = _senzaAccenti(s.toLowerCase())
      .replaceAll(RegExp("['’`´]"), '')
      .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
      .trim();
  return t;
}

String _testo(Object? v) {
  if (v == null) return '';
  if (v is String) return v.trim();
  if (v is int) return v.toString();
  if (v is double) {
    if (v.isFinite && v == v.truncateToDouble()) return v.toInt().toString();
    return v.toString();
  }
  if (v is bool) return v ? 'true' : 'false';
  if (v is DateTime) return dataIt(v);
  return v.toString().trim();
}

String _spaziRidotti(String s) => s.trim().replaceAll(RegExp(r'\s+'), ' ');

/// Cognome o nome: se e' tutto maiuscolo o tutto minuscolo diventa
/// "Maiuscola Iniziale" (anche dopo apostrofo e trattino); se e' scritto
/// misto, resta com'e'.
String _nomeProprio(String valore) {
  final s = _spaziRidotti(valore);
  if (s.isEmpty) return s;
  if (s != s.toUpperCase() && s != s.toLowerCase()) return s;
  final b = StringBuffer();
  var inizio = true;
  for (final c in s.split('')) {
    b.write(inizio ? c.toUpperCase() : c.toLowerCase());
    inizio = c == ' ' || c == "'" || c == '’' || c == '-';
  }
  return b.toString();
}

const _particelle = {
  'de',
  'di',
  'da',
  'del',
  'della',
  'dalla',
  'dal',
  'dello',
  'lo',
  'la',
  'li',
  'van',
  'von',
  'mc',
};

/// "Rossi, Mario" -> (Rossi, Mario); "De Luca Marco" -> (De Luca, Marco);
/// "Rossi Maria Chiara" -> (Rossi, Maria Chiara).
({String cognome, String nome}) _dividiNomeCompleto(String valore) {
  final s = _spaziRidotti(valore);
  final virgola = s.indexOf(',');
  if (virgola >= 0) {
    return (
      cognome: _spaziRidotti(s.substring(0, virgola)),
      nome: _spaziRidotti(s.substring(virgola + 1)),
    );
  }
  final parole = s.isEmpty ? <String>[] : s.split(' ');
  if (parole.isEmpty) return (cognome: '', nome: '');
  var fine = 1;
  while (fine < parole.length - 1 &&
      _particelle.contains(_chiave(parole[fine - 1]))) {
    fine++;
  }
  return (
    cognome: parole.sublist(0, fine).join(' '),
    nome: parole.sublist(fine).join(' '),
  );
}

// ---------------------------------------------------------------------------
// Date

const _mesi = {
  'gennaio': 1,
  'gen': 1,
  'febbraio': 2,
  'feb': 2,
  'marzo': 3,
  'mar': 3,
  'aprile': 4,
  'apr': 4,
  'maggio': 5,
  'mag': 5,
  'giugno': 6,
  'giu': 6,
  'luglio': 7,
  'lug': 7,
  'agosto': 8,
  'ago': 8,
  'settembre': 9,
  'set': 9,
  'sett': 9,
  'ottobre': 10,
  'ott': 10,
  'novembre': 11,
  'nov': 11,
  'dicembre': 12,
  'dic': 12,
};

DateTime? _giorno(int anno, int mese, int giorno) {
  if (mese < 1 || mese > 12 || giorno < 1 || giorno > 31) return null;
  final d = DateTime(anno, mese, giorno);
  if (d.year != anno || d.month != mese || d.day != giorno) return null;
  return d;
}

int _annoCompleto(String anno, DateTime oggi) {
  if (anno.length == 4) return int.parse(anno);
  final yy = int.parse(anno);
  return yy <= oggi.year % 100 ? 2000 + yy : 1900 + yy;
}

/// Una data da una cella. Null se non si legge (o non e' una data valida).
DateTime? _leggiData(Object? v, DateTime oggi) {
  if (v is DateTime) return DateTime(v.year, v.month, v.day);
  if (v is num) {
    if (!v.isFinite || v < 1 || v > 80000) return null;
    return DateTime(1899, 12, 30 + v.floor());
  }
  if (v is! String) return null;
  final s = _spaziRidotti(v);
  if (s.isEmpty) return null;

  var m = RegExp(r'^(\d{1,2})\s*[/\-.]\s*(\d{1,2})\s*[/\-.]\s*(\d{4}|\d{2})$')
      .firstMatch(s);
  if (m != null) {
    return _giorno(
      _annoCompleto(m[3]!, oggi),
      int.parse(m[2]!),
      int.parse(m[1]!),
    );
  }
  m = RegExp(r'^(\d{4})[-/.](\d{1,2})[-/.](\d{1,2})(?:[ T].*)?$').firstMatch(s);
  if (m != null) {
    return _giorno(int.parse(m[1]!), int.parse(m[2]!), int.parse(m[3]!));
  }
  m = RegExp(r'^(\d{1,2})\s*(?:°|º)?\s+([^\s\d./-]+?)\.?,?\s+(\d{4}|\d{2})$')
      .firstMatch(s);
  if (m != null) {
    final mese = _mesi[_chiave(m[2]!)];
    if (mese == null) return null;
    return _giorno(_annoCompleto(m[3]!, oggi), mese, int.parse(m[1]!));
  }
  return null;
}

// ---------------------------------------------------------------------------
// Colonne

enum _Col {
  cognome,
  nome,
  cognomeNome,
  nascita,
  squadra,
  ruolo,
  sesso,
  tessera,
  email,
  telefono,
  visita,
  consenso,
  note,
}

const _etichetteColonne = {
  _Col.cognome: 'Cognome',
  _Col.nome: 'Nome',
  _Col.cognomeNome: 'Cognome e nome',
  _Col.nascita: 'Data di nascita',
  _Col.squadra: 'Squadra',
  _Col.ruolo: 'Ruolo',
  _Col.sesso: 'Sesso',
  _Col.tessera: 'Tessera',
  _Col.email: 'Email genitore',
  _Col.telefono: 'Telefono genitore',
  _Col.visita: 'Visita medica',
  _Col.consenso: 'Consenso privacy',
  _Col.note: 'Note',
};

_Col? _colonnaDaTitolo(String titolo) {
  final t = _chiave(titolo);
  if (t.isEmpty) return null;
  final prima = t.split(' ').first;
  if (t.contains('nascita') ||
      prima == 'nato' ||
      prima == 'nata' ||
      t == 'dn' ||
      t == 'data n') {
    return _Col.nascita;
  }
  if (t.contains('visita') ||
      t.contains('certificato') ||
      t.contains('idoneita')) {
    return _Col.visita;
  }
  if (t.contains('privacy') || t.contains('consenso')) return _Col.consenso;
  if (t.contains('tessera') || t.contains('matricola')) return _Col.tessera;
  if (t.contains('mail')) return _Col.email;
  if (t.contains('telefono') ||
      t.contains('cellulare') ||
      t == 'cell' ||
      t == 'tel') {
    return _Col.telefono;
  }
  if (const {
    'cognome e nome',
    'cognome nome',
    'nominativo',
    'atleta',
  }.contains(t)) {
    return _Col.cognomeNome;
  }
  if (t == 'cognome') return _Col.cognome;
  if (t == 'nome') return _Col.nome;
  if (const {'squadra', 'categoria', 'gruppo', 'cat'}.contains(t)) {
    return _Col.squadra;
  }
  if (t == 'ruolo') return _Col.ruolo;
  if (const {'sesso', 'genere', 'm f', 'sex'}.contains(t)) return _Col.sesso;
  if (const {'note', 'nota', 'annotazioni'}.contains(t)) return _Col.note;
  return null;
}

const _ruoli = {
  'portiere': 'portiere',
  'p': 'portiere',
  'por': 'portiere',
  'gk': 'portiere',
  'centroboa': 'centroboa',
  'cb': 'centroboa',
  'boa': 'centroboa',
  'marcatore': 'marcatore',
  'difensore': 'marcatore',
  'dif': 'marcatore',
  'esterno': 'esterno',
  'ala': 'esterno',
  'movimento': 'movimento',
  'giocatore': 'movimento',
  'mov': 'movimento',
  'm': 'movimento',
};

const _sessi = {
  'm': 'M',
  'maschio': 'M',
  'maschile': 'M',
  'uomo': 'M',
  'ragazzo': 'M',
  'u': 'M',
  'f': 'F',
  'femmina': 'F',
  'femminile': 'F',
  'donna': 'F',
  'ragazza': 'F',
  'd': 'F',
};

const _si = {'si', 'x', 'yes', 'true', '1', 'firmato'};

final _reEmail = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

// ---------------------------------------------------------------------------
// Lettura

bool _rigaVuota(List<Object?> riga) => riga.every((c) => _testo(c).isEmpty);

/// Legge la [tabella] e dice cosa ne farebbe l'app. Non scrive niente.
///
/// [squadre]: quelle del club. [esistenti]: gli atleti del club, anche non
/// attivi. [pallanuoto]: solo allora la colonna Ruolo conta. [oggi]: per i
/// test; di norma la data di oggi.
FoglioAtleti analizzaFoglioAtleti(
  List<List<Object?>> tabella, {
  required List<Gruppo> squadre,
  required List<Atleta> esistenti,
  required bool pallanuoto,
  DateTime? oggi,
}) {
  final adesso = oggi ?? DateTime.now();
  final giornoOggi = DateTime(adesso.year, adesso.month, adesso.day);

  // 1. La riga dei titoli: la prima, entro le prime 10, con le colonne dei
  // nomi.
  int? rigaTitoli;
  var colonne = <_Col, int>{};
  var titoli = <String>[];
  for (var i = 0; i < tabella.length && i < 10; i++) {
    final trovate = <_Col, int>{};
    for (var c = 0; c < tabella[i].length; c++) {
      final col = _colonnaDaTitolo(_testo(tabella[i][c]));
      if (col != null && !trovate.containsKey(col)) trovate[col] = c;
    }
    final separati =
        trovate.containsKey(_Col.cognome) && trovate.containsKey(_Col.nome);
    if (separati || trovate.containsKey(_Col.cognomeNome)) {
      rigaTitoli = i;
      colonne = trovate;
      titoli = [for (final c in tabella[i]) _testo(c)];
      break;
    }
  }
  if (rigaTitoli == null) {
    return const FoglioAtleti(
      errore:
          'Non trovo le colonne Cognome e Nome: la prima riga del foglio '
          'deve avere i titoli. Puoi partire dal modello.',
    );
  }

  final separati =
      colonne.containsKey(_Col.cognome) && colonne.containsKey(_Col.nome);
  // Il nome in una colonna sola serve solo se mancano le due separate.
  if (separati) colonne.remove(_Col.cognomeNome);
  final colCognomeNome = separati ? null : colonne[_Col.cognomeNome];

  if (!pallanuoto) colonne.remove(_Col.ruolo);

  final usate = colonne.values.toSet();
  final riconosciute = [
    for (final e in _etichetteColonne.entries)
      if (colonne.containsKey(e.key)) e.value,
  ];
  final nonUsate = [
    for (var c = 0; c < titoli.length; c++)
      if (titoli[c].isNotEmpty && !usate.contains(c)) titoli[c],
  ];

  if (!colonne.containsKey(_Col.nascita)) {
    return FoglioAtleti(
      colonneRiconosciute: riconosciute,
      colonneNonUsate: nonUsate,
      errore:
          'Non trovo la colonna Data di nascita: serve per riconoscere '
          'gli atleti. Puoi partire dal modello.',
    );
  }

  final righeDati = [
    for (var i = rigaTitoli + 1; i < tabella.length; i++)
      if (!_rigaVuota(tabella[i])) i,
  ];
  if (righeDati.length > maxRigheFoglioAtleti) {
    return FoglioAtleti(
      colonneRiconosciute: riconosciute,
      colonneNonUsate: nonUsate,
      errore:
          'Il foglio ha ${righeDati.length} righe: ne leggo al massimo '
          '$maxRigheFoglioAtleti per volta. Dividilo in più file.',
    );
  }

  // 2. Le righe.
  final squadrePerChiave = <String, String>{
    for (final g in squadre) _chiave(g.nome): g.id,
  };
  String chiaveAtleta(String cognome, String nome, DateTime d) =>
      '${_chiave(cognome)}|${_chiave(nome)}|'
      '${d.year}-${d.month}-${d.day}';
  final esistentiPerChiave = <String, Atleta>{};
  final esistentiPerNome = <String, Atleta>{};
  for (final a in esistenti) {
    esistentiPerChiave.putIfAbsent(
      chiaveAtleta(a.cognome, a.nome, a.dataNascita),
      () => a,
    );
    esistentiPerNome.putIfAbsent(
      '${_chiave(a.cognome)}|${_chiave(a.nome)}',
      () => a,
    );
  }

  Object? cella(List<Object?> riga, _Col col) {
    final idx = colonne[col];
    if (idx == null || idx >= riga.length) return null;
    return riga[idx];
  }

  final nuovi = <RigaNuova>[];
  final giaPresenti = <RigaGiaPresente>[];
  final escluse = <RigaEsclusa>[];
  final viste = <String, int>{};
  final sconosciute = <String, String>{};

  for (final i in righeDati) {
    final riga = tabella[i];
    final numero = i + 1;
    void escludi(String motivo) =>
        escluse.add(RigaEsclusa(riga: numero, motivo: motivo));

    String cognome;
    String nome;
    if (colCognomeNome != null) {
      final testo = colCognomeNome < riga.length
          ? _testo(riga[colCognomeNome])
          : '';
      final diviso = _dividiNomeCompleto(testo);
      cognome = _nomeProprio(diviso.cognome);
      nome = _nomeProprio(diviso.nome);
    } else {
      cognome = _nomeProprio(_testo(cella(riga, _Col.cognome)));
      nome = _nomeProprio(_testo(cella(riga, _Col.nome)));
    }
    if (cognome.isEmpty && nome.isEmpty) {
      escludi('mancano cognome e nome');
      continue;
    }
    if (cognome.isEmpty) {
      escludi('manca il cognome');
      continue;
    }
    if (nome.isEmpty) {
      escludi('manca il nome');
      continue;
    }

    final cellaNascita = cella(riga, _Col.nascita);
    final testoNascita = _testo(cellaNascita);
    if (testoNascita.isEmpty) {
      escludi('manca la data di nascita');
      continue;
    }
    final nascita = _leggiData(cellaNascita, adesso);
    if (nascita == null) {
      escludi('data di nascita non leggibile: «$testoNascita»');
      continue;
    }
    if (nascita.isBefore(DateTime(1940)) || nascita.isAfter(giornoOggi)) {
      escludi('data di nascita strana: ${dataIt(nascita)}');
      continue;
    }

    final chiave = chiaveAtleta(cognome, nome, nascita);
    final prima = viste[chiave];
    if (prima != null) {
      escludi('uguale alla riga $prima');
      continue;
    }
    viste[chiave] = numero;

    final avvisi = <String>[];

    // Squadra.
    final testoSquadra = _testo(cella(riga, _Col.squadra));
    final squadra = testoSquadra.isEmpty ? null : _spaziRidotti(testoSquadra);
    String? squadraId;
    if (squadra != null) {
      squadraId = squadrePerChiave[_chiave(squadra)];
      if (squadraId == null) {
        sconosciute.putIfAbsent(_chiave(squadra), () => squadra);
      }
    }

    // Ruolo (solo pallanuoto: altrimenti la colonna non esiste qui).
    String? ruolo;
    final testoRuolo = _testo(cella(riga, _Col.ruolo));
    if (testoRuolo.isNotEmpty) {
      ruolo = _ruoli[_chiave(testoRuolo)];
      if (ruolo == null) {
        avvisi.add('Ruolo «$testoRuolo» non riconosciuto: lasciato vuoto.');
      }
    }

    // Sesso.
    String? sesso;
    final testoSesso = _testo(cella(riga, _Col.sesso));
    if (testoSesso.isNotEmpty) {
      sesso = _sessi[_chiave(testoSesso)];
      if (sesso == null) {
        avvisi.add('Sesso «$testoSesso» non riconosciuto: lasciato vuoto.');
      }
    }

    final tessera = _testo(cella(riga, _Col.tessera));

    // Email.
    String? email;
    final testoEmail = _testo(cella(riga, _Col.email));
    if (testoEmail.isNotEmpty) {
      if (_reEmail.hasMatch(testoEmail)) {
        email = testoEmail.toLowerCase();
      } else {
        avvisi.add('Email «$testoEmail» non valida: lasciata vuota.');
      }
    }

    final telefono = _testo(cella(riga, _Col.telefono));

    // Visita medica.
    DateTime? visita;
    final cellaVisita = cella(riga, _Col.visita);
    final testoVisita = _testo(cellaVisita);
    if (testoVisita.isNotEmpty) {
      visita = _leggiData(cellaVisita, adesso);
      if (visita == null) {
        avvisi.add(
          'Data della visita medica «$testoVisita» non leggibile: '
          'lasciata vuota.',
        );
      }
    }

    // Consenso.
    final cellaConsenso = cella(riga, _Col.consenso);
    final consenso =
        cellaConsenso == true || _si.contains(_chiave(_testo(cellaConsenso)));

    final note = _testo(cella(riga, _Col.note));

    final esistente = esistentiPerChiave[chiave];
    if (esistente != null) {
      giaPresenti.add(
        RigaGiaPresente(
          riga: numero,
          cognome: cognome,
          nome: nome,
          dataNascita: nascita,
          atleta: esistente,
          squadra: squadra,
          squadraId: squadraId,
          ruolo: ruolo,
          sesso: sesso,
          tessera: tessera.isEmpty ? null : tessera,
          email: email,
          telefono: telefono.isEmpty ? null : telefono,
          visitaMedica: visita,
          consenso: consenso,
          note: note.isEmpty ? null : note,
          avvisi: avvisi,
        ),
      );
      continue;
    }

    final stessoNome = esistentiPerNome['${_chiave(cognome)}|${_chiave(nome)}'];
    if (stessoNome != null) {
      avvisi.insert(
        0,
        "C'è già ${stessoNome.nomeCompleto} nato il "
        '${dataIt(stessoNome.dataNascita)}: controlla la data.',
      );
    }
    nuovi.add(
      RigaNuova(
        riga: numero,
        cognome: cognome,
        nome: nome,
        dataNascita: nascita,
        squadra: squadra,
        squadraId: squadraId,
        ruolo: ruolo,
        sesso: sesso,
        tessera: tessera.isEmpty ? null : tessera,
        email: email,
        telefono: telefono.isEmpty ? null : telefono,
        visitaMedica: visita,
        consenso: consenso,
        note: note.isEmpty ? null : note,
        avvisi: avvisi,
      ),
    );
  }

  return FoglioAtleti(
    colonneRiconosciute: riconosciute,
    colonneNonUsate: nonUsate,
    avvisi: [
      if (colCognomeNome != null)
        'Cognome e nome sono in una colonna sola: li ho separati io. '
            'Controlla che siano giusti, oppure usa due colonne.',
    ],
    nuovi: nuovi,
    giaPresenti: giaPresenti,
    escluse: escluse,
    squadreSconosciute: sconosciute.values.toList(),
  );
}
