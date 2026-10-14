import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/date_italiane.dart';
import '../../../core/utils/error_messages.dart';
import '../../../theme/app_layout.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../theme/colori_app.dart';
import '../../../theme/tema_provider.dart';
import '../../../widgets/app_list_panel.dart';
import '../../../widgets/app_list_row.dart';
import '../../../widgets/bottone_tema_bordo_vasca.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/loading_skeleton.dart';
import '../../../widgets/nascondi_barra_club.dart';
import '../../../widgets/schermo_acceso.dart';
import '../../atleti/application/atleti_providers.dart';
import '../../atleti/domain/atleta.dart';
import '../../gruppi/application/selezione_gruppo_provider.dart';
import '../application/test_club_providers.dart';
import '../data/test_club_repository.dart';
import '../domain/massimale.dart';
import '../domain/tastierino_test.dart';
import '../domain/test_club.dart';

/// I risultati di un test a raffica, a bordo vasca (fase 2 del "Mako
/// della pallanuoto", proposta 3): un atleta dopo l'altro, una prova
/// dopo l'altra, con un tastierino grande. Per un tempo si scrivono solo
/// le cifre, come al cronometro ("862" è 8,62). Finite le prove di un
/// atleta il risultato si salva (anche senza rete: parte appena torna) e
/// si passa al prossimo. Il tasto ⌫ a campo vuoto riapre l'ultima prova
/// per correggerla. Gli atleti sono quelli della squadra scelta in alto.
///
/// Per un massimale i due campi sono i chili sollevati e le ripetizioni
/// (fino a [ripetizioniMassimeStima]): si salva il massimale stimato.
class InserisciRisultatiScreen extends ConsumerStatefulWidget {
  const InserisciRisultatiScreen({required this.test, super.key});

  final TestClub test;

  @override
  ConsumerState<InserisciRisultatiScreen> createState() =>
      _InserisciRisultatiScreenState();
}

class _InserisciRisultatiScreenState
    extends ConsumerState<InserisciRisultatiScreen> {
  DateTime _data = DateTime.now();

  /// L'ordine degli atleti, fissato al primo caricamento: non deve
  /// cambiare sotto le dita mentre si scrive.
  List<Atleta>? _atleti;
  int _indice = 0;
  bool _finito = false;

  /// Le prove dell'atleta in corso, non ancora salvate.
  final _prove = <double>[];
  String _testo = '';

  /// I risultati già salvati in questa sessione (id atleta → valori).
  final _salvati = <String, List<double>>{};
  bool _salvataggio = false;

  final _focus = FocusNode();

  TestClub get _test => widget.test;

  /// L'unità del campo che si sta scrivendo: per un massimale prima i
  /// chili, poi le ripetizioni.
  UnitaTest get _unita => unitaDelCampo(_test, _prove.length);

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  bool _stessoGiorno(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// I risultati già nel database per il giorno scelto.
  Map<String, List<double>> _giaFatti(List<RisultatoTest> risultati) => {
    for (final r in risultati)
      if (r.testId == _test.id && _stessoGiorno(r.data, _data))
        r.atletaId: r.valori,
  };

  void _prepara(List<Atleta> atleti, List<RisultatoTest> risultati) {
    if (_atleti != null) return;
    _atleti = atleti;
    final fatti = _giaFatti(risultati);
    // Si parte dal primo che oggi non l'ha ancora fatto.
    final primo = atleti.indexWhere((a) => !fatti.containsKey(a.id));
    _indice = primo == -1 ? 0 : primo;
  }

  void _tasto(String t) {
    if (_salvataggio || _finito) return;
    if (t == '⌫' && _testo.isEmpty && _prove.isNotEmpty) {
      // Riapre l'ultima prova per correggerla.
      setState(() {
        final ultima = _prove.removeLast();
        _testo = testoDaValore(_unita, ultima);
      });
      return;
    }
    setState(() => _testo = conTasto(_unita, _testo, t));
  }

  Future<void> _registra() async {
    final valore = valoreDelCampo(_test, _prove.length, _testo);
    if (valore == null || _salvataggio) return;
    setState(() {
      _prove.add(valore);
      _testo = '';
    });
    if (_prove.length >= campiPerAtleta(_test)) await _chiudiAtleta();
  }

  /// Salva le prove dell'atleta (se ce ne sono) e passa al prossimo. Di
  /// un massimale si salva solo se ci sono chili e ripetizioni.
  Future<void> _chiudiAtleta() async {
    final atleti = _atleti!;
    final atleta = atleti[_indice];
    final massimale = _test.massimale;
    if (massimale && _prove.length < 2) _prove.clear();
    if (_prove.isNotEmpty) {
      final valori = massimale
          ? [stimaMassimale(_prove[0], _prove[1].round())]
          : List.of(_prove);
      setState(() => _salvataggio = true);
      try {
        await ref
            .read(testClubRepositoryProvider)
            .salvaRisultato(
              testId: _test.id,
              atletaId: atleta.id,
              clubId: _test.clubId,
              data: _data,
              valori: valori,
              caricoKg: massimale ? _prove[0] : null,
              ripetizioni: massimale ? _prove[1].round() : null,
            );
        _salvati[atleta.id] = valori;
      } catch (e) {
        if (mounted) {
          setState(() => _salvataggio = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Risultato di ${atleta.nomeCompleto} non salvato: '
                '${messaggioErrore(e)}',
              ),
            ),
          );
        }
        return;
      }
    }
    if (!mounted) return;
    setState(() {
      _salvataggio = false;
      _prove.clear();
      _testo = '';
      if (_indice + 1 < atleti.length) {
        _indice++;
      } else {
        _finito = true;
      }
    });
  }

  void _vaiA(int indice) => setState(() {
    _indice = indice;
    _prove.clear();
    _testo = '';
    _finito = false;
  });

  Future<void> _scegliAtleta(Map<String, List<double>> fatti) async {
    final atleti = _atleti!;
    final scelto = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.s16,
          0,
          AppSpacing.s16,
          AppSpacing.s24,
        ),
        child: AppListPanel(
          righe: [
            for (final (i, a) in atleti.indexed)
              AppListRow(
                titolo: a.nomeCompleto,
                sottotitolo: switch (fatti[a.id]) {
                  final v? =>
                    'Fatto: ${formattaValore(_unita, _test.punteggioDi(v))}',
                  null => 'Da fare',
                },
                onTap: () => Navigator.of(sheetContext).pop(i),
              ),
          ],
        ),
      ),
    );
    if (scelto != null) _vaiA(scelto);
  }

  Future<void> _cambiaGiorno() async {
    final scelto = await showDatePicker(
      context: context,
      initialDate: _data,
      firstDate: DateTime(_data.year - 2),
      lastDate: DateTime.now(),
    );
    if (scelto != null) setState(() => _data = scelto);
  }

  Future<bool> _confermaUscita() async {
    if (_prove.isEmpty && _testo.isEmpty) return true;
    final esci = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Uscire senza salvare?'),
        content: Text(
          'Le prove di ${_atleti![_indice].nomeCompleto} non ancora '
          'salvate andranno perse.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Annulla'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Esci'),
          ),
        ],
      ),
    );
    return esci == true;
  }

  KeyEventResult _tastiera(FocusNode _, KeyEvent evento) {
    if (evento is! KeyDownEvent) return KeyEventResult.ignored;
    final carattere = evento.character;
    if (carattere != null && RegExp(r'^[0-9]$').hasMatch(carattere)) {
      _tasto(carattere);
      return KeyEventResult.handled;
    }
    if (carattere == ',' || carattere == '.') {
      _tasto(',');
      return KeyEventResult.handled;
    }
    if (evento.logicalKey == LogicalKeyboardKey.backspace) {
      _tasto('⌫');
      return KeyEventResult.handled;
    }
    if (evento.logicalKey == LogicalKeyboardKey.enter ||
        evento.logicalKey == LogicalKeyboardKey.numpadEnter) {
      _registra();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) =>
      NascondiBarraClub(child: SchermoAcceso(child: _costruisci(context)));

  Widget _costruisci(BuildContext context) {
    final risultatiAsync = ref.watch(risultatiTestClubProvider(_test.clubId));
    final atletiAsync = ref.watch(
      atletiListProvider((clubId: _test.clubId, includeInactive: false)),
    );
    final gruppoId = ref.watch(selezioneGruppoProvider)?.gruppoId;
    final temaVasca = temaBordoVascaDa(
      ref.watch(temaBordoVascaOverrideProvider),
    );

    Widget corpo;
    if (risultatiAsync.isLoading || atletiAsync.isLoading) {
      corpo = const Padding(
        padding: EdgeInsets.all(AppSpacing.s16),
        child: LoadingSkeletonList(righe: 4),
      );
    } else {
      final risultati = risultatiAsync.value ?? const <RisultatoTest>[];
      _prepara([
        for (final a in atletiAsync.value ?? const <Atleta>[])
          if (gruppoId == null || a.gruppoId == gruppoId) a,
      ], risultati);
      final atleti = _atleti!;
      final fatti = {..._giaFatti(risultati), ..._salvati};
      if (atleti.isEmpty) {
        corpo = EmptyState(
          icona: Icons.groups_outlined,
          titolo: 'Nessun atleta nella squadra',
          descrizione:
              'I risultati si segnano per gli atleti della squadra scelta '
              'in alto.',
          azionePrincipale: 'Torna indietro',
          onAzionePrincipale: () => Navigator.of(context).pop(),
        );
      } else if (_finito) {
        corpo = _Fine(
          fatti: fatti.length,
          di: atleti.length,
          onTorna: () => Navigator.of(context).pop(),
          onRivedi: () => _scegliAtleta(fatti),
        );
      } else {
        corpo = _Raffica(
          test: _test,
          atleta: atleti[_indice],
          numero: _indice + 1,
          di: atleti.length,
          giaFatto: fatti[atleti[_indice].id],
          prove: _prove,
          testo: _testo,
          salvataggio: _salvataggio,
          onTasto: _tasto,
          onRegistra: _registra,
          onSalta: _chiudiAtleta,
        );
      }
    }

    Widget pagina = PopScope(
      canPop: _prove.isEmpty && _testo.isEmpty,
      onPopInvokedWithResult: (fatto, _) async {
        if (fatto) return;
        if (await _confermaUscita() && context.mounted) {
          setState(() {
            _prove.clear();
            _testo = '';
          });
          Navigator.of(context).pop();
        }
      },
      child: Focus(
        focusNode: _focus,
        autofocus: true,
        onKeyEvent: _tastiera,
        child: Scaffold(
          appBar: AppBar(
            title: Text('${_test.nome} · ${dataCompatta(_data)}'),
            actions: [
              IconButton(
                tooltip: 'Cambia giorno',
                icon: const Icon(Icons.calendar_today_outlined),
                onPressed: _prove.isEmpty ? _cambiaGiorno : null,
              ),
              if (_atleti != null && _atleti!.isNotEmpty)
                IconButton(
                  tooltip: 'Scegli un atleta',
                  icon: const Icon(Icons.format_list_bulleted),
                  onPressed: () => _scegliAtleta({
                    ..._giaFatti(risultatiAsync.value ?? const []),
                    ..._salvati,
                  }),
                ),
              const BottoneTemaBordoVasca(),
            ],
          ),
          body: SafeArea(child: corpo),
        ),
      ),
    );
    if (temaVasca != null) pagina = Theme(data: temaVasca, child: pagina);
    return pagina;
  }
}

/// L'atleta in corso: nome, prove fatte, il valore che si scrive e il
/// tastierino. Su schermo largo il tastierino sta a destra.
class _Raffica extends StatelessWidget {
  const _Raffica({
    required this.test,
    required this.atleta,
    required this.numero,
    required this.di,
    required this.giaFatto,
    required this.prove,
    required this.testo,
    required this.salvataggio,
    required this.onTasto,
    required this.onRegistra,
    required this.onSalta,
  });

  final TestClub test;
  final Atleta atleta;
  final int numero;
  final int di;
  final List<double>? giaFatto;
  final List<double> prove;
  final String testo;
  final bool salvataggio;
  final ValueChanged<String> onTasto;
  final VoidCallback onRegistra;
  final VoidCallback onSalta;

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    final tablet = Breakpoint.of(context) != Breakpoint.compatto;
    final massimale = test.massimale;
    final unita = unitaDelCampo(test, prove.length);
    final valore = valoreDelCampo(test, prove.length, testo);
    final valido = valore != null;
    final prova = prove.length + 1;
    final ultimoCampo = prova >= campiPerAtleta(test);
    // Per un massimale: cosa si scrive adesso e, con chili e ripetizioni,
    // il massimale che ne viene.
    final etichettaCampo = !massimale
        ? null
        : prove.isEmpty
        ? 'Chili sollevati'
        : 'Ripetizioni fatte (fino a $ripetizioniMassimeStima)';
    final stima = massimale && prove.length == 1 && valore != null
        ? stimaMassimale(prove.first, valore.round())
        : null;
    final troppe =
        massimale &&
        prove.length == 1 &&
        valore == null &&
        (valoreDigitato(UnitaTest.ripetizioni, testo) ?? 0) >
            ripetizioniMassimeStima;
    final semantica = massimale ? (etichettaCampo ?? '') : 'Prova $prova';

    final info = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Atleta $numero di $di',
          style: AppTypography.corpo.copyWith(color: colori.testoSecondario),
        ),
        const SizedBox(height: AppSpacing.s4),
        Text(
          atleta.nomeCompleto,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.titoloXl.copyWith(color: colori.testo),
        ),
        if (giaFatto case final v?)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.s4),
            child: Text(
              'Già fatto oggi: ${formattaValore(test.unita, test.punteggioDi(v))}. '
              'Rifacendolo si sostituisce.',
              style: AppTypography.piccolo.copyWith(
                color: colori.testoSecondario,
              ),
            ),
          ),
        const SizedBox(height: AppSpacing.s16),
        if (massimale)
          Wrap(
            spacing: AppSpacing.s8,
            runSpacing: AppSpacing.s8,
            children: [
              _Prova(
                etichetta: 'Chili',
                valore: prove.isNotEmpty
                    ? formattaValore(UnitaTest.chili, prove[0], sigla: false)
                    : null,
                inCorso: prove.isEmpty,
              ),
              _Prova(
                etichetta: 'Ripetizioni',
                valore: prove.length > 1 ? '${prove[1].round()}' : null,
                inCorso: prove.length == 1,
              ),
            ],
          )
        else if (test.prove > 1)
          Wrap(
            spacing: AppSpacing.s8,
            runSpacing: AppSpacing.s8,
            children: [
              for (var i = 0; i < test.prove; i++)
                _Prova(
                  etichetta: '${i + 1}ª',
                  valore: i < prove.length
                      ? formattaValore(test.unita, prove[i], sigla: false)
                      : null,
                  inCorso: i == prove.length,
                ),
            ],
          ),
        const SizedBox(height: AppSpacing.s16),
        if (etichettaCampo != null)
          Text(
            etichettaCampo,
            style: AppTypography.corpoForte.copyWith(
              color: colori.testoSecondario,
            ),
          ),
        Semantics(
          liveRegion: true,
          label: testo.isEmpty
              ? '$semantica: da scrivere'
              : '$semantica: ${testoMostrato(unita, testo)} ${unita.sigla}',
          child: ExcludeSemantics(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: testo.isEmpty
                        ? (unita == UnitaTest.secondi ? '0,00' : '0')
                        : testoMostrato(unita, testo),
                    style: AppTypography.numerica(
                      (tablet
                              ? AppTypography.displayTablet
                              : AppTypography.display)
                          .copyWith(
                            color: testo.isEmpty
                                ? colori.testoTenue
                                : colori.testo,
                          ),
                    ),
                  ),
                  TextSpan(
                    text: ' ${unita.sigla}',
                    style: AppTypography.titolo.copyWith(
                      color: colori.testoSecondario,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (stima != null)
          Text(
            'Massimale stimato: ${formattaValore(UnitaTest.chili, stima)}',
            style: AppTypography.numerica(AppTypography.corpoForte)
                .copyWith(color: colori.testo),
          ),
        if (troppe)
          Text(
            'Fino a $ripetizioniMassimeStima ripetizioni: oltre, la stima '
            'non regge. Prova con un carico più pesante.',
            style: AppTypography.piccolo.copyWith(color: colori.attenzione),
          ),
      ],
    );

    final tastierino = _Tastierino(
      conVirgola: unita.conDecimali,
      onTasto: salvataggio ? null : onTasto,
    );
    final azioni = Row(
      children: [
        Expanded(
          child: _Bottone(
            etichetta: prove.isEmpty || massimale ? 'Salta' : 'Basta prove',
            onTap: salvataggio ? null : onSalta,
          ),
        ),
        const SizedBox(width: AppSpacing.s12),
        Expanded(
          flex: 2,
          child: _Bottone(
            etichetta: ultimoCampo
                ? 'Registra e avanti'
                : massimale
                ? 'Avanti'
                : 'Registra',
            principale: true,
            onTap: valido && !salvataggio ? onRegistra : null,
          ),
        ),
      ],
    );

    return LayoutBuilder(
      builder: (context, vincoli) {
        if (vincoli.maxWidth >= 760) {
          return Padding(
            padding: const EdgeInsets.all(AppSpacing.s24),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: SingleChildScrollView(child: info)),
                const SizedBox(width: AppSpacing.s24),
                SizedBox(
                  width: 360,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      tastierino,
                      const SizedBox(height: AppSpacing.s12),
                      azioni,
                    ],
                  ),
                ),
              ],
            ),
          );
        }
        return Padding(
          padding: const EdgeInsets.all(AppSpacing.s16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: SingleChildScrollView(child: info)),
              const SizedBox(height: AppSpacing.s12),
              tastierino,
              const SizedBox(height: AppSpacing.s12),
              azioni,
            ],
          ),
        );
      },
    );
  }
}

/// Una prova nella fila sopra il valore ("2ª", o "Chili" e "Ripetizioni"
/// per un massimale): fatta, in corso o da fare.
class _Prova extends StatelessWidget {
  const _Prova({required this.etichetta, this.valore, this.inCorso = false});

  final String etichetta;
  final String? valore;
  final bool inCorso;

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s12,
        vertical: AppSpacing.s8,
      ),
      decoration: BoxDecoration(
        color: inCorso ? colori.azioneTenue : colori.superficie,
        borderRadius: BorderRadius.circular(AppRadius.controllo),
        border: Border.all(color: inCorso ? colori.azione : colori.linea),
      ),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '$etichetta ',
              style: AppTypography.etichetta.copyWith(
                color: colori.testoSecondario,
              ),
            ),
            TextSpan(
              text: valore ?? '—',
              style: AppTypography.numerica(AppTypography.corpoForte)
                  .copyWith(color: colori.testo),
            ),
          ],
        ),
      ),
    );
  }
}

/// Il tastierino: cifre, la virgola dove ha senso, ⌫. Tasti da 64.
class _Tastierino extends StatelessWidget {
  const _Tastierino({required this.conVirgola, required this.onTasto});

  final bool conVirgola;
  final ValueChanged<String>? onTasto;

  @override
  Widget build(BuildContext context) {
    const righe = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
    ];
    Widget tasto(String t, {String? etichetta}) => Expanded(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s4),
        child: _Bottone(
          etichetta: etichetta ?? t,
          grande: true,
          semantica: t == '⌫' ? 'Cancella' : null,
          onTap: onTasto == null ? null : () => onTasto!(t),
        ),
      ),
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final riga in righe)
          Row(children: [for (final t in riga) tasto(t)]),
        Row(
          children: [
            if (conVirgola) tasto(',') else const Expanded(child: SizedBox()),
            tasto('0'),
            tasto('⌫'),
          ],
        ),
      ],
    );
  }
}

/// Un bersaglio da bordo vasca: alto 64, pieno solo per l'azione
/// principale; [grande] per i tasti delle cifre.
class _Bottone extends StatelessWidget {
  const _Bottone({
    required this.etichetta,
    required this.onTap,
    this.principale = false,
    this.grande = false,
    this.semantica,
  });

  final String etichetta;
  final VoidCallback? onTap;
  final bool principale;
  final bool grande;
  final String? semantica;

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    final stile = ButtonStyle(
      minimumSize: const WidgetStatePropertyAll(
        Size.fromHeight(AppSpacing.altezzaMinimaBersaglioVasca),
      ),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.controllo),
        ),
      ),
      textStyle: WidgetStatePropertyAll(
        grande
            ? AppTypography.numerica(AppTypography.titolo)
            : AppTypography.corpoForte.copyWith(fontSize: 18),
      ),
    );
    final testo = Text(
      etichetta,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      semanticsLabel: semantica,
    );
    final bottone = principale
        ? FilledButton(onPressed: onTap, style: stile, child: testo)
        : OutlinedButton(
            onPressed: onTap,
            style: stile.copyWith(
              foregroundColor: WidgetStatePropertyAll(colori.testo),
              side: WidgetStatePropertyAll(
                BorderSide(color: colori.lineaForte),
              ),
            ),
            child: testo,
          );
    return bottone;
  }
}

/// Finita la squadra: quanti risultati, e si torna alla classifica.
class _Fine extends StatelessWidget {
  const _Fine({
    required this.fatti,
    required this.di,
    required this.onTorna,
    required this.onRivedi,
  });

  final int fatti;
  final int di;
  final VoidCallback onTorna;
  final VoidCallback onRivedi;

  @override
  Widget build(BuildContext context) => EmptyState(
    icona: Icons.check_circle_outline,
    titolo: 'Squadra finita',
    descrizione: '$fatti atleti su $di hanno un risultato per questo giorno.',
    azionePrincipale: 'Torna alla classifica',
    onAzionePrincipale: onTorna,
    azioneSecondaria: 'Scegli un atleta',
    onAzioneSecondaria: onRivedi,
  );
}
