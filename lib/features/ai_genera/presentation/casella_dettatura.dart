import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/dettatura/dettatura_vocale.dart';
import '../../../core/dettatura/testo_con_prefisso.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../theme/colori_app.dart';
import '../../../widgets/app_text_field.dart';

/// Casella di testo con il microfono: si scrive a mano o si detta a voce
/// (Web Speech API del browser, gratuita ma solo Chrome/Edge — altrove
/// resta scrivibile, il microfono è un di più). Chi la usa tiene il
/// [controller] e, prima di inviare il testo, chiama [CasellaDettaturaState.ferma]
/// (con una `GlobalKey<CasellaDettaturaState>`).
class CasellaDettatura extends StatefulWidget {
  const CasellaDettatura({
    required this.controller,
    required this.etichetta,
    this.aiuto,
    this.maxLines = 4,
    super.key,
  });

  final TextEditingController controller;
  final String etichetta;
  final String? aiuto;
  final int maxLines;

  @override
  State<CasellaDettatura> createState() => CasellaDettaturaState();
}

class CasellaDettaturaState extends State<CasellaDettatura> {
  DettatoreVocale? _dettatore;
  bool _inAscolto = false;
  String? _erroreMicrofono;

  /// Diagnostica TEMPORANEA per il difetto della dettatura ripetuta — da
  /// togliere (il campo e il pannello sotto) una volta risolto per
  /// sempre, vedi `dettatura_vocale_web.dart`.
  final List<String> _logGrezzo = [];

  /// Cosa c'era già scritto prima di premere il microfono: un prefisso
  /// fisso su cui si affianca il testo della sessione corrente, che
  /// `DettatoreVocale` ricostruisce sempre per intero ad ogni
  /// aggiornamento (mai da sommare qui) — vedi `dettatura_vocale_web.dart`.
  String _prefisso = '';

  @override
  void dispose() {
    _dettatore?.dispose();
    super.dispose();
  }

  void ferma() => _dettatore?.ferma();

  void _alternaAscolto() {
    if (_inAscolto) {
      _dettatore?.ferma();
      return;
    }
    setState(() {
      _erroreMicrofono = null;
      _logGrezzo.clear();
    });
    _prefisso = widget.controller.text.trim();
    _dettatore = DettatoreVocale(
      onTrascrizione: (testoSessione) {
        if (!mounted) return;
        final testo = testoConPrefisso(_prefisso, testoSessione);
        widget.controller
          ..text = testo
          ..selection = TextSelection.collapsed(offset: testo.length);
      },
      onErrore: (messaggio) {
        if (!mounted) return;
        setState(() => _erroreMicrofono = messaggio);
      },
      onFine: () {
        if (!mounted) return;
        setState(() => _inAscolto = false);
      },
      onEventoGrezzo: (riga) {
        if (!mounted) return;
        setState(() {
          _logGrezzo.add(riga);
          if (_logGrezzo.length > 200) _logGrezzo.removeAt(0);
        });
      },
    );
    setState(() => _inAscolto = true);
    _dettatore!.avvia();
  }

  void _copiaLog() {
    Clipboard.setData(ClipboardData(text: _logGrezzo.join('\n')));
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Log copiato')));
  }

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    final microfono = DettatoreVocale.disponibile;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppTextField(
          etichetta: widget.etichetta,
          controller: widget.controller,
          maxLines: widget.maxLines,
          aiuto: microfono
              ? widget.aiuto
              : '${widget.aiuto ?? ''} Il microfono non è disponibile su '
                    'questo browser (funziona su Chrome): scrivi il testo.',
        ),
        if (microfono) ...[
          const SizedBox(height: AppSpacing.s12),
          Center(
            child: IconButton.filled(
              iconSize: 32,
              padding: const EdgeInsets.all(AppSpacing.s12),
              style: IconButton.styleFrom(
                backgroundColor: _inAscolto ? colori.rosso : colori.azione,
              ),
              icon: Icon(
                _inAscolto ? Icons.stop : Icons.mic,
                color: colori.azioneInk,
              ),
              tooltip: _inAscolto ? 'Ferma la dettatura' : 'Detta a voce',
              onPressed: _alternaAscolto,
            ),
          ),
          if (_inAscolto)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.s8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.circle, size: 10, color: colori.rosso),
                  const SizedBox(width: AppSpacing.s8),
                  Text(
                    'Sto ascoltando...',
                    style: AppTypography.piccolo.copyWith(
                      color: colori.testoSecondario,
                    ),
                  ),
                ],
              ),
            ),
          if (_erroreMicrofono != null)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.s8),
              child: Text(
                _erroreMicrofono!,
                textAlign: TextAlign.center,
                style: AppTypography.piccolo.copyWith(color: colori.rosso),
              ),
            ),
          if (_logGrezzo.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.s12),
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.s8),
                decoration: BoxDecoration(
                  color: colori.superficieAlt,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: colori.linea),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Log tecnico (temporaneo, per capire il '
                            'problema della dettatura)',
                            style: AppTypography.piccolo.copyWith(
                              color: colori.testoSecondario,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy, size: 18),
                          tooltip: 'Copia il log',
                          onPressed: _copiaLog,
                        ),
                      ],
                    ),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 160),
                      child: SingleChildScrollView(
                        child: SelectableText(
                          _logGrezzo.join('\n'),
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ],
    );
  }
}
