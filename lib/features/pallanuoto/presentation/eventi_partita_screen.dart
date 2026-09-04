import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/error_messages.dart';
import '../../atleti/application/atleti_providers.dart';
import '../../atleti/domain/atleta.dart';
import '../application/pallanuoto_providers.dart';
import '../data/eventi_partita_repository.dart';
import '../domain/evento_partita.dart';
import '../domain/partita.dart';

const _esitiTiroSemplice = [('gol', 'Gol'), ('non_gol', 'Non gol')];
const _esitiTiroDettagliato = [
  ('gol', 'Gol'),
  ('parato', 'Parato'),
  ('palo_fuori', 'Palo/fuori'),
];
const _esitiSuperiorita = [('gol', 'Gol'), ('non_gol', 'Non gol')];
const _contestiTiro = [
  ('azione', 'Azione'),
  ('superiorita', 'Superiorità'),
  ('rigore', 'Rigore'),
];

String _etichettaContesto(String contesto) {
  switch (contesto) {
    case 'superiorita':
      return 'superiorità';
    case 'rigore':
      return 'rigore';
    default:
      return '';
  }
}

String _etichettaEsito(String? esito) {
  switch (esito) {
    case 'gol':
      return 'Gol';
    case 'non_gol':
      return 'Non gol';
    case 'parato':
      return 'Parato';
    case 'palo_fuori':
      return 'Palo/fuori';
    default:
      return 'In corso';
  }
}

class EventiPartitaScreen extends ConsumerWidget {
  const EventiPartitaScreen({required this.partita, super.key});

  final Partita partita;

  String _descrizione(EventoPartita e, Map<String, Atleta> atletiPerId) {
    final tempo = e.periodo != null ? ' (T${e.periodo})' : '';
    switch (e.tipo) {
      case 'tiro':
        final nome = atletiPerId[e.atletaId]?.nomeCompleto ?? 'Atleta rimosso';
        final contesto = _etichettaContesto(e.contestoTiro);
        final suffisso = contesto.isEmpty ? '' : ' ($contesto)';
        return 'Tiro — $nome — ${_etichettaEsito(e.esito)}$suffisso$tempo';
      case 'espulsione':
        final nome = atletiPerId[e.atletaId]?.nomeCompleto ?? 'Atleta rimosso';
        return 'Espulsione — $nome$tempo';
      case 'superiorita':
        final squadra = e.squadra == 'nostra' ? 'nostra' : 'avversaria';
        return 'Superiorità $squadra — ${_etichettaEsito(e.esito)}$tempo';
      default:
        return e.tipo;
    }
  }

  IconData _icona(EventoPartita e) {
    switch (e.tipo) {
      case 'tiro':
        return Icons.sports_handball_outlined;
      case 'espulsione':
        return Icons.warning_amber_outlined;
      case 'superiorita':
        return e.squadra == 'nostra'
            ? Icons.trending_up
            : Icons.trending_down;
      default:
        return Icons.circle_outlined;
    }
  }

  Future<void> _onTap(
    BuildContext context,
    WidgetRef ref,
    EventoPartita evento,
  ) async {
    if (evento.tipo == 'superiorita' && evento.esito == null) {
      await showDialog<void>(
        context: context,
        builder: (_) => _DialogConcludiSuperiorita(evento: evento),
      );
      return;
    }
    final conferma = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminare l\'evento?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annulla'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Elimina'),
          ),
        ],
      ),
    );
    if (conferma == true) {
      try {
        await ref
            .read(eventiPartitaRepositoryProvider)
            .eliminaEvento(evento.id);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(messaggioErrore(e))));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventiAsync = ref.watch(eventiPartitaListProvider(partita.id));
    final convocatiAsync = ref.watch(distintaListProvider(partita.id));
    final atletiAsync = ref.watch(
      atletiListProvider((clubId: partita.clubId, includeInactive: false)),
    );

    final atletiPerId = {
      for (final a in atletiAsync.value ?? const <Atleta>[]) a.id: a,
    };
    final convocatiAtleti =
        (convocatiAsync.value ?? [])
            .map((g) => atletiPerId[g.atletaId])
            .whereType<Atleta>()
            .toList()
          ..sort((a, b) => a.cognome.compareTo(b.cognome));

    return Scaffold(
      appBar: AppBar(
        title: Text('Eventi — ${partita.squadraCasa} - ${partita.squadraTrasferta}'),
      ),
      body: Column(
        children: [
          Expanded(
            child: eventiAsync.when(
              data: (eventi) => eventi.isEmpty
                  ? const Center(
                      child: Text('Nessun evento. Usa i pulsanti sotto.'),
                    )
                  : ListView.separated(
                      itemCount: eventi.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final e = eventi[index];
                        return ListTile(
                          leading: Icon(_icona(e)),
                          title: Text(_descrizione(e, atletiPerId)),
                          trailing:
                              e.tipo == 'superiorita' && e.esito == null
                              ? const Text('Concludi')
                              : null,
                          onTap: () => _onTap(context, ref, e),
                        );
                      },
                    ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) =>
                  Center(child: Text(messaggioErrore(error))),
            ),
          ),
          const Divider(height: 1),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.icon(
                    onPressed: convocatiAtleti.isEmpty
                        ? null
                        : () => showDialog<void>(
                            context: context,
                            builder: (_) => _DialogRegistraTiro(
                              partita: partita,
                              convocati: convocatiAtleti,
                            ),
                          ),
                    icon: const Icon(Icons.sports_handball_outlined),
                    label: const Text('Tiro'),
                  ),
                  FilledButton.icon(
                    onPressed: convocatiAtleti.isEmpty
                        ? null
                        : () => showDialog<void>(
                            context: context,
                            builder: (_) => _DialogRegistraEspulsione(
                              partita: partita,
                              convocati: convocatiAtleti,
                            ),
                          ),
                    icon: const Icon(Icons.warning_amber_outlined),
                    label: const Text('Espulsione'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => showDialog<void>(
                      context: context,
                      builder: (_) => _DialogRegistraSuperiorita(
                        partita: partita,
                        squadra: 'nostra',
                      ),
                    ),
                    icon: const Icon(Icons.trending_up),
                    label: const Text('Sup. nostra'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => showDialog<void>(
                      context: context,
                      builder: (_) => _DialogRegistraSuperiorita(
                        partita: partita,
                        squadra: 'avversaria',
                      ),
                    ),
                    icon: const Icon(Icons.trending_down),
                    label: const Text('Sup. avversaria'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Selettore di tempo (1-4), mostrato solo se la partita traccia il tempo.
class _SelettorePeriodo extends StatelessWidget {
  const _SelettorePeriodo({required this.value, required this.onChanged});

  final int? value;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<int>(
      initialValue: value,
      decoration: const InputDecoration(labelText: 'Tempo'),
      items: [
        for (var t = 1; t <= 4; t++)
          DropdownMenuItem(value: t, child: Text('Tempo $t')),
      ],
      onChanged: onChanged,
    );
  }
}

class _DialogRegistraTiro extends ConsumerStatefulWidget {
  const _DialogRegistraTiro({required this.partita, required this.convocati});

  final Partita partita;
  final List<Atleta> convocati;

  @override
  ConsumerState<_DialogRegistraTiro> createState() =>
      _DialogRegistraTiroState();
}

class _DialogRegistraTiroState extends ConsumerState<_DialogRegistraTiro> {
  String? _atletaId;
  String? _esito;
  String _contesto = 'azione';
  int? _periodo;
  bool _isSubmitting = false;
  String? _errore;

  List<(String, String)> get _opzioniEsito =>
      widget.partita.dettaglioTiro == 'dettagliato'
      ? _esitiTiroDettagliato
      : _esitiTiroSemplice;

  Future<void> _salva() async {
    if (_atletaId == null || _esito == null) {
      setState(() => _errore = 'Seleziona atleta ed esito');
      return;
    }
    setState(() {
      _isSubmitting = true;
      _errore = null;
    });
    try {
      await ref
          .read(eventiPartitaRepositoryProvider)
          .registraTiro(
            partitaId: widget.partita.id,
            atletaId: _atletaId!,
            esito: _esito!,
            periodo: _periodo,
            contestoTiro: _contesto,
          );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) setState(() => _errore = messaggioErrore(e));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Registra tiro'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<String>(
              initialValue: _atletaId,
              decoration: const InputDecoration(labelText: 'Atleta'),
              items: [
                for (final a in widget.convocati)
                  DropdownMenuItem(value: a.id, child: Text(a.nomeCompleto)),
              ],
              onChanged: (v) => setState(() => _atletaId = v),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                for (final (valore, etichetta) in _opzioniEsito)
                  ChoiceChip(
                    label: Text(etichetta),
                    selected: _esito == valore,
                    onSelected: (_) => setState(() => _esito = valore),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Contesto',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              children: [
                for (final (valore, etichetta) in _contestiTiro)
                  ChoiceChip(
                    label: Text(etichetta),
                    selected: _contesto == valore,
                    onSelected: (_) => setState(() => _contesto = valore),
                  ),
              ],
            ),
            if (widget.partita.tracciaTempo) ...[
              const SizedBox(height: 12),
              _SelettorePeriodo(
                value: _periodo,
                onChanged: (v) => setState(() => _periodo = v),
              ),
            ],
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
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Annulla'),
        ),
        FilledButton(
          onPressed: _isSubmitting ? null : _salva,
          child: const Text('Salva'),
        ),
      ],
    );
  }
}

class _DialogRegistraEspulsione extends ConsumerStatefulWidget {
  const _DialogRegistraEspulsione({
    required this.partita,
    required this.convocati,
  });

  final Partita partita;
  final List<Atleta> convocati;

  @override
  ConsumerState<_DialogRegistraEspulsione> createState() =>
      _DialogRegistraEspulsioneState();
}

class _DialogRegistraEspulsioneState
    extends ConsumerState<_DialogRegistraEspulsione> {
  String? _atletaId;
  int? _periodo;
  bool _isSubmitting = false;
  String? _errore;

  Future<void> _salva() async {
    if (_atletaId == null) {
      setState(() => _errore = 'Seleziona un atleta');
      return;
    }
    setState(() {
      _isSubmitting = true;
      _errore = null;
    });
    try {
      await ref
          .read(eventiPartitaRepositoryProvider)
          .registraEspulsione(
            partitaId: widget.partita.id,
            atletaId: _atletaId!,
            periodo: _periodo,
          );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) setState(() => _errore = messaggioErrore(e));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Registra espulsione'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<String>(
              initialValue: _atletaId,
              decoration: const InputDecoration(labelText: 'Atleta'),
              items: [
                for (final a in widget.convocati)
                  DropdownMenuItem(value: a.id, child: Text(a.nomeCompleto)),
              ],
              onChanged: (v) => setState(() => _atletaId = v),
            ),
            if (widget.partita.tracciaTempo) ...[
              const SizedBox(height: 12),
              _SelettorePeriodo(
                value: _periodo,
                onChanged: (v) => setState(() => _periodo = v),
              ),
            ],
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
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Annulla'),
        ),
        FilledButton(
          onPressed: _isSubmitting ? null : _salva,
          child: const Text('Salva'),
        ),
      ],
    );
  }
}

class _DialogRegistraSuperiorita extends ConsumerStatefulWidget {
  const _DialogRegistraSuperiorita({
    required this.partita,
    required this.squadra,
  });

  final Partita partita;
  final String squadra; // nostra | avversaria

  @override
  ConsumerState<_DialogRegistraSuperiorita> createState() =>
      _DialogRegistraSuperioritaState();
}

class _DialogRegistraSuperioritaState
    extends ConsumerState<_DialogRegistraSuperiorita> {
  String? _esito;
  int? _periodo;
  bool _isSubmitting = false;
  String? _errore;

  bool get _esitoSubito => widget.partita.modalitaSuperiorita == 'singolo';

  Future<void> _salva() async {
    if (_esitoSubito && _esito == null) {
      setState(() => _errore = 'Seleziona l\'esito');
      return;
    }
    setState(() {
      _isSubmitting = true;
      _errore = null;
    });
    try {
      await ref
          .read(eventiPartitaRepositoryProvider)
          .registraSuperiorita(
            partitaId: widget.partita.id,
            squadra: widget.squadra,
            esito: _esitoSubito ? _esito : null,
            periodo: _periodo,
          );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) setState(() => _errore = messaggioErrore(e));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final titolo = widget.squadra == 'nostra'
        ? 'Superiorità nostra'
        : 'Superiorità avversaria';
    return AlertDialog(
      title: Text(titolo),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_esitoSubito)
              Wrap(
                spacing: 8,
                children: [
                  for (final (valore, etichetta) in _esitiSuperiorita)
                    ChoiceChip(
                      label: Text(etichetta),
                      selected: _esito == valore,
                      onSelected: (_) => setState(() => _esito = valore),
                    ),
                ],
              )
            else
              const Text(
                'Registrata come "in corso": la concludi più tardi '
                'toccandola nella lista.',
              ),
            if (widget.partita.tracciaTempo) ...[
              const SizedBox(height: 12),
              _SelettorePeriodo(
                value: _periodo,
                onChanged: (v) => setState(() => _periodo = v),
              ),
            ],
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
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Annulla'),
        ),
        FilledButton(
          onPressed: _isSubmitting ? null : _salva,
          child: const Text('Salva'),
        ),
      ],
    );
  }
}

class _DialogConcludiSuperiorita extends ConsumerStatefulWidget {
  const _DialogConcludiSuperiorita({required this.evento});

  final EventoPartita evento;

  @override
  ConsumerState<_DialogConcludiSuperiorita> createState() =>
      _DialogConcludiSuperioritaState();
}

class _DialogConcludiSuperioritaState
    extends ConsumerState<_DialogConcludiSuperiorita> {
  String? _esito;
  bool _isSubmitting = false;
  String? _errore;

  Future<void> _salva() async {
    if (_esito == null) {
      setState(() => _errore = 'Seleziona l\'esito');
      return;
    }
    setState(() {
      _isSubmitting = true;
      _errore = null;
    });
    try {
      await ref
          .read(eventiPartitaRepositoryProvider)
          .concludiSuperiorita(id: widget.evento.id, esito: _esito!);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) setState(() => _errore = messaggioErrore(e));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Concludi superiorità'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Wrap(
            spacing: 8,
            children: [
              for (final (valore, etichetta) in _esitiSuperiorita)
                ChoiceChip(
                  label: Text(etichetta),
                  selected: _esito == valore,
                  onSelected: (_) => setState(() => _esito = valore),
                ),
            ],
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
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Annulla'),
        ),
        FilledButton(
          onPressed: _isSubmitting ? null : _salva,
          child: const Text('Salva'),
        ),
      ],
    );
  }
}
