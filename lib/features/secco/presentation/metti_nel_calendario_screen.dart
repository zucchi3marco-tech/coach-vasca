import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/date_italiane.dart';
import '../../../core/utils/error_messages.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../theme/colori_app.dart';
import '../../../widgets/app_list_panel.dart';
import '../../../widgets/app_list_row.dart';
import '../../../widgets/app_scaffold.dart';
import '../../../widgets/app_select.dart';
import '../../../widgets/app_text_field.dart';
import '../../../widgets/error_banner.dart';
import '../../../widgets/form_group.dart';
import '../../../widgets/primary_button.dart';
import '../../../widgets/tonal_chip.dart';
import '../../gruppi/application/gruppi_providers.dart';
import '../../gruppi/application/selezione_gruppo_provider.dart';
import '../data/secco_repository.dart';
import '../domain/programma_secco.dart';

const _tuttoIlClub = '';
const _giorniBrevi = ['Lun', 'Mar', 'Mer', 'Gio', 'Ven', 'Sab', 'Dom'];

/// Mette un programma nel calendario di una squadra: per chi, il primo
/// giorno, i giorni della settimana (tanti quante le sedute: la A nel
/// primo, la B nel secondo) e i minuti; sotto le date di ogni settimana,
/// da controllare prima di creare le sedute.
class MettiNelCalendarioScreen extends ConsumerStatefulWidget {
  const MettiNelCalendarioScreen({
    required this.programma,
    this.oggi,
    super.key,
  });

  final ProgrammaSecco programma;

  /// Per i test: il giorno da cui si propone il primo lunedì.
  final DateTime? oggi;

  @override
  ConsumerState<MettiNelCalendarioScreen> createState() =>
      _MettiNelCalendarioScreenState();
}

class _MettiNelCalendarioScreenState
    extends ConsumerState<MettiNelCalendarioScreen> {
  final _formKey = GlobalKey<FormState>();
  late String? _gruppoId = ref.read(selezioneGruppoProvider)?.gruppoId;
  late DateTime _primoGiorno = prossimoLunedi(widget.oggi ?? DateTime.now());
  late final _data = TextEditingController(text: dataEstesa(_primoGiorno));
  late List<int> _giorni = giorniProposti(widget.programma.sedutePerSettimana);
  late final _durata = TextEditingController(
    text: '${widget.programma.durataMin}',
  );
  bool _salvo = false;
  String? _errore;

  int get _quante => widget.programma.sedutePerSettimana;

  @override
  void dispose() {
    _data.dispose();
    _durata.dispose();
    super.dispose();
  }

  Future<void> _scegliData() async {
    final scelta = await showDatePicker(
      context: context,
      initialDate: _primoGiorno,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (scelta != null) {
      setState(() {
        _primoGiorno = scelta;
        _data.text = dataEstesa(scelta);
      });
    }
  }

  void _alternaGiorno(int giorno) => setState(() {
    if (_quante == 1) {
      _giorni = [giorno];
    } else if (_giorni.contains(giorno)) {
      _giorni = [..._giorni]..remove(giorno);
    } else {
      _giorni = [..._giorni, giorno]..sort();
    }
  });

  Future<void> _salva(List<SedutaInCalendario> calendario) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _salvo = true;
      _errore = null;
    });
    final messaggero = ScaffoldMessenger.of(context);
    try {
      final quante = await ref
          .read(seccoRepositoryProvider)
          .mettiNelCalendario(
            programma: widget.programma,
            gruppoId: _gruppoId,
            calendario: calendario,
            durataMin: int.parse(_durata.text.trim()),
          );
      if (!mounted) return;
      Navigator.of(context).pop();
      messaggero
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              quante == 1
                  ? '1 seduta messa nel calendario'
                  : '$quante sedute messe nel calendario',
            ),
          ),
        );
    } catch (e) {
      if (mounted) {
        setState(() {
          _errore = messaggioErrore(e);
          _salvo = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    final p = widget.programma;
    final gruppi = ref.watch(gruppiListProvider(p.clubId)).value ?? const [];
    final giusti = _giorni.length == _quante;
    final calendario = giusti
        ? calendarioProgramma(
            primoGiorno: _primoGiorno,
            settimane: p.settimane.length,
            giorni: _giorni,
          )
        : const <SedutaInCalendario>[];
    final vuote = [
      for (final c in calendario)
        if (p.settimane[c.settimana - 1].sedute[c.seduta].isEmpty) c,
    ];
    final mancano = _quante - _giorni.length;

    return AppScaffold(
      scrollabile: true,
      appBar: AppBar(title: const Text('Metti nel calendario')),
      body: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              p.nome,
              style: AppTypography.titolo.copyWith(color: colori.testo),
            ),
            const SizedBox(height: AppSpacing.s4),
            Text(
              'Le sedute si creano nel calendario come sedute a secco: poi '
              'si cambiano una a una, e cambiare il programma non le tocca.',
              style: AppTypography.corpo.copyWith(
                color: colori.testoSecondario,
              ),
            ),
            const SizedBox(height: AppSpacing.s24),
            FormGroup(
              titolo: 'Per chi',
              campi: [
                AppSelect<String>(
                  etichetta: 'Squadra',
                  value:
                      _gruppoId != null && gruppi.any((g) => g.id == _gruppoId)
                      ? _gruppoId
                      : _tuttoIlClub,
                  items: [
                    for (final g in gruppi)
                      DropdownMenuItem(value: g.id, child: Text(g.nome)),
                    const DropdownMenuItem(
                      value: _tuttoIlClub,
                      child: Text('Tutto il club'),
                    ),
                  ],
                  onChanged: (id) => setState(
                    () => _gruppoId = id == null || id == _tuttoIlClub
                        ? null
                        : id,
                  ),
                ),
              ],
            ),
            FormGroup(
              titolo: 'Quando',
              campi: [
                AppTextField(
                  etichetta: 'Primo giorno',
                  controller: _data,
                  readOnly: true,
                  onTap: _salvo ? null : _scegliData,
                  suffixIcon: const Icon(Icons.calendar_today_outlined),
                  aiuto: 'Da qui ogni 7 giorni comincia una settimana.',
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Giorni della settimana',
                      style: AppTypography.etichetta.copyWith(
                        color: colori.testoSecondario,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s8),
                    Wrap(
                      spacing: AppSpacing.s8,
                      runSpacing: AppSpacing.s8,
                      children: [
                        for (var g = 1; g <= 7; g++)
                          TonalChip(
                            etichetta: _giorniBrevi[g - 1],
                            selezionato: _giorni.contains(g),
                            onSelezionato: (_) => _alternaGiorno(g),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.s8),
                    Text(
                      switch (mancano) {
                        0 when _quante == 1 => 'Una seduta a settimana.',
                        0 =>
                          'Ogni settimana la seduta A nel primo dei giorni '
                              'scelti, la B nel secondo'
                              '${_quante > 2 ? ', e così via' : ''}.',
                        1 => 'Scegli ancora un giorno.',
                        > 1 => 'Scegli ancora $mancano giorni.',
                        -1 =>
                          'Un giorno di troppo: le sedute a settimana sono '
                              '$_quante.',
                        _ =>
                          '${-mancano} giorni di troppo: le sedute a '
                              'settimana sono $_quante.',
                      },
                      style: AppTypography.piccolo.copyWith(
                        color: giusti
                            ? colori.testoSecondario
                            : colori.attenzione,
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
            if (calendario.isNotEmpty)
              FormGroup(
                titolo: 'Le sedute',
                isUltimo: true,
                campi: [
                  Text(
                    '${calendario.length == 1 ? '1 seduta a secco' : '${calendario.length} sedute a secco'}, '
                    'dal ${dataCompatta(calendario.first.data)} al '
                    '${dataCompatta(calendario.last.data)}.',
                    style: AppTypography.corpo.copyWith(color: colori.testo),
                  ),
                  AppListPanel(
                    righe: [
                      for (var s = 1; s <= p.settimane.length; s++)
                        AppListRow(
                          titolo: p.settimane[s - 1].scarico
                              ? 'Settimana $s · scarico'
                              : 'Settimana $s',
                          sottotitolo: [
                            for (final c in calendario)
                              if (c.settimana == s)
                                _quante == 1
                                    ? dataCompatta(c.data)
                                    : '${letteraSeduta(c.seduta)} '
                                          '${dataCompatta(c.data)}',
                          ].join(', '),
                        ),
                    ],
                  ),
                  if (vuote.isNotEmpty)
                    Text(
                      vuote.length == 1
                          ? 'Una seduta non ha esercizi '
                                '(settimana ${vuote.first.settimana}): si '
                                'crea vuota.'
                          : '${vuote.length} sedute non hanno esercizi: si '
                                'creano vuote.',
                      style: AppTypography.piccolo.copyWith(
                        color: colori.attenzione,
                      ),
                    ),
                ],
              ),
            if (_errore != null) ...[
              const SizedBox(height: AppSpacing.s12),
              ErrorBanner(
                messaggio: 'Non è stato possibile creare le sedute.',
                suggerimento:
                    'Riprova. Se l\'errore continua, chiudi e riapri l\'app.',
                dettaglioTecnico: _errore,
              ),
            ],
            const SizedBox(height: AppSpacing.s24),
            PrimaryButton(
              label: calendario.isEmpty
                  ? 'Scegli i giorni'
                  : calendario.length == 1
                  ? 'Metti 1 seduta nel calendario'
                  : 'Metti ${calendario.length} sedute nel calendario',
              isLoading: _salvo,
              onPressed: _salvo || calendario.isEmpty
                  ? null
                  : () => _salva(calendario),
            ),
          ],
        ),
      ),
    );
  }
}
