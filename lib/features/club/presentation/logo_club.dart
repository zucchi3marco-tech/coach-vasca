import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/error_messages.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../theme/colori_app.dart';
import '../../../theme/palette_acqua.dart';
import '../../../widgets/secondary_button.dart';
import '../../../widgets/section_header.dart';
import '../data/logo_club_repository.dart';

/// Come si sceglie l'immagine del logo: dietro un provider perché nei
/// test non c'è la finestra dei file del sistema.
final sceltaLogoProvider = Provider<Future<Uint8List?> Function()>(
  (ref) => () async {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: const ['png', 'jpg', 'jpeg'],
      dialogTitle: 'Scegli il logo del club',
    );
    if (file == null) return null;
    return file.readAsBytes();
  },
);

/// «Il logo del club» in «Il mio club»: il logo che va in testa ai PDF.
/// Il responsabile lo carica, lo cambia o lo toglie; gli altri lo vedono.
class SezioneLogoClub extends ConsumerStatefulWidget {
  const SezioneLogoClub({
    required this.clubId,
    required this.modificabile,
    super.key,
  });

  final String clubId;
  final bool modificabile;

  @override
  ConsumerState<SezioneLogoClub> createState() => _SezioneLogoClubState();
}

class _SezioneLogoClubState extends ConsumerState<SezioneLogoClub> {
  bool _occupato = false;

  void _avviso(String testo) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(testo)));
  }

  Future<void> _esegui(Future<void> Function() azione, String fatto) async {
    if (_occupato) return;
    setState(() => _occupato = true);
    try {
      await azione();
      ref.invalidate(logoClubProvider(widget.clubId));
      if (mounted) _avviso(fatto);
    } catch (e) {
      if (mounted) _avviso(messaggioErrore(e));
    } finally {
      if (mounted) setState(() => _occupato = false);
    }
  }

  Future<void> _carica() async {
    final Uint8List? bytes;
    try {
      bytes = await ref.read(sceltaLogoProvider)();
    } catch (e) {
      if (mounted) {
        _avviso('Non riesco ad aprire il file: ${messaggioErrore(e)}');
      }
      return;
    }
    if (bytes == null || !mounted) return;
    await _esegui(
      () => ref.read(logoClubRepositoryProvider).carica(widget.clubId, bytes!),
      'Logo salvato: da ora è in testa ai PDF.',
    );
  }

  Future<void> _togli() async {
    final conferma = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Togliere il logo?'),
        content: const Text(
          'I PDF avranno solo il nome del club. Puoi caricarlo di nuovo '
          'quando vuoi.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annulla'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Togli'),
          ),
        ],
      ),
    );
    if (conferma != true || !mounted) return;
    await _esegui(
      () => ref.read(logoClubRepositoryProvider).togli(widget.clubId),
      'Logo tolto.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    final logoAsync = ref.watch(logoClubProvider(widget.clubId));
    final logo = logoAsync.value;
    final caricamento = logoAsync.isLoading && !logoAsync.hasValue;

    final String spiegazione;
    if (logoAsync.hasError && !logoAsync.hasValue) {
      spiegazione = 'Non riesco a leggere il logo: controlla la connessione.';
    } else if (logo != null) {
      spiegazione = 'È in alto nei PDF: sedute, report, schemi e codici.';
    } else if (widget.modificabile) {
      spiegazione =
          'Mettilo e andrà in alto nei PDF: sedute, report, schemi e '
          'codici. PNG o JPG, fino a 1 MB.';
    } else {
      spiegazione = 'Non c\'è ancora: lo mette il responsabile del club.';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const TitoloSezione('Il logo del club'),
        Container(
          padding: const EdgeInsets.all(AppSpacing.paddingPannello),
          decoration: BoxDecoration(
            color: colori.superficie,
            borderRadius: BorderRadius.circular(AppRadius.pannello),
            border: Border.all(color: colori.linea),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 72,
                height: 72,
                padding: const EdgeInsets.all(AppSpacing.s8),
                decoration: BoxDecoration(
                  // Il logo si stampa su carta bianca: lo si guarda su
                  // bianco anche con il tema scuro.
                  color: logo != null
                      ? CartaPalette.foglio
                      : colori.superficieAlt,
                  borderRadius: BorderRadius.circular(AppRadius.controllo),
                  border: Border.all(color: colori.linea),
                ),
                alignment: Alignment.center,
                child: caricamento
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : logo != null
                    ? Image.memory(
                        logo,
                        fit: BoxFit.contain,
                        semanticLabel: 'Logo del club',
                        errorBuilder: (_, _, _) => Icon(
                          Icons.broken_image_outlined,
                          color: colori.testoTenue,
                        ),
                      )
                    : Icon(Icons.shield_outlined, color: colori.testoTenue),
              ),
              const SizedBox(width: AppSpacing.s16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      spiegazione,
                      style: AppTypography.piccolo.copyWith(
                        color: colori.testoSecondario,
                      ),
                    ),
                    if (widget.modificabile) ...[
                      const SizedBox(height: AppSpacing.s12),
                      Wrap(
                        spacing: AppSpacing.s8,
                        runSpacing: AppSpacing.s8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          SecondaryButton(
                            label: logo == null
                                ? 'Carica il logo'
                                : 'Cambia il logo',
                            icon: Icons.upload_outlined,
                            expanded: false,
                            onPressed: _occupato || caricamento
                                ? null
                                : _carica,
                          ),
                          if (logo != null)
                            TextButton(
                              onPressed: _occupato ? null : _togli,
                              child: const Text('Togli'),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
