import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/utils/error_messages.dart';
import '../../../core/utils/text_format.dart';
import '../../../theme/app_spacing.dart';
import '../../../widgets/app_scaffold.dart';
import '../../../widgets/app_select.dart';
import '../../../widgets/app_text_field.dart';
import '../../../widgets/error_banner.dart';
import '../../../widgets/primary_button.dart';
import '../../atleti/data/codici_gruppo_repository.dart';
import '../../atleti/data/inviti_atleta_repository.dart';
import '../data/auth_repository.dart';

enum _Passo { codice, confermaAtleta, confermaGruppo, anagrafica, account }

const _sport = ['nuoto', 'pallanuoto'];

/// Registrazione di un atleta tramite codice invito (FASE 9), raggiunta
/// da LoginScreen. Un solo punto d'ingresso per due tipi di codice, senza
/// che l'atleta debba sapere quale ha ricevuto:
/// - codice per-atleta (record gia' in rubrica): conferma nome, poi
///   email/password, poi si collega al record esistente;
/// - codice di gruppo (nessun record ancora): conferma gruppo/club, poi
///   l'atleta compila la propria anagrafica, poi email/password, e viene
///   creato un nuovo record gia' assegnato a quel gruppo.
class RiscattaInvitoScreen extends ConsumerStatefulWidget {
  const RiscattaInvitoScreen({super.key});

  @override
  ConsumerState<RiscattaInvitoScreen> createState() =>
      _RiscattaInvitoScreenState();
}

class _RiscattaInvitoScreenState extends ConsumerState<RiscattaInvitoScreen> {
  final _codiceController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nomeController = TextEditingController();
  final _cognomeController = TextEditingController();
  final _dataNascitaController = TextEditingController();

  _Passo _passo = _Passo.codice;
  AtletaInvitato? _invitato;
  GruppoInvitato? _gruppoInvitato;
  DateTime? _dataNascita;
  String? _sesso;
  String _sport = 'nuoto';
  bool _isSubmitting = false;
  String? _errore;

  @override
  void dispose() {
    _codiceController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _nomeController.dispose();
    _cognomeController.dispose();
    _dataNascitaController.dispose();
    super.dispose();
  }

  String get _codice => _codiceController.text.trim();

  Future<void> _verificaCodice() async {
    if (_codice.isEmpty) {
      setState(() => _errore = 'Inserisci il codice invito');
      return;
    }
    setState(() {
      _isSubmitting = true;
      _errore = null;
    });
    try {
      final invitato = await ref
          .read(invitiAtletaRepositoryProvider)
          .validaCodice(_codice);
      if (invitato != null) {
        if (mounted) {
          setState(() {
            _invitato = invitato;
            _passo = _Passo.confermaAtleta;
          });
        }
        return;
      }
      final gruppo = await ref
          .read(codiciGruppoRepositoryProvider)
          .validaCodice(_codice);
      if (gruppo != null) {
        if (mounted) {
          setState(() {
            _gruppoInvitato = gruppo;
            // Lo sport si conosce gia' dal gruppo (mai ambiguo come
            // club.sport per un club "nuoto e pallanuoto"): se e'
            // valorizzato, l'anagrafica non lo richiede piu'.
            if (gruppo.gruppoSport != null) _sport = gruppo.gruppoSport!;
            _passo = _Passo.confermaGruppo;
          });
        }
        return;
      }
      if (mounted) setState(() => _errore = 'Codice non valido o scaduto');
    } catch (e) {
      if (mounted) setState(() => _errore = messaggioErrore(e));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  bool _validaAnagrafica() {
    if (_nomeController.text.trim().isEmpty ||
        _cognomeController.text.trim().isEmpty ||
        _dataNascita == null) {
      setState(
        () => _errore = 'Nome, cognome e data di nascita sono obbligatori',
      );
      return false;
    }
    setState(() => _errore = null);
    return true;
  }

  Future<void> _pickDataNascita() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: _dataNascita ?? DateTime(now.year - 12),
      firstDate: DateTime(now.year - 100),
      lastDate: now,
    );
    if (selected != null) {
      setState(() {
        _dataNascita = selected;
        _dataNascitaController.text =
            '${selected.day.toString().padLeft(2, '0')}/'
            '${selected.month.toString().padLeft(2, '0')}/'
            '${selected.year}';
      });
    }
  }

  Future<void> _creaAccount() async {
    setState(() {
      _isSubmitting = true;
      _errore = null;
    });
    try {
      final authRepository = ref.read(authRepositoryProvider);
      // Se un tentativo precedente ha gia' creato l'account ma si e'
      // interrotto prima di collegarlo (es. rete caduta proprio in
      // mezzo), la sessione e' gia' attiva: rifare signUp fallirebbe con
      // "email gia' registrata" e bloccherebbe l'utente senza via
      // d'uscita. Si salta signUp e si riprova solo il collegamento.
      if (authRepository.currentUser == null) {
        final response = await authRepository.signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
        if (response.session == null) {
          if (mounted) {
            setState(
              () => _errore =
                  'Ti abbiamo inviato un\'email di conferma. Confermala, poi '
                  'torna qui e riprova con lo stesso codice.',
            );
          }
          return;
        }
      }
      if (_invitato != null) {
        await ref
            .read(invitiAtletaRepositoryProvider)
            .collegaConCodice(_codice);
      } else {
        await ref
            .read(codiciGruppoRepositoryProvider)
            .registraConCodice(
              codice: _codice,
              nome: capitalizzaNome(_nomeController.text),
              cognome: capitalizzaNome(_cognomeController.text),
              dataNascita: _dataNascita!,
              sesso: _sesso,
              sport: _sport,
            );
      }
      // authStateChangesProvider ha gia' una sessione attiva: la root
      // dell'app mostrera' l'Area atleta appena questo pop libera il
      // percorso di navigazione (stesso schema di SignUpScreen).
      if (mounted) Navigator.of(context).pop();
    } on AuthException catch (e) {
      if (mounted) setState(() => _errore = messaggioErrore(e));
    } catch (e) {
      if (mounted) setState(() => _errore = messaggioErrore(e));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      scrollabile: true,
      appBar: AppBar(title: const Text('Sei un atleta?')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              switch (_passo) {
                _Passo.codice => _PassoCodice(
                  controller: _codiceController,
                  isSubmitting: _isSubmitting,
                  onContinua: _verificaCodice,
                ),
                _Passo.confermaAtleta => _PassoConferma(
                  testo:
                      'Stai per registrarti come '
                      '${_invitato!.cognome} ${_invitato!.nome}.',
                  onContinua: () => setState(() => _passo = _Passo.account),
                  onAnnulla: () => setState(() {
                    _passo = _Passo.codice;
                    _errore = null;
                  }),
                ),
                _Passo.confermaGruppo => _PassoConferma(
                  testo:
                      'Stai per registrarti nel gruppo '
                      '${_gruppoInvitato!.gruppoNome} di '
                      '${_gruppoInvitato!.clubNome}.',
                  onContinua: () => setState(() => _passo = _Passo.anagrafica),
                  onAnnulla: () => setState(() {
                    _passo = _Passo.codice;
                    _errore = null;
                  }),
                ),
                _Passo.anagrafica => _PassoAnagrafica(
                  nomeController: _nomeController,
                  cognomeController: _cognomeController,
                  dataNascitaController: _dataNascitaController,
                  onPickData: _pickDataNascita,
                  sesso: _sesso,
                  onSessoChanged: (v) => setState(() => _sesso = v),
                  sport: _sport,
                  onSportChanged: (v) => setState(() => _sport = v ?? 'nuoto'),
                  sportGiaNoto: _gruppoInvitato?.gruppoSport != null,
                  onContinua: () {
                    if (_validaAnagrafica()) {
                      setState(() => _passo = _Passo.account);
                    }
                  },
                ),
                _Passo.account => _PassoAccount(
                  emailController: _emailController,
                  passwordController: _passwordController,
                  isSubmitting: _isSubmitting,
                  onCrea: _creaAccount,
                ),
              },
              if (_errore != null) ...[
                const SizedBox(height: AppSpacing.s16),
                ErrorBanner(messaggio: _errore!),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _PassoCodice extends StatelessWidget {
  const _PassoCodice({
    required this.controller,
    required this.isSubmitting,
    required this.onContinua,
  });

  final TextEditingController controller;
  final bool isSubmitting;
  final VoidCallback onContinua;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppTextField(
          etichetta: 'Codice invito',
          controller: controller,
          aiuto: 'Il codice che ti ha dato il tuo allenatore',
        ),
        const SizedBox(height: AppSpacing.s24),
        PrimaryButton(
          label: 'Continua',
          isLoading: isSubmitting,
          onPressed: isSubmitting ? null : onContinua,
        ),
      ],
    );
  }
}

class _PassoConferma extends StatelessWidget {
  const _PassoConferma({
    required this.testo,
    required this.onContinua,
    required this.onAnnulla,
  });

  final String testo;
  final VoidCallback onContinua;
  final VoidCallback onAnnulla;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          testo,
          style: Theme.of(context).textTheme.bodyLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.s24),
        PrimaryButton(label: 'Continua', onPressed: onContinua),
        const SizedBox(height: AppSpacing.s12),
        TextButton(onPressed: onAnnulla, child: const Text('Non è così')),
      ],
    );
  }
}

String _capitalizza(String s) =>
    s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

class _PassoAnagrafica extends StatelessWidget {
  const _PassoAnagrafica({
    required this.nomeController,
    required this.cognomeController,
    required this.dataNascitaController,
    required this.onPickData,
    required this.sesso,
    required this.onSessoChanged,
    required this.sport,
    required this.onSportChanged,
    this.sportGiaNoto = false,
    required this.onContinua,
  });

  final TextEditingController nomeController;
  final TextEditingController cognomeController;
  final TextEditingController dataNascitaController;
  final VoidCallback onPickData;
  final String? sesso;
  final ValueChanged<String?> onSessoChanged;
  final String sport;
  final ValueChanged<String?> onSportChanged;

  /// true quando lo sport si e' gia' dedotto dal gruppo (codice di
  /// gruppo di un club a sport unico): il menu non si mostra piu'.
  final bool sportGiaNoto;
  final VoidCallback onContinua;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppTextField(etichetta: 'Cognome', controller: cognomeController),
        const SizedBox(height: AppSpacing.s16),
        AppTextField(etichetta: 'Nome', controller: nomeController),
        const SizedBox(height: AppSpacing.s16),
        AppTextField(
          etichetta: 'Data di nascita',
          controller: dataNascitaController,
          readOnly: true,
          onTap: onPickData,
          suffixIcon: const Icon(Icons.calendar_today_outlined),
        ),
        const SizedBox(height: AppSpacing.s16),
        AppSelect<String>(
          etichetta: 'Sesso (facoltativo)',
          value: sesso,
          hint: 'Non specificato',
          items: const [
            DropdownMenuItem(value: 'M', child: Text('M')),
            DropdownMenuItem(value: 'F', child: Text('F')),
          ],
          onChanged: onSessoChanged,
        ),
        if (!sportGiaNoto) ...[
          const SizedBox(height: AppSpacing.s16),
          AppSelect<String>(
            etichetta: 'Sport',
            value: sport,
            items: [
              for (final s in _sport)
                DropdownMenuItem(value: s, child: Text(_capitalizza(s))),
            ],
            onChanged: onSportChanged,
          ),
        ],
        const SizedBox(height: AppSpacing.s24),
        PrimaryButton(label: 'Continua', onPressed: onContinua),
      ],
    );
  }
}

class _PassoAccount extends StatelessWidget {
  const _PassoAccount({
    required this.emailController,
    required this.passwordController,
    required this.isSubmitting,
    required this.onCrea,
  });

  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool isSubmitting;
  final VoidCallback onCrea;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppTextField(
          etichetta: 'Email',
          controller: emailController,
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
        ),
        const SizedBox(height: AppSpacing.s16),
        AppTextField(
          etichetta: 'Password',
          controller: passwordController,
          obscureText: true,
          autofillHints: const [AutofillHints.newPassword],
        ),
        const SizedBox(height: AppSpacing.s24),
        PrimaryButton(
          label: 'Crea account',
          isLoading: isSubmitting,
          onPressed: isSubmitting ? null : onCrea,
        ),
      ],
    );
  }
}
