import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/utils/error_messages.dart';
import '../../pallanuoto/application/pallanuoto_providers.dart';
import '../../pallanuoto/data/partite_repository.dart';
import '../../pallanuoto/domain/partita.dart';
import '../application/referti_providers.dart';
import '../data/referti_repository.dart';
import '../domain/referto_letto.dart';

class LeggiRefertoScreen extends ConsumerStatefulWidget {
  const LeggiRefertoScreen({required this.clubId, super.key});

  final String clubId;

  @override
  ConsumerState<LeggiRefertoScreen> createState() =>
      _LeggiRefertoScreenState();
}

class _LeggiRefertoScreenState extends ConsumerState<LeggiRefertoScreen> {
  Uint8List? _immagineBytes;
  String _mimeType = 'image/jpeg';
  bool _isLoading = false;
  String? _errore;
  RefertoLetto? _risultato;

  Future<void> _scegliFoto(ImageSource source) async {
    final file = await ImagePicker().pickImage(source: source, imageQuality: 85);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    setState(() {
      _immagineBytes = bytes;
      _mimeType = file.mimeType ?? 'image/jpeg';
      _risultato = null;
      _errore = null;
    });
  }

  Future<void> _mostraSceltaFonte() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Scatta una foto'),
              onTap: () => Navigator.of(context).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Scegli dalla galleria'),
              onTap: () => Navigator.of(context).pop(ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source != null) await _scegliFoto(source);
  }

  Future<void> _analizza() async {
    final bytes = _immagineBytes;
    if (bytes == null) return;
    setState(() {
      _isLoading = true;
      _errore = null;
    });
    try {
      final risultato = await ref
          .read(refertiRepositoryProvider)
          .leggiReferto(immagineBytes: bytes, mimeType: _mimeType);
      if (mounted) setState(() => _risultato = risultato);
    } catch (e) {
      if (mounted) setState(() => _errore = messaggioErrore(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Leggi referto')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Carica la foto di un referto FIN già compilato: un modello '
                'AI proverà a leggere punteggio, parziali e giocatori. '
                'Controlla sempre i dati letti prima di salvarli: non '
                'vengono salvati automaticamente da nessuna parte.',
              ),
              const SizedBox(height: 16),
              if (_immagineBytes != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.memory(_immagineBytes!, height: 220, fit: BoxFit.cover),
                ),
                const SizedBox(height: 12),
              ],
              OutlinedButton.icon(
                onPressed: _isLoading ? null : _mostraSceltaFonte,
                icon: const Icon(Icons.add_a_photo_outlined),
                label: Text(_immagineBytes == null ? 'Scegli foto' : 'Cambia foto'),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: (_immagineBytes == null || _isLoading) ? null : _analizza,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Analizza'),
              ),
              if (_errore != null) ...[
                const SizedBox(height: 16),
                Text(
                  _errore!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _isLoading ? null : _analizza,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Riprova'),
                ),
              ],
              if (_risultato != null) ...[
                const SizedBox(height: 24),
                const Text(
                  'Correggi qui sotto eventuali errori di lettura (soprattutto '
                  'i nomi) prima di usare questi dati.',
                  style: TextStyle(fontStyle: FontStyle.italic),
                ),
                const SizedBox(height: 12),
                _RefertoModificabile(
                  key: ObjectKey(_risultato),
                  referto: _risultato!,
                  clubId: widget.clubId,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Modifica manuale dei dati letti dal modello: la lettura di una foto
/// scritta a mano non è mai affidabile al 100%, soprattutto per i nomi, per
/// cui ogni campo resta un testo modificabile invece di essere di sola
/// lettura.
class _RefertoModificabile extends ConsumerStatefulWidget {
  const _RefertoModificabile({
    required this.referto,
    required this.clubId,
    super.key,
  });

  final RefertoLetto referto;
  final String clubId;

  @override
  ConsumerState<_RefertoModificabile> createState() =>
      _RefertoModificabileState();
}

class _RefertoModificabileState extends ConsumerState<_RefertoModificabile> {
  bool _isSaving = false;
  String? _saveError;
  late final TextEditingController _squadraCasaCtrl;
  late final TextEditingController _squadraTrasfertaCtrl;
  late final TextEditingController _risultatoCasaCtrl;
  late final TextEditingController _risultatoTrasfertaCtrl;
  late final List<(TextEditingController, TextEditingController)> _parzialiCtrl;
  late final List<_GiocatoreCtrl> _giocatoriCasaCtrl;
  late final List<_GiocatoreCtrl> _giocatoriTrasfertaCtrl;

  @override
  void initState() {
    super.initState();
    final r = widget.referto;
    _squadraCasaCtrl = TextEditingController(text: r.squadraCasa);
    _squadraTrasfertaCtrl = TextEditingController(text: r.squadraTrasferta);
    _risultatoCasaCtrl = TextEditingController(text: '${r.risultatoCasa}');
    _risultatoTrasfertaCtrl = TextEditingController(
      text: '${r.risultatoTrasferta}',
    );
    _parzialiCtrl = [
      for (final p in r.parziali)
        (
          TextEditingController(text: '${p.casa}'),
          TextEditingController(text: '${p.trasferta}'),
        ),
    ];
    _giocatoriCasaCtrl = [for (final g in r.giocatoriCasa) _GiocatoreCtrl(g)];
    _giocatoriTrasfertaCtrl = [
      for (final g in r.giocatoriTrasferta) _GiocatoreCtrl(g),
    ];
  }

  @override
  void dispose() {
    _squadraCasaCtrl.dispose();
    _squadraTrasfertaCtrl.dispose();
    _risultatoCasaCtrl.dispose();
    _risultatoTrasfertaCtrl.dispose();
    for (final (casa, trasferta) in _parzialiCtrl) {
      casa.dispose();
      trasferta.dispose();
    }
    for (final g in _giocatoriCasaCtrl) {
      g.dispose();
    }
    for (final g in _giocatoriTrasfertaCtrl) {
      g.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _squadraCasaCtrl,
                decoration: const InputDecoration(labelText: 'Squadra casa'),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 48,
              child: TextFormField(
                controller: _risultatoCasaCtrl,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
              ),
            ),
            const Text(' - '),
            SizedBox(
              width: 48,
              child: TextFormField(
                controller: _risultatoTrasfertaCtrl,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextFormField(
                controller: _squadraTrasfertaCtrl,
                decoration: const InputDecoration(
                  labelText: 'Squadra trasferta',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text('Parziali', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        for (var i = 0; i < _parzialiCtrl.length; i++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Text('Tempo ${i + 1}: '),
                SizedBox(
                  width: 48,
                  child: TextFormField(
                    controller: _parzialiCtrl[i].$1,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                  ),
                ),
                const Text(' - '),
                SizedBox(
                  width: 48,
                  child: TextFormField(
                    controller: _parzialiCtrl[i].$2,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 24),
        _TabellaSquadraModificabile(
          titolo: 'Squadra casa',
          giocatori: _giocatoriCasaCtrl,
        ),
        const SizedBox(height: 24),
        _TabellaSquadraModificabile(
          titolo: 'Squadra trasferta',
          giocatori: _giocatoriTrasfertaCtrl,
        ),
        const SizedBox(height: 24),
        if (_saveError != null) ...[
          Text(
            _saveError!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
          const SizedBox(height: 8),
        ],
        FilledButton.icon(
          onPressed: _isSaving ? null : _salva,
          icon: _isSaving
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.save_outlined),
          label: const Text('Salva referto'),
        ),
      ],
    );
  }

  int _parseInt(TextEditingController controller, String etichetta) {
    final valore = int.tryParse(controller.text.trim());
    if (valore == null) {
      throw FormatException('Valore non valido per "$etichetta"');
    }
    return valore;
  }

  Future<void> _salva() async {
    setState(() {
      _isSaving = true;
      _saveError = null;
    });
    try {
      final squadraCasa = _squadraCasaCtrl.text.trim();
      final squadraTrasferta = _squadraTrasfertaCtrl.text.trim();
      if (squadraCasa.isEmpty || squadraTrasferta.isEmpty) {
        throw const FormatException('Indica il nome di entrambe le squadre');
      }
      final risultatoCasa = _parseInt(_risultatoCasaCtrl, 'risultato casa');
      final risultatoTrasferta = _parseInt(
        _risultatoTrasfertaCtrl,
        'risultato trasferta',
      );
      final parziali = [
        for (final (casa, trasferta) in _parzialiCtrl)
          ParzialeReferto(
            casa: _parseInt(casa, 'parziale casa'),
            trasferta: _parseInt(trasferta, 'parziale trasferta'),
          ),
      ];
      List<GiocatoreReferto> leggiGiocatori(List<_GiocatoreCtrl> ctrls) => [
        for (final g in ctrls)
          GiocatoreReferto(
            numeroCalottina: _parseInt(g.numero, 'numero calottina'),
            nome: g.nome.text.trim(),
            reti: _parseInt(g.reti, 'reti'),
            espulsioni: _parseInt(g.espulsioni, 'espulsioni'),
          ),
      ];
      final giocatoriCasa = leggiGiocatori(_giocatoriCasaCtrl);
      final giocatoriTrasferta = leggiGiocatori(_giocatoriTrasfertaCtrl);

      if (!mounted) return;
      final scelta = await showDialog<_ScelteSalvataggio>(
        context: context,
        builder: (context) => _DialogSceltaPartita(clubId: widget.clubId),
      );
      if (scelta == null) return;

      String partitaId;
      if (scelta.partitaEsistente != null) {
        partitaId = scelta.partitaEsistente!.id;
      } else {
        final nuova = await ref
            .read(partiteRepositoryProvider)
            .createPartita(
              clubId: widget.clubId,
              data: scelta.dataNuovaPartita!,
              squadraCasa: squadraCasa,
              squadraTrasferta: squadraTrasferta,
              numeroMaxConvocati: 15,
              dettaglioTiro: 'semplice',
              tracciaTempo: true,
              modalitaSuperiorita: 'singolo',
            );
        partitaId = nuova.id;
      }

      await ref
          .read(refertiRepositoryProvider)
          .salvaReferto(
            partitaId: partitaId,
            squadraCasa: squadraCasa,
            squadraTrasferta: squadraTrasferta,
            risultatoCasa: risultatoCasa,
            risultatoTrasferta: risultatoTrasferta,
            parziali: parziali,
            giocatoriCasa: giocatoriCasa,
            giocatoriTrasferta: giocatoriTrasferta,
          );

      ref.invalidate(refertoPerPartitaProvider(partitaId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Referto salvato.')),
        );
      }
    } catch (e) {
      if (mounted) setState(() => _saveError = messaggioErrore(e));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}

/// Esito del dialog di scelta: o una partita esistente, o la data per una
/// nuova partita da creare al volo (nome squadre presi dal referto).
class _ScelteSalvataggio {
  const _ScelteSalvataggio({this.partitaEsistente, this.dataNuovaPartita});

  final Partita? partitaEsistente;
  final DateTime? dataNuovaPartita;
}

class _DialogSceltaPartita extends ConsumerStatefulWidget {
  const _DialogSceltaPartita({required this.clubId});

  final String clubId;

  @override
  ConsumerState<_DialogSceltaPartita> createState() =>
      _DialogSceltaPartitaState();
}

class _DialogSceltaPartitaState extends ConsumerState<_DialogSceltaPartita> {
  bool _nuovaPartita = false;
  Partita? _partitaSelezionata;
  DateTime _dataNuovaPartita = DateTime.now();

  Future<void> _pickData() async {
    final selezionata = await showDatePicker(
      context: context,
      initialDate: _dataNuovaPartita,
      firstDate: DateTime(DateTime.now().year - 2),
      lastDate: DateTime(DateTime.now().year + 2),
    );
    if (selezionata != null) {
      setState(() => _dataNuovaPartita = selezionata);
    }
  }

  @override
  Widget build(BuildContext context) {
    final partiteAsync = ref.watch(partiteListProvider(widget.clubId));

    return AlertDialog(
      title: const Text('Collega il referto a una partita'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: false, label: Text('Partita esistente')),
                ButtonSegment(value: true, label: Text('Nuova partita')),
              ],
              selected: {_nuovaPartita},
              onSelectionChanged: (s) =>
                  setState(() => _nuovaPartita = s.first),
            ),
            const SizedBox(height: 12),
            if (!_nuovaPartita)
              partiteAsync.when(
                data: (partite) => partite.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.only(left: 16),
                        child: Text('Nessuna partita in agenda per il club.'),
                      )
                    : Padding(
                        padding: const EdgeInsets.only(left: 16),
                        child: DropdownButtonFormField<Partita>(
                          initialValue: _partitaSelezionata,
                          isExpanded: true,
                          hint: const Text('Scegli la partita'),
                          items: [
                            for (final p in partite)
                              DropdownMenuItem(
                                value: p,
                                child: Text(
                                  '${p.squadraCasa} - ${p.squadraTrasferta} '
                                  '(${p.data.day.toString().padLeft(2, '0')}/'
                                  '${p.data.month.toString().padLeft(2, '0')}/'
                                  '${p.data.year})',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                          ],
                          onChanged: (v) =>
                              setState(() => _partitaSelezionata = v),
                        ),
                      ),
                loading: () => const Padding(
                  padding: EdgeInsets.only(left: 16),
                  child: LinearProgressIndicator(),
                ),
                error: (e, _) => Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: Text(messaggioErrore(e)),
                ),
              ),
            if (_nuovaPartita)
              Padding(
                padding: const EdgeInsets.only(left: 16),
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Data partita'),
                  subtitle: Text(
                    '${_dataNuovaPartita.day.toString().padLeft(2, '0')}/'
                    '${_dataNuovaPartita.month.toString().padLeft(2, '0')}/'
                    '${_dataNuovaPartita.year}',
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: _pickData,
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annulla'),
        ),
        FilledButton(
          onPressed: (!_nuovaPartita && _partitaSelezionata == null)
              ? null
              : () => Navigator.of(context).pop(
                  _nuovaPartita
                      ? _ScelteSalvataggio(dataNuovaPartita: _dataNuovaPartita)
                      : _ScelteSalvataggio(
                          partitaEsistente: _partitaSelezionata,
                        ),
                ),
          child: const Text('Conferma'),
        ),
      ],
    );
  }
}

class _GiocatoreCtrl {
  _GiocatoreCtrl(GiocatoreReferto g)
    : numero = TextEditingController(text: '${g.numeroCalottina}'),
      nome = TextEditingController(text: g.nome),
      reti = TextEditingController(text: '${g.reti}'),
      espulsioni = TextEditingController(text: '${g.espulsioni}');

  final TextEditingController numero;
  final TextEditingController nome;
  final TextEditingController reti;
  final TextEditingController espulsioni;

  void dispose() {
    numero.dispose();
    nome.dispose();
    reti.dispose();
    espulsioni.dispose();
  }
}

class _TabellaSquadraModificabile extends StatelessWidget {
  const _TabellaSquadraModificabile({
    required this.titolo,
    required this.giocatori,
  });

  final String titolo;
  final List<_GiocatoreCtrl> giocatori;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(titolo, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        for (final g in giocatori)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                SizedBox(
                  width: 44,
                  child: TextFormField(
                    controller: g.numero,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    decoration: const InputDecoration(isDense: true),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: g.nome,
                    decoration: const InputDecoration(isDense: true),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 56,
                  child: TextFormField(
                    controller: g.reti,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    decoration: const InputDecoration(
                      isDense: true,
                      labelText: 'Reti',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 56,
                  child: TextFormField(
                    controller: g.espulsioni,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    decoration: const InputDecoration(
                      isDense: true,
                      labelText: 'Esp.',
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
