import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/error_messages.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../theme/colori_app.dart';
import '../../../widgets/app_scaffold.dart';
import '../../../widgets/app_select.dart';
import '../../../widgets/app_text_field.dart';
import '../../../widgets/danger_button.dart';
import '../../../widgets/error_banner.dart';
import '../../../widgets/form_group.dart';
import '../../../widgets/primary_button.dart';
import '../../secco/application/secco_providers.dart';
import '../../secco/data/secco_repository.dart';
import '../../secco/domain/esercizio_secco.dart';
import '../application/test_club_providers.dart';
import '../data/test_club_repository.dart';
import '../domain/massimale.dart';
import '../domain/spiegazioni_test.dart';
import '../domain/test_club.dart';
import 'spiegazione_test.dart';
import 'test_club_widgets.dart';

/// Nuovo test del club, o la modifica di uno che c'è. Dopo i primi
/// risultati cosa si misura, quante prove e quale valore vince non si
/// cambiano più (le classifiche vecchie non tornerebbero): restano nome,
/// descrizione e archivio. Un test può essere il **massimale** di un
/// esercizio a secco a ripetizioni: in chili, da chili × ripetizioni.
///
/// Con [modello] o [modelloMassimale] è un test pronto già compilato (con
/// la sua spiegazione): l'allenatore lo cambia e lo aggiunge al club.
class TestClubFormScreen extends ConsumerStatefulWidget {
  const TestClubFormScreen({
    required this.clubId,
    this.test,
    this.modello,
    this.modelloMassimale,
    super.key,
  });

  final String clubId;
  final TestClub? test;
  final ModelloTest? modello;
  final ModelloMassimale? modelloMassimale;

  @override
  ConsumerState<TestClubFormScreen> createState() => _TestClubFormScreenState();
}

class _TestClubFormScreenState extends ConsumerState<TestClubFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _nome = TextEditingController(
    text:
        widget.test?.nome ??
        widget.modello?.nome ??
        widget.modelloMassimale?.nome ??
        '',
  );
  late final _descrizione = TextEditingController(
    text: switch (widget.test) {
      final t? => spiegazioneDi(t) ?? '',
      null => spiegazioneOriginale(_chiaveModello, massimale: _massimale) ?? '',
    },
  );
  late final _prove = TextEditingController(
    text: '${widget.test?.prove ?? widget.modello?.prove ?? 1}',
  );
  late UnitaTest _unita =
      widget.test?.unita ?? widget.modello?.unita ?? UnitaTest.secondi;
  late bool _piuBassoMeglio =
      widget.test?.piuBassoMeglio ?? widget.modello?.piuBassoMeglio ?? true;
  late PunteggioTest _punteggio =
      widget.test?.punteggio ??
      widget.modello?.punteggio ??
      PunteggioTest.migliore;
  late bool _massimale =
      widget.test?.massimale ?? widget.modelloMassimale != null;
  late String? _esercizioId = widget.test?.esercizioId;

  /// Un test pronto ancora da aggiungere.
  bool get _daPronto =>
      widget.test == null &&
      (widget.modello != null || widget.modelloMassimale != null);

  /// La chiave del test pronto da cui viene, se c'è.
  String? get _chiaveModello =>
      widget.test?.modello ??
      widget.modello?.chiave ??
      widget.modelloMassimale?.chiave;

  /// L'esercizio pronto di un massimale pronto.
  ModelloEsercizio? get _esercizioPronto => switch (widget.modelloMassimale) {
    final m? =>
      modelliEsercizi.where((e) => e.chiave == m.esercizio).firstOrNull,
    null => null,
  };

  /// Il nome proposto dall'ultimo esercizio scelto: se l'allenatore non
  /// l'ha cambiato, cambia con l'esercizio.
  String? _nomeProposto;
  bool _senzaEsercizio = false;
  bool _salvataggio = false;
  String? _errore;

  void _scegliEsercizio(EsercizioSecco e) {
    final proposto =
        'Massimale ${e.nome.substring(0, 1).toLowerCase()}${e.nome.substring(1)}';
    setState(() {
      _esercizioId = e.id;
      _senzaEsercizio = false;
      if (_nome.text.trim().isEmpty || _nome.text == _nomeProposto) {
        _nome.text = proposto;
      }
      _nomeProposto = proposto;
    });
  }

  void _cambiaTipo(bool massimale) => setState(() {
    _massimale = massimale;
    if (massimale && _descrizione.text.trim().isEmpty) {
      _descrizione.text = comeSiFaMassimale;
    } else if (!massimale && _descrizione.text == comeSiFaMassimale) {
      _descrizione.clear();
    }
  });

  @override
  void dispose() {
    _nome.dispose();
    _descrizione.dispose();
    _prove.dispose();
    super.dispose();
  }

  int get _numeroProve => int.tryParse(_prove.text.trim()) ?? 1;

  Future<void> _salva() async {
    final pronto = _esercizioPronto;
    final esercizioMancante =
        _massimale && _esercizioId == null && pronto == null;
    if (!_formKey.currentState!.validate() || esercizioMancante) {
      if (esercizioMancante) setState(() => _senzaEsercizio = true);
      return;
    }
    setState(() {
      _salvataggio = true;
      _errore = null;
    });
    final originale = widget.test;
    try {
      // Un massimale pronto porta con sé il suo esercizio, aggiunto
      // all'elenco degli esercizi a secco se manca.
      if (_massimale && pronto != null) {
        _esercizioId =
            (await ref
                    .read(seccoRepositoryProvider)
                    .esercizioPronto(widget.clubId, pronto))
                .id;
      }
      final test = _massimale
          ? TestClub.massimale(
              id: originale?.id ?? '',
              clubId: widget.clubId,
              nome: _nome.text.trim(),
              esercizioId: _esercizioId!,
              descrizione: _descrizione.text.trim(),
              modello: _chiaveModello,
              archiviato: originale?.archiviato ?? false,
            )
          : TestClub(
              id: originale?.id ?? '',
              clubId: widget.clubId,
              nome: _nome.text.trim(),
              descrizione: _descrizione.text.trim(),
              unita: _unita,
              piuBassoMeglio: _piuBassoMeglio,
              prove: _numeroProve,
              punteggio: _numeroProve > 1 ? _punteggio : PunteggioTest.migliore,
              modello: _chiaveModello,
              archiviato: originale?.archiviato ?? false,
            );
      final repository = ref.read(testClubRepositoryProvider);
      if (originale == null) {
        await repository.creaTest(test);
      } else {
        await repository.aggiornaTest(test);
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) setState(() => _errore = messaggioErrore(e));
    } finally {
      if (mounted) setState(() => _salvataggio = false);
    }
  }

  Future<void> _archivia() async {
    final test = widget.test!;
    try {
      await ref
          .read(testClubRepositoryProvider)
          .aggiornaTest(test.copyWith(archiviato: !test.archiviato));
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) setState(() => _errore = messaggioErrore(e));
    }
  }

  Future<void> _elimina(int risultati) async {
    final test = widget.test!;
    final conferma = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Eliminare ${test.nome}?'),
        content: Text(
          risultati == 0
              ? "L'operazione non si può annullare."
              : 'Si eliminano anche i suoi $risultati risultati. '
                    "L'operazione non si può annullare: per toglierlo "
                    "dall'elenco tenendo i risultati, archivialo.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Annulla'),
          ),
          DangerButton(
            label: 'Elimina',
            expanded: false,
            onPressed: () => Navigator.of(dialogContext).pop(true),
          ),
        ],
      ),
    );
    if (conferma != true || !mounted) return;
    try {
      await ref.read(testClubRepositoryProvider).eliminaTest(test.id);
      if (!mounted) return;
      // Anche la classifica del test, sotto, non c'è più.
      Navigator.of(context)
        ..pop()
        ..pop();
    } catch (e) {
      if (mounted) setState(() => _errore = messaggioErrore(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    final test = widget.test;
    final risultati = test == null
        ? 0
        : (ref.watch(risultatiTestClubProvider(widget.clubId)).value ?? [])
              .where((r) => r.testId == test.id)
              .length;
    final bloccato = risultati > 0;
    // Per un massimale: gli esercizi a ripetizioni del club che non hanno
    // già il loro massimale.
    final esercizi = _massimale
        ? ref.watch(eserciziSeccoProvider(widget.clubId)).value ??
              const <EsercizioSecco>[]
        : const <EsercizioSecco>[];
    final altriMassimali = _massimale
        ? {
            for (final t
                in ref.watch(testClubProvider(widget.clubId)).value ??
                    const <TestClub>[])
              if (t.id != test?.id) ?t.esercizioId,
          }
        : const <String>{};
    final scegliibili = [
      for (final e in esercizi)
        if (!e.aTempo &&
            (!e.archiviato || e.id == _esercizioId) &&
            !altriMassimali.contains(e.id))
          e,
    ];
    final esercizioScelto = esercizi
        .where((e) => e.id == _esercizioId)
        .firstOrNull;

    final Widget campoEsercizio;
    if (_esercizioPronto case final e?) {
      campoEsercizio = Text(
        'Di: ${e.nome}',
        style: AppTypography.corpoForte.copyWith(color: colori.testo),
      );
    } else if (bloccato ||
        (test != null && test.massimale && scegliibili.isEmpty)) {
      campoEsercizio = Text(
        'Di: ${esercizioScelto?.nome ?? 'esercizio tolto dall\'elenco'}',
        style: AppTypography.corpoForte.copyWith(color: colori.testo),
      );
    } else if (scegliibili.isEmpty) {
      campoEsercizio = Text(
        'Nell\'elenco esercizi a secco del club non ci sono esercizi a '
        'ripetizioni senza un massimale: aggiungili dall\'elenco, o usa un '
        'massimale pronto.',
        style: AppTypography.corpo.copyWith(color: colori.testoSecondario),
      );
    } else {
      campoEsercizio = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppSelect<String>(
            etichetta: 'Di quale esercizio',
            value: _esercizioId,
            hint: 'Scegli l\'esercizio',
            items: [
              for (final e in scegliibili)
                DropdownMenuItem(value: e.id, child: Text(e.nome)),
            ],
            onChanged: (id) {
              final e = scegliibili.where((e) => e.id == id).firstOrNull;
              if (e != null) _scegliEsercizio(e);
            },
          ),
          if (_senzaEsercizio)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.s4),
              child: Text(
                'Scegli l\'esercizio',
                style: AppTypography.piccolo.copyWith(color: colori.rosso),
              ),
            ),
        ],
      );
    }

    return AppScaffold(
      scrollabile: true,
      appBar: AppBar(
        title: Text(
          test != null
              ? 'Modifica test'
              : _daPronto
              ? 'Aggiungi test'
              : 'Nuovo test',
        ),
        actions: [
          if (test != null)
            PopupMenuButton<VoidCallback>(
              icon: const Icon(Icons.more_vert),
              tooltip: 'Altre azioni',
              onSelected: (azione) => azione(),
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: _archivia,
                  child: Text(test.archiviato ? 'Riattiva' : 'Archivia'),
                ),
                PopupMenuItem(
                  value: () => _elimina(risultati),
                  child: Text('Elimina', style: TextStyle(color: colori.rosso)),
                ),
              ],
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FormGroup(
              titolo: 'Il test',
              campi: [
                if (test == null && !_daPronto)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Che test è',
                        style: AppTypography.etichetta.copyWith(
                          color: colori.testoSecondario,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.s8),
                      SegmentedButton<bool>(
                        showSelectedIcon: false,
                        segments: const [
                          ButtonSegment(
                            value: false,
                            label: Text('Una misura'),
                          ),
                          ButtonSegment(
                            value: true,
                            label: Text('Un massimale'),
                          ),
                        ],
                        selected: {_massimale},
                        onSelectionChanged: (s) => _cambiaTipo(s.first),
                      ),
                    ],
                  ),
                if (_massimale) campoEsercizio,
                AppTextField(
                  etichetta: 'Nome',
                  controller: _nome,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Obbligatorio' : null,
                ),
                CampoSpiegazione(
                  controller: _descrizione,
                  originale: spiegazioneOriginale(
                    _chiaveModello,
                    massimale: _massimale,
                  ),
                ),
              ],
            ),
            FormGroup(
              titolo: 'La misura',
              isUltimo: true,
              spiegazione: bloccato
                  ? 'Non si cambia: ci sono già $risultati risultati.'
                  : null,
              campi: _massimale
                  ? [
                      Text(
                        'In chili, vince il più alto. Per ogni atleta si '
                        'scrivono i chili sollevati e le ripetizioni fatte '
                        '(fino a $ripetizioniMassimeStima): l\'app stima il '
                        'massimale. Con una ripetizione è quello provato.',
                        style: AppTypography.corpo.copyWith(
                          color: colori.testo,
                        ),
                      ),
                    ]
                  : bloccato
                  ? [
                      Text(
                        descrizioneMisura(test!),
                        style: AppTypography.corpoForte.copyWith(
                          color: colori.testo,
                        ),
                      ),
                    ]
                  : [
                      AppSelect<UnitaTest>(
                        etichetta: 'Cosa si misura',
                        value: _unita,
                        items: [
                          for (final u in UnitaTest.values)
                            DropdownMenuItem(
                              value: u,
                              child: Text(
                                u == UnitaTest.secondi
                                    ? 'Tempo (secondi)'
                                    : '${u.etichetta} (${u.sigla})',
                              ),
                            ),
                        ],
                        onChanged: (u) => setState(() {
                          _unita = u ?? UnitaTest.secondi;
                          _piuBassoMeglio = _unita.piuBassoMeglioDiSolito;
                        }),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Vince',
                            style: AppTypography.etichetta.copyWith(
                              color: colori.testoSecondario,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.s8),
                          SegmentedButton<bool>(
                            showSelectedIcon: false,
                            segments: const [
                              ButtonSegment(
                                value: true,
                                label: Text('Il più basso'),
                              ),
                              ButtonSegment(
                                value: false,
                                label: Text('Il più alto'),
                              ),
                            ],
                            selected: {_piuBassoMeglio},
                            onSelectionChanged: (s) =>
                                setState(() => _piuBassoMeglio = s.first),
                          ),
                        ],
                      ),
                      AppTextField(
                        etichetta: 'Prove per atleta',
                        controller: _prove,
                        keyboardType: TextInputType.number,
                        aiuto: 'Per un 6 × 15 m: 6',
                        onChanged: (_) => setState(() {}),
                        validator: (v) {
                          final n = int.tryParse(v?.trim() ?? '');
                          return n == null || n < 1 || n > 20
                              ? 'Da 1 a 20'
                              : null;
                        },
                      ),
                      if (_numeroProve > 1)
                        AppSelect<PunteggioTest>(
                          etichetta: 'In classifica',
                          value: _punteggio,
                          items: [
                            for (final p in PunteggioTest.values)
                              DropdownMenuItem(
                                value: p,
                                child: Text('${p.etichetta} delle prove'),
                              ),
                          ],
                          onChanged: (p) => setState(
                            () => _punteggio = p ?? PunteggioTest.migliore,
                          ),
                        ),
                    ],
            ),
            const SizedBox(height: AppSpacing.s24),
            if (_errore != null) ...[
              ErrorBanner(
                messaggio: 'Non è stato possibile salvare il test.',
                suggerimento: 'Riprova.',
                dettaglioTecnico: _errore,
              ),
              const SizedBox(height: AppSpacing.s16),
            ],
            PrimaryButton(
              label: _daPronto ? 'Aggiungi al club' : 'Salva test',
              isLoading: _salvataggio,
              onPressed: _salvataggio ? null : _salva,
            ),
          ],
        ),
      ),
    );
  }
}
