import 'package:flutter/material.dart';

import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../theme/colori_app.dart';
import '../../../widgets/app_scaffold.dart';
import '../../../widgets/premibile.dart';
import 'riscatta_invito_screen.dart';
import 'signup_screen.dart';

/// Il primo passo di "Registrati": chi sei, atleta o allenatore. Prima
/// "Registrati" portava dritto alla registrazione da allenatore e il
/// percorso dell'atleta era un link in fondo al login: alcuni atleti si
/// sono registrati come allenatori e hanno creato un club vuoto invece di
/// entrare in quello della squadra.
///
/// Le due strade sostituiscono questa schermata (pushReplacement): a
/// registrazione finita sopra il login non resta nulla di aperto, e
/// "indietro" torna al login.
class SceltaRegistrazioneScreen extends StatelessWidget {
  const SceltaRegistrazioneScreen({this.emailIniziale, super.key});

  /// L'email già scritta sul login, passata alla registrazione da
  /// allenatore come faceva prima il pulsante "Registrati".
  final String? emailIniziale;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      scrollabile: true,
      appBar: AppBar(title: const Text('Registrati')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Chi sei?',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.s24),
              SceltaRuolo(
                icona: Icons.pool_outlined,
                titolo: 'Sono un atleta',
                descrizione:
                    'Entro nella mia squadra con il codice che mi ha dato '
                    'l\'allenatore.',
                nota: 'Non hai il codice? Chiedilo al tuo allenatore.',
                onTap: () => Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (_) => const RiscattaInvitoScreen(),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.s12),
              SceltaRuolo(
                icona: Icons.sports_outlined,
                titolo: 'Sono un allenatore',
                descrizione:
                    'Creo il club della mia squadra e invito gli atleti.',
                onTap: () => Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (_) => SignUpScreen(emailIniziale: emailIniziale),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Una delle due strade di [SceltaRegistrazioneScreen]: icona, titolo e
/// cosa succede, tutto il riquadro premibile.
class SceltaRuolo extends StatelessWidget {
  const SceltaRuolo({
    required this.icona,
    required this.titolo,
    required this.descrizione,
    required this.onTap,
    this.nota,
    super.key,
  });

  final IconData icona;
  final String titolo;
  final String descrizione;
  final String? nota;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    return Premibile(
      onTap: onTap,
      raggio: AppRadius.pannello,
      etichetta: titolo,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.paddingPannello),
        decoration: BoxDecoration(
          color: colori.superficie,
          borderRadius: BorderRadius.circular(AppRadius.pannello),
          border: Border.all(color: colori.linea),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: colori.azioneTenue,
                borderRadius: BorderRadius.circular(AppRadius.controllo),
              ),
              child: Icon(icona, color: colori.azione),
            ),
            const SizedBox(width: AppSpacing.s16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(titolo, style: AppTypography.corpoForte),
                  const SizedBox(height: AppSpacing.s4),
                  Text(
                    descrizione,
                    style: AppTypography.corpo.copyWith(
                      color: colori.testoSecondario,
                    ),
                  ),
                  if (nota != null) ...[
                    const SizedBox(height: AppSpacing.s4),
                    Text(
                      nota!,
                      style: AppTypography.piccolo.copyWith(
                        color: colori.testoTenue,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.s8),
            Icon(Icons.chevron_right, color: colori.testoTenue),
          ],
        ),
      ),
    );
  }
}
