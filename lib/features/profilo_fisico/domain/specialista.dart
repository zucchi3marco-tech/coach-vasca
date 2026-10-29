/// I tipi di specialista convenzionato (profilo fisico, passo B).
enum TipoSpecialista {
  nutrizionista('Nutrizionista sportivo', 'Nutrizionisti sportivi'),
  fisioterapista('Fisioterapista', 'Fisioterapisti'),
  osteopata('Osteopata', 'Osteopati'),
  massoterapista('Massoterapista', 'Massoterapisti');

  const TipoSpecialista(this.etichetta, this.plurale);

  final String etichetta;
  final String plurale;

  static TipoSpecialista? daNome(String nome) {
    for (final t in values) {
      if (t.name == nome) return t;
    }
    return null;
  }
}

/// Uno specialista del club (tabella `specialisti`): lo scrive il
/// responsabile, con un sito o un numero WhatsApp.
class Specialista {
  const Specialista({
    required this.clubId,
    required this.tipo,
    required this.nome,
    this.id,
    this.descrizione,
    this.sito,
    this.whatsapp,
  });

  /// null se il tipo non è fra quelli conosciuti (una versione più nuova
  /// dell'app potrebbe averne aggiunti).
  static Specialista? fromMap(Map<String, dynamic> m) {
    final tipo = TipoSpecialista.daNome(m['tipo'] as String? ?? '');
    if (tipo == null) return null;
    return Specialista(
      id: m['id'] as String?,
      clubId: m['club_id'] as String,
      tipo: tipo,
      nome: m['nome'] as String,
      descrizione: m['descrizione'] as String?,
      sito: m['sito'] as String?,
      whatsapp: m['whatsapp'] as String?,
    );
  }

  final String? id;
  final String clubId;
  final TipoSpecialista tipo;
  final String nome;
  final String? descrizione;

  /// «https://…».
  final String? sito;

  /// «+393331234567».
  final String? whatsapp;

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'club_id': clubId,
    'tipo': tipo.name,
    'nome': nome,
    'descrizione': descrizione,
    'sito': sito,
    'whatsapp': whatsapp,
  };

  /// Come si contatta, in una riga: «WhatsApp +39 333 123 4567 ·
  /// studiorossi.it».
  String get contatti => [
    if (whatsapp != null) 'WhatsApp ${mostraWhatsapp(whatsapp!)}',
    if (sito != null) mostraSito(sito!),
  ].join(' · ');
}

/// Gli specialisti in ordine: per tipo, poi per nome.
List<Specialista> ordinaSpecialisti(Iterable<Specialista> elenco) =>
    [...elenco]..sort((a, b) {
      final t = a.tipo.index.compareTo(b.tipo.index);
      return t != 0 ? t : a.nome.toLowerCase().compareTo(b.nome.toLowerCase());
    });

/// Il numero come lo scrive chiunque («333 123 4567», «+39 333-1234567»,
/// «0039 333…») con il prefisso internazionale, solo cifre:
/// «+393331234567». Senza prefisso vale quello italiano. null se vuoto;
/// [FormatException] se non è un numero.
String? leggiWhatsapp(String testo) {
  final t = testo.trim();
  if (t.isEmpty) return null;
  if (RegExp(r'[^0-9+\s().\-/]').hasMatch(t)) {
    throw const FormatException('Scrivi solo il numero, con o senza +39');
  }
  var cifre = t.replaceAll(RegExp(r'[^0-9+]'), '');
  if (cifre.startsWith('00')) cifre = '+${cifre.substring(2)}';
  if (cifre.indexOf('+') > 0 || '+'.allMatches(cifre).length > 1) {
    throw const FormatException('Il + va solo all\'inizio');
  }
  if (!cifre.startsWith('+')) cifre = '+39$cifre';
  if (!RegExp(r'^\+[0-9]{8,15}$').hasMatch(cifre)) {
    throw const FormatException('Il numero è troppo corto o troppo lungo');
  }
  return cifre;
}

/// «+39 333 123 4567» per i numeri italiani, gli altri come sono.
String mostraWhatsapp(String numero) {
  if (!numero.startsWith('+39') || numero.length != 13) return numero;
  final n = numero.substring(3);
  return '+39 ${n.substring(0, 3)} ${n.substring(3, 6)} ${n.substring(6)}';
}

/// Il sito con «https://» davanti, se manca. null se vuoto;
/// [FormatException] se non sembra un sito.
String? leggiSito(String testo) {
  final t = testo.trim();
  if (t.isEmpty) return null;
  final conSchema = RegExp(r'^https?://', caseSensitive: false).hasMatch(t)
      ? t.replaceFirstMapped(
          RegExp(r'^https?://', caseSensitive: false),
          (m) => m[0]!.toLowerCase(),
        )
      : 'https://$t';
  final uri = Uri.tryParse(conSchema);
  if (conSchema.length > 300 ||
      conSchema.contains(RegExp(r'\s')) ||
      uri == null ||
      !uri.host.contains('.') ||
      uri.host.startsWith('.') ||
      uri.host.endsWith('.')) {
    throw const FormatException('Non sembra un sito: per esempio studio.it');
  }
  return conSchema;
}

/// «studiorossi.it/sport»: senza «https://», «www.» e la barra finale.
String mostraSito(String sito) => sito
    .replaceFirst(RegExp(r'^https?://', caseSensitive: false), '')
    .replaceFirst(RegExp(r'^www\.'), '')
    .replaceFirst(RegExp(r'/$'), '');
