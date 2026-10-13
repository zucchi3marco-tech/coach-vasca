import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/error_messages.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../theme/colori_app.dart';
import '../../../widgets/app_scaffold.dart';
import '../../../widgets/app_text_field.dart';
import '../../../widgets/danger_button.dart';
import '../../../widgets/error_banner.dart';
import '../../../widgets/form_group.dart';
import '../../../widgets/primary_button.dart';
import '../../../widgets/tonal_chip.dart';
import '../data/secco_repository.dart';
import '../domain/programma_secco.dart';

/// Nome, a cosa serve, quante sedute a settimana e quanto dura ognuna: un
/// programma nuovo (parte con la prima settimana, da riempire) o uno da
/// cambiare. Torna il programma salvato.
class ProgrammaSeccoFormScreen extends ConsumerStatefulWidget {
  const ProgrammaSeccoFormScreen({
    required this.clubId,
    this.programma,
    super.key,
  });

  final String clubId;
  final ProgrammaSecco? programma;

  @override
  ConsumerState<ProgrammaSeccoFormScreen> createState() =>
      _ProgrammaSeccoFormScreenState();
}

class _ProgrammaSeccoFormScreenState
    extends ConsumerState<ProgrammaSeccoFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _nome = TextEditingController(text: widget.programma?.nome ?? '');
  late final _descrizione = TextEditingController(
    text: widget.programma?.descrizione ?? '',
  );
  late final _durata = TextEditingController(
    text: '${widget.programma?.durataMin ?? 20}',
  );
  late int _sedute = widget.programma?.sedutePerSettimana ?? 2;
  bool _salvo = false;
  String? _errore;

  bool get _modifica => widget.programma != null;

  @override
  void dispose() {
    _nome.dispose();
    _descrizione.dispose();
    _durata.dispose();
    super.dispose();
  }

  /// Togliendo sedute a settimana, se quelle in fondo hanno esercizi si
  /// chiede prima.
  Future<bool> _confermaMenoSedute(ProgrammaSecco p) async {
    final toltePiene = p.settimane.any(
      (s) => s.sedute.skip(_sedute).any((e) => e.isNotEmpty),
    );
    if (!toltePiene) return true;
    final tolte = [
      for (var i = _sedute; i < p.sedutePerSettimana; i++) letteraSeduta(i),
    ].join(' e ');
    final conferma = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Togliere la seduta $tolte?'),
        content: Text(
          'In ogni settimana del programma la seduta $tolte si toglie con i '
          'suoi esercizi. Le sedute già nel calendario restano.',
        ),
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
    return conferma == true;
  }

  Future<void> _salva() async {
    if (!_formKey.currentState!.validate()) return;
    final vecchio = widget.programma;
    if (vecchio != null &&
        _sedute < vecchio.sedutePerSettimana &&
        !await _confermaMenoSedute(vecchio)) {
      return;
    }
    setState(() {
      _salvo = true;
      _errore = null;
    });
    final repository = ref.read(seccoRepositoryProvider);
    final programma = ProgrammaSecco(
      id: vecchio?.id ?? '',
      clubId: widget.clubId,
      nome: _nome.text.trim(),
      descrizione: _descrizione.text,
      durataMin: int.parse(_durata.text.trim()),
      // Un programma nuovo parte con la prima settimana, vuota.
      settimane:
          vecchio?.settimane ??
          [
            SettimanaProgramma(
              sedute: [for (var i = 0; i < _sedute; i++) const []],
            ),
          ],
      modello: vecchio?.modello,
    ).conSedutePerSettimana(_sedute);
    try {
      final salvato = _modifica
          ? await repository.aggiornaProgramma(programma)
          : await repository.creaProgramma(programma);
      if (mounted) Navigator.of(context).pop(salvato);
    } catch (e) {
      if (mounted) setState(() => _errore = messaggioErrore(e));
    } finally {
      if (mounted) setState(() => _salvo = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    return AppScaffold(
      scrollabile: true,
      appBar: AppBar(
        title: Text(_modifica ? 'Modifica programma' : 'Nuovo programma'),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FormGroup(
              titolo: 'Programma',
              campi: [
                AppTextField(
                  etichetta: 'Nome',
                  controller: _nome,
                  aiuto: 'Per esempio: Spalla del tiratore.',
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Scrivi il nome del programma'
                      : null,
                ),
                AppTextField(
                  etichetta: 'A cosa serve (facoltativo)',
                  controller: _descrizione,
                  maxLines: 3,
                  aiuto: 'Lo leggi tu: nelle sedute arriva solo il nome.',
                ),
              ],
            ),
            FormGroup(
              titolo: 'Ogni settimana',
              isUltimo: true,
              campi: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sedute a settimana',
                      style: AppTypography.etichetta.copyWith(
                        color: colori.testoSecondario,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s8),
                    Wrap(
                      spacing: AppSpacing.s8,
                      runSpacing: AppSpacing.s8,
                      children: [
                        for (var n = 1; n <= 4; n++)
                          TonalChip(
                            etichetta: '$n',
                            selezionato: _sedute == n,
                            onSelezionato: (_) => setState(() => _sedute = n),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.s8),
                    Text(
                      _sedute == 1
                          ? 'La stessa seduta, una volta a settimana.'
                          : 'Sedute diverse (${[for (var i = 0; i < _sedute; i++) letteraSeduta(i)].join(', ')}), '
                                'ognuna in un giorno.',
                      style: AppTypography.piccolo.copyWith(
                        color: colori.testoSecondario,
                      ),
                    ),
                  ],
                ),
                AppTextField(
                  etichetta: 'Minuti di ogni seduta',
                  controller: _durata,
                  keyboardType: TextInputType.number,
                  aiuto: 'I minuti che contano nel carico del secco.',
                  validator: (v) {
                    final minuti = int.tryParse(v?.trim() ?? '');
                    return minuti == null || minuti < 1 || minuti > 600
                        ? 'Scrivi i minuti, da 1 a 600'
                        : null;
                  },
                ),
              ],
            ),
            if (_errore != null) ...[
              const SizedBox(height: AppSpacing.s12),
              ErrorBanner(messaggio: _errore!),
            ],
            const SizedBox(height: AppSpacing.s24),
            PrimaryButton(
              label: _modifica ? 'Salva programma' : 'Crea il programma',
              isLoading: _salvo,
              onPressed: _salvo ? null : _salva,
            ),
          ],
        ),
      ),
    );
  }
}
