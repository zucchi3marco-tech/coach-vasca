import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/condivisione/apri_indirizzo.dart';
import '../../../core/utils/error_messages.dart';
import '../../../core/video/link_youtube.dart';
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
import '../domain/esercizio_secco.dart';
import 'video_esercizio.dart';

/// Un esercizio dell'elenco del club, nuovo o da cambiare: nome, per che
/// cosa, a ripetizioni o a tempo, attrezzo e come si fa. Da un esercizio
/// esistente si archivia (resta nelle sedute già fatte) o, se non è in
/// nessuna seduta, si elimina. Torna l'esercizio salvato.
class EsercizioSeccoFormScreen extends ConsumerStatefulWidget {
  const EsercizioSeccoFormScreen({
    required this.clubId,
    this.esercizio,
    super.key,
  });

  final String clubId;
  final EsercizioSecco? esercizio;

  @override
  ConsumerState<EsercizioSeccoFormScreen> createState() =>
      _EsercizioSeccoFormScreenState();
}

class _EsercizioSeccoFormScreenState
    extends ConsumerState<EsercizioSeccoFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _nome = TextEditingController(text: widget.esercizio?.nome ?? '');
  late final _attrezzo = TextEditingController(
    text: widget.esercizio?.attrezzo ?? '',
  );
  late final _descrizione = TextEditingController(
    text: widget.esercizio?.descrizione ?? '',
  );
  late final _video = TextEditingController(
    text: switch (widget.esercizio) {
      EsercizioSecco(:final videoYoutube?, :final videoDaS) => linkYoutube(
        videoYoutube,
        da: videoDaS,
      ),
      _ => '',
    },
  );
  late CategoriaEsercizio _categoria =
      widget.esercizio?.categoria ?? CategoriaEsercizio.spalla;
  late MisuraEsercizio _misura =
      widget.esercizio?.misura ?? MisuraEsercizio.ripetizioni;
  bool _salvo = false;
  String? _errore;

  bool get _modifica => widget.esercizio != null;

  @override
  void dispose() {
    _nome.dispose();
    _attrezzo.dispose();
    _descrizione.dispose();
    _video.dispose();
    super.dispose();
  }

  EsercizioSecco _daSalvare({bool? archiviato}) => EsercizioSecco(
    id: widget.esercizio?.id ?? '',
    clubId: widget.clubId,
    nome: _nome.text.trim(),
    categoria: _categoria,
    misura: _misura,
    attrezzo: _attrezzo.text,
    descrizione: _descrizione.text,
    modello: widget.esercizio?.modello,
    archiviato: archiviato ?? widget.esercizio?.archiviato ?? false,
    videoYoutube: idYoutubeDa(_video.text),
    videoDaS: inizioYoutubeDa(_video.text),
  );

  Future<void> _salva({bool? archiviato}) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _salvo = true;
      _errore = null;
    });
    final repository = ref.read(seccoRepositoryProvider);
    try {
      final salvato = _modifica
          ? await repository.aggiornaEsercizio(
              _daSalvare(archiviato: archiviato),
            )
          : await repository.creaEsercizio(_daSalvare());
      if (mounted) Navigator.of(context).pop(salvato);
    } catch (e) {
      if (mounted) setState(() => _errore = messaggioErrore(e));
    } finally {
      if (mounted) setState(() => _salvo = false);
    }
  }

  /// La ricerca di YouTube con il nome dell'esercizio, in una scheda nuova
  /// (o, se non si può, l'indirizzo negli appunti).
  void _cercaSuYoutube() {
    final nome = _nome.text.trim();
    final indirizzo =
        'https://www.youtube.com/results?search_query='
        '${Uri.encodeQueryComponent(nome.isEmpty ? 'esercizio prevenzione spalla' : '$nome esercizio')}';
    if (apriIndirizzo(indirizzo)) return;
    Clipboard.setData(ClipboardData(text: indirizzo));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Indirizzo della ricerca copiato.')),
    );
  }

  Future<void> _elimina() async {
    final e = widget.esercizio!;
    final repository = ref.read(seccoRepositoryProvider);
    if (await repository.inUso(e.id)) {
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text('${e.nome} è già usato'),
          content: const Text(
            'Un esercizio usato in una seduta o in un programma non si '
            'elimina: archivialo, così non compare più fra quelli da '
            'scegliere.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Chiudi'),
            ),
          ],
        ),
      );
      return;
    }
    if (!mounted) return;
    final conferma = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Eliminare ${e.nome}?'),
        content: const Text('Esce dall\'elenco degli esercizi del club.'),
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
      await repository.eliminaEsercizio(e.id);
      if (mounted) Navigator.of(context).pop();
    } catch (err) {
      if (mounted) setState(() => _errore = messaggioErrore(err));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    final archiviato = widget.esercizio?.archiviato ?? false;
    return AppScaffold(
      scrollabile: true,
      appBar: AppBar(
        title: Text(_modifica ? 'Modifica esercizio' : 'Nuovo esercizio'),
        actions: [
          if (_modifica)
            PopupMenuButton<VoidCallback>(
              icon: const Icon(Icons.more_vert),
              tooltip: 'Altre azioni',
              onSelected: (azione) => azione(),
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: () => _salva(archiviato: !archiviato),
                  child: Text(archiviato ? 'Ripristina' : 'Archivia'),
                ),
                PopupMenuItem(value: _elimina, child: const Text('Elimina')),
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
              titolo: 'Esercizio',
              campi: [
                AppTextField(
                  etichetta: 'Nome',
                  controller: _nome,
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Scrivi il nome dell\'esercizio'
                      : null,
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Per che cosa',
                      style: AppTypography.etichetta.copyWith(
                        color: colori.testoSecondario,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s8),
                    Wrap(
                      spacing: AppSpacing.s8,
                      runSpacing: AppSpacing.s8,
                      children: [
                        for (final c in CategoriaEsercizio.values)
                          TonalChip(
                            etichetta: c.etichetta,
                            selezionato: _categoria == c,
                            onSelezionato: (_) =>
                                setState(() => _categoria = c),
                          ),
                      ],
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Si conta',
                      style: AppTypography.etichetta.copyWith(
                        color: colori.testoSecondario,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s8),
                    SegmentedButton<MisuraEsercizio>(
                      showSelectedIcon: false,
                      segments: [
                        for (final m in MisuraEsercizio.values)
                          ButtonSegment(value: m, label: Text(m.etichetta)),
                      ],
                      selected: {_misura},
                      onSelectionChanged: (s) =>
                          setState(() => _misura = s.first),
                    ),
                  ],
                ),
              ],
            ),
            FormGroup(
              titolo: 'Come si fa',
              isUltimo: true,
              campi: [
                AppTextField(
                  etichetta: 'Attrezzo (facoltativo)',
                  controller: _attrezzo,
                  aiuto: 'Per esempio: elastico, manubrio, palla medica.',
                ),
                AppTextField(
                  etichetta: 'Come si fa (facoltativo)',
                  controller: _descrizione,
                  maxLines: 5,
                  aiuto: 'Lo legge anche l\'atleta nella sua seduta.',
                ),
                AppTextField(
                  etichetta: 'Video su YouTube (facoltativo)',
                  controller: _video,
                  keyboardType: TextInputType.url,
                  aiuto:
                      'Incolla il link del video, anche «non in elenco»: se '
                      'ha il minuto di partenza, parte da lì. Lo vede anche '
                      'l\'atleta.',
                  validator: (v) =>
                      v == null || v.trim().isEmpty || idYoutubeDa(v) != null
                      ? null
                      : 'Non è un link di YouTube: copialo da «Condividi» '
                            'sotto il video',
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: _cercaSuYoutube,
                    icon: const Icon(Icons.search),
                    label: const Text('Cerca su YouTube'),
                  ),
                ),
                // L'anteprima del video del link, per controllare che sia
                // quello giusto.
                ValueListenableBuilder(
                  valueListenable: _video,
                  builder: (context, valore, _) {
                    final id = idYoutubeDa(valore.text);
                    return id == null
                        ? const SizedBox.shrink()
                        : VideoEsercizio(
                            videoId: id,
                            inizio: inizioYoutubeDa(valore.text),
                          );
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
              label: 'Salva esercizio',
              isLoading: _salvo,
              onPressed: _salvo ? null : _salva,
            ),
          ],
        ),
      ),
    );
  }
}
