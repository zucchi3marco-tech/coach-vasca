import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Ricerca nel sorgente che tiene onesta la migrazione a DESIGN.md
/// versione 2 (FASE 15): impedisce che schermate/widget tornino
/// silenziosamente a colori non legati al tema, cosa che `flutter
/// analyze` da solo non intercetta (sono comunque `Color` validi dal
/// punto di vista del type-checker).
///
/// Non copre `lib/theme/`, dove primitivi e palette VIVONO
/// legittimamente come costanti letterali.
void main() {
  final libPath = '${Directory.current.path}${Platform.pathSeparator}lib';

  String relativoALib(File file) {
    var relativo = file.path.substring(libPath.length);
    if (relativo.startsWith(Platform.pathSeparator)) {
      relativo = relativo.substring(1);
    }
    return relativo.replaceAll(r'\', '/');
  }

  Iterable<File> dartFilesFuori(String sottocartella) sync* {
    final dir = Directory('$libPath${Platform.pathSeparator}$sottocartella');
    if (!dir.existsSync()) return;
    for (final entita in dir.listSync(recursive: true)) {
      if (entita is File && entita.path.endsWith('.dart')) yield entita;
    }
  }

  Iterable<File> tuttiIFileDart() sync* {
    final dir = Directory(libPath);
    for (final entita in dir.listSync(recursive: true)) {
      if (entita is File && entita.path.endsWith('.dart')) yield entita;
    }
  }

  test('nessun file referenzia ancora AppColors o app_colors.dart '
      '(rimossi in FASE 15 punto 5: il colore vive solo in ColoriApp/'
      'TokenDominio, letto con context.colori/context.dominio)', () {
    final colpevoli = <String>[];
    for (final file in tuttiIFileDart()) {
      final contenuto = file.readAsStringSync();
      if (contenuto.contains('app_colors.dart') ||
          contenuto.contains('AppColors.') ||
          contenuto.contains('AppColors(')) {
        colpevoli.add(relativoALib(file));
      }
    }
    expect(
      colpevoli,
      isEmpty,
      reason:
          'File che referenziano ancora il vecchio sistema AppColors: '
          '${colpevoli.join(', ')}. Usa context.colori (ColoriApp) o '
          'context.dominio (TokenDominio) invece.',
    );
  });

  test('nessuna schermata/widget fuori da lib/theme/ usa un colore letterale '
      'non legato al tema (Colors.X o Color(0x...)), a parte le eccezioni '
      'documentate in DESIGN.md', () {
    // path relativo a lib/, riga (contenuto esatto trim()) — ogni
    // eccezione qui DEVE avere un commento nel codice sorgente che ne
    // spiega il motivo (vedi DESIGN.md sezione 3 "Regola sul rosso" e
    // dintorni). Aggiungerne una senza documentarla nel sorgente stesso
    // vanifica lo scopo di questo controllo.
    const eccezioni = <String, Set<String>>{
      'features/pallanuoto/presentation/fascia_calottine_partita.dart': {
        'color: Colors.black,',
      },
      'features/pallanuoto/presentation/partita_live_screen.dart': {
        'color: Colors.black54,',
      },
    };

    final colpevoli = <String>[];
    final pattern = RegExp(r'Colors\.\w+|Color\(0x');

    for (final sottocartella in ['features', 'widgets']) {
      for (final file in dartFilesFuori(sottocartella)) {
        final percorsoRelativo = relativoALib(file);
        final righeConsentite = eccezioni[percorsoRelativo] ?? const {};
        final righe = file.readAsLinesSync();
        for (var i = 0; i < righe.length; i++) {
          final riga = righe[i].trim();
          if (riga.contains('Colors.transparent')) continue;
          if (!pattern.hasMatch(riga)) continue;
          if (righeConsentite.contains(riga)) continue;
          colpevoli.add('$percorsoRelativo:${i + 1}: $riga');
        }
      }
    }

    expect(
      colpevoli,
      isEmpty,
      reason:
          'Colori letterali non legati al tema trovati fuori da '
          'lib/theme/ (usa context.colori.X, o aggiungi '
          "un'eccezione documentata qui se è deliberata — vedi "
          'DESIGN.md): ${colpevoli.join(' | ')}',
    );
  });
}
