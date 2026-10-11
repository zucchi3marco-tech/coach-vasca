import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/date_italiane.dart';
import '../../../core/utils/error_messages.dart';
import '../../../core/utils/giorni.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/colori_app.dart';
import '../../../widgets/app_scaffold.dart';
import '../../../widgets/app_text_field.dart';
import '../../../widgets/error_banner.dart';
import '../../../widgets/form_group.dart';
import '../../../widgets/primary_button.dart';
import '../data/stagioni_repository.dart';
import '../domain/stagione.dart';

/// "18" o "18,5" km -> metri; null se vuoto, -1 se non è un numero.
int? metriDaKm(String testo) {
  final pulito = testo.trim().replaceAll(',', '.');
  if (pulito.isEmpty) return null;
  final km = double.tryParse(pulito);
  if (km == null || km < 0) return -1;
  return (km * 1000).round();
}

/// 18000 -> "18", 18500 -> "18,5".
String kmDaMetri(int metri) {
  final km = metri / 1000;
  return km == km.roundToDouble()
      ? km.round().toString()
      : km.toStringAsFixed(1).replaceAll('.', ',');
}

/// Una fase della stagione, nuova o da modificare ([indice] nella lista
/// delle fasi): nome, date dentro la stagione e i due obiettivi di ogni
/// settimana, entrambi facoltativi.
class FaseFormScreen extends ConsumerStatefulWidget {
  const FaseFormScreen({required this.stagione, this.indice, super.key});

  final Stagione stagione;
  final int? indice;

  @override
  ConsumerState<FaseFormScreen> createState() => _FaseFormScreenState();
}

class _FaseFormScreenState extends ConsumerState<FaseFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nome;
  late final TextEditingController _km;
  late final TextEditingController _carico;
  late DateTime _inizio;
  late DateTime _fine;
  bool _salvataggio = false;
  String? _errore;

  FaseStagione? get _esistente =>
      widget.indice == null ? null : widget.stagione.fasi[widget.indice!];

  @override
  void initState() {
    super.initState();
    final s = widget.stagione;
    final f = _esistente;
    if (f != null) {
      _inizio = f.dataInizio;
      _fine = f.dataFine;
    } else {
      // Una fase nuova parte dal giorno dopo l'ultima e arriva in fondo
      // alla stagione.
      final ultima = s.fasi.isEmpty ? null : s.fasi.last;
      _inizio = ultima == null
          ? s.dataInizio
          : aggiungiGiorni(soloData(ultima.dataFine), 1);
      if (_inizio.isAfter(s.dataFine)) _inizio = soloData(s.dataFine);
      _fine = s.dataFine;
    }
    final usati = {for (final f in s.fasi) f.nome};
    _nome = TextEditingController(
      text:
          f?.nome ??
          nomiFasiProposti.where((n) => !usati.contains(n)).firstOrNull ??
          '',
    );
    _km = TextEditingController(
      text: f?.obiettivoMetri == null ? '' : kmDaMetri(f!.obiettivoMetri!),
    );
    _carico = TextEditingController(text: f?.obiettivoCarico?.toString() ?? '');
  }

  @override
  void dispose() {
    _nome.dispose();
    _km.dispose();
    _carico.dispose();
    super.dispose();
  }

  Future<void> _scegliData({required bool inizio}) async {
    final s = widget.stagione;
    final scelta = await showDatePicker(
      context: context,
      initialDate: inizio ? _inizio : _fine,
      firstDate: inizio ? s.dataInizio : _inizio,
      lastDate: s.dataFine,
    );
    if (scelta == null) return;
    setState(() {
      if (inizio) {
        _inizio = scelta;
        if (_fine.isBefore(_inizio)) _fine = _inizio;
      } else {
        _fine = scelta;
      }
    });
  }

  /// La prima fase (diversa da questa) che ha dei giorni in comune.
  FaseStagione? _sovrapposta() {
    for (final (i, f) in widget.stagione.fasi.indexed) {
      if (i == widget.indice) continue;
      if (!f.dataInizio.isAfter(_fine) && !f.dataFine.isBefore(_inizio)) {
        return f;
      }
    }
    return null;
  }

  Future<void> _salva() async {
    if (!_formKey.currentState!.validate()) return;
    final altra = _sovrapposta();
    if (altra != null) {
      setState(
        () => _errore =
            'Si sovrappone alla fase «${altra.nome}» '
            '(${dataCompatta(altra.dataInizio)} – '
            '${dataCompatta(altra.dataFine)}). Cambia le date.',
      );
      return;
    }
    final fase = FaseStagione(
      nome: _nome.text.trim(),
      dataInizio: soloData(_inizio),
      dataFine: soloData(_fine),
      obiettivoMetri: metriDaKm(_km.text),
      obiettivoCarico: int.tryParse(_carico.text.trim()),
    );
    final fasi = [...widget.stagione.fasi];
    if (widget.indice == null) {
      fasi.add(fase);
    } else {
      fasi[widget.indice!] = fase;
    }
    await _scrivi(fasi);
  }

  Future<void> _elimina() async {
    final conferma = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminare la fase?'),
        content: Text(
          '«${_esistente!.nome}» e i suoi obiettivi spariscono dai grafici. '
          'Allenamenti e partite restano come sono.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annulla'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Elimina'),
          ),
        ],
      ),
    );
    if (conferma != true) return;
    await _scrivi([...widget.stagione.fasi]..removeAt(widget.indice!));
  }

  Future<void> _scrivi(List<FaseStagione> fasi) async {
    setState(() {
      _salvataggio = true;
      _errore = null;
    });
    try {
      await ref
          .read(stagioniRepositoryProvider)
          .salvaFasi(widget.stagione.id, fasi);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) setState(() => _errore = messaggioErrore(e));
    } finally {
      if (mounted) setState(() => _salvataggio = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    return AppScaffold(
      scrollabile: true,
      appBar: AppBar(
        title: Text(_esistente == null ? 'Nuova fase' : 'Modifica fase'),
        actions: [
          if (_esistente != null)
            TextButton.icon(
              onPressed: _salvataggio ? null : _elimina,
              icon: Icon(Icons.delete_outline, color: colori.rosso),
              label: Text('Elimina', style: TextStyle(color: colori.rosso)),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FormGroup(
              titolo: 'Fase',
              campi: [
                AppTextField(
                  etichetta: 'Nome',
                  controller: _nome,
                  validator: (v) => (v ?? '').trim().isEmpty
                      ? 'Scrivi il nome della fase'
                      : null,
                ),
                Wrap(
                  spacing: AppSpacing.s8,
                  runSpacing: AppSpacing.s8,
                  children: [
                    for (final n in nomiFasiProposti)
                      ActionChip(
                        label: Text(n),
                        onPressed: () => setState(() => _nome.text = n),
                      ),
                  ],
                ),
                AppTextField(
                  key: ValueKey('inizio-$_inizio'),
                  etichetta: 'Dal',
                  valoreIniziale: dataNumerica(_inizio),
                  readOnly: true,
                  onTap: () => _scegliData(inizio: true),
                  suffixIcon: const Icon(Icons.calendar_today_outlined),
                ),
                AppTextField(
                  key: ValueKey('fine-$_fine'),
                  etichetta: 'Al',
                  valoreIniziale: dataNumerica(_fine),
                  readOnly: true,
                  onTap: () => _scegliData(inizio: false),
                  suffixIcon: const Icon(Icons.calendar_today_outlined),
                ),
              ],
            ),
            FormGroup(
              titolo: 'Obiettivi di ogni settimana',
              isUltimo: true,
              campi: [
                AppTextField(
                  etichetta: 'Volume della squadra, km (facoltativo)',
                  controller: _km,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  aiuto:
                      'Compare come linea sul grafico "Volume per '
                      'settimana" degli allenamenti.',
                  validator: (v) => metriDaKm(v ?? '') == -1
                      ? 'Scrivi un numero di km'
                      : null,
                ),
                AppTextField(
                  etichetta: 'Carico di un atleta (facoltativo)',
                  controller: _carico,
                  keyboardType: TextInputType.number,
                  aiuto:
                      'RPE × minuti della settimana, per esempio 2400: '
                      'compare sul grafico del carico di ogni atleta.',
                  validator: (v) {
                    final t = (v ?? '').trim();
                    if (t.isEmpty) return null;
                    final n = int.tryParse(t);
                    return n == null || n < 0
                        ? 'Scrivi un numero intero'
                        : null;
                  },
                ),
              ],
            ),
            if (_errore != null) ...[
              ErrorBanner(messaggio: _errore!),
              const SizedBox(height: AppSpacing.s16),
            ],
            PrimaryButton(
              label: 'Salva fase',
              isLoading: _salvataggio,
              onPressed: _salvataggio ? null : _salva,
            ),
          ],
        ),
      ),
    );
  }
}
