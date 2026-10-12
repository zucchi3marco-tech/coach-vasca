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
import '../application/test_club_providers.dart';
import '../data/test_club_repository.dart';
import '../domain/test_club.dart';
import 'test_club_widgets.dart';

/// Nuovo test del club, o la modifica di uno che c'è. Dopo i primi
/// risultati cosa si misura, quante prove e quale valore vince non si
/// cambiano più (le classifiche vecchie non tornerebbero): restano nome,
/// descrizione e archivio.
class TestClubFormScreen extends ConsumerStatefulWidget {
  const TestClubFormScreen({required this.clubId, this.test, super.key});

  final String clubId;
  final TestClub? test;

  @override
  ConsumerState<TestClubFormScreen> createState() => _TestClubFormScreenState();
}

class _TestClubFormScreenState extends ConsumerState<TestClubFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _nome = TextEditingController(text: widget.test?.nome ?? '');
  late final _descrizione = TextEditingController(
    text: widget.test?.descrizione ?? '',
  );
  late final _prove = TextEditingController(text: '${widget.test?.prove ?? 1}');
  late UnitaTest _unita = widget.test?.unita ?? UnitaTest.secondi;
  late bool _piuBassoMeglio = widget.test?.piuBassoMeglio ?? true;
  late PunteggioTest _punteggio =
      widget.test?.punteggio ?? PunteggioTest.migliore;
  bool _salvataggio = false;
  String? _errore;

  @override
  void dispose() {
    _nome.dispose();
    _descrizione.dispose();
    _prove.dispose();
    super.dispose();
  }

  int get _numeroProve => int.tryParse(_prove.text.trim()) ?? 1;

  Future<void> _salva() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _salvataggio = true;
      _errore = null;
    });
    final originale = widget.test;
    final test = TestClub(
      id: originale?.id ?? '',
      clubId: widget.clubId,
      nome: _nome.text.trim(),
      descrizione: _descrizione.text.trim(),
      unita: _unita,
      piuBassoMeglio: _piuBassoMeglio,
      prove: _numeroProve,
      punteggio: _numeroProve > 1 ? _punteggio : PunteggioTest.migliore,
      modello: originale?.modello,
      archiviato: originale?.archiviato ?? false,
    );
    try {
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
          .aggiornaTest(
            TestClub(
              id: test.id,
              clubId: test.clubId,
              nome: test.nome,
              descrizione: test.descrizione,
              unita: test.unita,
              piuBassoMeglio: test.piuBassoMeglio,
              prove: test.prove,
              punteggio: test.punteggio,
              modello: test.modello,
              archiviato: !test.archiviato,
            ),
          );
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

    return AppScaffold(
      scrollabile: true,
      appBar: AppBar(
        title: Text(test == null ? 'Nuovo test' : 'Modifica test'),
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
                AppTextField(
                  etichetta: 'Nome',
                  controller: _nome,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Obbligatorio' : null,
                ),
                AppTextField(
                  etichetta: 'Come si fa (facoltativo)',
                  controller: _descrizione,
                  maxLines: 3,
                  aiuto: 'Distanza, partenza, peso, recupero fra le prove',
                ),
              ],
            ),
            FormGroup(
              titolo: 'La misura',
              isUltimo: true,
              spiegazione: bloccato
                  ? 'Non si cambia: ci sono già $risultati risultati.'
                  : null,
              campi: bloccato
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
              label: 'Salva test',
              isLoading: _salvataggio,
              onPressed: _salvataggio ? null : _salva,
            ),
          ],
        ),
      ),
    );
  }
}
