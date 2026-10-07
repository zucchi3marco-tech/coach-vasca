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
import '../../gruppi/application/gruppi_providers.dart';
import '../application/schemi_tattici_providers.dart';
import '../data/schemi_tattici_repository.dart';
import '../domain/schema_tattico.dart';
import 'striscia_passi.dart';
import 'water_polo_tactics_board.dart';
import '../../../widgets/nascondi_barra_club.dart';

/// Crea (o modifica) uno schema tattico: titolo + una sequenza di passi
/// (al più [SchemaTattico.massimoPassi]), ciascuno con la propria
/// lavagna modificabile — es. passo 1 le posizioni di partenza, passo 2
/// le frecce di movimento, passo 3 le posizioni finali. Ogni
/// tocco/trascinamento sulla lavagna aggiorna solo lo stato di questo
/// form (in memoria); il salvataggio vero e proprio avviene al tocco di
/// "Salva schema".
class SchemaTatticoFormScreen extends ConsumerStatefulWidget {
  const SchemaTatticoFormScreen({required this.clubId, this.schema, super.key});

  final String clubId;
  final SchemaTattico? schema;

  @override
  ConsumerState<SchemaTatticoFormScreen> createState() =>
      _SchemaTatticoFormScreenState();
}

class _SchemaTatticoFormScreenState
    extends ConsumerState<SchemaTatticoFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titoloController;
  late final TextEditingController _categoriaController;
  late final Set<String> _gruppoIdsSelezionati;

  late List<PassoSchema> _passi;
  int _passoAttuale = 0;
  late CampoLavagna _campo;
  bool _bloccata = false;

  /// Cresce quando i passi cambiano tutti insieme (duplica, sposta,
  /// elimina, specchia): la lavagna va ricostruita anche se l'indice del
  /// passo scelto è rimasto lo stesso, o mostrerebbe il contenuto vecchio.
  int _versione = 0;

  bool _inRiproduzione = false;
  int _passoPartenza = 0;
  int _passoMostrato = 0;
  int _avvii = 0;
  double _velocita = 1.0;

  bool _isSubmitting = false;
  String? _errorMessage;

  bool get _isEditing => widget.schema != null;

  @override
  void initState() {
    super.initState();
    final s = widget.schema;
    _titoloController = TextEditingController(text: s?.titolo ?? '');
    _categoriaController = TextEditingController(text: s?.categoria ?? '');
    _gruppoIdsSelezionati = {...?s?.gruppoIds};
    _passi = List.of(s?.passi ?? const [(giocatori: [], frecce: [])]);
    _campo = CampoLavagna.values.byName(s?.campo ?? 'intero');
  }

  @override
  void dispose() {
    _titoloController.dispose();
    _categoriaController.dispose();
    super.dispose();
  }

  void _onCambiato(
    List<GiocatoreLavagna> giocatori,
    List<FrecciaLavagna> frecce,
  ) {
    // setState anche se la lavagna si ridisegna da sola: la miniatura del
    // passo nella striscia deve seguire ogni modifica.
    setState(
      () => _passi[_passoAttuale] = passoSchemaDaLavagna(giocatori, frecce),
    );
  }

  void _cambiaCampo(CampoLavagna nuovo) => setState(() => _campo = nuovo);

  PassoLavagna _passoAWidget(PassoSchema p) => passoLavagnaDaSchema(p);

  void _play() {
    // Dall'ultimo passo non c'è niente da animare: si riparte dal primo.
    final partenza = _passoAttuale >= _passi.length - 1 ? 0 : _passoAttuale;
    setState(() {
      _inRiproduzione = true;
      _passoPartenza = partenza;
      _passoMostrato = partenza;
      _avvii++;
    });
  }

  /// Fine o stop: si torna a lavorare sul passo a cui si era arrivati.
  void _fermaRiproduzione() {
    if (!_inRiproduzione) return;
    setState(() {
      _inRiproduzione = false;
      _passoAttuale = _passoMostrato;
    });
  }

  void _seleziona(int indice) => setState(() {
    _inRiproduzione = false;
    _passoAttuale = indice;
  });

  void _duplicaPasso(int indice) {
    if (_passi.length >= SchemaTattico.massimoPassi) return;
    setState(() {
      _passi.insert(indice + 1, _passi[indice]);
      _passoAttuale = indice + 1;
      _versione++;
    });
  }

  void _spostaPasso(int da, int a) {
    if (a < 0 || a >= _passi.length) return;
    setState(() {
      final passo = _passi.removeAt(da);
      _passi.insert(a, passo);
      _passoAttuale = a;
      _versione++;
    });
  }

  void _specchia() => setState(() {
    _passi = [for (final p in _passi) passoSpecchiato(p)];
    _versione++;
  });

  void _aggiungiPasso() {
    if (_passi.length >= SchemaTattico.massimoPassi) return;
    setState(() {
      // Il nuovo passo parte dalle posizioni dei giocatori dell'attuale
      // (di solito il passo successivo riparte da dove sta il
      // precedente, non da zero), ma senza le sue frecce: sono
      // annotazioni di quel singolo passo, non devono restare a
      // descrivere uno spostamento vecchio nei passi successivi.
      _passi.add((
        giocatori: _passi[_passoAttuale].giocatori,
        frecce: const [],
      ));
      _passoAttuale = _passi.length - 1;
    });
  }

  Future<void> _eliminaPasso(int indice) async {
    final passo = _passi[indice];
    if (passo.giocatori.isNotEmpty || passo.frecce.isNotEmpty) {
      final conferma = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Eliminare il passo ${indice + 1}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Annulla'),
            ),
            DangerButton(
              label: 'Elimina',
              expanded: false,
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        ),
      );
      if (conferma != true) return;
    }
    setState(() {
      _passi.removeAt(indice);
      if (_passoAttuale > indice || _passoAttuale >= _passi.length) {
        _passoAttuale = (_passoAttuale - 1).clamp(0, _passi.length - 1);
      }
      _versione++;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final repository = ref.read(schemiTatticiRepositoryProvider);
    try {
      if (_isEditing) {
        await repository.aggiornaSchema(
          id: widget.schema!.id,
          gruppoIds: _gruppoIdsSelezionati.toList(),
          titolo: _titoloController.text.trim(),
          categoria: _categoriaController.text.trim(),
          campo: _campo.name,
          passi: _passi,
        );
      } else {
        await repository.creaSchema(
          clubId: widget.clubId,
          gruppoIds: _gruppoIdsSelezionati.toList(),
          titolo: _titoloController.text.trim(),
          categoria: _categoriaController.text.trim(),
          campo: _campo.name,
          passi: _passi,
        );
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) setState(() => _errorMessage = messaggioErrore(e));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _elimina() async {
    final conferma = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminare questo schema?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annulla'),
          ),
          DangerButton(
            label: 'Elimina',
            expanded: false,
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );
    if (conferma == true) {
      await ref
          .read(schemiTatticiRepositoryProvider)
          .eliminaSchema(widget.schema!.id);
      if (mounted) Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) =>
      NascondiBarraClub(child: _costruisci(context));

  Widget _costruisci(BuildContext context) {
    final categorieEsistenti =
        (ref.watch(schemiTatticiListProvider(widget.clubId)).value ?? [])
            .map((s) => s.categoria)
            .where((c) => c.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
    final gruppi = ref.watch(gruppiListProvider(widget.clubId)).value ?? [];
    final passoAttuale = _passoAWidget(_passi[_passoAttuale]);
    final passoFantasma = _passoAttuale > 0
        ? _passoAWidget(_passi[_passoAttuale - 1])
        : null;

    return AppScaffold(
      scrollabile: true,
      physics: _bloccata ? const NeverScrollableScrollPhysics() : null,
      appBar: AppBar(
        title: Text(_isEditing ? 'Modifica schema' : 'Nuovo schema'),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // La lavagna prima di tutto: è quello che si apre la pagina per
            // fare. Sotto, la striscia dei passi; titolo, categoria e
            // gruppi in fondo.
            WaterPoloTacticsBoard(
              key: ValueKey((_passoAttuale, _versione)),
              giocatoriIniziali: passoAttuale.giocatori,
              frecceIniziali: passoAttuale.frecce,
              passoFantasma: passoFantasma,
              campo: _campo,
              bloccata: _bloccata,
              onCampoCambiato: _cambiaCampo,
              onBloccataCambiato: (b) => setState(() => _bloccata = b),
              onCambiato: _onCambiato,
              sostitutoVasca: _inRiproduzione
                  ? SchemaTatticoPlayer(
                      key: ValueKey(_avvii),
                      passi: [for (final p in _passi) _passoAWidget(p)],
                      campo: _campo,
                      mostraComandi: false,
                      passoIniziale: _passoPartenza,
                      avviaSubito: true,
                      velocita: _velocita,
                      onPassoCambiato: (i) =>
                          setState(() => _passoMostrato = i),
                      onFine: _fermaRiproduzione,
                    )
                  : null,
            ),
            const SizedBox(height: AppSpacing.s12),
            StrisciaPassi(
              passi: [for (final p in _passi) _passoAWidget(p)],
              campo: _campo,
              selezionato: _inRiproduzione ? _passoMostrato : _passoAttuale,
              inRiproduzione: _inRiproduzione,
              velocita: _velocita,
              onSeleziona: _seleziona,
              onPlay: _play,
              onStop: _fermaRiproduzione,
              onVelocita: (v) => setState(() => _velocita = v),
              onSpecchia: _specchia,
              onSposta: _spostaPasso,
              onElimina: _eliminaPasso,
              onAggiungi: _passi.length < SchemaTattico.massimoPassi
                  ? _aggiungiPasso
                  : null,
              onDuplica: _passi.length < SchemaTattico.massimoPassi
                  ? _duplicaPasso
                  : null,
            ),
            const SizedBox(height: AppSpacing.s24),
            FormGroup(
              titolo: 'Dettagli dello schema',
              isUltimo: true,
              campi: [
                AppTextField(
                  etichetta: 'Titolo',
                  controller: _titoloController,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Inserisci un titolo'
                      : null,
                ),
                AppTextField(
                  etichetta: 'Categoria',
                  controller: _categoriaController,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Inserisci una categoria (es. Transizioni, '
                            'Superiorità, Difesa...)'
                      : null,
                ),
                if (categorieEsistenti.isNotEmpty)
                  Wrap(
                    spacing: AppSpacing.s8,
                    runSpacing: AppSpacing.s8,
                    children: [
                      for (final categoria in categorieEsistenti)
                        ActionChip(
                          label: Text(categoria),
                          onPressed: () => setState(
                            () => _categoriaController.text = categoria,
                          ),
                        ),
                    ],
                  ),
                Text(
                  'Gruppi (facoltativo, nessuno = tutto il club)',
                  style: AppTypography.corpo.copyWith(
                    color: context.colori.testoSecondario,
                  ),
                ),
                const SizedBox(height: AppSpacing.s8),
                Wrap(
                  spacing: AppSpacing.s8,
                  runSpacing: AppSpacing.s8,
                  children: [
                    for (final g in gruppi)
                      TonalChip(
                        etichetta: g.nome,
                        selezionato: _gruppoIdsSelezionati.contains(g.id),
                        onSelezionato: (selezionato) => setState(() {
                          if (selezionato) {
                            _gruppoIdsSelezionati.add(g.id);
                          } else {
                            _gruppoIdsSelezionati.remove(g.id);
                          }
                        }),
                      ),
                    for (final id in _gruppoIdsSelezionati)
                      if (!gruppi.any((g) => g.id == id))
                        TonalChip(
                          etichetta: 'Gruppo non trovato',
                          selezionato: true,
                          onSelezionato: (_) =>
                              setState(() => _gruppoIdsSelezionati.remove(id)),
                        ),
                  ],
                ),
              ],
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: AppSpacing.s16),
              ErrorBanner(messaggio: _errorMessage!),
            ],
            const SizedBox(height: AppSpacing.s24),
            PrimaryButton(
              label: 'Salva schema',
              isLoading: _isSubmitting,
              onPressed: _isSubmitting ? null : _submit,
            ),
            if (_isEditing) ...[
              const SizedBox(height: AppSpacing.s12),
              DangerButton(label: 'Elimina', onPressed: _elimina),
            ],
          ],
        ),
      ),
    );
  }
}
