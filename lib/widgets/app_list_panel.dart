import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Pannello che raggruppa più [AppListRow], separate da filetti da 1px —
/// vedi DESIGN.md sezione 8, "Elenchi".
class AppListPanel extends StatelessWidget {
  const AppListPanel({required this.righe, super.key});

  final List<Widget> righe;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.superficie,
        borderRadius: BorderRadius.circular(AppSpacing.raggioPannello),
        border: Border.all(color: AppColors.linea),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < righe.length; i++) ...[
            righe[i],
            if (i != righe.length - 1)
              const Divider(color: AppColors.linea, height: 1),
          ],
        ],
      ),
    );
  }
}

/// Stesso aspetto di [AppListPanel] (bordo, filetti), ma le righe si possono
/// trascinare per cambiarne l'ordine — usato dove l'ordine è deciso dal
/// coach (macrocicli, mesocicli, microcicli) invece che da un campo
/// "Ordine" digitato a mano. Ogni riga richiede una [Key] univoca (di solito
/// l'id del record) per farsi riconoscere durante il trascinamento.
class ReorderableAppListPanel extends StatelessWidget {
  const ReorderableAppListPanel({
    required this.righe,
    required this.onReorderItem,
    super.key,
  });

  final List<({Key chiave, Widget riga})> righe;

  /// Chiamato con l'indice di partenza e quello di arrivo (già corretto
  /// per la rimozione dell'elemento spostato — vedi
  /// [ReorderableListView.onReorderItem]).
  final ReorderCallback onReorderItem;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.superficie,
        borderRadius: BorderRadius.circular(AppSpacing.raggioPannello),
        border: Border.all(color: AppColors.linea),
      ),
      clipBehavior: Clip.antiAlias,
      child: ReorderableListView(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        onReorderItem: onReorderItem,
        children: [
          for (var i = 0; i < righe.length; i++)
            Container(
              key: righe[i].chiave,
              decoration: BoxDecoration(
                border: i == righe.length - 1
                    ? null
                    : const Border(
                        bottom: BorderSide(color: AppColors.linea),
                      ),
              ),
              child: righe[i].riga,
            ),
        ],
      ),
    );
  }
}
