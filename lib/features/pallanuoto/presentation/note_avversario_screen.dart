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
import '../data/note_avversari_repository.dart';
import '../domain/nota_avversario.dart';
import '../domain/scheda_avversario.dart';

/// Le note dello staff su un avversario: come gioca la squadra e i
/// giocatori da tenere d'occhio. Quelli dei referti si aggiungono con un
/// tocco. Torna `true` se ha salvato o tolto le note.
class NoteAvversarioScreen extends ConsumerStatefulWidget {
  const NoteAvversarioScreen({
    required this.nota,
    this.dalReferto = const [],
    super.key,
  });

  /// Quella da cambiare, o una nuova ([NotaAvversario.nuova]).
  final NotaAvversario nota;

  /// I loro giocatori dai referti, da aggiungere con un tocco.
  final List<GiocatoreAvversario> dalReferto;

  @override
  ConsumerState<NoteAvversarioScreen> createState() =>
      _NoteAvversarioScreenState();
}

class _Riga {
  _Riga({int? numero, String nome = '', String nota = ''})
    : numero = TextEditingController(text: numero?.toString() ?? ''),
      nome = TextEditingController(text: nome),
      nota = TextEditingController(text: nota);

  final TextEditingController numero;
  final TextEditingController nome;
  final TextEditingController nota;

  GiocatoreDaNotare get giocatore => GiocatoreDaNotare(
    numero: int.tryParse(numero.text.trim()),
    nome: nome.text,
    nota: nota.text,
  );

  void dispose() {
    numero.dispose();
    nome.dispose();
    nota.dispose();
  }
}

class _NoteAvversarioScreenState extends ConsumerState<NoteAvversarioScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nota;
  late final List<_Riga> _righe;
  bool _salvando = false;
  String? _errore;

  bool get _esiste => widget.nota.id != null;

  @override
  void initState() {
    super.initState();
    _nota = TextEditingController(text: widget.nota.nota);
    _righe = [
      for (final g in widget.nota.giocatori)
        _Riga(numero: g.numero, nome: g.nome, nota: g.nota),
    ];
  }

  @override
  void dispose() {
    _nota.dispose();
    for (final r in _righe) {
      r.dispose();
    }
    super.dispose();
  }

  String _chiaveNome(String nome) =>
      nome.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

  /// I giocatori dei referti non ancora nell'elenco.
  List<GiocatoreAvversario> get _suggeriti {
    final presenti = {
      for (final r in _righe)
        if (r.nome.text.trim().isNotEmpty) _chiaveNome(r.nome.text),
    };
    return [
      for (final g in widget.dalReferto)
        if (g.nome.trim().isNotEmpty && !presenti.contains(_chiaveNome(g.nome)))
          g,
    ];
  }

  void _aggiungi({int? numero, String nome = ''}) {
    if (_righe.length >= NotaAvversario.limiteGiocatori) return;
    setState(() => _righe.add(_Riga(numero: numero, nome: nome)));
  }

  void _togli(_Riga riga) {
    setState(() => _righe.remove(riga));
    riga.dispose();
  }

  Future<void> _salva() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _salvando = true;
      _errore = null;
    });
    try {
      await ref
          .read(noteAvversariRepositoryProvider)
          .salva(
            widget.nota.copiaCon(
              nota: _nota.text,
              giocatori: [for (final r in _righe) r.giocatore],
            ),
          );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) setState(() => _errore = messaggioErrore(e));
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  Future<void> _togliTutto() async {
    final conferma = await showDialog<bool>(
      context: context,
      builder: (dialogo) => AlertDialog(
        title: Text('Togliere le note su «${widget.nota.nome}»?'),
        content: const Text(
          'Spariscono la nota sulla squadra e i giocatori per tutti, '
          'staff e atleti.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogo).pop(false),
            child: const Text('Annulla'),
          ),
          DangerButton(
            label: 'Togli',
            expanded: false,
            onPressed: () => Navigator.of(dialogo).pop(true),
          ),
        ],
      ),
    );
    if (conferma != true || !mounted) return;
    setState(() {
      _salvando = true;
      _errore = null;
    });
    try {
      // Il nome FIN scelto a mano resta: serve alla classifica.
      await ref
          .read(noteAvversariRepositoryProvider)
          .salva(widget.nota.copiaCon(nota: '', giocatori: const []));
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) setState(() => _errore = messaggioErrore(e));
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  String? _lunghezza(String? v, int massimo) =>
      v != null && v.trim().length > massimo
      ? 'Al massimo $massimo caratteri'
      : null;

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    final suggeriti = _suggeriti;
    return AppScaffold(
      scrollabile: true,
      appBar: AppBar(
        title: Text('Note su ${widget.nota.nome}'),
        actions: [
          if (_esiste && !widget.nota.senzaNote)
            TextButton.icon(
              onPressed: _salvando ? null : _togliTutto,
              icon: Icon(Icons.delete_outline, color: colori.rosso),
              label: Text('Togli', style: TextStyle(color: colori.rosso)),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FormGroup(
              titolo: 'La squadra',
              campi: [
                AppTextField(
                  etichetta: 'Come giocano',
                  aiuto:
                      'Per esempio: pressano alto, cercano sempre il '
                      'centroboa, in superiorità tirano dal 2. La vede tutta '
                      'la squadra, anche chi non è convocato.',
                  controller: _nota,
                  maxLines: 6,
                  validator: (v) => _lunghezza(v, NotaAvversario.limiteNota),
                ),
              ],
            ),
            FormGroup(
              titolo: 'Giocatori da tenere d\'occhio',
              isUltimo: true,
              campi: [
                for (final (i, r) in _righe.indexed)
                  _CampiGiocatore(
                    key: ObjectKey(r),
                    riga: r,
                    indice: i,
                    abilitato: !_salvando,
                    lunghezza: _lunghezza,
                    onTogli: () => _togli(r),
                  ),
                if (suggeriti.isNotEmpty) ...[
                  Text(
                    'Dai referti',
                    style: AppTypography.etichetta.copyWith(
                      color: colori.testoSecondario,
                    ),
                  ),
                  Wrap(
                    spacing: AppSpacing.s8,
                    runSpacing: AppSpacing.s8,
                    children: [
                      for (final g in suggeriti)
                        ActionChip(
                          avatar: const Icon(Icons.add, size: 18),
                          label: Text('${g.numero} ${g.nome}'),
                          onPressed:
                              _salvando ||
                                  _righe.length >=
                                      NotaAvversario.limiteGiocatori
                              ? null
                              : () => _aggiungi(numero: g.numero, nome: g.nome),
                        ),
                    ],
                  ),
                ],
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed:
                        _salvando ||
                            _righe.length >= NotaAvversario.limiteGiocatori
                        ? null
                        : () => _aggiungi(),
                    icon: const Icon(Icons.person_add_alt_1_outlined),
                    label: const Text('Aggiungi un giocatore'),
                  ),
                ),
              ],
            ),
            if (_errore != null) ...[
              const SizedBox(height: AppSpacing.s12),
              ErrorBanner(messaggio: _errore!),
            ],
            const SizedBox(height: AppSpacing.s24),
            PrimaryButton(
              label: 'Salva',
              isLoading: _salvando,
              onPressed: _salvando ? null : _salva,
            ),
          ],
        ),
      ),
    );
  }
}

/// Numero, nome e «cosa fa» di un giocatore.
class _CampiGiocatore extends StatelessWidget {
  const _CampiGiocatore({
    required this.riga,
    required this.indice,
    required this.abilitato,
    required this.lunghezza,
    required this.onTogli,
    super.key,
  });

  final _Riga riga;
  final int indice;
  final bool abilitato;
  final String? Function(String?, int) lunghezza;
  final VoidCallback onTogli;

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s12),
      decoration: BoxDecoration(
        color: colori.superficieAlt,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 80,
                child: AppTextField(
                  etichetta: 'Numero',
                  controller: riga.numero,
                  keyboardType: TextInputType.number,
                  abilitato: abilitato,
                  validator: (v) {
                    final t = v?.trim() ?? '';
                    if (t.isEmpty) return null;
                    final n = int.tryParse(t);
                    return n == null || n < 1 || n > 99 ? '1–99' : null;
                  },
                ),
              ),
              const SizedBox(width: AppSpacing.s12),
              Expanded(
                child: AppTextField(
                  etichetta: 'Nome',
                  controller: riga.nome,
                  abilitato: abilitato,
                  validator: (v) =>
                      lunghezza(v, NotaAvversario.limiteNomeGiocatore),
                ),
              ),
              IconButton(
                tooltip: 'Togli il giocatore ${indice + 1}',
                onPressed: abilitato ? onTogli : null,
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s8),
          AppTextField(
            etichetta: 'Cosa fa',
            aiuto:
                'Per esempio: tira solo di destro, nuota tanto in controfuga.',
            controller: riga.nota,
            maxLines: 2,
            abilitato: abilitato,
            validator: (v) => lunghezza(v, NotaAvversario.limiteNotaGiocatore),
          ),
        ],
      ),
    );
  }
}
