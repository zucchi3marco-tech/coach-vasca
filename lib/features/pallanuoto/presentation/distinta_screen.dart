import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';

import '../../../core/utils/error_messages.dart';
import '../../atleti/application/atleti_providers.dart';
import '../../atleti/domain/atleta.dart';
import '../application/pallanuoto_providers.dart';
import '../data/distinta_repository.dart';
import '../domain/distinta_giocatore.dart';
import '../domain/partita.dart';
import '../pdf/distinta_pdf.dart';
import 'eventi_partita_screen.dart';
import 'partita_form_screen.dart';

class DistintaScreen extends ConsumerWidget {
  const DistintaScreen({required this.partita, super.key});

  final Partita partita;

  String _formattaData(DateTime data) =>
      '${data.day.toString().padLeft(2, '0')}/'
      '${data.month.toString().padLeft(2, '0')}/'
      '${data.year}';

  String _sottotitoloConvocato(DistintaGiocatore g) {
    final tag = <String>[
      if (g.capitano) 'Capitano',
      if (g.viceCapitano) 'Vice capitano',
      if (g.portiere) 'Portiere',
      if (g.fuoriquota) 'Fuoriquota',
    ];
    return tag.join(' · ');
  }

  Future<void> _esporta(
    BuildContext context,
    WidgetRef ref,
    List<DistintaGiocatore> convocati,
    Map<String, Atleta> atletiPerId,
  ) async {
    final righe = [
      for (final g in convocati)
        (giocatore: g, atleta: atletiPerId[g.atletaId]),
    ]..removeWhere((r) => r.atleta == null);
    await Printing.layoutPdf(
      onLayout: (_) => generaDistintaPdf(
        partita: partita,
        convocati: [
          for (final r in righe) (giocatore: r.giocatore, atleta: r.atleta!),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final distintaAsync = ref.watch(distintaListProvider(partita.id));
    final atletiAsync = ref.watch(
      atletiListProvider((clubId: partita.clubId, includeInactive: false)),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('${partita.squadraCasa} - ${partita.squadraTrasferta}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.timeline),
            tooltip: 'Eventi partita',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => EventiPartitaScreen(partita: partita),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.ios_share),
            tooltip: 'Esporta distinta',
            onPressed: () {
              final convocati = distintaAsync.value;
              final atleti = atletiAsync.value;
              if (convocati == null || atleti == null) return;
              _esporta(
                context,
                ref,
                convocati,
                {for (final a in atleti) a.id: a},
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Modifica partita',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => PartitaFormScreen(
                  clubId: partita.clubId,
                  partita: partita,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_formattaData(partita.data)}'
                  '${partita.ora != null && partita.ora!.isNotEmpty ? ' · ${partita.ora}' : ''}'
                  '${partita.luogo != null && partita.luogo!.isNotEmpty ? ' · ${partita.luogo}' : ''}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (partita.campionato != null &&
                    partita.campionato!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(partita.campionato!),
                ],
                if (partita.coloreCalottina != null &&
                    partita.coloreCalottina!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text('Calottina: ${partita.coloreCalottina}'),
                ],
                const SizedBox(height: 8),
                distintaAsync.when(
                  data: (convocati) => Text(
                    '${convocati.length}/${partita.numeroMaxConvocati} convocati',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  loading: () => const SizedBox.shrink(),
                  error: (_, _) => const SizedBox.shrink(),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: distintaAsync.when(
              data: (convocati) => atletiAsync.when(
                data: (atleti) {
                  final atletiPerId = {for (final a in atleti) a.id: a};
                  if (convocati.isEmpty) {
                    return const Center(
                      child: Text(
                        'Nessun convocato. Tocca "+" per aggiungerne uno.',
                      ),
                    );
                  }
                  return ListView.separated(
                    itemCount: convocati.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final g = convocati[index];
                      final atleta = atletiPerId[g.atletaId];
                      return ListTile(
                        leading: CircleAvatar(
                          child: Text('${g.numeroCalottina}'),
                        ),
                        title: Text(atleta?.nomeCompleto ?? 'Atleta rimosso'),
                        subtitle: Text(
                          [
                            if (atleta?.numeroTesseraFin != null &&
                                atleta!.numeroTesseraFin!.isNotEmpty)
                              'Tessera ${atleta.numeroTesseraFin}',
                            _sottotitoloConvocato(g),
                          ].where((s) => s.isNotEmpty).join(' · '),
                        ),
                        onTap: () => showDialog<void>(
                          context: context,
                          builder: (_) => _DialogModificaConvocato(
                            partita: partita,
                            convocato: g,
                          ),
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(
                  child: Text('Errore nel caricamento atleti: ${messaggioErrore(error)}'),
                ),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Text(
                  'Errore nel caricamento distinta: ${messaggioErrore(error)}',
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: distintaAsync.maybeWhen(
        data: (convocati) => convocati.length >= partita.numeroMaxConvocati
            ? null
            : FloatingActionButton(
                heroTag: 'fab-distinta',
                tooltip: 'Aggiungi convocato',
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => _DialogSelezionaAtleta(
                    partita: partita,
                    convocatiEsistenti: convocati,
                  ),
                ),
                child: const Icon(Icons.add),
              ),
        orElse: () => null,
      ),
    );
  }
}

class _DialogSelezionaAtleta extends ConsumerWidget {
  const _DialogSelezionaAtleta({
    required this.partita,
    required this.convocatiEsistenti,
  });

  final Partita partita;
  final List<DistintaGiocatore> convocatiEsistenti;

  /// Il piu' piccolo numero di calottina (da 1 in su) non ancora usato in
  /// questa distinta: solo un suggerimento di partenza, l'allenatore puo'
  /// sempre cambiarlo dopo dal dettaglio del convocato.
  int get _prossimoNumeroLibero {
    final usati = convocatiEsistenti.map((g) => g.numeroCalottina).toSet();
    var numero = 1;
    while (usati.contains(numero)) {
      numero++;
    }
    return numero;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final atletiAsync = ref.watch(
      atletiListProvider((clubId: partita.clubId, includeInactive: false)),
    );
    final idGiaConvocati = convocatiEsistenti.map((g) => g.atletaId).toSet();
    return AlertDialog(
      title: const Text('Aggiungi convocato'),
      content: SizedBox(
        width: double.maxFinite,
        child: atletiAsync.when(
          data: (atleti) {
            final disponibili =
                atleti
                    .where(
                      (a) =>
                          a.sport == 'pallanuoto' &&
                          !idGiaConvocati.contains(a.id),
                    )
                    .toList()
                  ..sort((a, b) => a.cognome.compareTo(b.cognome));
            if (disponibili.isEmpty) {
              return const Text(
                'Nessun atleta di pallanuoto disponibile da convocare.',
              );
            }
            return SizedBox(
              height: 400,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: disponibili.length,
                itemBuilder: (context, index) {
                  final atleta = disponibili[index];
                  return ListTile(
                    title: Text(atleta.nomeCompleto),
                    onTap: () async {
                      final numero = _prossimoNumeroLibero;
                      Navigator.of(context).pop();
                      try {
                        await ref
                            .read(distintaRepositoryProvider)
                            .aggiungiConvocato(
                              partitaId: partita.id,
                              atletaId: atleta.id,
                              numeroCalottina: numero,
                            );
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                "Errore nell'aggiunta: ${messaggioErrore(e)}",
                              ),
                            ),
                          );
                        }
                      }
                    },
                  );
                },
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Text(messaggioErrore(error)),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Chiudi'),
        ),
      ],
    );
  }
}

class _DialogModificaConvocato extends ConsumerStatefulWidget {
  const _DialogModificaConvocato({
    required this.partita,
    required this.convocato,
  });

  final Partita partita;
  final DistintaGiocatore convocato;

  @override
  ConsumerState<_DialogModificaConvocato> createState() =>
      _DialogModificaConvocatoState();
}

class _DialogModificaConvocatoState
    extends ConsumerState<_DialogModificaConvocato> {
  late final TextEditingController _numeroController;
  late bool _capitano;
  late bool _viceCapitano;
  late bool _portiere;
  late bool _fuoriquota;
  bool _isSubmitting = false;
  String? _errore;

  @override
  void initState() {
    super.initState();
    _numeroController = TextEditingController(
      text: '${widget.convocato.numeroCalottina}',
    );
    _capitano = widget.convocato.capitano;
    _viceCapitano = widget.convocato.viceCapitano;
    _portiere = widget.convocato.portiere;
    _fuoriquota = widget.convocato.fuoriquota;
  }

  @override
  void dispose() {
    _numeroController.dispose();
    super.dispose();
  }

  Future<void> _salva() async {
    final numero = int.tryParse(_numeroController.text.trim());
    if (numero == null || numero <= 0) {
      setState(() => _errore = 'Numero di calottina non valido');
      return;
    }
    setState(() {
      _isSubmitting = true;
      _errore = null;
    });
    try {
      await ref
          .read(distintaRepositoryProvider)
          .aggiornaConvocato(
            id: widget.convocato.id,
            numeroCalottina: numero,
            capitano: _capitano,
            viceCapitano: _viceCapitano,
            portiere: _portiere,
            fuoriquota: _fuoriquota,
          );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) setState(() => _errore = messaggioErrore(e));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _rimuovi() async {
    setState(() => _isSubmitting = true);
    try {
      await ref
          .read(distintaRepositoryProvider)
          .rimuoviConvocato(widget.convocato.id);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        setState(() {
          _errore = messaggioErrore(e);
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Convocato'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _numeroController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'N. calottina'),
            ),
            const SizedBox(height: 8),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Capitano'),
              value: _capitano,
              onChanged: (v) => setState(() {
                _capitano = v ?? false;
                if (_capitano) _viceCapitano = false;
              }),
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Vice capitano'),
              value: _viceCapitano,
              onChanged: (v) => setState(() {
                _viceCapitano = v ?? false;
                if (_viceCapitano) _capitano = false;
              }),
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Portiere'),
              value: _portiere,
              onChanged: (v) => setState(() => _portiere = v ?? false),
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Fuoriquota'),
              value: _fuoriquota,
              onChanged: (v) => setState(() => _fuoriquota = v ?? false),
            ),
            if (_errore != null) ...[
              const SizedBox(height: 8),
              Text(
                _errore!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : _rimuovi,
          child: const Text('Rimuovi'),
        ),
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Annulla'),
        ),
        FilledButton(
          onPressed: _isSubmitting ? null : _salva,
          child: _isSubmitting
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Salva'),
        ),
      ],
    );
  }
}
