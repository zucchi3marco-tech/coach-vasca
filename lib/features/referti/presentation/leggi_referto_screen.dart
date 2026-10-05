import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/utils/error_messages.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../theme/colori_app.dart';
import '../../../widgets/app_scaffold.dart';
import '../../../widgets/error_banner.dart';
import '../../../widgets/primary_button.dart';
import '../../../widgets/secondary_button.dart';
import '../../../widgets/section_header.dart';
import '../../atleti/application/atleti_providers.dart';
import '../../atleti/domain/atleta.dart';
import '../../pallanuoto/data/distinta_repository.dart';
import '../../pallanuoto/domain/partita.dart';
import '../application/referti_providers.dart';
import '../data/referti_repository.dart';
import '../domain/referto_letto.dart';

class LeggiRefertoScreen extends ConsumerStatefulWidget {
  const LeggiRefertoScreen({required this.partita, super.key});

  /// La partita a cui appartiene il referto: si arriva qui dalla partita
  /// stessa, quindi il referto è già assegnato a quella giusta.
  final Partita partita;

  @override
  ConsumerState<LeggiRefertoScreen> createState() => _LeggiRefertoScreenState();
}

class _LeggiRefertoScreenState extends ConsumerState<LeggiRefertoScreen> {
  Uint8List? _immagineBytes;
  String _mimeType = 'image/jpeg';
  bool _isLoading = false;
  String? _errore;
  RefertoLetto? _risultato;

  Future<void> _scegliFoto(ImageSource source) async {
    final file = await ImagePicker().pickImage(
      source: source,
      imageQuality: 85,
      // Una foto di un referto scritto a mano si legge bene anche
      // ridotta: senza questo limite una foto scattata con un telefono
      // recente (anche 4000px di lato) viene mandata all'AI a piena
      // risoluzione, gonfiando inutilmente tempo di invio e costo.
      maxWidth: 1600,
    );
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
    final colori = context.colori;
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.s8),
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
    final colori = context.colori;
    return AppScaffold(
      scrollabile: true,
      appBar: AppBar(title: const Text('Leggi referto')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Carica la foto di un referto FIN già compilato: un modello '
            'AI proverà a leggere punteggio, parziali e giocatori. '
            'Controlla sempre i dati letti prima di salvarli: non vengono '
            'salvati automaticamente da nessuna parte.',
            style: AppTypography.piccolo.copyWith(
              color: colori.testoSecondario,
            ),
          ),
          const SizedBox(height: AppSpacing.s16),
          if (_immagineBytes != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.controllo),
              child: Image.memory(
                _immagineBytes!,
                height: 220,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: AppSpacing.s12),
          ],
          SecondaryButton(
            onPressed: _isLoading ? null : _mostraSceltaFonte,
            icon: Icons.add_a_photo_outlined,
            label: _immagineBytes == null ? 'Scegli foto' : 'Cambia foto',
          ),
          const SizedBox(height: AppSpacing.s12),
          PrimaryButton(
            label: 'Analizza',
            isLoading: _isLoading,
            onPressed: (_immagineBytes == null || _isLoading)
                ? null
                : _analizza,
          ),
          if (_errore != null) ...[
            const SizedBox(height: AppSpacing.s16),
            ErrorBanner(messaggio: _errore!),
            const SizedBox(height: AppSpacing.s8),
            SecondaryButton(
              onPressed: _isLoading ? null : _analizza,
              icon: Icons.refresh,
              label: 'Riprova',
            ),
          ],
          if (_risultato != null) ...[
            const SizedBox(height: AppSpacing.s24),
            Text(
              'Correggi qui sotto eventuali errori di lettura (soprattutto '
              'i nomi) prima di usare questi dati.',
              style: AppTypography.piccolo.copyWith(
                color: colori.testoSecondario,
              ),
            ),
            const SizedBox(height: AppSpacing.s12),
            _RefertoModificabile(
              key: ObjectKey(_risultato),
              referto: _risultato!,
              partita: widget.partita,
            ),
          ],
        ],
      ),
    );
  }
}

/// Modifica manuale dei dati letti dal modello: la lettura di una foto
/// scritta a mano non è mai affidabile al 100%, soprattutto per i nomi, per
/// cui ogni campo resta un testo modificabile invece di essere di sola
/// lettura.
///
/// Nota di design: le righe della tabella giocatori usano `TextFormField`
/// stretti invece di `AppTextField` (che impone un'etichetta sopra e
/// occupa tutta la larghezza) — DESIGN.md sezione 4 prevede proprio questa
/// eccezione per le "colonne strette" di distinta/tabella passi/referto.
class _RefertoModificabile extends ConsumerStatefulWidget {
  const _RefertoModificabile({
    required this.referto,
    required this.partita,
    super.key,
  });

  final RefertoLetto referto;
  final Partita partita;

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
    final colori = context.colori;
    final stileCifre = AppTypography.condensata(
      AppTypography.numerica(AppTypography.corpo.copyWith(color: colori.testo)),
    );
    final stileCorpo = AppTypography.corpo.copyWith(color: colori.testo);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, vincoli) {
            Widget campoGol(TextEditingController ctrl, {String? etichetta}) =>
                TextFormField(
                  controller: ctrl,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: stileCifre,
                  decoration: InputDecoration(labelText: etichetta),
                );
            final campoCasa = TextFormField(
              controller: _squadraCasaCtrl,
              decoration: const InputDecoration(labelText: 'Squadra casa'),
            );
            final campoTrasferta = TextFormField(
              controller: _squadraTrasfertaCtrl,
              decoration: const InputDecoration(labelText: 'Squadra trasferta'),
            );
            // Su telefono due nomi di squadra e due punteggi affiancati
            // non ci stanno: una riga per squadra, ognuna col suo
            // punteggio.
            if (vincoli.maxWidth < 480) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(child: campoCasa),
                      const SizedBox(width: AppSpacing.s8),
                      SizedBox(
                        width: 64,
                        child: campoGol(_risultatoCasaCtrl, etichetta: 'Gol'),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.s8),
                  Row(
                    children: [
                      Expanded(child: campoTrasferta),
                      const SizedBox(width: AppSpacing.s8),
                      SizedBox(
                        width: 64,
                        child: campoGol(
                          _risultatoTrasfertaCtrl,
                          etichetta: 'Gol',
                        ),
                      ),
                    ],
                  ),
                ],
              );
            }
            return Row(
              children: [
                Expanded(child: campoCasa),
                const SizedBox(width: AppSpacing.s8),
                SizedBox(width: 48, child: campoGol(_risultatoCasaCtrl)),
                Text(' - ', style: stileCorpo),
                SizedBox(width: 48, child: campoGol(_risultatoTrasfertaCtrl)),
                const SizedBox(width: AppSpacing.s8),
                Expanded(child: campoTrasferta),
              ],
            );
          },
        ),
        const SizedBox(height: AppSpacing.s16),
        const SectionHeader('Parziali'),
        const SizedBox(height: AppSpacing.s8),
        for (var i = 0; i < _parzialiCtrl.length; i++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.s4),
            child: Row(
              children: [
                Text('Tempo ${i + 1}: ', style: stileCorpo),
                SizedBox(
                  width: 48,
                  child: TextFormField(
                    controller: _parzialiCtrl[i].$1,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    style: stileCifre,
                  ),
                ),
                Text(' - ', style: stileCorpo),
                SizedBox(
                  width: 48,
                  child: TextFormField(
                    controller: _parzialiCtrl[i].$2,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    style: stileCifre,
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: AppSpacing.s24),
        _TabellaSquadraModificabile(
          titolo: 'Squadra casa',
          giocatori: _giocatoriCasaCtrl,
        ),
        const SizedBox(height: AppSpacing.s24),
        _TabellaSquadraModificabile(
          titolo: 'Squadra trasferta',
          giocatori: _giocatoriTrasfertaCtrl,
        ),
        const SizedBox(height: AppSpacing.s24),
        if (_saveError != null) ...[
          ErrorBanner(messaggio: _saveError!),
          const SizedBox(height: AppSpacing.s8),
        ],
        PrimaryButton(
          label: 'Salva referto',
          icon: Icons.save_outlined,
          isLoading: _isSaving,
          onPressed: _isSaving ? null : _salva,
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
      // Valida subito i numeri dei giocatori (servono anche per il
      // collegamento agli atleti più avanti): il resto della lettura
      // (GiocatoreReferto con atletaId) si costruisce solo dopo, a
      // collegamento fatto.
      for (final g in [..._giocatoriCasaCtrl, ..._giocatoriTrasfertaCtrl]) {
        _parseInt(g.numero, 'numero calottina');
        _parseInt(g.reti, 'reti');
        _parseInt(g.espulsioni, 'espulsioni');
      }

      if (!mounted) return;
      final partitaId = widget.partita.id;
      final nostraSquadra = widget.partita.nostraSquadra;

      final nostriGiocatori = nostraSquadra == 'casa'
          ? _giocatoriCasaCtrl
          : _giocatoriTrasfertaCtrl;
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) => _DialogCollegaAtleti(
          clubId: widget.partita.clubId,
          partitaId: partitaId,
          giocatori: nostriGiocatori,
        ),
      );

      List<GiocatoreReferto> leggiGiocatori(List<_GiocatoreCtrl> ctrls) => [
        for (final g in ctrls)
          GiocatoreReferto(
            numeroCalottina: _parseInt(g.numero, 'numero calottina'),
            nome: g.nome.text.trim(),
            reti: _parseInt(g.reti, 'reti'),
            espulsioni: _parseInt(g.espulsioni, 'espulsioni'),
            atletaId: g.atletaId,
          ),
      ];
      final giocatoriCasa = leggiGiocatori(_giocatoriCasaCtrl);
      final giocatoriTrasferta = leggiGiocatori(_giocatoriTrasfertaCtrl);

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
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Referto salvato.')));
        // Si torna alla partita: il referto salvato compare lì.
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) setState(() => _saveError = messaggioErrore(e));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}

/// Collega ogni giocatore della NOSTRA squadra (letto dal referto) a un
/// Atleta esistente: serve per le statistiche stagionali per singolo
/// atleta. Auto-collega prima dalla distinta della partita quando
/// disponibile (stesso numero di calottina), poi per cognome (il referto
/// scrive "COGNOME Iniziale."): se il cognome corrisponde a un solo
/// atleta si collega da solo, se ne corrispondono piu' di uno si lascia
/// la scelta manuale per non collegare quello sbagliato. Un giocatore
/// senza collegamento resta comunque salvato nel referto (nome/reti/
/// espulsioni), ma le sue statistiche non compaiono per nessun atleta:
/// da qui l'avviso, non bloccante.
class _DialogCollegaAtleti extends ConsumerStatefulWidget {
  const _DialogCollegaAtleti({
    required this.clubId,
    required this.partitaId,
    required this.giocatori,
  });

  final String clubId;
  final String partitaId;
  final List<_GiocatoreCtrl> giocatori;

  @override
  ConsumerState<_DialogCollegaAtleti> createState() =>
      _DialogCollegaAtletiState();
}

class _DialogCollegaAtletiState extends ConsumerState<_DialogCollegaAtleti> {
  bool _caricamento = true;
  bool _autoCollegoDaCognomeFatto = false;

  @override
  void initState() {
    super.initState();
    _autoCollegaDaDistinta();
  }

  Future<void> _autoCollegaDaDistinta() async {
    try {
      final distintaRepo = ref.read(distintaRepositoryProvider);
      await distintaRepo.refreshFromRemote(widget.partitaId);
      final convocati = await distintaRepo
          .watchPerPartita(widget.partitaId)
          .first;
      final atletaPerNumero = {
        for (final c in convocati) c.numeroCalottina: c.atletaId,
      };
      for (final g in widget.giocatori) {
        if (g.atletaId != null) continue;
        final numero = int.tryParse(g.numero.text.trim());
        if (numero != null && atletaPerNumero.containsKey(numero)) {
          g.atletaId = atletaPerNumero[numero];
        }
      }
    } catch (_) {
      // Nessuna distinta per questa partita, o offline: si procede col
      // collegamento per cognome e, per il resto, manuale.
    } finally {
      if (mounted) setState(() => _caricamento = false);
    }
  }

  /// Per chi non e' stato collegato dalla distinta: cerca un atleta il cui
  /// cognome compaia nel nome letto dal referto. Ambiguo (0 o piu' di 1
  /// corrispondenza) → resta non collegato, scelta manuale.
  void _autoCollegaDaCognome(List<Atleta> atleti) {
    if (_autoCollegoDaCognomeFatto) return;
    _autoCollegoDaCognomeFatto = true;
    for (final g in widget.giocatori) {
      if (g.atletaId != null) continue;
      final nomeLetto = g.nome.text.trim().toUpperCase();
      if (nomeLetto.isEmpty) continue;
      final corrispondenti = atleti.where((a) {
        final cognome = a.cognome.trim();
        return cognome.isNotEmpty && nomeLetto.contains(cognome.toUpperCase());
      }).toList();
      if (corrispondenti.length == 1) {
        g.atletaId = corrispondenti.first.id;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final atletiAsync = ref.watch(
      atletiListProvider((clubId: widget.clubId, includeInactive: false)),
    );
    final nonCollegati = widget.giocatori
        .where((g) => g.atletaId == null)
        .length;
    final colori = context.colori;

    return AlertDialog(
      title: const Text('Collega i giocatori agli atleti'),
      content: SizedBox(
        width: double.maxFinite,
        child: _caricamento
            ? const Padding(
                padding: EdgeInsets.all(AppSpacing.s24),
                child: Center(child: CircularProgressIndicator()),
              )
            : atletiAsync.when(
                data: (atleti) {
                  _autoCollegaDaCognome(atleti);
                  final ordinati = [...atleti]
                    ..sort((a, b) => a.cognome.compareTo(b.cognome));
                  return SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Solo per la nostra squadra: servono per le '
                          'statistiche stagionali per singolo atleta. '
                          'Collegati già in automatico: chi ha lo stesso '
                          'numero di calottina di un convocato in distinta, '
                          'o il cui cognome corrisponde a un solo atleta. '
                          'Se due atleti hanno lo stesso cognome vanno '
                          'scelti a mano qui sotto.',
                          style: AppTypography.piccolo.copyWith(
                            color: colori.testoSecondario,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.s12),
                        for (final g in widget.giocatori)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: AppSpacing.s4,
                            ),
                            child: LayoutBuilder(
                              builder: (context, vincoli) {
                                final nome = Text(
                                  '${g.numero.text}  ${g.nome.text}',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.corpo.copyWith(
                                    color: colori.testo,
                                  ),
                                );
                                final scelta = DropdownButtonFormField<String?>(
                                  initialValue: g.atletaId,
                                  isExpanded: true,
                                  isDense: true,
                                  hint: const Text('Nessuno'),
                                  // Il valore scelto resta su una riga
                                  // (il campo e' compatto), nel menu i
                                  // nomi lunghi vanno su due.
                                  selectedItemBuilder: (context) => [
                                    const Text('Nessuno'),
                                    for (final a in ordinati)
                                      Text(
                                        a.nomeCompleto,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                  ],
                                  items: [
                                    const DropdownMenuItem<String?>(
                                      child: Text('Nessuno'),
                                    ),
                                    for (final a in ordinati)
                                      DropdownMenuItem<String?>(
                                        value: a.id,
                                        child: Text(
                                          a.nomeCompleto,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                  ],
                                  onChanged: (v) =>
                                      setState(() => g.atletaId = v),
                                );
                                // Nel dialog su telefono il nome letto
                                // sta sopra la scelta, a tutta larghezza.
                                if (vincoli.maxWidth < 400) {
                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      nome,
                                      const SizedBox(height: AppSpacing.s4),
                                      scelta,
                                    ],
                                  );
                                }
                                return Row(
                                  children: [
                                    Expanded(flex: 2, child: nome),
                                    const SizedBox(width: AppSpacing.s8),
                                    Expanded(flex: 3, child: scelta),
                                  ],
                                );
                              },
                            ),
                          ),
                        if (nonCollegati > 0) ...[
                          const SizedBox(height: AppSpacing.s12),
                          Text(
                            '$nonCollegati giocatori non collegati a un '
                            'atleta: le loro reti/espulsioni non verranno '
                            'conteggiate nelle statistiche per singolo '
                            'atleta (restano comunque salvate nel referto).',
                            style: AppTypography.piccolo.copyWith(
                              color: colori.rosso,
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text(
                  messaggioErrore(e),
                  style: AppTypography.piccolo.copyWith(color: colori.rosso),
                ),
              ),
      ),
      actions: [
        FilledButton(
          onPressed: _caricamento ? null : () => Navigator.of(context).pop(),
          child: const Text('Continua'),
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
      espulsioni = TextEditingController(text: '${g.espulsioni}'),
      atletaId = g.atletaId;

  final TextEditingController numero;
  final TextEditingController nome;
  final TextEditingController reti;
  final TextEditingController espulsioni;

  /// Collegato a un Atleta solo per i giocatori della nostra squadra,
  /// scelto nel dialog "Collega atleti" dopo aver indicato la partita
  /// (serve conoscere il numero di calottina e, se disponibile, la
  /// distinta per l'auto-collegamento). Mutabile: il dialog lo aggiorna
  /// direttamente su questi stessi oggetti.
  String? atletaId;

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
    final colori = context.colori;
    final stileCifre = AppTypography.condensata(
      AppTypography.numerica(AppTypography.corpo.copyWith(color: colori.testo)),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(titolo),
        const SizedBox(height: AppSpacing.s8),
        for (final g in giocatori)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.s4),
            child: LayoutBuilder(
              builder: (context, vincoli) {
                final stretto = vincoli.maxWidth < 480;
                Widget campoCifre(
                  TextEditingController ctrl, {
                  String? etichetta,
                }) => TextFormField(
                  controller: ctrl,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: stileCifre,
                  decoration: InputDecoration(
                    isDense: true,
                    labelText: etichetta,
                  ),
                );
                final nome = TextFormField(
                  controller: g.nome,
                  style: AppTypography.corpo.copyWith(color: colori.testo),
                  decoration: InputDecoration(
                    isDense: true,
                    labelText: stretto ? 'Giocatore' : null,
                  ),
                );
                // Su telefono il nome prende tutta la prima riga; numero,
                // reti ed espulsioni scendono sotto.
                if (stretto) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      nome,
                      const SizedBox(height: AppSpacing.s8),
                      Row(
                        children: [
                          SizedBox(
                            width: 64,
                            child: campoCifre(g.numero, etichetta: 'N.'),
                          ),
                          const SizedBox(width: AppSpacing.s8),
                          SizedBox(
                            width: 64,
                            child: campoCifre(g.reti, etichetta: 'Reti'),
                          ),
                          const SizedBox(width: AppSpacing.s8),
                          SizedBox(
                            width: 64,
                            child: campoCifre(g.espulsioni, etichetta: 'Esp.'),
                          ),
                        ],
                      ),
                    ],
                  );
                }
                return Row(
                  children: [
                    SizedBox(width: 44, child: campoCifre(g.numero)),
                    const SizedBox(width: AppSpacing.s8),
                    Expanded(child: nome),
                    const SizedBox(width: AppSpacing.s8),
                    SizedBox(
                      width: 56,
                      child: campoCifre(g.reti, etichetta: 'Reti'),
                    ),
                    const SizedBox(width: AppSpacing.s8),
                    SizedBox(
                      width: 56,
                      child: campoCifre(g.espulsioni, etichetta: 'Esp.'),
                    ),
                  ],
                );
              },
            ),
          ),
      ],
    );
  }
}
