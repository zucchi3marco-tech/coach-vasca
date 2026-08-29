import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/pace_format.dart';
import '../../presenze/presentation/presenze_screen.dart';
import '../application/allenamenti_providers.dart';
import '../domain/allenamento.dart';
import '../domain/serie.dart';
import 'serie_labels.dart';

const _accento = Color(0xFFFFC107);

/// Vista pensata per un tablet fissato a bordo vasca: sfondo nero, testo
/// grande e ad alto contrasto (leggibile con luce solare diretta),
/// orientamento forzato landscape. Solo lettura: la modifica della
/// scheda resta nella schermata di dettaglio "da ufficio".
class SchedaBordoVascaScreen extends ConsumerStatefulWidget {
  const SchedaBordoVascaScreen({required this.allenamento, super.key});

  final Allenamento allenamento;

  @override
  ConsumerState<SchedaBordoVascaScreen> createState() =>
      _SchedaBordoVascaScreenState();
}

class _SchedaBordoVascaScreenState
    extends ConsumerState<SchedaBordoVascaScreen> {
  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    super.dispose();
  }

  String _sottotitoloSerie(Serie s) {
    final parti = <String>[];
    if (s.zona != null) parti.add('zona ${s.zona}');
    if (s.passoObiettivoS != null) {
      parti.add('${formatPaceSeconds(s.passoObiettivoS!)}/100m');
    }
    if (s.recuperoS != null) parti.add("rec ${s.recuperoS}''");
    if (s.ripartenzaS != null) {
      parti.add('rip ${formatPaceSeconds(s.ripartenzaS!)}');
    }
    return parti.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final allenamento = widget.allenamento;
    final serieAsync = ref.watch(serieListProvider(allenamento.id));

    return Theme(
      data: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        colorScheme: const ColorScheme.dark(
          surface: Colors.black,
          primary: _accento,
          onPrimary: Colors.black,
        ),
      ),
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          title: Text(
            '${allenamento.data.day.toString().padLeft(2, '0')}/'
            '${allenamento.data.month.toString().padLeft(2, '0')}/'
            '${allenamento.data.year}'
            '${allenamento.gruppo != null && allenamento.gruppo!.isNotEmpty ? ' · ${allenamento.gruppo}' : ''}',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ),
        body: SafeArea(
          child: serieAsync.when(
            data: (serie) => serie.isEmpty
                ? const Center(
                    child: Text(
                      'Nessuna serie in questo allenamento.',
                      style: TextStyle(color: Colors.white70, fontSize: 22),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: serie.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final s = serie[index];
                      final sottotitolo = _sottotitoloSerie(s);
                      return Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.white24,
                            width: 1.5,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              labelBlocco(s.blocco).toUpperCase(),
                              style: const TextStyle(
                                color: _accento,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${s.ripetute}×${s.distanzaM}m '
                              '${labelStile(s.stile)} ${labelEsecuzione(s.esecuzione)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (sottotitolo.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(
                                sottotitolo,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 20,
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
            loading: () =>
                const Center(child: CircularProgressIndicator(color: _accento)),
            error: (error, _) => Center(
              child: Text(
                'Errore: $error',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              height: 64,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: _accento,
                  foregroundColor: Colors.black,
                  textStyle: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => PresenzeScreen(allenamento: allenamento),
                  ),
                ),
                child: const Text('SEGNA PRESENZE'),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
