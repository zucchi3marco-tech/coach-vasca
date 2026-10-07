import 'package:flutter/widgets.dart';

import '../core/schermo/schermo_acceso.dart';

/// Tiene lo schermo acceso finché questa schermata è aperta: per le
/// schermate da bordo vasca (DESIGN.md sezione 14).
class SchermoAcceso extends StatefulWidget {
  const SchermoAcceso({required this.child, super.key});

  final Widget child;

  @override
  State<SchermoAcceso> createState() => _SchermoAccesoState();
}

class _SchermoAccesoState extends State<SchermoAcceso> {
  @override
  void initState() {
    super.initState();
    tieniSchermoAcceso();
  }

  @override
  void dispose() {
    lasciaSpegnereSchermo();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
