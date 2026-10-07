import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Riquadro che si abbassa leggermente sotto il dito, con vibrazione
/// breve al tocco: si capisce subito che e' premibile. E' il tocco di
/// tutte le schede in stile "Oggi".
class Premibile extends StatefulWidget {
  const Premibile({
    required this.child,
    required this.onTap,
    this.onLongPress,
    this.raggio = 20,
    this.etichetta,
    super.key,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double raggio;
  final String? etichetta;

  @override
  State<Premibile> createState() => _PremibileState();
}

class _PremibileState extends State<Premibile> {
  bool _premuto = false;
  bool _sopra = false;

  @override
  Widget build(BuildContext context) {
    final ridotto = MediaQuery.disableAnimationsOf(context);
    final scala = _premuto ? 0.97 : (_sopra ? 1.01 : 1.0);
    return Semantics(
      button: widget.onTap != null,
      label: widget.etichetta,
      child: MouseRegion(
        cursor: widget.onTap == null
            ? MouseCursor.defer
            : SystemMouseCursors.click,
        onEnter: (_) => setState(() => _sopra = true),
        onExit: (_) => setState(() => _sopra = false),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: widget.onTap == null
              ? null
              : (_) => setState(() => _premuto = true),
          onTapCancel: () => setState(() => _premuto = false),
          onTapUp: (_) => setState(() => _premuto = false),
          onTap: widget.onTap == null
              ? null
              : () {
                  HapticFeedback.selectionClick();
                  widget.onTap!();
                },
          onLongPress: widget.onLongPress,
          child: AnimatedScale(
            scale: ridotto ? 1 : scala,
            duration: const Duration(milliseconds: 140),
            curve: Curves.easeOutCubic,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
