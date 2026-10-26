import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/date_italiane.dart';
import '../../../core/utils/error_messages.dart';
import '../../../theme/app_spacing.dart';
import '../../../widgets/app_scaffold.dart';
import '../../../widgets/app_text_field.dart';
import '../../../widgets/danger_button.dart';
import '../../../widgets/error_banner.dart';
import '../../../widgets/form_group.dart';
import '../../../widgets/primary_button.dart';
import '../../atleti/domain/atleta.dart';
import '../data/test_club_repository.dart';
import '../domain/massimale.dart';
import '../domain/tastierino_test.dart';
import '../domain/test_club.dart';

/// L'atleta scrive il suo risultato in un test aperto agli atleti
/// (proposta 13): il giorno, le prove (o, per un massimale, chili e
/// ripetizioni). Con [esistente] lo corregge o lo toglie; il giorno di un
/// risultato già scritto non si cambia.
class SegnaRisultatoScreen extends ConsumerStatefulWidget {
  const SegnaRisultatoScreen({
    required this.test,
    required this.atleta,
    this.esistente,
    super.key,
  });

  final TestClub test;
  final Atleta atleta;
  final RisultatoTest? esistente;

  @override
  ConsumerState<SegnaRisultatoScreen> createState() =>
      _SegnaRisultatoScreenState();
}

class _SegnaRisultatoScreenState extends ConsumerState<SegnaRisultatoScreen> {
  final _formKey = GlobalKey<FormState>();
  late DateTime _data = widget.esistente?.data ?? _oggi();
  late final TextEditingController _dataTesto = TextEditingController(
    text: dataEstesa(_data),
  );
  late final List<TextEditingController> _campi = [
    for (var i = 0; i < campiPerAtleta(widget.test); i++)
      TextEditingController(text: _testoIniziale(i)),
  ];
  bool _salvataggio = false;
  String? _errore;

  static DateTime _oggi() {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  /// Il valore già scritto del campo [i], come si scrive a mano.
  String _testoIniziale(int i) {
    final r = widget.esistente;
    if (r == null) return '';
    final test = widget.test;
    final double? v = test.massimale
        ? (i == 0 ? r.caricoKg : r.ripetizioni?.toDouble())
        : (i < r.valori.length ? r.valori[i] : null);
    if (v == null) return '';
    final unita = unitaDelCampo(test, i);
    return switch (unita) {
      UnitaTest.secondi ||
      UnitaTest.chili ||
      UnitaTest.kmh => formattaValore(unita, v, sigla: false),
      _ => '${v.round()}',
    };
  }

  String _etichetta(int i) {
    final test = widget.test;
    if (test.massimale) return i == 0 ? 'Chili sollevati' : 'Ripetizioni';
    final nome = test.unita == UnitaTest.secondi
        ? 'Tempo (s)'
        : '${test.unita.etichetta} (${test.unita.sigla})';
    return test.prove == 1 ? nome : 'Prova ${i + 1} · $nome';
  }

  String? _aiuto(int i) {
    final test = widget.test;
    if (test.massimale) {
      return i == 0
          ? 'Il carico più pesante sollevato bene'
          : 'Da 1 a $ripetizioniMassimeStima';
    }
    return test.unita == UnitaTest.secondi ? 'Es. 8,62 o 1:05,20' : null;
  }

  @override
  void dispose() {
    _dataTesto.dispose();
    for (final c in _campi) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _scegliData() async {
    final scelta = await showDatePicker(
      context: context,
      initialDate: _data,
      firstDate: DateTime(_oggi().year - 2),
      lastDate: _oggi(),
    );
    if (scelta == null || !mounted) return;
    setState(() {
      _data = scelta;
      _dataTesto.text = dataEstesa(scelta);
    });
  }

  Future<void> _salva() async {
    if (!_formKey.currentState!.validate()) return;
    final test = widget.test;
    final valori = [
      for (var i = 0; i < _campi.length; i++)
        valoreDelCampoScritto(test, i, _campi[i].text),
    ];
    setState(() {
      _salvataggio = true;
      _errore = null;
    });
    try {
      final repository = ref.read(testClubRepositoryProvider);
      if (test.massimale) {
        final kg = valori[0]!;
        final ripetizioni = valori[1]!.round();
        await repository.salvaRisultato(
          testId: test.id,
          atletaId: widget.atleta.id,
          clubId: widget.atleta.clubId,
          data: _data,
          valori: [stimaMassimale(kg, ripetizioni)],
          caricoKg: kg,
          ripetizioni: ripetizioni,
          comeAtleta: true,
        );
      } else {
        await repository.salvaRisultato(
          testId: test.id,
          atletaId: widget.atleta.id,
          clubId: widget.atleta.clubId,
          data: _data,
          // Le prove non scritte non contano (si possono fare meno prove).
          valori: [for (final v in valori) ?v],
          comeAtleta: true,
        );
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) setState(() => _errore = messaggioErrore(e));
    } finally {
      if (mounted) setState(() => _salvataggio = false);
    }
  }

  Future<void> _togli() async {
    final r = widget.esistente!;
    final conferma = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Togliere il risultato del ${dataNumerica(r.data)}?'),
        content: const Text('Esce anche dalla classifica.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Annulla'),
          ),
          DangerButton(
            label: 'Togli',
            expanded: false,
            onPressed: () => Navigator.of(dialogContext).pop(true),
          ),
        ],
      ),
    );
    if (conferma != true || !mounted) return;
    try {
      await ref.read(testClubRepositoryProvider).eliminaRisultato(r.id);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) setState(() => _errore = messaggioErrore(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final test = widget.test;
    final esistente = widget.esistente;
    return AppScaffold(
      scrollabile: true,
      appBar: AppBar(
        title: Text(esistente == null ? 'Il tuo risultato' : 'Correggi'),
        actions: [
          if (esistente != null)
            IconButton(
              tooltip: 'Togli il risultato',
              icon: const Icon(Icons.delete_outline),
              onPressed: _togli,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FormGroup(
              titolo: test.nome,
              spiegazione: test.comeSiLegge,
              isUltimo: true,
              campi: [
                AppTextField(
                  etichetta: 'Giorno',
                  controller: _dataTesto,
                  readOnly: true,
                  abilitato: esistente == null,
                  onTap: esistente == null ? _scegliData : null,
                  suffixIcon: const Icon(Icons.calendar_today_outlined),
                ),
                for (var i = 0; i < _campi.length; i++)
                  AppTextField(
                    etichetta: _etichetta(i),
                    controller: _campi[i],
                    aiuto: _aiuto(i),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: (v) {
                      final vuoto = (v ?? '').trim().isEmpty;
                      // Con più prove basta la prima.
                      if (vuoto && !test.massimale && i > 0) return null;
                      if (vuoto) return 'Scrivilo';
                      return valoreDelCampoScritto(test, i, v!) == null
                          ? 'Non va bene'
                          : null;
                    },
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.s24),
            if (_errore != null) ...[
              ErrorBanner(messaggio: 'Risultato non salvato. $_errore'),
              const SizedBox(height: AppSpacing.s16),
            ],
            PrimaryButton(
              label: 'Salva',
              isLoading: _salvataggio,
              onPressed: _salvataggio ? null : _salva,
            ),
          ],
        ),
      ),
    );
  }
}
