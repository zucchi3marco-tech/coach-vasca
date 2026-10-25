import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/error_messages.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../theme/colori_app.dart';
import '../../../widgets/app_scaffold.dart';
import '../../../widgets/cap_badge.dart';
import '../../../widgets/error_banner.dart';
import '../../../widgets/primary_button.dart';
import '../../atleti/domain/atleta.dart';
import '../data/distinta_repository.dart';
import '../domain/distinta_giocatore.dart';
import '../domain/numeri_distinta.dart';
import '../domain/partita.dart';
import 'capitani_distinta.dart';

/// Riordina i numeri di calottina trascinando le righe: il numero segue
/// la posizione. I due portieri restano fermi in cima, all'1 e al 13; gli
/// altri prendono i numeri dal 2 in su nell'ordine dell'elenco (vedi
/// `numeriInOrdine`). Si chiude con `true` se i numeri sono stati salvati.
class RiordinaNumeriScreen extends ConsumerStatefulWidget {
  const RiordinaNumeriScreen({
    required this.partita,
    required this.convocati,
    required this.atletiPerId,
    super.key,
  });

  final Partita partita;
  final List<DistintaGiocatore> convocati;
  final Map<String, Atleta> atletiPerId;

  @override
  ConsumerState<RiordinaNumeriScreen> createState() =>
      _RiordinaNumeriScreenState();
}

class _RiordinaNumeriScreenState extends ConsumerState<RiordinaNumeriScreen> {
  /// I primi due portieri, per numero: fermi in cima.
  late final List<DistintaGiocatore> _fissi;

  /// Tutti gli altri, nell'ordine in cui si vedono (all'inizio, per numero).
  late List<DistintaGiocatore> _ordine;
  late final List<String> _ordineIniziale;

  bool _salvataggio = false;
  bool _puoUscire = false;
  String? _errore;

  @override
  void initState() {
    super.initState();
    final tutti = [...widget.convocati]
      ..sort((a, b) => a.numeroCalottina.compareTo(b.numeroCalottina));
    _fissi = tutti
        .where((g) => g.portiere)
        .take(numeriPortieri.length)
        .toList();
    final idFissi = {for (final g in _fissi) g.id};
    _ordine = [
      for (final g in tutti)
        if (!idFissi.contains(g.id)) g,
    ];
    _ordineIniziale = [for (final g in _ordine) g.id];
  }

  /// Il numero di ognuno, con l'ordine di adesso.
  Map<String, int> get _numeri => numeriInOrdine(
    portieri: [for (final g in _fissi) g.id],
    altri: [for (final g in _ordine) g.id],
  );

  /// Solo chi cambia numero.
  Map<String, int> _cambi(Map<String, int> numeri) => {
    for (final g in widget.convocati)
      if (numeri[g.id] != null && numeri[g.id] != g.numeroCalottina)
        g.id: numeri[g.id]!,
  };

  /// Le righe sono state spostate rispetto a come erano.
  bool get _riordinato =>
      !listEquals([for (final g in _ordine) g.id], _ordineIniziale);

  void _sposta(int da, int a) {
    setState(() {
      final g = _ordine.removeAt(da);
      _ordine.insert(a, g);
    });
  }

  Future<void> _salva() async {
    final cambi = _cambi(_numeri);
    if (cambi.isEmpty || _salvataggio) return;
    setState(() {
      _salvataggio = true;
      _errore = null;
    });
    try {
      await ref
          .read(distintaRepositoryProvider)
          .rinumera(widget.partita.id, cambi);
      if (!mounted) return;
      setState(() {
        _puoUscire = true;
        _salvataggio = false;
      });
      Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _errore = messaggioErrore(e);
          _salvataggio = false;
        });
      }
    }
  }

  Future<void> _esci() async {
    if (_salvataggio) return;
    final esci = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Uscire senza salvare?'),
        content: const Text('I numeri che hai spostato andranno persi.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Resta'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: context.colori.rosso),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Esci senza salvare'),
          ),
        ],
      ),
    );
    if (esci == true && mounted) {
      setState(() => _puoUscire = true);
      Navigator.of(context).pop();
    }
  }

  Widget _riga(
    DistintaGiocatore g,
    Map<String, int> numeri, {
    int? indice,
    bool ultima = false,
  }) {
    return _RigaNumero(
      giocatore: g,
      numero: numeri[g.id] ?? g.numeroCalottina,
      nome: nomeConvocato(g, widget.atletiPerId),
      colore: coloreCalottinaDi(widget.partita, g),
      indice: indice,
      onSu: indice == null || indice == 0
          ? null
          : () => _sposta(indice, indice - 1),
      onGiu: indice == null || ultima
          ? null
          : () => _sposta(indice, indice + 1),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    final numeri = _numeri;
    final cambi = _cambi(numeri);
    final scuro = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: _puoUscire || (!_riordinato && !_salvataggio),
      onPopInvokedWithResult: (fatto, _) {
        if (!fatto) _esci();
      },
      child: AppScaffold(
        appBar: AppBar(title: const Text('Riordina i numeri')),
        // La barra in basso resta ferma: il pulsante c'è sempre, anche con
        // venti righe da scorrere. Livello 2 del DESIGN.md.
        bottomNavigationBar: DecoratedBox(
          decoration: BoxDecoration(
            color: scuro ? colori.superficieAlt : colori.superficie,
            border: Border(top: BorderSide(color: colori.linea)),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.s16,
                AppSpacing.s12,
                AppSpacing.s16,
                AppSpacing.s12,
              ),
              child: Center(
                heightFactor: 1,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_errore != null) ...[
                        ErrorBanner(
                          messaggio: 'Non è stato possibile salvare i numeri.',
                          suggerimento:
                              'Riprova. Se l\'errore continua, chiudi e '
                              'riapri l\'app.',
                          dettaglioTecnico: _errore,
                        ),
                        const SizedBox(height: AppSpacing.s12),
                      ],
                      PrimaryButton(
                        label: 'Salva i numeri',
                        isLoading: _salvataggio,
                        onPressed: cambi.isEmpty ? null : _salva,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        body: ReorderableListView.builder(
          buildDefaultDragHandles: false,
          padding: const EdgeInsets.only(bottom: AppSpacing.s16),
          // Il trascinamento si vede dal contorno, senza ombra.
          proxyDecorator: (figlio, indice, animazione) => Material(
            color: Colors.transparent,
            child: Container(
              foregroundDecoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.pannello),
                border: Border.all(color: colori.azione, width: 2),
              ),
              child: figlio,
            ),
          ),
          header: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Trascina le righe: il numero segue la posizione. '
                'I portieri restano all\'1 e al 13.',
                style: AppTypography.corpo.copyWith(
                  color: colori.testoSecondario,
                ),
              ),
              const SizedBox(height: AppSpacing.s16),
              for (final g in _fissi)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.s8),
                  child: _riga(g, numeri),
                ),
            ],
          ),
          itemCount: _ordine.length,
          onReorderItem: _sposta,
          itemBuilder: (context, indice) {
            final g = _ordine[indice];
            return Padding(
              key: ValueKey(g.id),
              padding: const EdgeInsets.only(bottom: AppSpacing.s8),
              child: _riga(
                g,
                numeri,
                indice: indice,
                ultima: indice == _ordine.length - 1,
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Una riga: maniglia (o lucchetto per i portieri fermi), calottina col
/// numero nuovo, nome, segni di capitano e vice e i due pulsanti per
/// spostare di un posto senza trascinare.
class _RigaNumero extends StatelessWidget {
  const _RigaNumero({
    required this.giocatore,
    required this.numero,
    required this.nome,
    required this.colore,
    required this.indice,
    required this.onSu,
    required this.onGiu,
  });

  final DistintaGiocatore giocatore;

  /// Il numero che avrà dopo il salvataggio.
  final int numero;
  final String nome;
  final CapColore colore;

  /// Il posto nell'elenco da trascinare; null per un portiere fermo.
  final int? indice;
  final VoidCallback? onSu;
  final VoidCallback? onGiu;

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    final fissa = indice == null;
    final cambia = numero != giocatore.numeroCalottina;
    return Container(
      constraints: const BoxConstraints(
        minHeight: AppSpacing.altezzaMinimaRiga,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s8,
        vertical: AppSpacing.s8,
      ),
      decoration: BoxDecoration(
        color: fissa ? colori.superficieAlt : colori.superficie,
        borderRadius: BorderRadius.circular(AppRadius.pannello),
        border: Border.all(color: colori.linea),
      ),
      child: Row(
        children: [
          if (fissa)
            Semantics(
              label: 'Portiere fermo',
              child: SizedBox(
                width: 32,
                child: Icon(
                  Icons.lock_outline,
                  size: 20,
                  color: colori.testoTenue,
                ),
              ),
            )
          else
            ReorderableDragStartListener(
              index: indice!,
              child: Semantics(
                label: 'Trascina per spostare',
                child: SizedBox(
                  width: 32,
                  height: AppSpacing.altezzaMinimaBersaglio,
                  child: Icon(
                    Icons.drag_indicator,
                    color: colori.testoSecondario,
                  ),
                ),
              ),
            ),
          const SizedBox(width: AppSpacing.s8),
          CapBadge(numero: numero, colore: colore),
          const SizedBox(width: AppSpacing.s12),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: AppSpacing.s8,
                  runSpacing: AppSpacing.s4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      nome,
                      style: AppTypography.corpoForte.copyWith(
                        color: colori.testo,
                      ),
                    ),
                    if (giocatore.capitano) const SegnoFascia.capitano(),
                    if (giocatore.viceCapitano) const SegnoFascia.vice(),
                  ],
                ),
                if (cambia)
                  Text(
                    'Era il ${giocatore.numeroCalottina}',
                    style: AppTypography.piccolo.copyWith(
                      color: colori.testoSecondario,
                    ),
                  ),
              ],
            ),
          ),
          if (!fissa) ...[
            _PulsanteSposta(
              icona: Icons.keyboard_arrow_up,
              etichetta: 'Sposta su',
              onPressed: onSu,
            ),
            _PulsanteSposta(
              icona: Icons.keyboard_arrow_down,
              etichetta: 'Sposta giù',
              onPressed: onGiu,
            ),
          ],
        ],
      ),
    );
  }
}

class _PulsanteSposta extends StatelessWidget {
  const _PulsanteSposta({
    required this.icona,
    required this.etichetta,
    required this.onPressed,
  });

  final IconData icona;
  final String etichetta;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: etichetta,
      onPressed: onPressed,
      icon: Icon(icona),
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.standard,
      constraints: const BoxConstraints(
        minWidth: 40,
        minHeight: AppSpacing.altezzaMinimaBersaglio,
      ),
    );
  }
}
