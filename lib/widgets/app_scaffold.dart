import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

/// Scaffold di base: margine laterale coerente (16 su telefono, 24 su
/// tablet — vedi DESIGN.md sezione 5) e sfondo dal tema. Usalo al posto
/// di uno `Scaffold` nudo per ogni schermata nuova.
class AppScaffold extends StatelessWidget {
  const AppScaffold({
    required this.body,
    this.appBar,
    this.floatingActionButton,
    this.persistentFooterButtons,
    this.bottomNavigationBar,
    this.scrollabile = false,
    super.key,
  });

  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? floatingActionButton;
  final List<Widget>? persistentFooterButtons;
  final Widget? bottomNavigationBar;

  /// Se true, avvolge il contenuto in uno scroll verticale (form lunghi,
  /// contenuto che può eccedere l'altezza dello schermo).
  final bool scrollabile;

  /// Oltre questa larghezza il contenuto smette di allargarsi e resta
  /// centrato — su un monitor desktop, campi di testo larghi quanto la
  /// finestra intera sono scomodi da leggere (analisi video, punto 3.5).
  static const _larghezzaMassimaContenuto = 760.0;

  @override
  Widget build(BuildContext context) {
    final larghezza = MediaQuery.sizeOf(context).width;
    final margine = larghezza >= 600
        ? AppSpacing.margineLateraleTablet
        : AppSpacing.margineLateraleTelefono;
    final contenuto = Padding(padding: EdgeInsets.all(margine), child: body);
    final corpo = scrollabile
        ? SingleChildScrollView(child: contenuto)
        : contenuto;

    return Scaffold(
      appBar: appBar,
      floatingActionButton: floatingActionButton,
      persistentFooterButtons: persistentFooterButtons,
      bottomNavigationBar: bottomNavigationBar,
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: _larghezzaMassimaContenuto,
            ),
            child: corpo,
          ),
        ),
      ),
    );
  }
}
