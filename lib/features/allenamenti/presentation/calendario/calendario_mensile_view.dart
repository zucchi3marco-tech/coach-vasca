import 'package:flutter/material.dart';

import '../../../../theme/app_spacing.dart';
import '../../../../theme/app_typography.dart';
import '../../../../theme/colori_app.dart';
import '../../domain/allenamento.dart';
import 'allenamenti_per_giorno.dart';

class CalendarioMensileView extends StatefulWidget {
  const CalendarioMensileView({
    required this.allenamenti,
    required this.onGiornoSelezionato,
    super.key,
  });

  final List<Allenamento> allenamenti;
  final ValueChanged<DateTime> onGiornoSelezionato;

  @override
  State<CalendarioMensileView> createState() => _CalendarioMensileViewState();
}

class _CalendarioMensileViewState extends State<CalendarioMensileView> {
  late DateTime _mese;

  static const _nomiMesi = [
    'Gennaio',
    'Febbraio',
    'Marzo',
    'Aprile',
    'Maggio',
    'Giugno',
    'Luglio',
    'Agosto',
    'Settembre',
    'Ottobre',
    'Novembre',
    'Dicembre',
  ];
  static const _nomiGiorni = ['L', 'M', 'M', 'G', 'V', 'S', 'D'];

  @override
  void initState() {
    super.initState();
    final oggi = DateTime.now();
    _mese = DateTime(oggi.year, oggi.month);
  }

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    final perGiorno = raggruppaPerGiorno(widget.allenamenti);
    final ultimoGiornoMese = DateTime(_mese.year, _mese.month + 1, 0).day;
    final offsetIniziale = _mese.weekday - 1;
    final oggi = DateTime.now();

    final celle = <Widget>[
      for (var i = 0; i < offsetIniziale; i++) const SizedBox.shrink(),
      for (var giorno = 1; giorno <= ultimoGiornoMese; giorno++)
        _CellaGiorno(
          giorno: giorno,
          evidenziato: isStessoGiorno(
            DateTime(_mese.year, _mese.month, giorno),
            oggi,
          ),
          haAllenamenti: perGiorno.containsKey(
            DateTime(_mese.year, _mese.month, giorno),
          ),
          onTap: () => widget.onGiornoSelezionato(
            DateTime(_mese.year, _mese.month, giorno),
          ),
        ),
    ];

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s4,
            vertical: AppSpacing.s4,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: Icon(Icons.chevron_left, color: colori.testoSecondario),
                onPressed: () => setState(
                  () => _mese = DateTime(_mese.year, _mese.month - 1),
                ),
              ),
              Text(
                '${_nomiMesi[_mese.month - 1]} ${_mese.year}',
                style: AppTypography.sezione.copyWith(color: colori.testo),
              ),
              IconButton(
                icon: Icon(Icons.chevron_right, color: colori.testoSecondario),
                onPressed: () => setState(
                  () => _mese = DateTime(_mese.year, _mese.month + 1),
                ),
              ),
            ],
          ),
        ),
        Row(
          children: _nomiGiorni
              .map(
                (g) => Expanded(
                  child: Center(
                    child: Text(
                      g,
                      style: AppTypography.etichetta.copyWith(
                        color: colori.testoSecondario,
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        GridView.count(
          crossAxisCount: 7,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: celle,
        ),
      ],
    );
  }
}

class _CellaGiorno extends StatelessWidget {
  const _CellaGiorno({
    required this.giorno,
    required this.evidenziato,
    required this.haAllenamenti,
    required this.onTap,
  });

  final int giorno;
  final bool evidenziato;
  final bool haAllenamenti;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.controllo),
      child: Container(
        margin: const EdgeInsets.all(AppSpacing.s4),
        decoration: BoxDecoration(
          border: evidenziato ? Border.all(color: colori.azione) : null,
          borderRadius: BorderRadius.circular(AppRadius.controllo),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$giorno',
              style: AppTypography.corpo.copyWith(color: colori.testo),
            ),
            const SizedBox(height: 2),
            SizedBox(
              height: 6,
              width: 6,
              child: haAllenamenti
                  ? DecoratedBox(
                      decoration: BoxDecoration(
                        color: colori.azione,
                        shape: BoxShape.circle,
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
