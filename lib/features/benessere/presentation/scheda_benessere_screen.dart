import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/error_messages.dart';
import '../../../theme/app_typography.dart';
import '../../../theme/colori_app.dart';
import '../../../theme/tokens_dominio.dart';
import '../../atleti/domain/atleta.dart';
import '../../home/atleta/grafica_pallanuoto.dart';
import '../application/benessere_providers.dart';
import '../data/schede_benessere_repository.dart';
import '../domain/scheda_benessere.dart';
import 'punteggio_widgets.dart';

/// L'impegno a cui si riferisce la scheda (prossimo allenamento o
/// partita), per dirlo all'atleta e salvarlo con la scheda.
typedef ImpegnoBenessere = ({String tipo, String id, String descrizione});

/// Scheda benessere da compilare prima di allenamento o partita, pensata
/// per il pollice (circa 30 secondi): ore e qualita' del sonno, le altre
/// quattro voci del questionario McLean (energia, muscoli, stress,
/// umore), dolori con zona e intensita', sintomi di malattia. In fondo
/// l'anteprima della Prontezza. Riapre la scheda di oggi se c'e' gia'.
class SchedaBenessereScreen extends ConsumerStatefulWidget {
  const SchedaBenessereScreen({required this.atleta, this.impegno, super.key});

  final Atleta atleta;
  final ImpegnoBenessere? impegno;

  @override
  ConsumerState<SchedaBenessereScreen> createState() =>
      _SchedaBenessereScreenState();
}

class _SchedaBenessereScreenState extends ConsumerState<SchedaBenessereScreen> {
  bool? _dolori;
  final Set<String> _zone = {};
  double _intensita = 4;
  double _sonno = 8;
  bool _sonnoToccato = false;
  bool _salvataggio = false;
  bool _inizializzata = false;

  /// Voci McLean 1-5, per chiave (vedi [vociQuestionario]).
  final Map<String, int> _voci = {};

  /// null = non ancora risposto; vuoto = "nessun sintomo".
  Set<String>? _sintomi;

  void _precompila(SchedaBenessere? s) {
    if (_inizializzata || s == null) return;
    _inizializzata = true;
    _dolori = s.dolori;
    _zone
      ..clear()
      ..addAll(s.zoneDolore);
    _intensita = (s.intensitaDolore ?? 4).toDouble();
    _sonno = s.oreSonno;
    _sonnoToccato = true;
    for (final (chiave, v) in [
      ('qualitaSonno', s.qualitaSonno),
      ('energia', s.energia),
      ('muscoli', s.muscoli),
      ('stress', s.stress),
      ('umore', s.umore),
    ]) {
      if (v != null) _voci[chiave] = v;
    }
    if (s.qualitaSonno != null) _sintomi = s.sintomi.toSet();
  }

  /// Quante delle 8 risposte sono date (per la barra in alto).
  int get _risposte =>
      (_sonnoToccato ? 1 : 0) +
      _voci.length +
      (_dolori != null && (_dolori == false || _zone.isNotEmpty) ? 1 : 0) +
      (_sintomi != null ? 1 : 0);

  static const _totaleRisposte = 8;

  bool get _completa => _risposte == _totaleRisposte;

  /// La scheda come sarebbe inviata ora, per l'anteprima del punteggio.
  SchedaBenessere get _bozza => SchedaBenessere(
    id: '',
    atletaId: widget.atleta.id,
    clubId: widget.atleta.clubId,
    data: DateTime.now(),
    dolori: _dolori ?? false,
    zoneDolore: _zone.toList(),
    intensitaDolore: _dolori == true ? _intensita.round() : null,
    oreSonno: _sonno,
    compilataIl: DateTime.now(),
    qualitaSonno: _voci['qualitaSonno'],
    energia: _voci['energia'],
    muscoli: _voci['muscoli'],
    stress: _voci['stress'],
    umore: _voci['umore'],
    sintomi: (_sintomi ?? {}).toList(),
  );

  Future<void> _invia() async {
    setState(() => _salvataggio = true);
    try {
      await ref
          .read(schedeBenessereRepositoryProvider)
          .salva(
            atletaId: widget.atleta.id,
            clubId: widget.atleta.clubId,
            data: DateTime.now(),
            dolori: _dolori!,
            zoneDolore: _zone.toList(),
            intensitaDolore: _dolori! ? _intensita.round() : null,
            oreSonno: _sonno,
            qualitaSonno: _voci['qualitaSonno'],
            energia: _voci['energia'],
            muscoli: _voci['muscoli'],
            stress: _voci['stress'],
            umore: _voci['umore'],
            sintomi: (_sintomi ?? {}).toList(),
            eventoTipo: widget.impegno?.tipo,
            eventoId: widget.impegno?.id,
          );
      HapticFeedback.mediumImpact();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Scheda inviata al tuo allenatore. Buon lavoro!'),
        ),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _salvataggio = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invio non riuscito: ${messaggioErrore(e)}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    _precompila(ref.watch(schedaBenessereOggiProvider(widget.atleta.id)));
    final colori = context.colori;
    final dominio = context.dominio;

    return Scaffold(
      appBar: AppBar(title: const Text('Scheda benessere')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
              children: [
                _Testata(impegno: widget.impegno),
                const SizedBox(height: 12),
                _Avanzamento(fatte: _risposte, totale: _totaleRisposte),
                const SizedBox(height: 16),
                _Domanda(
                  numero: 1,
                  titolo: 'Quanto hai dormito stanotte?',
                  aiuto: 'Trascina o scegli una delle ore qui sotto.',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _Sonno(
                        ore: _sonno,
                        toccato: _sonnoToccato,
                        accento: dominio.evidenzaViola,
                        onCambia: (v) => setState(() {
                          _sonno = v;
                          _sonnoToccato = true;
                        }),
                      ),
                      const SizedBox(height: 20),
                      _Scala5(
                        domanda: vociQuestionario[0].domanda,
                        etichette: vociQuestionario[0].etichette,
                        valore: _voci['qualitaSonno'],
                        onScegli: (v) =>
                            setState(() => _voci['qualitaSonno'] = v),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _Domanda(
                  numero: 2,
                  titolo: 'Come ti senti?',
                  aiuto: 'Un tocco per riga: non c\'è una risposta giusta.',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final (k, voce)
                          in vociQuestionario.skip(1).indexed) ...[
                        if (k > 0) const SizedBox(height: 18),
                        _Scala5(
                          domanda: voce.domanda,
                          etichette: voce.etichette,
                          valore: _voci[voce.chiave],
                          onScegli: (v) =>
                              setState(() => _voci[voce.chiave] = v),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _Domanda(
                  numero: 3,
                  titolo: 'Hai dolori?',
                  aiuto: 'Anche un fastidio piccolo: meglio dirlo prima.',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _Risposta(
                              testo: 'No, sto bene',
                              icona: Icons.sentiment_satisfied_alt,
                              colore: colori.ok,
                              scelta: _dolori == false,
                              onTap: () => setState(() => _dolori = false),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _Risposta(
                              testo: 'Sì, ho dolore',
                              icona: Icons.healing_outlined,
                              colore: colori.attenzione,
                              scelta: _dolori == true,
                              onTap: () => setState(() => _dolori = true),
                            ),
                          ),
                        ],
                      ),
                      AnimatedSize(
                        duration: const Duration(milliseconds: 260),
                        curve: Curves.easeOutCubic,
                        alignment: Alignment.topCenter,
                        child: _dolori == true
                            ? _DettaglioDolore(
                                zone: _zone,
                                intensita: _intensita,
                                onZona: (z) => setState(
                                  () => _zone.contains(z)
                                      ? _zone.remove(z)
                                      : _zone.add(z),
                                ),
                                onIntensita: (v) =>
                                    setState(() => _intensita = v),
                              )
                            : const SizedBox(width: double.infinity),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _Domanda(
                  numero: 4,
                  titolo: 'Ti senti male?',
                  aiuto: 'Febbre o altri sintomi: l\'allenatore deve saperlo.',
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('No, niente'),
                        avatar: const Icon(Icons.check, size: 18),
                        showCheckmark: false,
                        selected: _sintomi != null && _sintomi!.isEmpty,
                        onSelected: (_) {
                          HapticFeedback.selectionClick();
                          setState(() => _sintomi = {});
                        },
                      ),
                      for (final (chiave, nome) in sintomiMalattia)
                        FilterChip(
                          label: Text(nome),
                          selected: _sintomi?.contains(chiave) ?? false,
                          onSelected: (_) {
                            HapticFeedback.selectionClick();
                            setState(() {
                              final s = {...?_sintomi};
                              s.contains(chiave)
                                  ? s.remove(chiave)
                                  : s.add(chiave);
                              _sintomi = s;
                            });
                          },
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Prima di rispondere non c'e' nulla da stimare: un "80 —
                // Pronto" a scheda vuota sembrava gia' un risultato.
                if (_risposte == 0)
                  const _AnteprimaVuota()
                else
                  _AnteprimaPunteggio(
                    punteggio: calcolaPunteggio(
                      _bozza,
                      dataNascita: widget.atleta.dataNascita,
                    ),
                    completa: _completa,
                  ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Center(
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: FilledButton.icon(
                onPressed: _completa && !_salvataggio ? _invia : null,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: _salvataggio
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send_rounded),
                label: Text(
                  _completa
                      ? 'Invia all\'allenatore'
                      : _dolori == true && _zone.isEmpty
                      ? 'Indica dove hai dolore'
                      : 'Mancano ${_totaleRisposte - _risposte} risposte',
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Testata extends StatelessWidget {
  const _Testata({this.impegno});

  final ImpegnoBenessere? impegno;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: SizedBox(
        height: 150,
        child: Stack(
          children: [
            const Positioned.fill(
              child: AcquaAnimata(conPorta: false, conCorsia: false),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AcquaPalette.profonda.withValues(alpha: 0.85),
                      AcquaPalette.profonda.withValues(alpha: 0.2),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Come stai oggi?',
                    style: AppTypography.titoloXl.copyWith(
                      color: AcquaPalette.bianco,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    impegno == null
                        ? 'Due domande, meno di un minuto.'
                        : 'Prima ${impegno!.descrizione}',
                    style: AppTypography.corpo.copyWith(
                      color: AcquaPalette.schiuma.withValues(alpha: 0.85),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.lock_outline,
                        size: 14,
                        color: AcquaPalette.schiuma.withValues(alpha: 0.7),
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          'La vede solo il tuo allenatore',
                          style: AppTypography.etichetta.copyWith(
                            color: AcquaPalette.schiuma.withValues(alpha: 0.7),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Domanda extends StatelessWidget {
  const _Domanda({
    required this.numero,
    required this.titolo,
    required this.aiuto,
    required this.child,
  });

  final int numero;
  final String titolo;
  final String aiuto;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colori.superficie,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colori.linea),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: colori.azioneTenue,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$numero',
                  style: AppTypography.etichetta.copyWith(
                    color: colori.azione,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titolo,
                      style: AppTypography.titolo.copyWith(
                        color: colori.testo,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      aiuto,
                      style: AppTypography.piccolo.copyWith(
                        color: colori.testoSecondario,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _Risposta extends StatelessWidget {
  const _Risposta({
    required this.testo,
    required this.icona,
    required this.colore,
    required this.scelta,
    required this.onTap,
  });

  final String testo;
  final IconData icona;
  final Color colore;
  final bool scelta;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    return Semantics(
      button: true,
      selected: scelta,
      label: testo,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
          decoration: BoxDecoration(
            color: scelta
                ? colore.withValues(alpha: 0.16)
                : colori.superficieAlt,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: scelta ? colore : colori.linea,
              width: scelta ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              AnimatedScale(
                scale: scelta ? 1.15 : 1,
                duration: const Duration(milliseconds: 180),
                child: Icon(
                  icona,
                  size: 32,
                  color: scelta ? colore : colori.testoSecondario,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                testo,
                textAlign: TextAlign.center,
                style: AppTypography.corpoForte.copyWith(
                  color: scelta ? colore : colori.testo,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DettaglioDolore extends StatelessWidget {
  const _DettaglioDolore({
    required this.zone,
    required this.intensita,
    required this.onZona,
    required this.onIntensita,
  });

  final Set<String> zone;
  final double intensita;
  final ValueChanged<String> onZona;
  final ValueChanged<double> onIntensita;

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    final valore = intensita.round();
    final (etichetta, colore) = switch (valore) {
      <= 3 => ('Lieve', colori.ok),
      <= 6 => ('Moderato', colori.attenzione),
      _ => ('Forte', colori.rosso),
    };
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Dove?',
            style: AppTypography.corpoForte.copyWith(color: colori.testo),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final (chiave, nome) in zoneCorpo)
                FilterChip(
                  label: Text(nome),
                  selected: zone.contains(chiave),
                  onSelected: (_) {
                    HapticFeedback.selectionClick();
                    onZona(chiave);
                  },
                ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Quanto forte?',
                  style: AppTypography.corpoForte.copyWith(color: colori.testo),
                ),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 160),
                child: Text(
                  '$valore/10 · $etichetta',
                  key: ValueKey(valore),
                  style: AppTypography.corpoForte.copyWith(color: colore),
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: colore,
              thumbColor: colore,
              overlayColor: colore.withValues(alpha: 0.15),
              trackHeight: 8,
            ),
            child: Slider(
              value: intensita,
              min: 1,
              max: 10,
              divisions: 9,
              label: '$valore',
              onChanged: (v) {
                if (v.round() != intensita.round()) {
                  HapticFeedback.selectionClick();
                }
                onIntensita(v);
              },
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '1 · appena',
                style: AppTypography.etichetta.copyWith(
                  color: colori.testoSecondario,
                ),
              ),
              Text(
                '10 · fortissimo',
                style: AppTypography.etichetta.copyWith(
                  color: colori.testoSecondario,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Sonno extends StatelessWidget {
  const _Sonno({
    required this.ore,
    required this.toccato,
    required this.accento,
    required this.onCambia,
  });

  final double ore;
  final bool toccato;
  final Color accento;
  final ValueChanged<double> onCambia;

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    final commento = !toccato
        ? 'Scegli le ore di sonno'
        : ore < 6
        ? 'Poche: il tuo allenatore ne terrà conto'
        : ore < 7
        ? 'Un po\' meno del solito'
        : ore <= 10
        ? 'Ottimo riposo'
        : 'Tanto riposo';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Icon(Icons.bedtime_outlined, color: accento, size: 32),
            const SizedBox(width: 10),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 140),
              child: Text(
                toccato ? formattaOre(ore) : '— h',
                key: ValueKey(toccato ? ore : -1),
                style: AppTypography.numerica(
                  AppTypography.numeroGrande.copyWith(
                    color: colori.testo,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  commento,
                  style: AppTypography.piccolo.copyWith(
                    color: colori.testoSecondario,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SliderTheme(
          // Binario vuoto visibile: senza, la barra sembrava gia' piena
          // fino in fondo. Finche' non si sceglie, tutto e' sbiadito.
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: accento.withValues(alpha: toccato ? 1 : 0.35),
            inactiveTrackColor: accento.withValues(alpha: 0.14),
            thumbColor: accento.withValues(alpha: toccato ? 1 : 0.5),
            overlayColor: accento.withValues(alpha: 0.15),
            trackHeight: 8,
          ),
          child: Slider(
            value: ore,
            min: 0,
            max: 12,
            divisions: 24,
            label: formattaOre(ore),
            onChanged: (v) {
              if (v != ore) HapticFeedback.selectionClick();
              onCambia(v);
            },
          ),
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final o in const [5.0, 6.0, 7.0, 8.0, 9.0, 10.0])
              ChoiceChip(
                label: Text(o == 10 ? '10+ h' : formattaOre(o)),
                selected: toccato && ore == o,
                onSelected: (_) {
                  HapticFeedback.selectionClick();
                  onCambia(o);
                },
              ),
          ],
        ),
      ],
    );
  }
}

/// Barra in alto: quante risposte mancano.
class _Avanzamento extends StatelessWidget {
  const _Avanzamento({required this.fatte, required this.totale});

  final int fatte;
  final int totale;

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    final completa = fatte == totale;
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: TweenAnimationBuilder<double>(
              tween: Tween(end: fatte / totale),
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              builder: (context, t, _) => LinearProgressIndicator(
                value: t,
                minHeight: 8,
                backgroundColor: colori.linea,
                color: completa ? colori.ok : colori.azione,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          completa ? 'Pronta da inviare' : '$fatte di $totale',
          style: AppTypography.etichetta.copyWith(
            color: completa ? colori.ok : colori.testoSecondario,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

/// Cinque faccine dal rosso al verde: la domanda sopra, la parola scelta
/// sotto. Toccabili con il pollice anche a bordo vasca.
class _Scala5 extends StatelessWidget {
  const _Scala5({
    required this.domanda,
    required this.etichette,
    required this.valore,
    required this.onScegli,
  });

  final String domanda;
  final List<String> etichette;
  final int? valore;
  final ValueChanged<int> onScegli;

  static const _facce = [
    Icons.sentiment_very_dissatisfied,
    Icons.sentiment_dissatisfied,
    Icons.sentiment_neutral,
    Icons.sentiment_satisfied,
    Icons.sentiment_very_satisfied,
  ];

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    final scala = [
      colori.rosso,
      Color.lerp(colori.rosso, colori.attenzione, 0.6)!,
      colori.attenzione,
      Color.lerp(colori.attenzione, colori.ok, 0.6)!,
      colori.ok,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                domanda,
                style: AppTypography.corpoForte.copyWith(color: colori.testo),
              ),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 160),
              child: Text(
                valore == null ? '' : etichette[valore! - 1],
                key: ValueKey(valore),
                style: AppTypography.corpoForte.copyWith(
                  color: valore == null ? colori.testo : scala[valore! - 1],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            for (var i = 0; i < 5; i++) ...[
              if (i > 0) const SizedBox(width: 6),
              Expanded(
                child: Semantics(
                  button: true,
                  selected: valore == i + 1,
                  label: '$domanda ${etichette[i]}',
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      onScegli(i + 1);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      curve: Curves.easeOutCubic,
                      height: 52,
                      decoration: BoxDecoration(
                        color: valore == i + 1
                            ? scala[i].withValues(alpha: 0.18)
                            : colori.superficieAlt,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: valore == i + 1 ? scala[i] : colori.linea,
                          width: valore == i + 1 ? 2 : 1,
                        ),
                      ),
                      child: AnimatedScale(
                        scale: valore == i + 1 ? 1.15 : 1,
                        duration: const Duration(milliseconds: 160),
                        child: Icon(
                          _facce[i],
                          size: 28,
                          color: valore == i + 1
                              ? scala[i]
                              : colori.testoSecondario,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _AnteprimaVuota extends StatelessWidget {
  const _AnteprimaVuota();

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colori.superficie,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colori.linea),
      ),
      child: Row(
        children: [
          Icon(Icons.insights_outlined, color: colori.testoSecondario),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'La tua prontezza compare qui mentre rispondi.',
              style: AppTypography.piccolo.copyWith(
                color: colori.testoSecondario,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// La Prontezza che si aggiorna mentre si risponde.
class _AnteprimaPunteggio extends StatelessWidget {
  const _AnteprimaPunteggio({required this.punteggio, required this.completa});

  final PunteggioBenessere punteggio;
  final bool completa;

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 250),
      opacity: completa ? 1 : 0.55,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colori.superficie,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colori.linea),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                AnelloPunteggio(
                  valore: punteggio.valore,
                  livello: punteggio.livello,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        completa ? 'La tua prontezza' : 'Anteprima prontezza',
                        style: AppTypography.etichetta.copyWith(
                          color: colori.testoSecondario,
                        ),
                      ),
                      Text(
                        punteggio.etichetta,
                        style: AppTypography.titolo.copyWith(
                          color: coloreLivello(context, punteggio.livello),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Come si calcola',
                  onPressed: () => mostraSpiegazionePunteggio(context),
                  icon: const Icon(Icons.info_outline),
                ),
              ],
            ),
            const SizedBox(height: 12),
            MotiviPunteggio(punteggio: punteggio),
          ],
        ),
      ),
    );
  }
}
