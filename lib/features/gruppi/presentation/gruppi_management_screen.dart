import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/error_messages.dart';
import '../../../theme/colori_app.dart';
import '../../../widgets/app_scaffold.dart';
import '../../../widgets/app_text_field.dart';
import '../../../widgets/danger_button.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/error_banner.dart';
import '../../../widgets/form_group.dart';
import '../../../widgets/loading_skeleton.dart';
import '../../../widgets/primary_button.dart';
import '../../../widgets/riquadri.dart';
import '../../../widgets/scheda_elenco.dart';
import '../../../widgets/section_header.dart';
import '../../atleti/application/atleti_providers.dart';
import '../../atleti/presentation/codici_gruppo_screen.dart';
import '../../club/application/current_club_provider.dart';
import '../application/gruppi_providers.dart';
import '../data/gruppi_repository.dart';
import '../domain/gruppo.dart';

/// Aggiungi/rinomina/elimina un gruppo — raggiungibile dalla schermata di
/// scelta gruppo, per non dover passare dall'onboarding iniziale ogni
/// volta che serve un nuovo gruppo.
class GruppiManagementScreen extends ConsumerStatefulWidget {
  const GruppiManagementScreen({required this.clubId, super.key});

  final String clubId;

  @override
  ConsumerState<GruppiManagementScreen> createState() =>
      _GruppiManagementScreenState();
}

class _GruppiManagementScreenState
    extends ConsumerState<GruppiManagementScreen> {
  final _nuovoGruppoController = TextEditingController();
  bool _isSubmitting = false;
  String? _errore;

  @override
  void dispose() {
    _nuovoGruppoController.dispose();
    super.dispose();
  }

  Future<void> _aggiungi() async {
    final nome = _nuovoGruppoController.text.trim();
    if (nome.isEmpty) {
      setState(() => _errore = 'Indica il nome del gruppo');
      return;
    }
    setState(() {
      _isSubmitting = true;
      _errore = null;
    });
    try {
      final gruppiAttuali =
          ref.read(gruppiListProvider(widget.clubId)).value ?? [];
      final clubSport = ref.read(currentClubProvider).value?.sport;
      final gruppoSport = clubSport == 'nuoto' || clubSport == 'pallanuoto'
          ? clubSport
          : null;
      await ref
          .read(gruppiRepositoryProvider)
          .createGruppo(
            clubId: widget.clubId,
            nome: nome,
            ordine: gruppiAttuali.length + 1,
            sport: gruppoSport,
          );
      _nuovoGruppoController.clear();
    } catch (e) {
      if (mounted) setState(() => _errore = messaggioErrore(e));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _rinomina(Gruppo gruppo) async {
    final controller = TextEditingController(text: gruppo.nome);
    final nuovoNome = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rinomina gruppo'),
        content: AppTextField(etichetta: 'Nome gruppo', controller: controller),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annulla'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Salva'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (nuovoNome == null || nuovoNome.isEmpty || nuovoNome == gruppo.nome) {
      return;
    }
    try {
      await ref
          .read(gruppiRepositoryProvider)
          .updateGruppo(id: gruppo.id, nome: nuovoNome, ordine: gruppo.ordine);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(messaggioErrore(e))));
      }
    }
  }

  Future<void> _elimina(Gruppo gruppo) async {
    final conferma = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Eliminare "${gruppo.nome}"?'),
        content: const Text(
          'Gli atleti, gli allenamenti e le stagioni collegati a questo '
          'gruppo resteranno senza gruppo assegnato.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annulla'),
          ),
          DangerButton(
            label: 'Elimina',
            expanded: false,
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );
    if (conferma != true) return;
    try {
      await ref.read(gruppiRepositoryProvider).deleteGruppo(gruppo.id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(messaggioErrore(e))));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final gruppiAsync = ref.watch(gruppiListProvider(widget.clubId));
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
    final colori = context.colori;

    void apriCodici(Gruppo g) => Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => CodiciGruppoScreen(gruppo: g)),
    );

    return AppScaffold(
      scrollabile: true,
      appBar: AppBar(title: const Text('Gestisci gruppi')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FormGroup(
            titolo: 'Nuovo gruppo',
            campi: [
              AppTextField(
                etichetta: 'Nome del gruppo',
                controller: _nuovoGruppoController,
              ),
              PrimaryButton(
                label: 'Aggiungi gruppo',
                isLoading: _isSubmitting,
                onPressed: _isSubmitting ? null : _aggiungi,
              ),
              if (_errore != null) ErrorBanner(messaggio: _errore!),
            ],
          ),
          gruppiAsync.when(
            data: (gruppi) => gruppi.isEmpty
                ? const EmptyState(
                    icona: Icons.groups_outlined,
                    titolo: 'Nessun gruppo',
                    descrizione: 'Aggiungi il primo gruppo di allenamento.',
                    azionePrincipale: 'Ho capito',
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TitoloSezione('I tuoi gruppi', conteggio: gruppi.length),
                      GrigliaSchede(
                        colonneMassime: 1,
                        figli: [
                          for (final g in gruppi)
                            SchedaElenco(
                              leading: const IconaRiquadro(
                                Icons.groups_outlined,
                                dimensione: 44,
                              ),
                              titolo: g.nome,
                              sottotitolo: switch (atleti
                                  .where((a) => a.gruppoId == g.id)
                                  .length) {
                                0 => 'Nessun atleta',
                                1 => '1 atleta',
                                final n => '$n atleti',
                              },
                              mostraFreccia: false,
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Il codice per far registrare gli atleti
                                  // del gruppo: prima solo nel menu ⋮.
                                  IconButton(
                                    tooltip: 'Codice di registrazione',
                                    icon: Icon(
                                      Icons.qr_code_2_outlined,
                                      color: colori.azione,
                                    ),
                                    onPressed: () => apriCodici(g),
                                  ),
                                  PopupMenuButton<VoidCallback>(
                                    icon: Icon(
                                      Icons.more_vert,
                                      color: colori.testoSecondario,
                                    ),
                                    tooltip: 'Altre azioni',
                                    onSelected: (azione) => azione(),
                                    itemBuilder: (context) => [
                                      PopupMenuItem(
                                        value: () => _rinomina(g),
                                        child: const Text('Rinomina'),
                                      ),
                                      PopupMenuItem(
                                        value: () => _elimina(g),
                                        child: Text(
                                          'Elimina',
                                          style: TextStyle(color: colori.rosso),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
            loading: () => const LoadingSkeletonList(righe: 3),
            error: (error, _) => ErrorBanner(
              messaggio: 'Non è stato possibile caricare i gruppi.',
              dettaglioTecnico: messaggioErrore(error),
            ),
          ),
        ],
      ),
    );
  }
}
