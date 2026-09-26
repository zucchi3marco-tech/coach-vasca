enum StatoPush {
  /// Il browser (o la piattaforma) non sa fare push.
  nonSupportato,

  /// iPhone/iPad: il push funziona solo con l'app aggiunta alla Home.
  installaPrima,

  /// Si puo' attivare (il permesso va chiesto con un tocco).
  daAttivare,

  /// L'utente ha bloccato le notifiche nelle impostazioni del browser.
  negato,

  /// Permesso dato e iscrizione presente.
  attivo,
}

class IscrizionePush {
  const IscrizionePush({
    required this.endpoint,
    required this.p256dh,
    required this.authKey,
  });

  final String endpoint;
  final String p256dh;
  final String authKey;
}
