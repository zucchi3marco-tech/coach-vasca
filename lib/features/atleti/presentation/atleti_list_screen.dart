import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/error_messages.dart';
import '../../carico/presentation/carico_atleta_screen.dart';
import '../../statistiche/presentation/statistiche_atleta_screen.dart';
import '../../stroke_rate/presentation/stroke_rate_screen.dart';
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
            onTapCarico: (atleta) => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => CaricoAtletaScreen(atleta: atleta),
              ),
            ),
            onTapStatistiche: (atleta) => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => StatisticheAtletaScreen(atleta: atleta),
              ),
            ),
            onTapBracciate: (atleta) => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => StrokeRateScreen(atleta: atleta),
              ),
            ),
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => ListView(
            children: [
              Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Errore nel caricamento atleti: ${messaggioErrore(error)}'),
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
    required this.onTapCarico,
    required this.onTapStatistiche,
    required this.onTapBracciate,
  });

  final List<Atleta> atleti;
  final ValueChanged<Atleta> onTap;
  final ValueChanged<Atleta> onTapTest;
  final ValueChanged<Atleta> onTapCarico;
  final ValueChanged<Atleta> onTapStatistiche;
  final ValueChanged<Atleta> onTapBracciate;

  /// Il rilevamento bracciate usa la fotocamera + Google ML Kit: disponibile
  /// solo nell'app nativa Android/iOS, non nella versione web.
  static bool get _bracciateDisponibili =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

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
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.show_chart),
                tooltip: 'Carico',
                onPressed: () => onTapCarico(atleta),
              ),
              IconButton(
                icon: const Icon(Icons.query_stats),
                tooltip: 'Statistiche',
                onPressed: () => onTapStatistiche(atleta),
              ),
              IconButton(
                icon: const Icon(Icons.speed_outlined),
                tooltip: 'Test',
                onPressed: () => onTapTest(atleta),
              ),
              if (_bracciateDisponibili)
                IconButton(
                  icon: const Icon(Icons.camera_alt_outlined),
                  tooltip: 'Bracciate',
                  onPressed: () => onTapBracciate(atleta),
                ),
            ],
          ),
          onTap: () => onTap(atleta),
        );
      },
    );
  }
}
