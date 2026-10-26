import 'voce.dart';

/// Fuori dal web (e nei test) non si registra e non si ascolta.
RegistratoreVoce creaRegistratore() => _SenzaRegistratore();

LettoreVoce creaLettore() => _SenzaLettore();

class _SenzaRegistratore implements RegistratoreVoce {
  @override
  bool get disponibile => false;

  @override
  bool get inRegistrazione => false;

  @override
  Future<void> avvia() async =>
      throw const ErroreVoce('Qui non si può registrare la voce.');

  @override
  Future<VoceRegistrata?> ferma() async => null;

  @override
  void annulla() {}
}

class _SenzaLettore implements LettoreVoce {
  @override
  void Function()? allaFine;

  @override
  Future<void> apri(String indirizzo) async {}

  @override
  Future<void> apriRegistrata(VoceRegistrata voce) async {}

  @override
  Future<void> suona({double secondo = 0}) async =>
      throw const ErroreVoce('Qui non si può ascoltare il commento.');

  @override
  void pausa() {}

  @override
  double get secondo => 0;

  @override
  bool get inRiproduzione => false;

  @override
  void chiudi() {}
}
