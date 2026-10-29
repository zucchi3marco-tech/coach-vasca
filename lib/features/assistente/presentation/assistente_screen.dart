import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/sport_app.dart';
import '../../../core/utils/date_format.dart';
import '../../../core/utils/date_italiane.dart';
import '../../../core/utils/error_messages.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../theme/colori_app.dart';
import '../../../widgets/app_scaffold.dart';
import '../../../widgets/error_banner.dart';
import '../../../widgets/loading_skeleton.dart';
import '../../allenamenti/data/allenamenti_repository.dart';
import '../../allenamenti/data/salva_piano_serie.dart';
import '../../allenamenti/data/serie_repository.dart';
import '../../allenamenti/domain/allenamento.dart';
import '../../allenamenti/domain/modifica_allenamento.dart';
import '../../allenamenti/domain/piano_salvataggio_testo.dart';
import '../../allenamenti/domain/prossimo_allenamento.dart';
import '../../allenamenti/presentation/allenamento_detail_screen.dart';
import '../../allenamenti/presentation/avviso_seduta_aperta.dart';
import '../../atleti/application/atleti_providers.dart';
import '../../atleti/domain/abbina_atleta.dart';
import '../../atleti/domain/atleta.dart';
import '../../gruppi/application/gruppi_providers.dart';
import '../../pallanuoto/data/distinta_repository.dart';
import '../../presenze/data/presenze_repository.dart';
import '../../presenze/domain/presenza.dart';
import '../../presenze/presentation/presenze_screen.dart';
import '../application/fonte_dati_riverpod.dart';
import '../data/assistente_repository.dart';
import '../domain/motore_assistente.dart';
import '../domain/pseudonimi.dart';
import '../domain/strumenti_assistente.dart';

/// L'assistente dell'allenatore (proposta 9 del piano): una chat che
/// risponde con i dati del club e propone azioni da confermare. I dati li
/// legge e li conta il telefono; all'AI arrivano solo codici al posto dei
/// nomi e numeri già calcolati, mai benessere e dolori (decisione del 13
/// ottobre 2026). La conversazione non si salva: uscendo, sparisce.
class AssistenteScreen extends ConsumerStatefulWidget {
  const AssistenteScreen({
    required this.clubId,
    this.gruppoId,
    this.seduta,
    this.oggi,
    super.key,
  });

  final String clubId;
  final String? gruppoId;

  /// Aperto dalla pagina di una seduta: le domande parlano di questa
  /// ("togli il 400 iniziale").
  final Allenamento? seduta;

  /// Per i test; di solito adesso.
  final DateTime? oggi;

  @override
  ConsumerState<AssistenteScreen> createState() => _AssistenteScreenState();
}

/// Cosa è successo a una proposta.
enum _Esito { daDecidere, inCorso, fatta, scartata }

class _AssistenteScreenState extends ConsumerState<AssistenteScreen> {
  final _domanda = TextEditingController();
  final _scorrimento = ScrollController();
  final _voci = <VoceChat>[];
  final _esiti = <SchedaAssistente, _Esito>{};
  final _sedutaCreata = <PropostaSeduta, Allenamento>{};
  final _modificaProvata = <PropostaModificaSeduta>{};
  MotoreAssistente? _motore;
  bool _pensa = false;
  String? _strumento;

  DateTime get _oggi => widget.oggi ?? DateTime.now();

  @override
  void dispose() {
    _domanda.dispose();
    _scorrimento.dispose();
    super.dispose();
  }

  /// Il motore nasce alla prima domanda, con i codici degli atleti di
  /// adesso.
  Future<MotoreAssistente> _preparaMotore() async {
    if (_motore case final m?) return m;
    final fonte = FonteDatiRiverpod(
      ref,
      clubId: widget.clubId,
      gruppoId: widget.gruppoId,
    );
    final pseudonimi = Pseudonimi(await fonte.atleti());
    String? squadra;
    for (final g
        in ref.read(gruppiListProvider(widget.clubId)).value ?? const []) {
      if (g.id == widget.gruppoId) squadra = g.nome;
    }
    final repository = ref.read(assistenteRepositoryProvider);
    final contesto = <String, Object?>{
      'oggi': formatDateOnly(_oggi),
      'giorno': nomeGiorno(_oggi),
      'sport': sportApp,
      'squadra': squadra ?? 'tutto il club',
      if (widget.seduta case final s?)
        'seduta_aperta': {
          'id': s.id,
          'data': formatDateOnly(s.data),
          'giorno': nomeGiorno(s.data),
          'tipo': s.tipo,
        },
    };
    return _motore = MotoreAssistente(
      pseudonimi: pseudonimi,
      strumenti: StrumentiAssistente(
        fonte: fonte,
        pseudonimi: pseudonimi,
        oggi: _oggi,
      ),
      chiama: (messaggi) => repository.prossimoMessaggio(
        clubId: widget.clubId,
        contesto: contesto,
        messaggi: messaggi,
      ),
    );
  }

  void _scendi() => WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!_scorrimento.hasClients) return;
    _scorrimento.animateTo(
      _scorrimento.position.maxScrollExtent,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
  });

  Future<void> _chiedi([String? testo]) async {
    final domanda = (testo ?? _domanda.text).trim();
    if (domanda.isEmpty || _pensa) return;
    _domanda.clear();
    setState(() {
      _voci.add(DomandaAllenatore(domanda));
      _pensa = true;
      _strumento = null;
    });
    _scendi();
    try {
      final motore = await _preparaMotore();
      final risposta = await motore.chiedi(
        domanda,
        suStrumento: (s) {
          if (mounted) setState(() => _strumento = etichetteStrumenti[s]);
        },
      );
      if (!mounted) return;
      setState(() {
        _voci.addAll(risposta);
        for (final v in risposta) {
          if (v is VoceScheda && v.scheda is! SchedaSalute) {
            _esiti[v.scheda] = _Esito.daDecidere;
          }
        }
      });
    } catch (e) {
      if (mounted) {
        setState(
          () => _voci.add(
            ErroreAssistente(
              messaggioErrore(e).replaceFirst('Exception: ', ''),
              domanda: domanda,
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _pensa = false);
      _scendi();
    }
  }

  void _riprova(ErroreAssistente errore) {
    setState(() {
      _voci.remove(errore);
      // La domanda è già in vista: si rifà senza ripeterla.
      final i = _voci.lastIndexWhere(
        (v) => v is DomandaAllenatore && v.testo == errore.domanda,
      );
      if (i >= 0) _voci.removeAt(i);
    });
    _chiedi(errore.domanda);
  }

  void _ricomincia() => setState(() {
    _voci.clear();
    _esiti.clear();
    _sedutaCreata.clear();
    _modificaProvata.clear();
    _motore = null;
  });

  Future<void> _convoca(PropostaConvocazione p) async {
    setState(() => _esiti[p] = _Esito.inCorso);
    final repository = ref.read(distintaRepositoryProvider);
    try {
      for (final n in p.nuovi) {
        await repository.aggiungiConvocato(
          partitaId: p.partita.id,
          atletaId: n.atleta.id,
          numeroCalottina: n.numero,
          portiere: n.atleta.portiere,
        );
      }
      _motore?.annota(
        'Convocazione salvata: ${p.nuovi.length} atleti aggiunti alla '
        'distinta della partita ${p.partita.id}.',
      );
      if (mounted) setState(() => _esiti[p] = _Esito.fatta);
    } catch (e) {
      if (!mounted) return;
      setState(() => _esiti[p] = _Esito.daDecidere);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Convocazione non salvata: ${messaggioErrore(e)}'),
        ),
      );
    }
  }

  /// Come "Scrivi o detta": l'allenamento nella data proposta, per la
  /// squadra scelta, con le serie nell'ordine scritto.
  Future<void> _creaSeduta(PropostaSeduta p) async {
    setState(() => _esiti[p] = _Esito.inCorso);
    try {
      final allenamento = await ref
          .read(allenamentiRepositoryProvider)
          .createAllenamento(
            clubId: widget.clubId,
            data: p.data,
            titolo: p.titolo,
            gruppoId: widget.gruppoId,
          );
      final piano = pianoSalvataggio(
        vecchie: const [],
        nuove: p.scritto.serie,
        nuovoId: () => const Uuid().v4(),
      );
      await eseguiPianoSerie(
        ref.read(serieRepositoryProvider),
        allenamentoId: allenamento.id,
        piano: piano,
      );
      _motore?.annota(
        'Seduta creata il ${formatDateOnly(p.data)} con '
        '${p.scritto.serie.length} serie.',
      );
      if (mounted) {
        setState(() {
          _esiti[p] = _Esito.fatta;
          _sedutaCreata[p] = allenamento;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _esiti[p] = _Esito.daDecidere);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Seduta non creata: ${messaggioErrore(e)}')),
      );
    }
  }

  /// Salva solo chi cambia: chi era già segnato così resta com'è.
  Future<void> _salvaAppello(
    PropostaAppello p,
    Map<String, String> stati,
  ) async {
    setState(() => _esiti[p] = _Esito.inCorso);
    final repository = ref.read(presenzeRepositoryProvider);
    try {
      await Future.wait([
        for (final r in p.righe)
          if (stati[r.atleta.id] case final stato? when stato != r.attuale)
            repository.segnaPresenza(
              allenamentoId: p.allenamento.id,
              atletaId: r.atleta.id,
              stato: stato,
            ),
      ]);
      int quanti(bool Function(String) vale) => stati.values.where(vale).length;
      _motore?.annota(
        'Appello salvato per la seduta ${p.allenamento.id}: '
        '${quanti(contaComePresente)} presenti (di cui '
        '${quanti((s) => s == statoRitardo)} in ritardo), '
        '${quanti((s) => s == statoAssente)} assenti, '
        '${quanti((s) => s == statoGiustificato)} giustificati.',
      );
      if (mounted) setState(() => _esiti[p] = _Esito.fatta);
    } catch (e) {
      if (!mounted) return;
      setState(() => _esiti[p] = _Esito.daDecidere);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Appello non salvato: ${messaggioErrore(e)}')),
      );
    }
  }

  /// Come "Scrivi l'allenamento": tocca solo le serie che cambiano (quelle
  /// segnate «fatta» restano tali), dopo aver controllato che la seduta
  /// sia ancora quella letta dall'assistente.
  Future<void> _salvaModifica(PropostaModificaSeduta p) async {
    final seduta = p.allenamento;
    setState(() => _esiti[p] = _Esito.inCorso);
    final repository = ref.read(serieRepositoryProvider);
    try {
      final attuali = await repository.fetchPerAllenamento(seduta.id);
      // Dopo un salvataggio a metà le serie sono già un po' cambiate (da
      // qui): riprovando si finisce il lavoro.
      if (!_modificaProvata.contains(p) && !stesseSerie(attuali, p.serie)) {
        _motore?.annota(
          'La seduta ${seduta.id} è cambiata dopo la proposta: modifiche non '
          'salvate. Rileggila con leggi_seduta prima di riproporle.',
        );
        if (!mounted) return;
        setState(() => _esiti[p] = _Esito.scartata);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'La seduta è cambiata dopo la proposta: chiedi di nuovo '
              'all\'assistente.',
            ),
          ),
        );
        return;
      }
      if (!mounted) return;
      // Un collega l'ha cambiata intanto? (Senza rete si salva e basta.)
      final esito = await controllaPrimaDiSalvare(
        context,
        ref,
        allenamentoId: seduta.id,
        clubId: seduta.clubId,
      );
      if (esito != true) {
        if (esito == false) {
          _motore?.annota(
            'L\'allenatore ha tenuto la versione del collega: modifiche non '
            'salvate.',
          );
        }
        if (mounted) {
          setState(
            () => _esiti[p] = esito == false
                ? _Esito.scartata
                : _Esito.daDecidere,
          );
        }
        return;
      }
      _modificaProvata.add(p);
      if (p.cambiaSerie) {
        await eseguiPianoSerie(
          repository,
          allenamentoId: seduta.id,
          piano: pianoSalvataggio(
            vecchie: attuali,
            nuove: p.scritto.serie,
            nuovoId: () => const Uuid().v4(),
          ),
        );
      }
      if (p.cambiaTitolo || p.cambiaNote) {
        await ref
            .read(allenamentiRepositoryProvider)
            .updateAllenamento(
              originale: seduta,
              data: seduta.data,
              titolo: p.titolo,
              gruppoId: seduta.gruppoId,
              note: p.note,
              durataMin: seduta.durataMin,
            );
      }
      unawaited(sedutaSalvata(ref, seduta.id));
      _motore?.annota(
        'Modifiche salvate nella seduta ${seduta.id}'
        '${p.cambiaSerie ? ': ora ha ${p.scritto.serie.length} serie' : ''}.',
      );
      if (mounted) setState(() => _esiti[p] = _Esito.fatta);
    } catch (e) {
      if (!mounted) return;
      setState(() => _esiti[p] = _Esito.daDecidere);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Modifiche non salvate: ${messaggioErrore(e)}. Riprova: le serie '
            'già salvate non si duplicano.',
          ),
        ),
      );
    }
  }

  void _scarta(SchedaAssistente p) {
    _motore?.annota('L\'allenatore ha scartato la proposta.');
    setState(() => _esiti[p] = _Esito.scartata);
  }

  static const _esempi = [
    'Com\'è andata la superiorità nelle ultime 5 partite?',
    'Convoca per la prossima partita, escludendo chi ha male alla spalla',
    'Chi ha segnato dolori questa settimana?',
    'Prepara la seduta di giovedì, con lavoro per i portieri',
    'Appello di oggi: tutti presenti',
  ];

  /// Aperto dalla pagina di una seduta.
  static const _esempiSeduta = [
    'Aggiungi 4x50 gambe alla fine del riscaldamento',
    'Togli l\'ultima serie del principale',
    'Cambia il titolo in «Superiorità e tiri»',
  ];

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    // I nomi per la scheda della salute e le proposte arrivano già qui.
    final atleti =
        ref
            .watch(
              atletiListProvider((
                clubId: widget.clubId,
                includeInactive: false,
              )),
            )
            .value ??
        const [];

    return AppScaffold(
      larghezzaMassima: 820,
      appBar: AppBar(
        title: const Text('Assistente'),
        actions: [
          if (_voci.isNotEmpty)
            IconButton(
              tooltip: 'Ricomincia',
              onPressed: _pensa ? null : _ricomincia,
              icon: const Icon(Icons.restart_alt),
            ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ListView(
              controller: _scorrimento,
              padding: const EdgeInsets.only(bottom: AppSpacing.s16),
              children: [
                const _Riservatezza(),
                const SizedBox(height: AppSpacing.s16),
                if (_voci.isEmpty)
                  _Inizio(
                    seduta: widget.seduta,
                    esempi: widget.seduta == null ? _esempi : _esempiSeduta,
                    onEsempio: _chiedi,
                  ),
                for (final v in _voci)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.s12),
                    child: switch (v) {
                      DomandaAllenatore(:final testo) => _Domanda(testo),
                      RispostaAssistente() => _Risposta(v),
                      ErroreAssistente() => _Errore(
                        v,
                        onRiprova: _pensa ? null : () => _riprova(v),
                      ),
                      VoceScheda(:final scheda) => switch (scheda) {
                        SchedaSalute() => _CartaSalute(scheda, atleti: atleti),
                        PropostaConvocazione() => _CartaConvocazione(
                          scheda,
                          atleti: atleti,
                          esito: _esiti[scheda] ?? _Esito.daDecidere,
                          onConferma: () => _convoca(scheda),
                          onScarta: () => _scarta(scheda),
                        ),
                        PropostaSeduta() => _CartaSeduta(
                          scheda,
                          esito: _esiti[scheda] ?? _Esito.daDecidere,
                          creata: _sedutaCreata[scheda],
                          onConferma: () => _creaSeduta(scheda),
                          onScarta: () => _scarta(scheda),
                        ),
                        PropostaAppello() => _CartaAppello(
                          scheda,
                          atleti: atleti,
                          esito: _esiti[scheda] ?? _Esito.daDecidere,
                          onConferma: (stati) => _salvaAppello(scheda, stati),
                          onScarta: () => _scarta(scheda),
                        ),
                        PropostaModificaSeduta() => _CartaModificaSeduta(
                          scheda,
                          esito: _esiti[scheda] ?? _Esito.daDecidere,
                          // Dalla pagina della seduta si torna indietro.
                          apri: widget.seduta?.id == scheda.allenamento.id
                              ? null
                              : () => Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => AllenamentoDetailScreen(
                                      allenamento: scheda.allenamento,
                                    ),
                                  ),
                                ),
                          onConferma: () => _salvaModifica(scheda),
                          onScarta: () => _scarta(scheda),
                        ),
                      },
                    },
                  ),
                if (_pensa) _InAttesa(strumento: _strumento),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.s8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  key: const Key('domanda-assistente'),
                  controller: _domanda,
                  minLines: 1,
                  maxLines: 4,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _chiedi(),
                  decoration: InputDecoration(
                    hintText: widget.seduta == null
                        ? 'Chiedi sui dati della squadra'
                        : 'Cosa cambio in questa seduta?',
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.s8),
              IconButton.filled(
                tooltip: 'Chiedi',
                onPressed: _pensa ? null : _chiedi,
                icon: const Icon(Icons.arrow_upward),
                style: IconButton.styleFrom(
                  minimumSize: const Size(
                    AppSpacing.altezzaMinimaBersaglio,
                    AppSpacing.altezzaMinimaBersaglio,
                  ),
                  backgroundColor: colori.azione,
                  foregroundColor: colori.azioneInk,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// La riga in alto che dice cosa esce dal telefono.
class _Riservatezza extends StatelessWidget {
  const _Riservatezza();

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.lock_outline, size: 16, color: colori.testoSecondario),
        const SizedBox(width: AppSpacing.s8),
        Expanded(
          child: Text(
            'Nomi e dati sulla salute restano sul telefono: all\'AI arrivano '
            'codici al posto dei nomi e numeri già calcolati.',
            style: AppTypography.piccolo.copyWith(
              color: colori.testoSecondario,
            ),
          ),
        ),
      ],
    );
  }
}

class _Inizio extends StatelessWidget {
  const _Inizio({
    required this.seduta,
    required this.esempi,
    required this.onEsempio,
  });

  final Allenamento? seduta;
  final List<String> esempi;
  final ValueChanged<String> onEsempio;

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpacing.s16),
        Icon(Icons.forum_outlined, size: 48, color: colori.testoTenue),
        const SizedBox(height: AppSpacing.s12),
        Text(switch (seduta) {
          final s? => 'Cambia «${s.titoloMostrato}» di ${dataEstesa(s.data)}',
          null => 'Chiedi all\'assistente',
        }, style: AppTypography.sezione.copyWith(color: colori.testo)),
        const SizedBox(height: AppSpacing.s8),
        Text(
          seduta == null
              ? 'Risponde con i dati del club, fa l\'appello («assenti Rossi '
                    'e Bianchi, Verdi in ritardo») e propone convocazioni e '
                    'sedute, e cambia quelle che ci sono: ogni proposta la '
                    'controlli e la confermi tu.'
              : 'Di\' cosa cambiare: serie, titolo o note. Ti mostra prima e '
                    'dopo, e salvi tu; le serie già segnate «fatta» restano '
                    'tali.',
          style: AppTypography.piccolo.copyWith(color: colori.testoSecondario),
        ),
        const SizedBox(height: AppSpacing.s16),
        Wrap(
          spacing: AppSpacing.s8,
          runSpacing: AppSpacing.s8,
          children: [
            for (final e in esempi)
              ActionChip(label: Text(e), onPressed: () => onEsempio(e)),
          ],
        ),
      ],
    );
  }
}

class _Domanda extends StatelessWidget {
  const _Domanda(this.testo);

  final String testo;

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    return Align(
      alignment: Alignment.centerRight,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s16,
            vertical: AppSpacing.s12,
          ),
          decoration: BoxDecoration(
            color: colori.azioneTenue,
            borderRadius: BorderRadius.circular(AppRadius.pannello),
          ),
          child: Text(
            testo,
            style: AppTypography.corpo.copyWith(color: colori.testo),
          ),
        ),
      ),
    );
  }
}

class _Risposta extends StatelessWidget {
  const _Risposta(this.risposta);

  final RispostaAssistente risposta;

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.paddingPannello),
          decoration: BoxDecoration(
            color: colori.superficie,
            borderRadius: BorderRadius.circular(AppRadius.pannello),
            border: Border.all(color: colori.linea),
          ),
          child: SelectableText(
            risposta.testo.isEmpty ? '…' : risposta.testo,
            style: AppTypography.corpo.copyWith(color: colori.testo),
          ),
        ),
        if (risposta.datiLetti.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.s4),
          Text(
            'Ha letto: ${risposta.datiLetti.join(', ')}',
            style: AppTypography.piccolo.copyWith(color: colori.testoTenue),
          ),
        ],
      ],
    );
  }
}

class _Errore extends StatelessWidget {
  const _Errore(this.errore, {required this.onRiprova});

  final ErroreAssistente errore;
  final VoidCallback? onRiprova;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      ErrorBanner(
        messaggio: 'L\'assistente non ha risposto.',
        suggerimento: errore.messaggio,
      ),
      TextButton(onPressed: onRiprova, child: const Text('Riprova')),
    ],
  );
}

class _InAttesa extends StatelessWidget {
  const _InAttesa({required this.strumento});

  final String? strumento;

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const LoadingSkeleton(width: 240, height: AppSpacing.s20),
        const SizedBox(height: AppSpacing.s8),
        Text(
          strumento == null ? 'Ci sto pensando' : 'Sto leggendo: $strumento',
          style: AppTypography.piccolo.copyWith(color: colori.testoTenue),
        ),
      ],
    );
  }
}

/// Il contenitore delle schede dell'assistente: pannello con titolo.
class _Carta extends StatelessWidget {
  const _Carta({
    required this.icona,
    required this.titolo,
    required this.figli,
  });

  final IconData icona;
  final String titolo;
  final List<Widget> figli;

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.paddingPannello),
      decoration: BoxDecoration(
        color: colori.superficie,
        borderRadius: BorderRadius.circular(AppRadius.pannello),
        border: Border.all(color: colori.lineaForte),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icona, size: 20, color: colori.azione),
              const SizedBox(width: AppSpacing.s8),
              Expanded(
                child: Text(
                  titolo,
                  style: AppTypography.corpoForte.copyWith(color: colori.testo),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s12),
          ...figli,
        ],
      ),
    );
  }
}

/// I pulsanti di una proposta, o com'è andata.
class _Decisione extends StatelessWidget {
  const _Decisione({
    required this.esito,
    required this.conferma,
    required this.fatto,
    required this.onConferma,
    required this.onScarta,
    this.dopo,
  });

  final _Esito esito;
  final String conferma;
  final String fatto;
  final VoidCallback? onConferma;
  final VoidCallback onScarta;

  /// Un'azione dopo averla fatta ("Apri la seduta").
  final Widget? dopo;

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    return switch (esito) {
      _Esito.fatta => Row(
        children: [
          Icon(Icons.check_circle, size: 20, color: colori.ok),
          const SizedBox(width: AppSpacing.s8),
          Expanded(
            child: Text(
              fatto,
              style: AppTypography.corpoForte.copyWith(color: colori.testo),
            ),
          ),
          ?dopo,
        ],
      ),
      _Esito.scartata => Text(
        'Proposta scartata',
        style: AppTypography.piccolo.copyWith(color: colori.testoTenue),
      ),
      _ => Wrap(
        spacing: AppSpacing.s8,
        runSpacing: AppSpacing.s8,
        children: [
          FilledButton(
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, AppSpacing.altezzaMinimaBersaglio),
            ),
            onPressed: esito == _Esito.inCorso ? null : onConferma,
            child: esito == _Esito.inCorso
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colori.azioneInk,
                    ),
                  )
                : Text(conferma),
          ),
          TextButton(
            onPressed: esito == _Esito.inCorso ? null : onScarta,
            child: const Text('Scarta'),
          ),
        ],
      ),
    };
  }
}

class _CartaConvocazione extends StatelessWidget {
  const _CartaConvocazione(
    this.proposta, {
    required this.atleti,
    required this.esito,
    required this.onConferma,
    required this.onScarta,
  });

  final PropostaConvocazione proposta;
  final List<Atleta> atleti;
  final _Esito esito;
  final VoidCallback onConferma;
  final VoidCallback onScarta;

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    final p = proposta.partita;
    return _Carta(
      icona: Icons.groups_outlined,
      titolo:
          'Distinta per ${dataEstesa(p.data)}, ${p.inCasa ? 'in casa' : 'in trasferta'} '
          'con ${p.avversario}',
      figli: [
        for (final n in proposta.nuovi)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.s4),
            child: Row(
              children: [
                SizedBox(
                  width: 32,
                  child: Text(
                    '${n.numero}',
                    style: AppTypography.numerica(AppTypography.corpoForte)
                        .copyWith(color: colori.testoSecondario),
                  ),
                ),
                Expanded(
                  child: Text(
                    '${atleti.isEmpty ? n.atleta.nomeCompleto : nomeBreve(n.atleta, atleti)}'
                    '${n.atleta.portiere ? ' (portiere)' : ''}',
                    style: AppTypography.corpo.copyWith(color: colori.testo),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: AppSpacing.s8),
        Text(
          '${['${proposta.nuovi.length} da aggiungere', if (proposta.giaConvocati > 0) '${proposta.giaConvocati} già in distinta'].join(', ')} (al massimo ${p.numeroMaxConvocati})',
          style: AppTypography.piccolo.copyWith(color: colori.testoSecondario),
        ),
        if (proposta.oltreIlMassimo) ...[
          const SizedBox(height: AppSpacing.s4),
          Text(
            'Sono ${proposta.totale}: oltre il massimo. Chiedi di toglierne '
            'qualcuno, o sistemala dalla distinta.',
            style: AppTypography.piccolo.copyWith(color: colori.attenzione),
          ),
        ],
        const SizedBox(height: AppSpacing.s12),
        _Decisione(
          esito: esito,
          conferma: 'Convoca',
          fatto: 'Convocati in distinta',
          onConferma: proposta.oltreIlMassimo ? null : onConferma,
          onScarta: onScarta,
        ),
      ],
    );
  }
}

class _CartaSeduta extends StatelessWidget {
  const _CartaSeduta(
    this.proposta, {
    required this.esito,
    required this.creata,
    required this.onConferma,
    required this.onScarta,
  });

  final PropostaSeduta proposta;
  final _Esito esito;
  final Allenamento? creata;
  final VoidCallback onConferma;
  final VoidCallback onScarta;

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    final s = proposta.scritto;
    final nonCapite = s.righeNonCapite;
    return _Carta(
      icona: Icons.pool,
      titolo: [
        'Seduta di ${dataEstesa(proposta.data)}',
        ?proposta.titolo,
      ].join(': '),
      figli: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.s12),
          decoration: BoxDecoration(
            color: colori.superficieAlt,
            borderRadius: BorderRadius.circular(AppRadius.controllo),
          ),
          child: SelectableText(
            proposta.testo.trim(),
            style: AppTypography.numerica(AppTypography.corpo)
                .copyWith(color: colori.testo),
          ),
        ),
        const SizedBox(height: AppSpacing.s8),
        Text(
          [
            if (s.metri > 0) formattaMetri(s.metri),
            s.serie.length == 1 ? '1 serie' : '${s.serie.length} serie',
          ].join(' · '),
          style: AppTypography.piccolo.copyWith(color: colori.testoSecondario),
        ),
        if (nonCapite > 0) ...[
          const SizedBox(height: AppSpacing.s4),
          Text(
            nonCapite == 1
                ? 'Una riga non è stata capita: non diventa una serie.'
                : '$nonCapite righe non sono state capite: non diventano '
                      'serie.',
            style: AppTypography.piccolo.copyWith(color: colori.attenzione),
          ),
        ],
        const SizedBox(height: AppSpacing.s12),
        _Decisione(
          esito: esito,
          conferma: 'Crea la seduta',
          fatto: 'Seduta creata',
          onConferma: onConferma,
          onScarta: onScarta,
          dopo: creata == null
              ? null
              : TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          AllenamentoDetailScreen(allenamento: creata!),
                    ),
                  ),
                  child: const Text('Apri'),
                ),
        ),
      ],
    );
  }
}

/// Le modifiche a una seduta che c'è: titolo e note che cambiano e le
/// serie riga per riga, le tolte in rosso e le aggiunte in verde.
class _CartaModificaSeduta extends StatelessWidget {
  const _CartaModificaSeduta(
    this.proposta, {
    required this.esito,
    required this.apri,
    required this.onConferma,
    required this.onScarta,
  });

  final PropostaModificaSeduta proposta;
  final _Esito esito;

  /// "Apri" dopo il salvataggio; null se la chat è aperta dalla seduta.
  final VoidCallback? apri;
  final VoidCallback onConferma;
  final VoidCallback onScarta;

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    final p = proposta;
    final a = p.allenamento;
    final s = p.scritto;
    final nonCapite = p.cambiaSerie ? s.righeNonCapite : 0;
    String numeroSerie(int n) => n == 1 ? '1 serie' : '$n serie';
    return _Carta(
      icona: Icons.edit_note,
      titolo: 'Modifiche a «${a.titoloMostrato}» di ${dataEstesa(a.data)}',
      figli: [
        if (p.cambiaTitolo)
          _Cambio(etichetta: 'Titolo', prima: a.titolo, dopo: p.titolo),
        if (p.cambiaNote)
          _Cambio(etichetta: 'Note', prima: a.note, dopo: p.note),
        if (p.cambiaSerie) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.s8),
            decoration: BoxDecoration(
              color: colori.superficieAlt,
              borderRadius: BorderRadius.circular(AppRadius.controllo),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final r in p.righe)
                  if (r.testo.trim().isEmpty)
                    const SizedBox(height: AppSpacing.s8)
                  else
                    _RigaCambiata(r),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.s8),
          Text(
            [
              if (p.metriPrima != s.metri)
                '${formattaMetri(p.metriPrima)} → ${formattaMetri(s.metri)}'
              else if (s.metri > 0)
                formattaMetri(s.metri),
              if (p.serie.length != s.serie.length)
                '${numeroSerie(p.serie.length)} → '
                    '${numeroSerie(s.serie.length)}'
              else
                numeroSerie(s.serie.length),
            ].join(' · '),
            style: AppTypography.piccolo.copyWith(
              color: colori.testoSecondario,
            ),
          ),
        ],
        if (nonCapite > 0) ...[
          const SizedBox(height: AppSpacing.s4),
          Text(
            nonCapite == 1
                ? 'Una riga non è stata capita: non diventa una serie.'
                : '$nonCapite righe non sono state capite: non diventano '
                      'serie.',
            style: AppTypography.piccolo.copyWith(color: colori.attenzione),
          ),
        ],
        const SizedBox(height: AppSpacing.s12),
        _Decisione(
          esito: esito,
          conferma: 'Salva le modifiche',
          fatto: 'Seduta aggiornata',
          onConferma: onConferma,
          onScarta: onScarta,
          dopo: apri == null
              ? null
              : TextButton(onPressed: apri, child: const Text('Apri')),
        ),
      ],
    );
  }
}

/// "Titolo: Tecnica → Superiorità".
class _Cambio extends StatelessWidget {
  const _Cambio({
    required this.etichetta,
    required this.prima,
    required this.dopo,
  });

  final String etichetta;
  final String? prima;
  final String? dopo;

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    String testo(String? t) =>
        t == null || t.trim().isEmpty ? '(niente)' : t.trim();
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s8),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '$etichetta: ',
              style: AppTypography.corpoForte.copyWith(color: colori.testo),
            ),
            TextSpan(
              text: testo(prima),
              style: AppTypography.corpo.copyWith(
                color: colori.testoSecondario,
                decoration: TextDecoration.lineThrough,
              ),
            ),
            TextSpan(
              text: ' → ',
              style: AppTypography.corpo.copyWith(
                color: colori.testoSecondario,
              ),
            ),
            TextSpan(
              text: testo(dopo),
              style: AppTypography.corpo.copyWith(color: colori.testo),
            ),
          ],
        ),
      ),
    );
  }
}

/// Una riga del confronto delle serie: «−» tolta, «+» aggiunta.
class _RigaCambiata extends StatelessWidget {
  const _RigaCambiata(this.riga);

  final RigaConfronto riga;

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    final (segno, colore, sfondo) = switch (riga.stato) {
      StatoRiga.tolta => ('−', colori.rosso, colori.rossoTenue),
      StatoRiga.aggiunta => ('+', colori.ok, colori.okTenue),
      StatoRiga.uguale => ('', colori.testoSecondario, null),
    };
    return Container(
      color: sfondo,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s12,
        vertical: 2,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 16,
            child: Text(
              segno,
              style: AppTypography.corpoForte.copyWith(color: colore),
            ),
          ),
          Expanded(
            child: Text(
              riga.testo,
              style: AppTypography.numerica(AppTypography.corpo).copyWith(
                color: riga.stato == StatoRiga.uguale
                    ? colori.testoSecondario
                    : colori.testo,
                decoration: riga.stato == StatoRiga.tolta
                    ? TextDecoration.lineThrough
                    : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// L'appello proposto: tutti gli attesi con lo stato, ognuno si cambia con
/// un tocco prima di salvare.
class _CartaAppello extends StatefulWidget {
  const _CartaAppello(
    this.proposta, {
    required this.atleti,
    required this.esito,
    required this.onConferma,
    required this.onScarta,
  });

  final PropostaAppello proposta;
  final List<Atleta> atleti;
  final _Esito esito;
  final ValueChanged<Map<String, String>> onConferma;
  final VoidCallback onScarta;

  @override
  State<_CartaAppello> createState() => _CartaAppelloState();
}

class _CartaAppelloState extends State<_CartaAppello> {
  late final _stati = {
    for (final r in widget.proposta.righe) r.atleta.id: r.proposto,
  };

  /// Prima le eccezioni (assenti, giustificati, in ritardo), poi i
  /// presenti; l'ordine resta quello anche cambiando uno stato, così le
  /// righe non saltano sotto il dito.
  late final _righe = [...widget.proposta.righe]
    ..sort((a, b) {
      final c = _ordine(a.proposto).compareTo(_ordine(b.proposto));
      return c != 0 ? c : _nome(a.atleta).compareTo(_nome(b.atleta));
    });

  static int _ordine(String stato) => switch (stato) {
    statoAssente => 0,
    statoGiustificato => 1,
    statoRitardo => 2,
    _ => 3,
  };

  String _nome(Atleta a) =>
      widget.atleti.isEmpty ? a.nomeCompleto : nomeBreve(a, widget.atleti);

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    final s = widget.proposta.allenamento;
    final titolo = s.titolo?.trim();
    int quanti(bool Function(String) vale) => _stati.values.where(vale).length;
    final presenti = quanti(contaComePresente);
    final ritardo = quanti((x) => x == statoRitardo);
    final assenti = quanti((x) => x == statoAssente);
    final giustificati = quanti((x) => x == statoGiustificato);
    final daDecidere = widget.esito == _Esito.daDecidere;
    return _Carta(
      icona: Icons.fact_check_outlined,
      titolo: [
        'Appello di ${dataEstesa(s.data)}',
        if (titolo != null && titolo.isNotEmpty) titolo,
      ].join(': '),
      figli: [
        Text(
          [
            '${presenti == 1 ? '1 presente' : '$presenti presenti'}'
                '${ritardo > 0 ? ' (di cui $ritardo in ritardo)' : ''}',
            if (assenti > 0) assenti == 1 ? '1 assente' : '$assenti assenti',
            if (giustificati > 0)
              giustificati == 1
                  ? '1 giustificato'
                  : '$giustificati giustificati',
          ].join(' · '),
          style: AppTypography.corpoForte.copyWith(color: colori.testo),
        ),
        const SizedBox(height: AppSpacing.s8),
        for (final r in _righe)
          Row(
            children: [
              Expanded(
                child: Text(
                  [
                    _nome(r.atleta),
                    if (r.daFuori) 'da un\'altra squadra',
                    if (r.attuale != null && !r.nominato) 'già segnato',
                  ].join(' · '),
                  style: AppTypography.corpo.copyWith(color: colori.testo),
                ),
              ),
              _MenuStato(
                key: Key('appello-${r.atleta.id}'),
                stato: _stati[r.atleta.id]!,
                onCambia: daDecidere
                    ? (nuovo) => setState(() => _stati[r.atleta.id] = nuovo)
                    : null,
              ),
            ],
          ),
        const SizedBox(height: AppSpacing.s12),
        _Decisione(
          esito: widget.esito,
          conferma: 'Salva l\'appello',
          fatto: 'Appello salvato',
          onConferma: () => widget.onConferma(Map.of(_stati)),
          onScarta: widget.onScarta,
          dopo: TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => PresenzeScreen(allenamento: s),
              ),
            ),
            child: const Text('Presenze'),
          ),
        ),
      ],
    );
  }
}

/// Lo stato di un atleta nell'appello, con il menu per cambiarlo: gli
/// stessi colori dei pulsanti delle presenze.
class _MenuStato extends StatelessWidget {
  const _MenuStato({required this.stato, required this.onCambia, super.key});

  final String stato;
  final ValueChanged<String>? onCambia;

  static IconData _icona(String stato) => switch (stato) {
    statoRitardo => Icons.schedule,
    statoAssente => Icons.close,
    statoGiustificato => Icons.event_note_outlined,
    _ => Icons.check,
  };

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    Color colore(String stato) => switch (stato) {
      statoRitardo => colori.azione,
      statoAssente => colori.testoSecondario,
      statoGiustificato => colori.attenzione,
      _ => colori.ok,
    };
    final etichetta = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(_icona(stato), size: 18, color: colore(stato)),
        const SizedBox(width: AppSpacing.s4),
        Text(
          etichettaStatoPresenza(stato),
          style: AppTypography.piccolo.copyWith(color: colore(stato)),
        ),
        if (onCambia != null)
          Icon(Icons.arrow_drop_down, size: 20, color: colori.testoSecondario),
      ],
    );
    return PopupMenuButton<String>(
      enabled: onCambia != null,
      tooltip: 'Cambia',
      initialValue: stato,
      onSelected: onCambia,
      itemBuilder: (_) => [
        for (final s in const [
          statoPresente,
          statoRitardo,
          statoAssente,
          statoGiustificato,
        ])
          PopupMenuItem(
            value: s,
            child: Row(
              children: [
                Icon(_icona(s), size: 18, color: colore(s)),
                const SizedBox(width: AppSpacing.s8),
                Text(etichettaStatoPresenza(s)),
              ],
            ),
          ),
      ],
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: AppSpacing.altezzaMinimaBersaglio,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s8),
          child: etichetta,
        ),
      ),
    );
  }
}

/// "dolore spalla 6/10, febbre": cosa ha segnato, in una voce sola.
String? _dettagli(RigaSalute r) {
  final voci = [
    if (r.scheda.dolori)
      'dolore ${r.scheda.zoneDolore.join(', ')}'
          '${r.scheda.intensitaDolore == null ? '' : ' ${r.scheda.intensitaDolore}/10'}',
    ...r.scheda.sintomi,
  ];
  return voci.isEmpty ? null : voci.join(', ');
}

/// Il benessere, calcolato e mostrato qui: all'AI non arriva.
class _CartaSalute extends StatelessWidget {
  const _CartaSalute(this.scheda, {required this.atleti});

  final SchedaSalute scheda;
  final List<Atleta> atleti;

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    String nome(Atleta a) =>
        atleti.isEmpty ? a.nomeCompleto : nomeBreve(a, atleti);
    return _Carta(
      icona: Icons.favorite_border,
      titolo: scheda.titolo,
      figli: [
        if (scheda.righe.isEmpty)
          Text(
            'Nessuno, nelle schede compilate.',
            style: AppTypography.corpo.copyWith(color: colori.testoSecondario),
          ),
        for (final r in scheda.righe)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.s8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${nome(r.atleta)} · ${r.punteggio.etichetta} '
                  '${r.punteggio.valore}',
                  style: AppTypography.corpoForte.copyWith(color: colori.testo),
                ),
                Text(
                  [traQuanto(r.giorno), ?_dettagli(r)].join(' · '),
                  style: AppTypography.piccolo.copyWith(
                    color: colori.testoSecondario,
                  ),
                ),
              ],
            ),
          ),
        if (scheda.senzaScheda.isNotEmpty)
          Text(
            'Senza scheda: ${scheda.senzaScheda.map(nome).join(', ')}',
            style: AppTypography.piccolo.copyWith(
              color: colori.testoSecondario,
            ),
          ),
        const SizedBox(height: AppSpacing.s8),
        Row(
          children: [
            Icon(Icons.lock_outline, size: 14, color: colori.testoTenue),
            const SizedBox(width: AppSpacing.s4),
            Expanded(
              child: Text(
                'Calcolato sul telefono: all\'AI non arriva.',
                style: AppTypography.piccolo.copyWith(color: colori.testoTenue),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
