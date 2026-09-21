import 'package:flutter/material.dart';

import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../theme/colori_app.dart';
import '../../../theme/tokens_dominio.dart';
import '../domain/evento_calendario.dart';

const _nomiMesi = [
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
const _nomiGiorni = ['L', 'M', 'M', 'G', 'V', 'S', 'D'];

/// Il mese iniziale del calendario: quello corrente, portato dentro
/// l'intervallo [primoGiorno, ultimoGiorno] della stagione.
DateTime meseIniziale(
  DateTime oggi,
  DateTime primoGiorno,
  DateTime ultimoGiorno,
) {
  final mese = DateTime(oggi.year, oggi.month);
  final primo = DateTime(primoGiorno.year, primoGiorno.month);
  final ultimo = DateTime(ultimoGiorno.year, ultimoGiorno.month);
  if (mese.isBefore(primo)) return primo;
  if (mese.isAfter(ultimo)) return ultimo;
  return mese;
}

/// Calendario mensile di una stagione: sfogliabile dal mese del primo
/// giorno a quello dell'ultimo, con un riquadro pieno e ben visibile sui
/// giorni con almeno un evento (partita o gara). Colore: azione = evento
/// di un gruppo, ambra = evento di tutto il club (senza gruppo); un
/// giorno con entrambi è azione con un punto ambra. I giorni fuori
/// stagione sono spenti e non si toccano.
///
/// Il tocco su un giorno della stagione passa a [onGiornoSelezionato] il
/// giorno e i suoi eventi (lista vuota = giorno libero).
class CalendarioStagioneView extends StatefulWidget {
  const CalendarioStagioneView({
    required this.primoGiorno,
    required this.ultimoGiorno,
    required this.eventi,
    required this.onGiornoSelezionato,
    super.key,
  });

  final DateTime primoGiorno;
  final DateTime ultimoGiorno;
  final List<EventoCalendario> eventi;
  final void Function(DateTime giorno, List<EventoCalendario> eventiDelGiorno)
  onGiornoSelezionato;

  @override
  State<CalendarioStagioneView> createState() => _CalendarioStagioneViewState();
}

class _CalendarioStagioneViewState extends State<CalendarioStagioneView> {
  late DateTime _mese;

  DateTime get _primoMese =>
      DateTime(widget.primoGiorno.year, widget.primoGiorno.month);
  DateTime get _ultimoMese =>
      DateTime(widget.ultimoGiorno.year, widget.ultimoGiorno.month);

  @override
  void initState() {
    super.initState();
    _mese = meseIniziale(
      DateTime.now(),
      widget.primoGiorno,
      widget.ultimoGiorno,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    final perGiorno = raggruppaEventiPerGiorno(widget.eventi);
    final primo = soloGiorno(widget.primoGiorno);
    final ultimo = soloGiorno(widget.ultimoGiorno);
    final oggi = soloGiorno(DateTime.now());
    final ultimoGiornoMese = DateTime(_mese.year, _mese.month + 1, 0).day;
    final offsetIniziale = _mese.weekday - 1;
    final puoIndietro = _mese.isAfter(_primoMese);
    final puoAvanti = _mese.isBefore(_ultimoMese);

    final celle = <Widget>[
      for (var i = 0; i < offsetIniziale; i++) const SizedBox.shrink(),
      for (var giorno = 1; giorno <= ultimoGiornoMese; giorno++)
        Builder(
          builder: (context) {
            final data = DateTime(_mese.year, _mese.month, giorno);
            final dentro = !data.isBefore(primo) && !data.isAfter(ultimo);
            final eventiDelGiorno = perGiorno[data] ?? const [];
            return _CellaGiorno(
              giorno: giorno,
              oggi: data == oggi,
              attivo: dentro,
              eventiGruppo: eventiDelGiorno.where((e) => !e.diClub).length,
              eventiClub: eventiDelGiorno.where((e) => e.diClub).length,
              onTap: () => widget.onGiornoSelezionato(data, eventiDelGiorno),
            );
          },
        ),
    ];

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: Icon(
                Icons.chevron_left,
                color: puoIndietro ? colori.testo : colori.linea,
              ),
              onPressed: puoIndietro
                  ? () => setState(
                      () => _mese = DateTime(_mese.year, _mese.month - 1),
                    )
                  : null,
            ),
            Text(
              '${_nomiMesi[_mese.month - 1]} ${_mese.year}',
              style: AppTypography.sezione.copyWith(color: colori.testo),
            ),
            IconButton(
              icon: Icon(
                Icons.chevron_right,
                color: puoAvanti ? colori.testo : colori.linea,
              ),
              onPressed: puoAvanti
                  ? () => setState(
                      () => _mese = DateTime(_mese.year, _mese.month + 1),
                    )
                  : null,
            ),
          ],
        ),
        Row(
          children: [
            for (final g in _nomiGiorni)
              Expanded(
                child: Center(
                  child: Text(
                    g,
                    style: AppTypography.etichetta.copyWith(
                      color: colori.testoSecondario,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.s4),
        GridView.count(
          crossAxisCount: 7,
          childAspectRatio: 1.15,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: celle,
        ),
        const SizedBox(height: AppSpacing.s8),
        const _Legenda(),
      ],
    );
  }
}

class _CellaGiorno extends StatelessWidget {
  const _CellaGiorno({
    required this.giorno,
    required this.oggi,
    required this.attivo,
    required this.eventiGruppo,
    required this.eventiClub,
    required this.onTap,
  });

  final int giorno;
  final bool oggi;
  final bool attivo;
  final int eventiGruppo;
  final int eventiClub;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    final ambra = context.dominio.evidenzaAmbra;
    final haGruppo = eventiGruppo > 0;
    final haClub = eventiClub > 0;
    final Color? sfondo = !attivo
        ? null
        : haGruppo
        ? colori.azione
        : haClub
        ? ambra
        : null;
    final coloreNumero = !attivo
        ? colori.linea
        : sfondo != null
        ? colori.azioneInk
        : colori.testo;
    final totale = eventiGruppo + eventiClub;

    return Semantics(
      button: attivo,
      label:
          'Giorno $giorno${totale > 0 ? ', $totale eventi' : ''}'
          '${attivo ? '' : ', fuori stagione'}',
      child: InkWell(
        onTap: attivo ? onTap : null,
        borderRadius: BorderRadius.circular(AppRadius.controllo),
        child: Container(
          margin: const EdgeInsets.all(AppSpacing.s4 / 2),
          decoration: BoxDecoration(
            color: sfondo,
            border: oggi ? Border.all(color: colori.testo, width: 2) : null,
            borderRadius: BorderRadius.circular(AppRadius.controllo),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Text(
                '$giorno',
                style: AppTypography.corpo.copyWith(
                  color: coloreNumero,
                  fontWeight: sfondo != null ? FontWeight.w700 : null,
                ),
              ),
              if (attivo && haGruppo && haClub)
                Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: ambra,
                      shape: BoxShape.circle,
                      border: Border.all(color: colori.azioneInk, width: 1),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Legenda extends StatelessWidget {
  const _Legenda();

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    Widget voce(Color colore, String testo) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: colore,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: AppSpacing.s8),
        Text(
          testo,
          style: AppTypography.piccolo.copyWith(color: colori.testoSecondario),
        ),
      ],
    );

    return Wrap(
      spacing: AppSpacing.s16,
      runSpacing: AppSpacing.s4,
      children: [
        voce(colori.azione, 'Evento del gruppo'),
        voce(context.dominio.evidenzaAmbra, 'Evento di tutto il club'),
      ],
    );
  }
}
