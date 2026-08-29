import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../test/presentation/test_list_screen.dart';
import '../application/atleti_providers.dart';
import '../data/atleti_repository.dart';
import '../domain/atleta.dart';
import 'atleta_form_screen.dart';

class AtletiListScreen extends ConsumerStatefulWidget {
  const AtletiListScreen({required this.clubId, super.key});

  final String clubId;

  @override
  ConsumerState<AtletiListScreen> createState() => _AtletiListScreenState();
}

class _AtletiListScreenState extends ConsumerState<AtletiListScreen> {
  bool _mostraInattivi = false;

  @override
  Widget build(BuildContext context) {
    final filter = (clubId: widget.clubId, includeInactive: _mostraInattivi);
    final atletiAsync = ref.watch(atletiListProvider(filter));

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () =>
            ref.read(atletiRepositoryProvider).refreshFromRemote(widget.clubId),
        child: atletiAsync.when(
          data: (atleti) => _AtletiList(
            atleti: atleti,
            onTap: (atleta) => _apriForm(context, atleta: atleta),
            onTapTest: (atleta) => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => TestListScreen(atleta: atleta),
              ),
            ),
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => ListView(
            children: [
              Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Errore nel caricamento atleti: $error'),
              ),
            ],
          ),
        ),
      ),
      persistentFooterButtons: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Mostra atleti inattivi'),
          value: _mostraInattivi,
          onChanged: (value) => setState(() => _mostraInattivi = value),
        ),
      ],
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab-atleti',
        onPressed: () => _apriForm(context),
        tooltip: 'Nuovo atleta',
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _apriForm(BuildContext context, {Atleta? atleta}) async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) =>
            AtletaFormScreen(clubId: widget.clubId, atleta: atleta),
      ),
    );
  }
}

class _AtletiList extends StatelessWidget {
  const _AtletiList({
    required this.atleti,
    required this.onTap,
    required this.onTapTest,
  });

  final List<Atleta> atleti;
  final ValueChanged<Atleta> onTap;
  final ValueChanged<Atleta> onTapTest;

  @override
  Widget build(BuildContext context) {
    if (atleti.isEmpty) {
      return ListView(
        children: const [
          Padding(
            padding: EdgeInsets.all(32),
            child: Center(
              child: Text('Nessun atleta. Tocca "+" per aggiungerne uno.'),
            ),
          ),
        ],
      );
    }

    return ListView.separated(
      itemCount: atleti.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final atleta = atleti[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: atleta.attivo
                ? null
                : Theme.of(context).disabledColor,
            child: Text(
              atleta.nome.isNotEmpty ? atleta.nome[0].toUpperCase() : '?',
            ),
          ),
          title: Text(atleta.nomeCompleto),
          subtitle: Text(
            [
              atleta.sport == 'nuoto' ? 'Nuoto' : 'Pallanuoto',
              if (atleta.gruppo != null && atleta.gruppo!.isNotEmpty)
                atleta.gruppo!,
              if (!atleta.attivo) 'inattivo',
            ].join(' · '),
          ),
          trailing: IconButton(
            icon: const Icon(Icons.speed_outlined),
            tooltip: 'Test',
            onPressed: () => onTapTest(atleta),
          ),
          onTap: () => onTap(atleta),
        );
      },
    );
  }
}
