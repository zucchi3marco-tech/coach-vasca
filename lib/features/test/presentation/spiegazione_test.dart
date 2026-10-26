import 'package:flutter/material.dart';

import '../../../core/utils/error_messages.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../theme/colori_app.dart';
import '../../../widgets/app_scaffold.dart';
import '../../../widgets/app_text_field.dart';
import '../../../widgets/error_banner.dart';
import '../../../widgets/primary_button.dart';
import '../domain/spiegazioni_test.dart';

/// La spiegazione di un test, a blocchi: il titolo del blocco ("Come si
/// fa") in grassetto, sotto il testo e i punti dell'elenco.
class SpiegazioneTest extends StatelessWidget {
  const SpiegazioneTest(this.testo, {super.key});

  final String testo;

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    final corpo = AppTypography.corpo.copyWith(color: colori.testo);
    final blocchi = blocchiSpiegazione(testo);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (i, b) in blocchi.indexed) ...[
          if (i > 0) const SizedBox(height: AppSpacing.s16),
          if (b.titolo case final t?) ...[
            Text(
              t,
              style: AppTypography.corpoForte.copyWith(color: colori.testo),
            ),
            const SizedBox(height: AppSpacing.s4),
          ],
          for (final r in b.righe)
            if (r.startsWith('•'))
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.s4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: AppSpacing.s16,
                      child: Text('•', style: corpo),
                    ),
                    Expanded(child: Text(r.substring(1).trim(), style: corpo)),
                  ],
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.s4),
                child: Text(r, style: corpo),
              ),
        ],
      ],
    );
  }
}

/// Il foglio "Come si fa" di un test: il nome, come si legge ([sotto]) e
/// la spiegazione. Con [onModifica] (solo l'allenatore) c'è anche
/// "Modifica la spiegazione" (o [etichettaModifica]); con [onAggiungi] (un
/// test pronto) il pulsante per aggiungerlo al club.
Future<void> mostraComeSiFaTest(
  BuildContext context, {
  required String titolo,
  String? sotto,
  required String? testo,
  VoidCallback? onModifica,
  String etichettaModifica = 'Modifica la spiegazione',
  VoidCallback? onAggiungi,
}) => showModalBottomSheet<void>(
  context: context,
  showDragHandle: true,
  isScrollControlled: true,
  builder: (sheetContext) {
    final colori = sheetContext.colori;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.s16,
          0,
          AppSpacing.s16,
          AppSpacing.s24,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              titolo,
              style: AppTypography.sezione.copyWith(color: colori.testo),
            ),
            if (sotto != null) ...[
              const SizedBox(height: AppSpacing.s4),
              Text(
                sotto,
                style: AppTypography.piccolo.copyWith(
                  color: colori.testoSecondario,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.s16),
            if (testo == null || testo.trim().isEmpty)
              Text(
                onModifica == null
                    ? 'Per come si fa, chiedi all\'allenatore.'
                    : 'Nessuna spiegazione: scrivila con «Modifica la '
                          'spiegazione».',
                style: AppTypography.corpo.copyWith(
                  color: colori.testoSecondario,
                ),
              )
            else
              SpiegazioneTest(testo),
            if (onAggiungi != null) ...[
              const SizedBox(height: AppSpacing.s24),
              PrimaryButton(
                label: 'Aggiungi al club',
                onPressed: () {
                  Navigator.of(sheetContext).pop();
                  onAggiungi();
                },
              ),
            ],
            if (onModifica != null) ...[
              const SizedBox(height: AppSpacing.s16),
              Center(
                child: TextButton.icon(
                  icon: const Icon(Icons.edit_outlined),
                  label: Text(etichettaModifica),
                  onPressed: () {
                    Navigator.of(sheetContext).pop();
                    onModifica();
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  },
);

/// La pagina per scrivere la spiegazione di un test che non ha un modulo
/// suo (BVS e T30): il testo, "Ripristina la spiegazione originale" e
/// "Salva". [salva] riceve il testo (null = torna all'originale).
class ModificaSpiegazioneScreen extends StatefulWidget {
  const ModificaSpiegazioneScreen({
    required this.titolo,
    required this.attuale,
    required this.originale,
    required this.salva,
    super.key,
  });

  final String titolo;
  final String attuale;
  final String originale;
  final Future<void> Function(String? testo) salva;

  @override
  State<ModificaSpiegazioneScreen> createState() =>
      _ModificaSpiegazioneScreenState();
}

class _ModificaSpiegazioneScreenState extends State<ModificaSpiegazioneScreen> {
  late final _testo = TextEditingController(text: widget.attuale);
  bool _salvataggio = false;
  String? _errore;

  @override
  void dispose() {
    _testo.dispose();
    super.dispose();
  }

  Future<void> _salva() async {
    setState(() {
      _salvataggio = true;
      _errore = null;
    });
    final t = _testo.text.trim();
    try {
      await widget.salva(t.isEmpty || t == widget.originale.trim() ? null : t);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) setState(() => _errore = messaggioErrore(e));
    } finally {
      if (mounted) setState(() => _salvataggio = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(title: Text(widget.titolo)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.s16),
        children: [
          CampoSpiegazione(controller: _testo, originale: widget.originale),
          if (_errore != null) ...[
            const SizedBox(height: AppSpacing.s16),
            ErrorBanner(
              messaggio: 'Spiegazione non salvata.',
              dettaglioTecnico: _errore,
            ),
          ],
          const SizedBox(height: AppSpacing.s24),
          PrimaryButton(
            label: 'Salva',
            isLoading: _salvataggio,
            onPressed: _salvataggio ? null : _salva,
          ),
        ],
      ),
    );
  }
}

/// Il campo della spiegazione, con sotto "Ripristina la spiegazione
/// originale" quando c'è un'[originale] diversa dal testo.
class CampoSpiegazione extends StatefulWidget {
  const CampoSpiegazione({required this.controller, this.originale, super.key});

  final TextEditingController controller;
  final String? originale;

  @override
  State<CampoSpiegazione> createState() => _CampoSpiegazioneState();
}

class _CampoSpiegazioneState extends State<CampoSpiegazione> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_aggiorna);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_aggiorna);
    super.dispose();
  }

  void _aggiorna() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final originale = widget.originale;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppTextField(
          etichetta: 'Come si fa',
          controller: widget.controller,
          maxLines: 14,
          aiuto:
              'A cosa serve, cosa serve, come si fa, come si misura. Una riga '
              'vuota separa i blocchi; la prima riga di un blocco è il suo '
              'titolo, una riga che comincia con • è un punto.',
          validator: (v) => (v?.length ?? 0) > lunghezzaMassimaSpiegazione
              ? 'Al massimo $lunghezzaMassimaSpiegazione caratteri'
              : null,
        ),
        if (originale != null &&
            widget.controller.text.trim() != originale.trim())
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              icon: const Icon(Icons.restore),
              label: const Text('Ripristina la spiegazione originale'),
              onPressed: () => widget.controller.text = originale,
            ),
          ),
      ],
    );
  }
}
