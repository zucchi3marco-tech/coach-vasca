/// I link di YouTube: l'id del video e il punto da cui parte. Servono al
/// video della partita e ai video degli esercizi a secco.
library;

final _soloId = RegExp(r'^[A-Za-z0-9_-]{11}$');

Uri? _uri(String testo) {
  final t = testo.trim();
  return Uri.tryParse(t.contains('://') ? t : 'https://$t');
}

/// L'id del video da un link di YouTube (watch, youtu.be, shorts, live,
/// embed, anche con `&t=` o `?si=`) o dall'id da solo; null se non è un
/// video di YouTube.
String? idYoutubeDa(String testo) {
  final t = testo.trim();
  if (_soloId.hasMatch(t)) return t;
  final uri = _uri(t);
  if (uri == null) return null;
  final host = uri.host.toLowerCase().replaceFirst(RegExp(r'^(www|m)\.'), '');
  String? candidato;
  if (host == 'youtu.be') {
    candidato = uri.pathSegments.firstOrNull;
  } else if (host == 'youtube.com' ||
      host == 'youtube-nocookie.com' ||
      host == 'music.youtube.com') {
    final segmenti = uri.pathSegments;
    if (segmenti.firstOrNull == 'watch') {
      candidato = uri.queryParameters['v'];
    } else if (segmenti.length >= 2 &&
        const ['embed', 'shorts', 'live', 'v'].contains(segmenti.first)) {
      candidato = segmenti[1];
    }
  }
  return candidato != null && _soloId.hasMatch(candidato) ? candidato : null;
}

final _tempo = RegExp(r'^(?:(\d+)h)?(?:(\d+)m)?(?:(\d+)s?)?$');

/// Il secondo da cui parte il video, dal link (`t=90`, `t=90s`,
/// `t=1m30s`, `start=90`); null se il link non lo dice o parte da zero.
int? inizioYoutubeDa(String testo) {
  final uri = _uri(testo);
  if (uri == null) return null;
  final valore = uri.queryParameters['t'] ?? uri.queryParameters['start'];
  if (valore == null || valore.isEmpty) return null;
  final m = _tempo.firstMatch(valore.toLowerCase());
  if (m == null) return null;
  final secondi =
      int.parse(m.group(1) ?? '0') * 3600 +
      int.parse(m.group(2) ?? '0') * 60 +
      int.parse(m.group(3) ?? '0');
  return secondi > 0 && secondi <= 86400 ? secondi : null;
}

/// Il link breve del video, dal secondo [da] se c'è.
String linkYoutube(String id, {int? da}) => da == null || da <= 0
    ? 'https://youtu.be/$id'
    : 'https://youtu.be/$id?t=$da';
