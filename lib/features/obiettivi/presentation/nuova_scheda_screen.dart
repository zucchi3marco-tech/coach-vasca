import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/error_messages.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../theme/colori_app.dart';
import '../../../widgets/app_scaffold.dart';
import '../../../widgets/app_text_field.dart';
import '../../../widgets/error_banner.dart';
import '../../../widgets/form_group.dart';
import '../../../widgets/primary_button.dart';
import '../../stagioni/domain/stagione.dart';
import '../data/obiettivi_repository.dart';
import '../domain/scheda_obiettivi.dart';

/// Una scheda obiettivi nuova per la [stagione]: il titolo e le domande,
/// scelte fra quelle pronte o scritte dall'allenatore. Arriva agli atleti
/// del gruppo della stagione (o a tutto il club).
class NuovaSchedaScreen extends ConsumerStatefulWidget {
  const NuovaSchedaScreen({
    required this.stagione,
    this.giaFatte = 0,
    super.key,
  });

  final Stagione stagione;

  /// Le schede che la stagione ha già: per proporre il titolo.
  final int giaFatte;

  @override
  ConsumerState<NuovaSchedaScreen> createState() => _NuovaSchedaScreenState();
}

class _NuovaSchedaScreenState extends ConsumerState<NuovaSchedaScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _titolo = TextEditingController(
    text: titoloSchedaProposto(widget.giaFatte),
  );
  final _nuova = TextEditingController();

  /// Le domande scelte, nell'ordine in cui le leggerà l'atleta.
  final _domande = <String>[
    domandeObiettiviPronte[0],
    domandeObiettiviPronte[1],
    domandeObiettiviPronte[2],
  ];
  bool _salvataggio = false;
  String? _errore;

  @override
  void initState() {
    super.initState();
    _nuova.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _titolo.dispose();
    _nuova.dispose();
    super.dispose();
  }

  bool get _piena => _domande.length >= massimoDomandeObiettivi;

  void _scegliPronta(String domanda, bool scelta) => setState(() {
    if (scelta) {
      if (!_piena) _domande.add(domanda);
    } else {
      _domande.remove(domanda);
    }
  });

  void _aggiungiSua() {
    final testo = _nuova.text.trim();
    if (testo.isEmpty || _piena || _domande.contains(testo)) return;
    setState(() {
      _domande.add(testo);
      _nuova.clear();
    });
  }

  Future<void> _manda() async {
    if (!_formKey.currentState!.validate()) return;
    if (_domande.isEmpty) {
      setState(() => _errore = 'Scegli o scrivi almeno una domanda.');
      return;
    }
    setState(() {
      _salvataggio = true;
      _errore = null;
    });
    try {
      await ref
          .read(obiettiviRepositoryProvider)
          .crea(
            clubId: widget.stagione.clubId,
            stagioneId: widget.stagione.id,
            gruppoId: widget.stagione.gruppoId,
            titolo: _titolo.text,
            domande: _domande,
          );
      aggiornaObiettivi(ref);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Scheda mandata: agli atleti arriva un avviso'),
        ),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) setState(() => _errore = messaggioErrore(e));
    } finally {
      if (mounted) setState(() => _salvataggio = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    final sue = [
      for (final d in _domande)
        if (!domandeObiettiviPronte.contains(d)) d,
    ];
    final sullaSalute = sembraSullaSalute(_nuova.text);

    return AppScaffold(
      scrollabile: true,
      appBar: AppBar(title: const Text('Nuova scheda obiettivi')),
      body: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FormGroup(
              titolo: 'Scheda',
              campi: [
                AppTextField(
                  etichetta: 'Titolo',
                  controller: _titolo,
                  validator: (v) {
                    final t = (v ?? '').trim();
                    if (t.isEmpty) return 'Scrivi il titolo';
                    if (t.length > lunghezzaMassimaTitoloScheda) {
                      return 'Al massimo $lunghezzaMassimaTitoloScheda '
                          'caratteri';
                    }
                    return null;
                  },
                ),
              ],
            ),
            FormGroup(
              titolo: 'Domande pronte',
              spiegazione:
                  'Tocca per aggiungere o togliere. Al massimo '
                  '$massimoDomandeObiettivi domande in tutto.',
              campi: [
                Material(
                  type: MaterialType.transparency,
                  child: Column(
                    children: [
                      for (final d in domandeObiettiviPronte)
                        CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          controlAffinity: ListTileControlAffinity.leading,
                          value: _domande.contains(d),
                          onChanged: !_domande.contains(d) && _piena
                              ? null
                              : (v) => _scegliPronta(d, v ?? false),
                          title: Text(d),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            FormGroup(
              titolo: 'Le tue domande',
              spiegazione:
                  'Niente domande sulla salute: molti atleti sono minorenni.',
              campi: [
                for (final d in sue)
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          d,
                          style: AppTypography.corpo.copyWith(
                            color: colori.testo,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Togli la domanda',
                        icon: const Icon(Icons.close),
                        onPressed: () => setState(() => _domande.remove(d)),
                      ),
                    ],
                  ),
                AppTextField(
                  etichetta: 'Una domanda tua',
                  controller: _nuova,
                  maxLines: 2,
                  abilitato: !_piena,
                  aiuto: _piena
                      ? 'Hai già $massimoDomandeObiettivi domande.'
                      : null,
                  validator: (v) =>
                      (v ?? '').trim().length > lunghezzaMassimaDomanda
                      ? 'Al massimo $lunghezzaMassimaDomanda caratteri'
                      : null,
                ),
                if (sullaSalute)
                  Text(
                    'Sembra una domanda sulla salute: meglio non chiederla '
                    'nella scheda, molti atleti sono minorenni.',
                    style: AppTypography.piccolo.copyWith(color: colori.rosso),
                  ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: _nuova.text.trim().isEmpty || _piena
                        ? null
                        : _aggiungiSua,
                    icon: const Icon(Icons.add),
                    label: const Text('Aggiungi la domanda'),
                  ),
                ),
              ],
            ),
            FormGroup(
              titolo: 'Cosa leggono gli atleti',
              spiegazione: 'Le domande non si cambiano dopo la prima risposta.',
              isUltimo: true,
              campi: [
                if (_domande.isEmpty)
                  Text(
                    'Nessuna domanda.',
                    style: AppTypography.piccolo.copyWith(
                      color: colori.testoSecondario,
                    ),
                  )
                else
                  for (final (i, d) in _domande.indexed)
                    Text(
                      '${i + 1}. $d',
                      style: AppTypography.corpo.copyWith(color: colori.testo),
                    ),
              ],
            ),
            const SizedBox(height: AppSpacing.s16),
            if (_errore != null) ...[
              ErrorBanner(messaggio: _errore!),
              const SizedBox(height: AppSpacing.s16),
            ],
            PrimaryButton(
              label: 'Manda agli atleti',
              isLoading: _salvataggio,
              onPressed: _salvataggio ? null : _manda,
            ),
          ],
        ),
      ),
    );
  }
}
