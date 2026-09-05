/// Scala di spaziatura e raggi — vedi DESIGN.md sezioni 5 e 6. Nessuna
/// dimensione va scritta a mano dentro una schermata: si usa una di
/// queste costanti.
abstract final class AppSpacing {
  // Scala a base 4.
  static const s4 = 4.0;
  static const s8 = 8.0;
  static const s12 = 12.0;
  static const s16 = 16.0;
  static const s20 = 20.0;
  static const s24 = 24.0;
  static const s28 = 28.0;
  static const s40 = 40.0;
  static const s56 = 56.0;

  // Valori con un ruolo preciso (sezione 5).
  static const margineLateraleTelefono = s16;
  static const margineLateraleTablet = s24;
  static const paddingPannello = s16;
  static const spazioCampiForm = s16;
  static const spazioGruppiForm = s28;
  static const spazioPannelli = s12;
  static const altezzaMinimaRiga = s56;
  static const spazioBersagli = s12;

  // Bersagli toccabili (sezioni 9 e 11).
  static const altezzaMinimaBersaglio = 48.0;
  static const altezzaMinimaBersaglioVasca = 64.0;

  // Raggi (sezione 6).
  static const raggioPannello = 12.0;
  static const raggioControllo = 8.0;
  static const raggioPillola = 999.0;
  static const raggioSheet = 20.0;
}
