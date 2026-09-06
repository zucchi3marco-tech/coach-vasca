import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/utils/error_messages.dart';
import '../../../theme/app_spacing.dart';
import '../../../widgets/app_scaffold.dart';
import '../../../widgets/app_text_field.dart';
import '../../../widgets/error_banner.dart';
import '../../../widgets/primary_button.dart';
import '../data/auth_repository.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confermaPasswordController = TextEditingController();

  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confermaPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final response = await ref
          .read(authRepositoryProvider)
          .signUp(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );

      if (!mounted) return;

      if (response.session != null) {
        // Sessione gia' attiva (conferma email disattivata sul progetto):
        // authStateChangesProvider fara' navigare automaticamente alla home.
        Navigator.of(context).pop();
        return;
      }

      // Conferma email richiesta: nessuna sessione finche' non si clicca
      // il link ricevuto via email.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Ti abbiamo inviato un\'email di conferma a '
            '${_emailController.text.trim()}. Confermala e poi accedi.',
          ),
          duration: const Duration(seconds: 6),
        ),
      );
      Navigator.of(context).pop();
    } on AuthException catch (e) {
      if (mounted) setState(() => _errorMessage = messaggioErrore(e));
    } catch (_) {
      if (mounted) {
        setState(() => _errorMessage = 'Errore di connessione. Riprova.');
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(title: const Text('Crea account coach')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppTextField(
                    etichetta: 'Email',
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Inserisci la tua email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.s16),
                  AppTextField(
                    etichetta: 'Password',
                    controller: _passwordController,
                    obscureText: true,
                    autofillHints: const [AutofillHints.newPassword],
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Inserisci una password';
                      }
                      if (value.length < 6) {
                        return 'Almeno 6 caratteri';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.s16),
                  AppTextField(
                    etichetta: 'Conferma password',
                    controller: _confermaPasswordController,
                    obscureText: true,
                    validator: (value) {
                      if (value != _passwordController.text) {
                        return 'Le password non coincidono';
                      }
                      return null;
                    },
                    onFieldSubmitted: (_) => _submit(),
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: AppSpacing.s12),
                    ErrorBanner(messaggio: _errorMessage!),
                  ],
                  const SizedBox(height: AppSpacing.s24),
                  PrimaryButton(
                    label: 'Crea account',
                    isLoading: _isSubmitting,
                    onPressed: _isSubmitting ? null : _submit,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
