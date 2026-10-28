import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/utils/date_italiane.dart';
import '../../../core/utils/error_messages.dart';
import '../../../core/utils/giorni.dart';
import '../../../core/utils/pace_format.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../theme/colori_app.dart';
import '../../../widgets/app_scaffold.dart';
import '../../../widgets/app_select.dart';
import '../../../widgets/app_text_field.dart';
import '../../../widgets/error_banner.dart';
import '../../../widgets/form_group.dart';
import '../../../widgets/pool_card.dart';
import '../../../widgets/primary_button.dart';
import '../../../widgets/secondary_button.dart';
import '../../../widgets/section_header.dart';
import '../../atleti/application/atleti_providers.dart';
import '../../atleti/data/personal_best_repository.dart';
import '../../atleti/domain/atleta.dart';
import '../../atleti/domain/pb_slots.dart';
import '../data/test_repository.dart';
import '../data/tempi_foto_repository.dart';
import '../domain/tempi_da_foto.dart';

/// Una riga da controllare: il nome letto, l'atleta abbinato (o scelto
/// dall'allenatore) e i valori, correggibili.
class _Riga {
  _Riga(this.letta, {required this.atletaId})
    : tempo = TextEditingController(
        text: letta.migliore == null
            ? ''
            : formatTempoCompatto(letta.migliore!),
      ),
      distanza = TextEditingController(text: letta.distanzaM?.toString() ?? '');

  final RigaTempiLetta letta;
  String? atletaId;
  final TextEditingController tempo;
  final TextEditingController distanza;

  void dispose() {
    tempo.dispose();
    distanza.dispose();
  }
}

/// "Tempi da una foto" (analisi "Il Mako della pallanuoto", proposta 8):
/// la foto del foglio o della lavagna dei tempi diventa una riga per
/// atleta. I nomi si abbinano da soli agli atleti della squadra; quelli
/// incerti li sceglie l'allenatore. Salvando, i tempi vanno fra i tempi
/// degli atleti o nei test BVS e T30.
class TempiDaFotoScreen extends ConsumerStatefulWidget {
  const TempiDaFotoScreen({required this.clubId, this.gruppoId, super.key});

  final String clubId;

  /// La squadra scelta in alto: i nomi si abbinano prima ai suoi atleti.
  final String? gruppoId;

  @override
  ConsumerState<TempiDaFotoScreen> createState() => _TempiDaFotoScreenState();
}

class _TempiDaFotoScreenState extends ConsumerState<TempiDaFotoScreen> {
  DestinazioneTempi _destinazione = DestinazioneTempi.tempi;
  SlotPersonalBest _slot = slotsPersonalBest.firstWhere(
    (s) => s.distanzaM == 100 && s.stile == 'libero',
    orElse: () => slotsPersonalBest.first,
  );
  DateTime _data = soloData(DateTime.now());

  Uint8List? _foto;
  String _mimeType = 'image/jpeg';
  bool _lettura = false;
  bool _salvataggio = false;
  String? _errore;
  List<_Riga>? _righe;

  @override
  void dispose() {
    for (final r in _righe ?? const <_Riga>[]) {
      r.dispose();
    }
    super.dispose();
  }

  List<Atleta> _atleti() {
    final tutti =
        ref
            .watch(
              atletiListProvider((
                clubId: widget.clubId,
                includeInactive: false,
              )),
            )
            .value ??
        const <Atleta>[];
    return [...tutti]..sort((a, b) => a.nomeCompleto.compareTo(b.nomeCompleto));
  }

  Future<void> _scegliFoto() async {
    final colori = context.colori;
    final fonte = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: Text(
                'Scatta una foto',
                style: AppTypography.corpo.copyWith(color: colori.testo),
              ),
              onTap: () => Navigator.of(context).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(
                'Scegli dalla galleria',
                style: AppTypography.corpo.copyWith(color: colori.testo),
              ),
              onTap: () => Navigator.of(context).pop(ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (fonte == null) return;
    // Un foglio scritto a mano si legge bene anche ridotto: meno tempo di
    // invio e meno costo (come per il referto).
    final file = await ImagePicker().pickImage(
      source: fonte,
      imageQuality: 85,
      maxWidth: 1600,
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    setState(() {
      _foto = bytes;
      _mimeType = file.mimeType ?? 'image/jpeg';
      _errore = null;
    });
  }

  Future<void> _leggi(List<Atleta> atleti) async {
    final foto = _foto;
    if (foto == null) return;
    setState(() {
      _lettura = true;
      _errore = null;
    });
    try {
      final lette = await ref
          .read(tempiFotoRepositoryProvider)
          .leggi(immagineBytes: foto, mimeType: _mimeType);
      // Prima gli atleti della squadra scelta, poi tutto il club.
      final squadra = widget.gruppoId == null
          ? atleti
          : atleti.where((a) => a.gruppoId == widget.gruppoId).toList();
      for (final r in _righe ?? const <_Riga>[]) {
        r.dispose();
      }
      setState(() {
        _righe = [
          for (final l in lette)
            _Riga(
              l,
              atletaId:
                  (abbinaAtleta(l.nome, squadra) ??
                          abbinaAtleta(l.nome, atleti))
                      ?.id,
            ),
        ];
      });
    } catch (e) {
      if (mounted) setState(() => _errore = messaggioErrore(e));
    } finally {
      if (mounted) setState(() => _lettura = false);
    }
  }

  /// Tempo e distanza della riga per la destinazione scelta; null se manca
  /// qualcosa.
  ({double tempoS, int? distanzaM})? _valori(_Riga r) {
    final distanza = int.tryParse(r.distanza.text.trim());
    switch (_destinazione) {
      case DestinazioneTempi.tempi:
        final tempo = leggiTempo(r.tempo.text);
        return tempo == null ? null : (tempoS: tempo, distanzaM: null);
      case DestinazioneTempi.bvs:
        final tempo = leggiTempo(r.tempo.text);
        return tempo == null || distanza == null || distanza <= 0
            ? null
            : (tempoS: tempo, distanzaM: distanza);
      case DestinazioneTempi.t30:
        return distanza == null || distanza <= 0
            ? null
            : (tempoS: 1800.0, distanzaM: distanza);
    }
  }

  bool _pronta(_Riga r) => r.atletaId != null && _valori(r) != null;

  Future<void> _salva() async {
    final righe = _righe ?? const <_Riga>[];
    final pronte = righe.where(_pronta).toList();
    if (pronte.isEmpty) return;
    setState(() {
      _salvataggio = true;
      _errore = null;
    });
    final nota = 'Dal foglio del ${dataNumerica(_data)}';
    try {
      for (final r in pronte) {
        final v = _valori(r)!;
        if (_destinazione == DestinazioneTempi.tempi) {
          await ref
              .read(personalBestRepositoryProvider)
              .creaPersonalBest(
                atletaId: r.atletaId!,
                stile: _slot.stile,
                distanzaM: _slot.distanzaM,
                tempoS: v.tempoS,
                data: _data,
                note: nota,
              );
        } else {
          await ref
              .read(testRepositoryProvider)
              .createTest(
                atletaId: r.atletaId!,
                tipo: _destinazione == DestinazioneTempi.bvs ? 'BVS' : 'T30',
                dataTest: _data,
                distanzaTotaleM: v.distanzaM!,
                tempoTotaleS: v.tempoS,
                note: nota,
              );
        }
      }
      if (!mounted) return;
      final scartate = righe.length - pronte.length;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${pronte.length == 1 ? 'Salvato 1 risultato' : 'Salvati ${pronte.length} risultati'}'
            '${scartate > 0 ? '; $scartate ${scartate == 1 ? 'riga incompleta non salvata' : 'righe incomplete non salvate'}' : ''}.',
          ),
        ),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) setState(() => _errore = messaggioErrore(e));
    } finally {
      if (mounted) setState(() => _salvataggio = false);
    }
  }

  Future<void> _scegliData() async {
    final scelta = await showDatePicker(
      context: context,
      initialDate: _data,
      firstDate: DateTime(DateTime.now().year - 2),
      lastDate: DateTime.now(),
    );
    if (scelta != null) setState(() => _data = scelta);
  }

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    final atleti = _atleti();
    final slots = slotsPersonalBest;
    final righe = _righe;
    final pronte = righe?.where(_pronta).length ?? 0;

    return AppScaffold(
      scrollabile: true,
      appBar: AppBar(title: const Text('Tempi da una foto')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FormGroup(
            titolo: 'Cosa c\'è sul foglio',
            campi: [
              SegmentedButton<DestinazioneTempi>(
                segments: [
                  for (final d in DestinazioneTempi.values)
                    ButtonSegment(value: d, label: Text(d.etichetta)),
                ],
                selected: {_destinazione},
                onSelectionChanged: (scelta) =>
                    setState(() => _destinazione = scelta.first),
              ),
              if (_destinazione == DestinazioneTempi.tempi)
                AppSelect<SlotPersonalBest>(
                  etichetta: 'Distanza e stile',
                  value: _slot,
                  items: [
                    for (final s in slots)
                      DropdownMenuItem(
                        value: s,
                        child: Text(
                          '${s.distanzaM} m ${capitalizzaParola(s.stile)}',
                        ),
                      ),
                  ],
                  onChanged: (s) {
                    if (s != null) setState(() => _slot = s);
                  },
                ),
              AppTextField(
                key: ValueKey('data-$_data'),
                etichetta: 'Giorno',
                valoreIniziale: dataNumerica(_data),
                readOnly: true,
                onTap: _scegliData,
                suffixIcon: const Icon(Icons.calendar_today_outlined),
              ),
            ],
          ),
          FormGroup(
            titolo: 'Foto',
            spiegazione:
                'Il foglio dritto e ben illuminato, un atleta per riga: il '
                'nome (anche solo il cognome) e il suo tempo. Controlli '
                'tutto prima di salvare.',
            campi: [
              if (_foto != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.memory(_foto!, height: 180, fit: BoxFit.cover),
                ),
              if (_foto == null)
                PrimaryButton(
                  label: 'Scatta o scegli la foto',
                  icon: Icons.photo_camera_outlined,
                  onPressed: _scegliFoto,
                )
              else ...[
                PrimaryButton(
                  label: righe == null ? 'Leggi i tempi' : 'Leggi di nuovo',
                  icon: Icons.document_scanner_outlined,
                  isLoading: _lettura,
                  onPressed: _lettura || _salvataggio
                      ? null
                      : () => _leggi(atleti),
                ),
                SecondaryButton(
                  label: 'Cambia foto',
                  onPressed: _lettura ? null : _scegliFoto,
                ),
              ],
            ],
          ),
          if (_errore != null) ...[
            ErrorBanner(messaggio: _errore!),
            const SizedBox(height: AppSpacing.s16),
          ],
          if (righe != null) ...[
            TitoloSezione(
              'Controlla e salva',
              conteggio: righe.length,
              spiegazione:
                  'I nomi sono abbinati agli atleti quando non ci sono '
                  'dubbi; dove manca, scegli tu l\'atleta. Correggi i '
                  'tempi letti male. Le righe incomplete non si salvano.',
            ),
            for (final (i, r) in righe.indexed) ...[
              _SchedaRiga(
                key: ObjectKey(r),
                riga: r,
                atleti: atleti,
                destinazione: _destinazione,
                completa: _pronta(r),
                onCambiata: () => setState(() {}),
                onTogli: () => setState(() {
                  r.dispose();
                  righe.removeAt(i);
                }),
              ),
              const SizedBox(height: AppSpacing.s12),
            ],
            const SizedBox(height: AppSpacing.s8),
            PrimaryButton(
              label: pronte == 1
                  ? 'Salva 1 risultato'
                  : 'Salva $pronte risultati',
              isLoading: _salvataggio,
              onPressed: pronte == 0 || _salvataggio || _lettura
                  ? null
                  : _salva,
            ),
            if (pronte < righe.length)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.s8),
                child: Text(
                  '${righe.length - pronte} da completare',
                  textAlign: TextAlign.center,
                  style: AppTypography.piccolo.copyWith(
                    color: colori.testoSecondario,
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _SchedaRiga extends StatelessWidget {
  const _SchedaRiga({
    required this.riga,
    required this.atleti,
    required this.destinazione,
    required this.completa,
    required this.onCambiata,
    required this.onTogli,
    super.key,
  });

  final _Riga riga;
  final List<Atleta> atleti;
  final DestinazioneTempi destinazione;
  final bool completa;
  final VoidCallback onCambiata;
  final VoidCallback onTogli;

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    final letti = riga.letta.tempiS;
    final conTempo = destinazione != DestinazioneTempi.t30;
    final conDistanza = destinazione != DestinazioneTempi.tempi;
    return PoolCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                completa ? Icons.check_circle_outline : Icons.help_outline,
                size: 20,
                color: completa ? colori.ok : colori.attenzione,
              ),
              const SizedBox(width: AppSpacing.s8),
              Expanded(
                child: Text(
                  'Scritto: «${riga.letta.nome}»',
                  style: AppTypography.corpoForte.copyWith(color: colori.testo),
                ),
              ),
              IconButton(
                tooltip: 'Togli questa riga',
                icon: const Icon(Icons.close),
                color: colori.testoSecondario,
                onPressed: onTogli,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s8),
          AppSelect<String?>(
            etichetta: 'Atleta',
            value: riga.atletaId,
            hint: 'Scegli l\'atleta',
            items: [
              for (final a in atleti)
                DropdownMenuItem(value: a.id, child: Text(a.nomeCompleto)),
            ],
            onChanged: (id) {
              riga.atletaId = id;
              onCambiata();
            },
          ),
          const SizedBox(height: AppSpacing.s12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (conTempo)
                Expanded(
                  child: AppTextField(
                    etichetta: 'Tempo',
                    controller: riga.tempo,
                    keyboardType: TextInputType.text,
                    aiuto: letti.length > 1
                        ? 'Letti ${letti.length} tempi: '
                              '${letti.map(formatTempoCompatto).join(' · ')}. '
                              'Si salva il migliore.'
                        : null,
                    onChanged: (_) => onCambiata(),
                  ),
                ),
              if (conTempo && conDistanza)
                const SizedBox(width: AppSpacing.s12),
              if (conDistanza)
                Expanded(
                  child: AppTextField(
                    etichetta: 'Metri',
                    controller: riga.distanza,
                    keyboardType: TextInputType.number,
                    onChanged: (_) => onCambiata(),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
