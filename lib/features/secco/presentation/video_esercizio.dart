import 'package:flutter/material.dart';

import '../../../core/video/lettore_youtube.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../theme/colori_app.dart';
import '../../../widgets/secondary_button.dart';

/// Il video di YouTube di un esercizio: prima "Guarda il video" (il
/// lettore si carica solo se serve), poi il video 16:9 dentro la pagina,
/// dal secondo [inizio].
class VideoEsercizio extends StatefulWidget {
  const VideoEsercizio({
    required this.videoId,
    this.inizio,
    this.aperto = false,
    super.key,
  });

  final String videoId;
  final int? inizio;

  /// Già aperto (per l'anteprima nel modulo dell'esercizio).
  final bool aperto;

  @override
  State<VideoEsercizio> createState() => _VideoEsercizioState();
}

class _VideoEsercizioState extends State<VideoEsercizio> {
  late bool _aperto = widget.aperto;
  final _controllore = ControlloreVideo();

  @override
  void dispose() {
    _controllore.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    if (!_aperto) {
      return SecondaryButton(
        label: 'Guarda il video',
        icon: Icons.smart_display_outlined,
        expanded: false,
        onPressed: () => setState(() => _aperto = true),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.controllo),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: LettoreYoutube(
              // Un video nuovo (o un altro punto di partenza) è un lettore
              // nuovo.
              key: ValueKey('${widget.videoId}@${widget.inizio}'),
              videoId: widget.videoId,
              inizio: widget.inizio,
              controllore: _controllore,
            ),
          ),
        ),
        ListenableBuilder(
          listenable: _controllore,
          builder: (context, _) => _controllore.errore == null
              ? const SizedBox.shrink()
              : Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.s8),
                  child: Text(
                    _controllore.errore!,
                    style: AppTypography.piccolo.copyWith(
                      color: colori.attenzione,
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}
