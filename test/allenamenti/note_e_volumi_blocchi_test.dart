import 'package:coach_vasca/features/allenamenti/domain/serie.dart';
import 'package:coach_vasca/features/allenamenti/domain/testo_allenamento.dart';
import 'package:coach_vasca/features/allenamenti/presentation/editor_testo_allenamento.dart';
import 'package:coach_vasca/features/allenamenti/presentation/nota_serie.dart';
import 'package:coach_vasca/features/allenamenti/presentation/riga_serie.dart';
import 'package:coach_vasca/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _app(Widget figlio) => MaterialApp(
  theme: AppTheme.chiaro,
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(disableAnimations: true),
    child: child!,
  ),
  home: Scaffold(body: SingleChildScrollView(child: figlio)),
);

const _nota =
    'Virata stretta e uscita in subacquea fino ai 5 metri, respirazione '
    'ogni 3 bracciate';

Serie _serie({String? note, int? recuperoDopo}) => Serie(
  id: 's1',
  allenamentoId: 'a1',
  clubId: 'c1',
  ordine: 1,
  blocco: 'principale',
  ripetute: 8,
  distanzaM: 100,
  stile: 'libero',
  esecuzione: 'nuoto',
  zona: 'B1',
  note: note,
  recuperoDopoS: recuperoDopo,
);

Future<void> _riga(WidgetTester tester, double larghezza) async {
  tester.view.physicalSize = Size(larghezza, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    _app(
      RigaSerie(
        serie: _serie(note: _nota),
        maniglia: const SizedBox(),
        primo: true,
        ultimo: true,
        onApri: () {},
        onAzione: (_) {},
      ),
    ),
  );
}

void main() {
  testWidgets('la nota si legge sempre, intera, accanto alla serie', (
    tester,
  ) async {
    // Su schermo largo a destra del titolo.
    await _riga(tester, 1000);
    final nota = find.text(_nota);
    expect(nota, findsOneWidget);
    final titolo = tester.getRect(find.textContaining('8×100'));
    expect(tester.getRect(nota).left, greaterThan(titolo.left + 200));

    // Su telefono sotto.
    await _riga(tester, 380);
    expect(find.text(_nota), findsOneWidget);
    expect(
      tester.getRect(find.text(_nota)).top,
      greaterThan(tester.getRect(find.textContaining('8×100')).bottom),
    );
  });

  testWidgets('il recupero fra le serie si legge con i minuti', (tester) async {
    await tester.pumpWidget(_app(const RecuperoFraSerie(150)));
    expect(
      find.text(
        "Recupero 2'30\" prima della serie successiva",
        findRichText: true,
      ),
      findsOneWidget,
    );
    expect(formattaRecupero(45), '45"');
    expect(formattaRecupero(120), "2'");
  });

  testWidgets('nel compilatore il volume sta accanto al titolo del blocco', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    const testo =
        'Riscaldamento\n400 mix A1\n\nPrincipale\n4x100 B1\nrec 1\'\n4x50';
    final controller = TextEditingController(text: testo);
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      _app(
        EditorTestoAllenamento(
          controller: controller,
          scritto: interpretaAllenamento(testo),
          riferimento: null,
        ),
      ),
    );
    await tester.pump();

    final campo = find.byKey(const Key('testo-allenamento'));
    final dentroIlCampo = find.descendant(
      of: find.ancestor(of: campo, matching: find.byType(Stack)).first,
      matching: find.text('400 m'),
    );
    expect(dentroIlCampo, findsOneWidget);
    expect(
      find.descendant(
        of: find.ancestor(of: campo, matching: find.byType(Stack)).first,
        matching: find.text('600 m · totale 1.000 m'),
      ),
      findsOneWidget,
    );
    // Sulla stessa riga del suo titolo, a destra.
    final rigaTitolo = tester.getRect(campo).top;
    final etichetta = tester.getRect(dentroIlCampo);
    expect(etichetta.top, lessThan(rigaTitolo + 40));
    expect(etichetta.right, greaterThan(tester.getRect(campo).center.dx));

    // Anche in "Come le ho capite", con il recupero.
    expect(find.text('400 m'), findsNWidgets(2));
    expect(
      find.text("Recupero 1' prima della serie successiva"),
      findsOneWidget,
    );
  });
}
