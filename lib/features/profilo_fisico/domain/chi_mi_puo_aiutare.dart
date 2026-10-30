import 'specialista.dart';

/// I problemi di «Chi mi può aiutare?» (profilo fisico, passo C), con lo
/// specialista del club a cui portano. È solo un indirizzo, mai una
/// diagnosi.
enum ProblemaFisico {
  dolore(
    'Dolore a spalla, schiena o ginocchio',
    TipoSpecialista.fisioterapista,
  ),
  rigidita('Rigidità o postura', TipoSpecialista.osteopata),
  gambe('Gambe pesanti o muscoli contratti', TipoSpecialista.massoterapista),
  energia(
    'Energia, alimentazione, peso per lo sport',
    TipoSpecialista.nutrizionista,
  ),

  /// Solo «senti il medico»: nessuno specialista.
  forte('Dolore forte, che non passa o con febbre', null),

  /// Tutti gli specialisti del club, e «parlane con il tuo allenatore».
  nonLoSo('Non lo so, o è un\'altra cosa', null);

  const ProblemaFisico(this.etichetta, this.tipo);

  final String etichetta;

  /// Lo specialista a cui porta; null per [forte] e [nonLoSo].
  final TipoSpecialista? tipo;

  bool get soloMedico => this == forte;

  /// Gli specialisti del club per questo problema: quelli del suo tipo,
  /// tutti per [nonLoSo], nessuno per [forte].
  List<Specialista> specialisti(Iterable<Specialista> delClub) =>
      switch (this) {
        forte => const [],
        nonLoSo => ordinaSpecialisti(delClub),
        _ => ordinaSpecialisti(delClub.where((s) => s.tipo == tipo)),
      };
}

/// Il messaggio WhatsApp già scritto: chi è, di che club e per cosa.
/// L'atleta lo può cambiare in WhatsApp prima di mandarlo.
String messaggioSpecialista({
  required String nomeAtleta,
  required String? nomeClub,
  required ProblemaFisico problema,
}) {
  final club = nomeClub == null || nomeClub.trim().isEmpty
      ? 'atleta di pallanuoto'
      : 'atleta del club ${nomeClub.trim()}';
  final richiesta = problema.tipo == null
      ? 'vorrei qualche informazione.'
      : 'vorrei un appuntamento per: ${problema.etichetta.toLowerCase()}.';
  return 'Buongiorno, sono ${nomeAtleta.trim()}, $club. Ho trovato il '
      'vostro contatto su WaterTactics e $richiesta';
}

/// Il collegamento che apre WhatsApp sulla chat con [numero]
/// («+393331234567») e il [testo] già scritto.
String collegamentoWhatsapp(String numero, String testo) =>
    'https://wa.me/${numero.replaceFirst('+', '')}'
    '?text=${Uri.encodeComponent(testo)}';
