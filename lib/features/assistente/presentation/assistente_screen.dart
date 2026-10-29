import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/condivisione/condividi_testo.dart';
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
import '../../../widgets/secondary_button.dart';
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
import '../../secco/data/secco_repository.dart';
import '../../secco/domain/esercizio_secco.dart';
import '../../secco/domain/programma_secco.dart';
import '../../secco/presentation/programma_secco_screen.dart';
import '../../secco/presentation/seduta_secco_screen.dart';
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
/// Com'è andata una proposta. [superata]: sostituita da una più nuova
/// sulla stessa seduta.
enum _Esito { daDecidere, inCorso, fatta, scartata, superata }

class _AssistenteScreenState extends ConsumerState<AssistenteScreen> {
  final _domanda = TextEditingController();
  final _scorrimento = ScrollController();
  final _voci = <VoceChat>[];
  final _esiti = <SchedaAssistente, _Esito>{};
  final _sedutaCreata = <SchedaAssistente, Allenamento>{};
  final _programmaCreato = <PropostaProgrammaSecco, ProgrammaSecco>{};
  final _modificaProvata = <SchedaAssistente>{};
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
        for (final v in risposta) {
          if (v is! VoceScheda || v.scheda is SchedaSalute) continue;
          // Una proposta nuova sulla stessa seduta prende il posto di quella
          // ancora da decidere (l'assistente l'ha corretta).
          if (_sedutaCambiata(v.scheda) case final id?) {
            for (final vecchia in _esiti.keys.toList()) {
              if (_sedutaCambiata(vecchia) == id &&
                  _esiti[vecchia] == _Esito.daDecidere) {
                _esiti[vecchia] = _Esito.superata;
              }
            }
          }
          _esiti[v.scheda] = _Esito.daDecidere;
        }
        _voci.addAll(risposta);
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

  /// La seduta che una proposta di modifica cambia.
  static String? _sedutaCambiata(SchedaAssistente s) => switch (s) {
    PropostaModificaSeduta(:final allenamento) ||
    PropostaModificaSecco(:final allenamento) => allenamento.id,
    _ => null,
  };

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
    _programmaCreato.clear();
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

  /// Come «Nuovo allenamento → A secco» più «Aggiungi esercizi»: la seduta
  /// per la squadra scelta, con gli esercizi nell'ordine proposto.
  Future<void> _creaSedutaSecco(PropostaSedutaSecco p) async {
    setState(() => _esiti[p] = _Esito.inCorso);
    try {
      final seduta = await ref
          .read(allenamentiRepositoryProvider)
          .createAllenamento(
            clubId: widget.clubId,
            data: p.data,
            titolo: p.titolo,
            gruppoId: widget.gruppoId,
            tipo: 'secco',
            durataMin: p.durataMin,
          );
      final secco = ref.read(seccoRepositoryProvider);
      for (final (i, d) in p.dosi.indexed) {
        await secco.aggiungiAllaSeduta(
          d.comeRiga(
            ordine: i + 1,
            allenamentoId: seduta.id,
            clubId: seduta.clubId,
          ),
        );
      }
      _motore?.annota(
        'Seduta a secco creata il ${formatDateOnly(p.data)} con '
        '${p.dosi.length} esercizi.',
      );
      if (mounted) {
        setState(() {
          _esiti[p] = _Esito.fatta;
          _sedutaCreata[p] = seduta;
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

  /// Il programma fra quelli del club: nel calendario lo mette
  /// l'allenatore, dal programma.
  Future<void> _creaProgramma(PropostaProgrammaSecco p) async {
    setState(() => _esiti[p] = _Esito.inCorso);
    try {
      final creato = await ref
          .read(seccoRepositoryProvider)
          .creaProgramma(
            ProgrammaSecco(
              id: '',
              clubId: widget.clubId,
              nome: p.programma.nome,
              descrizione: p.programma.descrizione,
              durataMin: p.programma.durataMin,
              settimane: p.programma.settimane,
            ),
          );
      _motore?.annota(
        'Programma a secco «${p.programma.nome}» creato fra quelli del '
        'club: ${p.programma.settimane.length} settimane. Non è ancora nel '
        'calendario.',
      );
      if (mounted) {
        setState(() {
          _esiti[p] = _Esito.fatta;
          _programmaCreato[p] = creato;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _esiti[p] = _Esito.daDecidere);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Programma non creato: ${messaggioErrore(e)}')),
      );
    }
  }

  /// Come la pagina della seduta a secco: tocca solo gli esercizi che
  /// cambiano (le serie fatte e le varianti restano sul loro esercizio),
  /// dopo aver controllato che la seduta sia ancora quella letta.
  Future<void> _salvaModificaSecco(PropostaModificaSecco p) async {
    final seduta = p.allenamento;
    setState(() => _esiti[p] = _Esito.inCorso);
    final secco = ref.read(seccoRepositoryProvider);
    try {
      final attuali = await secco.fetchSeduta(seduta.id);
      if (!_modificaProvata.contains(p) && !stessiEsercizi(attuali, p.righe)) {
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
      if (p.cambiaEsercizi) {
        final piano = pianoSecco(
          righe: attuali,
          dosi: p.dosi,
          allenamentoId: seduta.id,
          clubId: seduta.clubId,
          nuovoId: () => const Uuid().v4(),
        );
        for (final id in piano.elimina) {
          await secco.eliminaRiga(id);
        }
        for (final r in piano.aggiorna) {
          await secco.aggiornaRiga(r);
        }
        for (final r in piano.crea) {
          await secco.aggiungiAllaSeduta(r);
        }
      }
      if (p.cambiaTitolo || p.cambiaNote || p.cambiaDurata) {
        await ref
            .read(allenamentiRepositoryProvider)
            .updateAllenamento(
              originale: seduta,
              data: seduta.data,
              titolo: p.titolo,
              gruppoId: seduta.gruppoId,
              note: p.note,
              durataMin: p.durataMin,
            );
      }
      unawaited(sedutaSalvata(ref, seduta.id));
      _motore?.annota(
        'Modifiche salvate nella seduta a secco ${seduta.id}'
        '${p.cambiaEsercizi ? ': ora ha ${p.dosi.length} esercizi' : ''}.',
      );
      if (mounted) setState(() => _esiti[p] = _Esito.fatta);
    } catch (e) {
      if (!mounted) return;
      setState(() => _esiti[p] = _Esito.daDecidere);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Modifiche non salvate: ${messaggioErrore(e)}. Riprova: gli '
            'esercizi già salvati non si duplicano.',
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
    'Scrivi ai genitori che giovedì non c\'è allenamento',
    'Prepara 20\' di core e spalla a secco per venerdì',
    'Un programma a secco di 4 settimane per la spalla, 2 sedute da 20\'',
  ];

  /// Aperto dalla pagina di una seduta a secco.
  static const _esempiSecco = [
    'Togli l\'ultimo esercizio',
    'Una serie in più a tutti gli esercizi',
    'Cambia il titolo in «Spalla e core»',
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
                    esempi: switch (widget.seduta) {
                      null => _esempi,
                      final s when s.secco => _esempiSecco,
                      _ => _esempiSeduta,
                    },
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
                        PropostaSedutaSecco() => _CartaSedutaSecco(
                          scheda,
                          esito: _esiti[scheda] ?? _Esito.daDecidere,
                          apri: switch (_sedutaCreata[scheda]) {
                            final creata? => () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) =>
                                    SedutaSeccoScreen(allenamento: creata),
                              ),
                            ),
                            null => null,
                          },
                          onConferma: () => _creaSedutaSecco(scheda),
                          onScarta: () => _scarta(scheda),
                        ),
                        PropostaProgrammaSecco() => _CartaProgrammaSecco(
                          scheda,
                          esito: _esiti[scheda] ?? _Esito.daDecidere,
                          apri: switch (_programmaCreato[scheda]) {
                            final creato? => () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => ProgrammaSeccoScreen(
                                  clubId: widget.clubId,
                                  programmaId: creato.id,
                                ),
                              ),
                            ),
                            null => null,
                          },
                          onConferma: () => _creaProgramma(scheda),
                          onScarta: () => _scarta(scheda),
                        ),
                        PropostaModificaSecco() => _CartaModificaSecco(
                          scheda,
                          esito: _esiti[scheda] ?? _Esito.daDecidere,
                          apri: widget.seduta?.id == scheda.allenamento.id
                              ? null
                              : () => Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => SedutaSeccoScreen(
                                      allenamento: scheda.allenamento,
                                    ),
                                  ),
                                ),
                          onConferma: () => _salvaModificaSecco(scheda),
                          onScarta: () => _scarta(scheda),
                        ),
                        PropostaMessaggioFamiglie() => _CartaMessaggioFamiglie(
                          scheda,
                          onPreso: () => _motore?.annota(
                            'L\'allenatore ha preso il messaggio per le '
                            'famiglie (Condividi o Copia), forse dopo averlo '
                            'corretto.',
                          ),
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
                    'sedute anche a secco, programmi a secco e messaggi per i '
                    'genitori, e cambia le sedute che ci sono: ogni proposta '
                    'la controlli e la confermi tu.'
              : seduta!.secco
              ? 'Di\' cosa cambiare: esercizi, titolo, note o durata. Ti '
                    'mostra prima e dopo, e salvi tu; le varianti degli atleti '
                    'restano sul loro esercizio.'
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
      _Esito.superata => Text(
        'Sostituita dalla proposta più sotto',
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

/// Il messaggio per il gruppo dei genitori: si corregge nel campo e si
/// manda con Condividi o Copia, come la convocazione. Non si salva.
class _CartaMessaggioFamiglie extends StatefulWidget {
  const _CartaMessaggioFamiglie(this.proposta, {required this.onPreso});

  final PropostaMessaggioFamiglie proposta;

  /// Condiviso o copiato (la prima volta).
  final VoidCallback onPreso;

  @override
  State<_CartaMessaggioFamiglie> createState() =>
      _CartaMessaggioFamiglieState();
}

class _CartaMessaggioFamiglieState extends State<_CartaMessaggioFamiglie>
    with AutomaticKeepAliveClientMixin {
  late final _testo = TextEditingController(text: widget.proposta.testo);
  var _preso = false;

  // Le correzioni restano anche scorrendo la chat.
  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _testo.dispose();
    super.dispose();
  }

  void _segnaPreso() {
    if (_preso) return;
    _preso = true;
    widget.onPreso();
  }

  Future<void> _condividi() async {
    final testo = _testo.text.trim();
    if (testo.isEmpty) return;
    _segnaPreso();
    if (await condividiTesto(testo)) return;
    await _copia();
  }

  Future<void> _copia() async {
    final testo = _testo.text.trim();
    if (testo.isEmpty) return;
    _segnaPreso();
    await Clipboard.setData(ClipboardData(text: testo));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Messaggio copiato: incollalo nel gruppo WhatsApp'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final colori = context.colori;
    return _Carta(
      icona: Icons.chat_outlined,
      titolo: 'Messaggio per le famiglie',
      figli: [
        TextField(
          key: const Key('messaggio-famiglie'),
          controller: _testo,
          minLines: 3,
          maxLines: 14,
          keyboardType: TextInputType.multiline,
          style: AppTypography.corpo.copyWith(color: colori.testo),
          decoration: const InputDecoration(
            helperText: 'Puoi correggerlo prima di mandarlo',
          ),
        ),
        const SizedBox(height: AppSpacing.s12),
        Row(
          children: [
            Expanded(
              child: SecondaryButton(
                label: 'Condividi',
                icon: Icons.share_outlined,
                unaRiga: true,
                onPressed: _condividi,
              ),
            ),
            const SizedBox(width: AppSpacing.s12),
            Expanded(
              child: SecondaryButton(
                label: 'Copia',
                icon: Icons.copy_outlined,
                unaRiga: true,
                onPressed: _copia,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.s8),
        Text(
          'L\'app non lo manda e non lo salva: lo incolli tu nel gruppo dei '
          'genitori.',
          style: AppTypography.piccolo.copyWith(color: colori.testoSecondario),
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

/// Gli esercizi a secco di una seduta proposta, numerati: nome e dose.
class _EserciziSecco extends StatelessWidget {
  const _EserciziSecco(this.dosi, {required this.esercizi});

  final List<DoseEsercizio> dosi;
  final Map<String, EsercizioSecco> esercizi;

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.s12),
      decoration: BoxDecoration(
        color: colori.superficieAlt,
        borderRadius: BorderRadius.circular(AppRadius.controllo),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final (i, d) in dosi.indexed)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.s4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 24,
                    child: Text(
                      '${i + 1}',
                      style: AppTypography.numerica(AppTypography.corpo)
                          .copyWith(color: colori.testoSecondario),
                    ),
                  ),
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: esercizi[d.esercizioId]?.nome ?? 'Esercizio',
                            style: AppTypography.corpoForte.copyWith(
                              color: colori.testo,
                            ),
                          ),
                          TextSpan(
                            text:
                                '  ${prescrizioneEsercizio(d.comeRiga(ordine: i + 1))}',
                            style: AppTypography.corpo.copyWith(
                              color: colori.testoSecondario,
                            ),
                          ),
                          if (d.note case final n? when n.trim().isNotEmpty)
                            TextSpan(
                              text: ' · $n',
                              style: AppTypography.corpo.copyWith(
                                color: colori.testoSecondario,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _CartaSedutaSecco extends StatelessWidget {
  const _CartaSedutaSecco(
    this.proposta, {
    required this.esito,
    required this.apri,
    required this.onConferma,
    required this.onScarta,
  });

  final PropostaSedutaSecco proposta;
  final _Esito esito;
  final VoidCallback? apri;
  final VoidCallback onConferma;
  final VoidCallback onScarta;

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    final p = proposta;
    final stima = minutiDosi(p.dosi);
    return _Carta(
      icona: Icons.fitness_center,
      titolo: ['Seduta a secco di ${dataEstesa(p.data)}', ?p.titolo].join(': '),
      figli: [
        _EserciziSecco(p.dosi, esercizi: p.esercizi),
        const SizedBox(height: AppSpacing.s8),
        Text(
          [
            p.dosi.length == 1 ? '1 esercizio' : '${p.dosi.length} esercizi',
            "durata ${p.durataMin}'",
            if ((stima - p.durataMin).abs() >= 5)
              "fatti come scritto circa $stima'",
          ].join(' · '),
          style: AppTypography.piccolo.copyWith(color: colori.testoSecondario),
        ),
        const SizedBox(height: AppSpacing.s12),
        _Decisione(
          esito: esito,
          conferma: 'Crea la seduta',
          fatto: 'Seduta a secco creata',
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

/// Il programma proposto: le sedute della prima settimana, come cresce e
/// le settimane di scarico.
class _CartaProgrammaSecco extends StatelessWidget {
  const _CartaProgrammaSecco(
    this.proposta, {
    required this.esito,
    required this.apri,
    required this.onConferma,
    required this.onScarta,
  });

  final PropostaProgrammaSecco proposta;
  final _Esito esito;
  final VoidCallback? apri;
  final VoidCallback onConferma;
  final VoidCallback onScarta;

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    final p = proposta.programma;
    final prima = p.settimane.first;
    final quante = prima.sedute.length;
    final scarico = proposta.scarico;
    final piccolo = AppTypography.piccolo.copyWith(
      color: colori.testoSecondario,
    );
    return _Carta(
      icona: Icons.event_repeat,
      titolo: 'Programma a secco «${p.nome}»',
      figli: [
        if (p.descrizione case final d? when d.isNotEmpty) ...[
          Text(d, style: AppTypography.corpo.copyWith(color: colori.testo)),
          const SizedBox(height: AppSpacing.s8),
        ],
        Text(
          [
            p.settimane.length == 1
                ? '1 settimana'
                : '${p.settimane.length} settimane',
            quante == 1 ? '1 seduta a settimana' : '$quante sedute a settimana',
            "da ${p.durataMin}'",
            if (scarico.isNotEmpty)
              'scarico ${scarico.length == 1 ? 'la' : 'le'} '
                  '${scarico.map((w) => '$wª').join(', ')}',
          ].join(' · '),
          style: AppTypography.corpoForte.copyWith(color: colori.testo),
        ),
        const SizedBox(height: AppSpacing.s12),
        Text('Settimana 1', style: piccolo),
        const SizedBox(height: AppSpacing.s4),
        for (final (i, seduta) in prima.sedute.indexed) ...[
          if (quante > 1) ...[
            Text(
              nomeSeduta(i, quante),
              style: AppTypography.corpoForte.copyWith(color: colori.testo),
            ),
            const SizedBox(height: AppSpacing.s4),
          ],
          _EserciziSecco(seduta, esercizi: proposta.esercizi),
          const SizedBox(height: AppSpacing.s8),
        ],
        Text(
          'Poi ogni settimana un po\' di più: una serie in più fino a 4, poi '
          'qualche ripetizione o qualche secondo (la mobilità resta com\'è)'
          '${scarico.isEmpty ? '' : '; nello scarico una serie in meno'}. '
          'Dopo averlo creato puoi cambiare ogni settimana e metterlo nel '
          'calendario della squadra.',
          style: piccolo,
        ),
        const SizedBox(height: AppSpacing.s12),
        _Decisione(
          esito: esito,
          conferma: 'Crea il programma',
          fatto: 'Programma creato',
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

/// Le modifiche a una seduta a secco: titolo, note e durata che cambiano e
/// gli esercizi riga per riga, i tolti in rosso e gli aggiunti in verde.
class _CartaModificaSecco extends StatelessWidget {
  const _CartaModificaSecco(
    this.proposta, {
    required this.esito,
    required this.apri,
    required this.onConferma,
    required this.onScarta,
  });

  final PropostaModificaSecco proposta;
  final _Esito esito;
  final VoidCallback? apri;
  final VoidCallback onConferma;
  final VoidCallback onScarta;

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    final p = proposta;
    final a = p.allenamento;
    String quanti(int n) => n == 1 ? '1 esercizio' : '$n esercizi';
    String? minuti(int? m) => m == null ? null : "$m'";
    final prima = p.principaliPrima.length;
    return _Carta(
      icona: Icons.edit_note,
      titolo: 'Modifiche a «${a.titoloMostrato}» di ${dataEstesa(a.data)}',
      figli: [
        if (p.cambiaTitolo)
          _Cambio(etichetta: 'Titolo', prima: a.titolo, dopo: p.titolo),
        if (p.cambiaNote)
          _Cambio(etichetta: 'Note', prima: a.note, dopo: p.note),
        if (p.cambiaDurata)
          _Cambio(
            etichetta: 'Durata',
            prima: minuti(a.durataMin),
            dopo: minuti(p.durataMin),
          ),
        if (p.cambiaEsercizi) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.s8),
            decoration: BoxDecoration(
              color: colori.superficieAlt,
              borderRadius: BorderRadius.circular(AppRadius.controllo),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [for (final r in p.confronto) _RigaCambiata(r)],
            ),
          ),
          const SizedBox(height: AppSpacing.s8),
          Text(
            prima == p.dosi.length
                ? quanti(prima)
                : '${quanti(prima)} → ${quanti(p.dosi.length)}',
            style: AppTypography.piccolo.copyWith(
              color: colori.testoSecondario,
            ),
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
