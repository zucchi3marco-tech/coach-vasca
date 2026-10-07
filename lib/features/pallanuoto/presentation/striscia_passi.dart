import 'package:flutter/material.dart';

import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../theme/colori_app.dart';
import '../../../theme/palette_acqua.dart';
import '../../../widgets/section_header.dart';
import 'water_polo_tactics_board.dart';

const _spiegazionePassi =
    'Ogni passo è una schermata a sé: es. passo 1 le posizioni di '
    'partenza con le frecce, passo 2 dove arrivano. Un passo nuovo parte '
    'dalle posizioni di quello scelto. Con play i giocatori vanno da un '
    'passo al successivo seguendo le frecce.\n\n'
    'Tocca una miniatura per lavorarci; dal suo menu la duplichi, la '
    'sposti o la elimini. "Specchia" scambia destra e sinistra in tutti i '
    'passi, per giocare lo stesso schema sull\'altro lato.';

enum _AzionePasso { duplica, prima, dopo, elimina }

/// La striscia dei passi sotto la vasca dell'editor, come la linea del
/// tempo di un programma di animazione: una miniatura per passo, il "+"
/// per aggiungerne uno, play per vedere lo schema in movimento senza
/// lasciare l'editor.
class StrisciaPassi extends StatelessWidget {
  const StrisciaPassi({
    required this.passi,
    required this.campo,
    required this.selezionato,
    required this.inRiproduzione,
    required this.velocita,
    required this.onSeleziona,
    required this.onPlay,
    required this.onStop,
    required this.onVelocita,
    required this.onSpecchia,
    required this.onSposta,
    required this.onElimina,
    this.onAggiungi,
    this.onDuplica,
    super.key,
  });

  final List<PassoLavagna> passi;
  final CampoLavagna campo;

  /// Il passo su cui si lavora, o quello mostrato durante il play.
  final int selezionato;
  final bool inRiproduzione;
  final double velocita;

  final ValueChanged<int> onSeleziona;
  final VoidCallback onPlay;
  final VoidCallback onStop;
  final ValueChanged<double> onVelocita;
  final VoidCallback onSpecchia;
  final void Function(int da, int a) onSposta;
  final ValueChanged<int> onElimina;

  /// `null` quando i passi sono già al massimo.
  final VoidCallback? onAggiungi;
  final ValueChanged<int>? onDuplica;

  static const velocitaDisponibili = [0.5, 1.0, 1.5, 2.0];
  static const altezzaMiniatura = 72.0;

  String _etichettaVelocita(double v) =>
      '${v}x'.replaceAll('.0x', 'x').replaceAll('.', ',');

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    final larghezza = (altezzaMiniatura * campo.proporzioni).clamp(
      altezzaMiniatura * 0.7,
      altezzaMiniatura * 1.6,
    );
    final prossimaVelocita =
        velocitaDisponibili[(velocitaDisponibili.indexOf(velocita) + 1) %
            velocitaDisponibili.length];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            IconButton.filled(
              icon: Icon(inRiproduzione ? Icons.stop : Icons.play_arrow),
              tooltip: inRiproduzione
                  ? 'Ferma'
                  : 'Guarda lo schema in movimento',
              onPressed: passi.length < 2
                  ? null
                  : (inRiproduzione ? onStop : onPlay),
            ),
            const SizedBox(width: AppSpacing.s8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Passo ${selezionato + 1} di ${passi.length}',
                    style: AppTypography.corpoForte.copyWith(
                      color: colori.testo,
                    ),
                  ),
                  Text(
                    passi.length < 2
                        ? 'Aggiungi un passo per vederlo in movimento.'
                        : 'Play: i giocatori seguono le frecce.',
                    style: AppTypography.piccolo.copyWith(
                      color: colori.testoSecondario,
                    ),
                  ),
                ],
              ),
            ),
            Tooltip(
              message: 'Velocità dell\'animazione',
              child: TextButton(
                onPressed: () => onVelocita(prossimaVelocita),
                child: Text(_etichettaVelocita(velocita)),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.flip),
              tooltip: 'Specchia lo schema (destra e sinistra)',
              onPressed: inRiproduzione ? null : onSpecchia,
            ),
            const PulsanteSpiegazione(
              titolo: 'Passi',
              spiegazione: _spiegazionePassi,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.s8),
        SizedBox(
          height: altezzaMiniatura + 8,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              for (var i = 0; i < passi.length; i++)
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.s8),
                  child: _Miniatura(
                    numero: i + 1,
                    passo: passi[i],
                    campo: campo,
                    larghezza: larghezza,
                    selezionata: i == selezionato,
                    conMenu: i == selezionato && !inRiproduzione,
                    onTap: () => onSeleziona(i),
                    onAzione: (azione) => switch (azione) {
                      _AzionePasso.duplica => onDuplica?.call(i),
                      _AzionePasso.prima => onSposta(i, i - 1),
                      _AzionePasso.dopo => onSposta(i, i + 1),
                      _AzionePasso.elimina => onElimina(i),
                    },
                    azioni: [
                      if (onDuplica != null) _AzionePasso.duplica,
                      if (i > 0) _AzionePasso.prima,
                      if (i < passi.length - 1) _AzionePasso.dopo,
                      if (passi.length > 1) _AzionePasso.elimina,
                    ],
                  ),
                ),
              if (onAggiungi != null && !inRiproduzione)
                _AggiungiPasso(larghezza: larghezza, onTap: onAggiungi!),
            ],
          ),
        ),
      ],
    );
  }
}

class _Miniatura extends StatelessWidget {
  const _Miniatura({
    required this.numero,
    required this.passo,
    required this.campo,
    required this.larghezza,
    required this.selezionata,
    required this.conMenu,
    required this.onTap,
    required this.onAzione,
    required this.azioni,
  });

  final int numero;
  final PassoLavagna passo;
  final CampoLavagna campo;
  final double larghezza;
  final bool selezionata;
  final bool conMenu;
  final VoidCallback onTap;
  final ValueChanged<_AzionePasso> onAzione;
  final List<_AzionePasso> azioni;

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    return Semantics(
      button: true,
      selected: selezionata,
      label: 'Passo $numero',
      child: Container(
        width: larghezza,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selezionata ? colori.azione : colori.linea,
            width: selezionata ? 3 : 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  onTap: onTap,
                  child: CustomPaint(
                    painter: MiniaturaPassoPainter(passo: passo, campo: campo),
                  ),
                ),
              ),
              Positioned(
                left: 4,
                top: 4,
                child: IgnorePointer(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: selezionata ? colori.azione : colori.superficie,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$numero',
                      style: AppTypography.piccolo.copyWith(
                        color: selezionata ? colori.azioneInk : colori.testo,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
              if (conMenu && azioni.isNotEmpty)
                Positioned(
                  right: 0,
                  top: 0,
                  child: PopupMenuButton<_AzionePasso>(
                    tooltip: 'Azioni sul passo $numero',
                    padding: EdgeInsets.zero,
                    onSelected: onAzione,
                    icon: Container(
                      decoration: BoxDecoration(
                        color: AcquaPalette.nero.withValues(alpha: 0.45),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.more_vert,
                        size: 18,
                        color: AcquaPalette.bianco,
                      ),
                    ),
                    itemBuilder: (_) => [
                      for (final a in azioni)
                        PopupMenuItem(
                          value: a,
                          child: Text(switch (a) {
                            _AzionePasso.duplica => 'Duplica',
                            _AzionePasso.prima => 'Sposta prima',
                            _AzionePasso.dopo => 'Sposta dopo',
                            _AzionePasso.elimina => 'Elimina',
                          }),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AggiungiPasso extends StatelessWidget {
  const _AggiungiPasso({required this.larghezza, required this.onTap});

  final double larghezza;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    return Tooltip(
      message: 'Aggiungi un passo',
      child: Material(
        color: colori.superficie,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: colori.lineaForte),
        ),
        child: InkWell(
          onTap: onTap,
          customBorder: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          child: SizedBox(
            width: larghezza < 64 ? 64 : larghezza,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add, color: colori.azione),
                Text(
                  'Passo',
                  style: AppTypography.piccolo.copyWith(color: colori.testo),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
