import 'package:coach_vasca/features/atleti/domain/atleta.dart';
import 'package:coach_vasca/features/club/application/current_club_provider.dart';
import 'package:coach_vasca/features/club/domain/club.dart';
import 'package:coach_vasca/features/profilo_fisico/data/profilo_fisico_repository.dart';
import 'package:coach_vasca/features/profilo_fisico/data/specialisti_repository.dart';
import 'package:coach_vasca/features/profilo_fisico/domain/chi_mi_puo_aiutare.dart';
import 'package:coach_vasca/features/profilo_fisico/domain/specialista.dart';
import 'package:coach_vasca/features/profilo_fisico/presentation/chi_mi_puo_aiutare_screen.dart';
import 'package:coach_vasca/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final _oggi = DateTime(2026, 10, 30);

Atleta _atleta({required DateTime nascita}) => Atleta(
  id: 'a1',
  clubId: 'c1',
  nome: 'Sofia',
  cognome: 'Rossi',
  dataNascita: nascita,
  sport: 'pallanuoto',
  consensoPrivacyFirmato: true,
  attivo: true,
  gruppoId: 'u16',
);

const _fisio = Specialista(
  id: 's1',
  clubId: 'c1',
  tipo: TipoSpecialista.fisioterapista,
  nome: 'Studio Rossi',
  descrizione: 'A Monza, sconto per gli atleti',
  whatsapp: '+393331234567',
);

const _nutri = Specialista(
  id: 's2',
  clubId: 'c1',
  tipo: TipoSpecialista.nutrizionista,
  nome: 'Dott.ssa Bianchi',
  sito: 'https://www.nutrisport.it/',
);

void main() {
  group('le regole', () {
    test('ogni problema porta allo specialista giusto', () {
      expect(ProblemaFisico.dolore.tipo, TipoSpecialista.fisioterapista);
      expect(ProblemaFisico.rigidita.tipo, TipoSpecialista.osteopata);
      expect(ProblemaFisico.gambe.tipo, TipoSpecialista.massoterapista);
      expect(ProblemaFisico.energia.tipo, TipoSpecialista.nutrizionista);
      expect(ProblemaFisico.forte.soloMedico, isTrue);

      const elenco = [_nutri, _fisio];
      expect(ProblemaFisico.dolore.specialisti(elenco), [_fisio]);
      expect(ProblemaFisico.energia.specialisti(elenco), [_nutri]);
      expect(ProblemaFisico.rigidita.specialisti(elenco), isEmpty);
      expect(ProblemaFisico.forte.specialisti(elenco), isEmpty);
      // «Non lo so»: tutti, per tipo.
      expect(ProblemaFisico.nonLoSo.specialisti(elenco), [_nutri, _fisio]);
    });

    test('il messaggio dice chi è, di che club e per cosa', () {
      expect(
        messaggioSpecialista(
          nomeAtleta: 'Sofia Rossi',
          nomeClub: 'Rari Nantes Monza',
          problema: ProblemaFisico.dolore,
        ),
        'Buongiorno, sono Sofia Rossi, atleta del club Rari Nantes Monza. '
        'Ho trovato il vostro contatto su WaterTactics e vorrei un '
        'appuntamento per: dolore a spalla, schiena o ginocchio.',
      );
      expect(
        messaggioSpecialista(
          nomeAtleta: 'Sofia Rossi',
          nomeClub: null,
          problema: ProblemaFisico.nonLoSo,
        ),
        'Buongiorno, sono Sofia Rossi, atleta di pallanuoto. Ho trovato il '
        'vostro contatto su WaterTactics e vorrei qualche informazione.',
      );
    });

    test('il collegamento WhatsApp ha il numero e il testo', () {
      expect(
        collegamentoWhatsapp('+393331234567', 'Ciao, sono Sofia: dolore?'),
        'https://wa.me/393331234567?text=Ciao%2C%20sono%20Sofia%3A%20dolore%3F',
      );
    });
  });

  group('la pagina', () {
    Future<void> apri(
      WidgetTester tester,
      Atleta atleta, {
      DateTime? consenso,
      List<Specialista> specialisti = const [_fisio, _nutri],
    }) async {
      tester.view.physicalSize = const Size(420, 2000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            consensoProfiloFisicoProvider.overrideWith(
              (ref, id) async => consenso,
            ),
            specialistiProvider.overrideWith((ref, id) async => specialisti),
            clubAtletaProvider.overrideWith(
              (ref, id) async => const Club(id: 'c1', nome: 'Rari Nantes'),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.chiaro,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(disableAnimations: true),
              child: child!,
            ),
            home: ChiMiPuoAiutareScreen(atleta: atleta, oggi: _oggi),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('chi ha meno di 18 anni senza consenso trova la pagina '
        'chiusa', (tester) async {
      await apri(tester, _atleta(nascita: DateTime(2011, 3, 4)));
      expect(find.textContaining('serve il consenso'), findsOneWidget);
      expect(find.text('Cosa senti?'), findsNothing);
      expect(find.text(ProblemaFisico.dolore.etichetta), findsNothing);
    });

    testWidgets('con il consenso il minorenne sceglie cosa sente', (
      tester,
    ) async {
      await apri(
        tester,
        _atleta(nascita: DateTime(2011, 3, 4)),
        consenso: DateTime(2026, 10, 1),
      );
      expect(find.text('Cosa senti?'), findsOneWidget);
      for (final p in ProblemaFisico.values) {
        expect(find.text(p.etichetta), findsOneWidget);
      }
    });

    testWidgets('dal dolore il fisioterapista, con il messaggio già pronto', (
      tester,
    ) async {
      final copiati = <String>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            copiati.add((call.arguments as Map)['text'] as String);
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      await apri(tester, _atleta(nascita: DateTime(2000, 1, 1)));
      await tester.tap(find.text(ProblemaFisico.dolore.etichetta));
      await tester.pumpAndSettle();

      expect(find.text('Studio Rossi'), findsOneWidget);
      expect(find.text('Dott.ssa Bianchi'), findsNothing);
      expect(find.textContaining('non una diagnosi'), findsOneWidget);

      // Fuori dal browser il messaggio va negli appunti.
      await tester.tap(find.text('Scrivi su WhatsApp'));
      await tester.pumpAndSettle();
      expect(copiati.single, contains('atleta del club Rari Nantes'));
      expect(copiati.single, contains('dolore a spalla, schiena o ginocchio'));
      expect(find.textContaining('+39 333 123 4567'), findsWidgets);
    });

    testWidgets('senza osteopata nel club: parlane con l\'allenatore', (
      tester,
    ) async {
      await apri(tester, _atleta(nascita: DateTime(2000, 1, 1)));
      await tester.tap(find.text(ProblemaFisico.rigidita.etichetta));
      await tester.pumpAndSettle();
      expect(find.text('Il club non ha ancora un osteopata'), findsOneWidget);
      await tester.tap(find.text('Scegli un\'altra cosa'));
      await tester.pumpAndSettle();
      expect(find.text('Cosa senti?'), findsOneWidget);
    });

    testWidgets('con un dolore forte solo il medico', (tester) async {
      await apri(tester, _atleta(nascita: DateTime(2000, 1, 1)));
      await tester.tap(find.text(ProblemaFisico.forte.etichetta));
      await tester.pumpAndSettle();
      expect(find.textContaining('la persona giusta è il medico'), findsOne);
      expect(find.text('Studio Rossi'), findsNothing);
      expect(find.text('Scrivi su WhatsApp'), findsNothing);
    });

    testWidgets('«Non lo so» mostra tutti gli specialisti, con il sito', (
      tester,
    ) async {
      await apri(tester, _atleta(nascita: DateTime(2000, 1, 1)));
      await tester.tap(find.text(ProblemaFisico.nonLoSo.etichetta));
      await tester.pumpAndSettle();
      expect(find.text('Studio Rossi'), findsOneWidget);
      expect(find.text('Dott.ssa Bianchi'), findsOneWidget);
      expect(find.text('Apri il sito'), findsOneWidget);
      expect(find.text('nutrisport.it'), findsOneWidget);
    });
  });
}
