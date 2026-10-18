import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/error_messages.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../theme/colori_app.dart';
import '../../../widgets/app_scaffold.dart';
import '../../../widgets/app_text_field.dart';
import '../../../widgets/primary_button.dart';
import '../../../widgets/testata_pagina.dart';
import '../application/current_club_provider.dart';
import '../data/membri_club_repository.dart';
import '../domain/ruolo_club.dart';

const _lunghezzaCodice = 10;

/// Un allenatore o un assistente entra nel club del responsabile con il
/// codice che gli ha mandato e il proprio nome. Si arriva da "Crea il tuo
/// club" (chi si registra come allenatore e non ha ancora un club).
class EntraConCodiceStaffScreen extends ConsumerStatefulWidget {
  const EntraConCodiceStaffScreen({super.key});

  @override
  ConsumerState<EntraConCodiceStaffScreen> createState() =>
      _EntraConCodiceStaffScreenState();
}

class _EntraConCodiceStaffScreenState
    extends ConsumerState<EntraConCodiceStaffScreen> {
  final _codiceController = TextEditingController();
  final _nomeController = TextEditingController();

  /// L'ultimo codice per cui si è chiesto al server di chi è.
  String? _codiceVerificato;
  bool _verificando = false;
  InvitoStaff? _invito;
  bool _codiceNonValido = false;
  String? _erroreVerifica;

  bool _entrando = false;
  String? _errore;

  @override
  void dispose() {
    _codiceController.dispose();
    _nomeController.dispose();
    super.dispose();
  }

  String get _codice => _codiceController.text;
  String get _nome => _nomeController.text.trim();

  /// Il codice si scrive in maiuscolo e non oltre le 10 lettere.
  void _codiceCambiato(String testo) {
    var normalizzato = testo.trim().toUpperCase();
    if (normalizzato.length > _lunghezzaCodice) {
      normalizzato = normalizzato.substring(0, _lunghezzaCodice);
    }
    if (normalizzato != testo) {
      _codiceController.value = TextEditingValue(
        text: normalizzato,
        selection: TextSelection.collapsed(offset: normalizzato.length),
      );
    }
    setState(() {
      _errore = null;
      if (normalizzato.length != _lunghezzaCodice) {
        _codiceVerificato = null;
        _invito = null;
        _codiceNonValido = false;
        _erroreVerifica = null;
      }
    });
    if (normalizzato.length == _lunghezzaCodice &&
        normalizzato != _codiceVerificato) {
      _verifica(normalizzato);
    }
  }

  Future<void> _verifica(String codice) async {
    _codiceVerificato = codice;
    setState(() {
      _verificando = true;
      _invito = null;
      _codiceNonValido = false;
      _erroreVerifica = null;
    });
    try {
      final invito = await ref
          .read(membriClubRepositoryProvider)
          .validaInvito(codice);
      // Nel frattempo il codice può essere cambiato.
      if (!mounted || _codiceVerificato != codice) return;
      setState(() {
        _invito = invito;
        _codiceNonValido = invito == null;
      });
    } catch (e) {
      if (!mounted || _codiceVerificato != codice) return;
      setState(() => _erroreVerifica = messaggioErrore(e));
    } finally {
      if (mounted && _codiceVerificato == codice) {
        setState(() => _verificando = false);
      }
    }
  }

  Future<void> _entra() async {
    final codice = _codice;
    final nome = _nome;
    if (codice.length != _lunghezzaCodice) {
      setState(() => _errore = 'Scrivi il codice di 10 caratteri.');
      return;
    }
    if (nome.isEmpty) {
      setState(() => _errore = 'Scrivi il tuo nome.');
      return;
    }
    setState(() {
      _entrando = true;
      _errore = null;
    });
    try {
      await ref.read(membriClubRepositoryProvider).entraConInvito(codice, nome);
      if (!mounted) return;
      // Ora l'account ha un club: la home lo rilegge e smette di proporre
      // "Crea il tuo club".
      ref.invalidate(currentClubProvider);
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      if (mounted) setState(() => _errore = messaggioErrore(e));
    } finally {
      if (mounted) setState(() => _entrando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colori = context.colori;
    final pronto =
        _codice.length == _lunghezzaCodice && _nome.isNotEmpty && !_entrando;

    String? esito;
    var esitoPositivo = false;
    if (_verificando) {
      esito = 'Controllo il codice…';
    } else if (_invito != null) {
      esito =
          'Entri in ${_invito!.clubNome} come '
          '${_invito!.ruolo.etichetta}.';
      esitoPositivo = true;
    } else if (_codiceNonValido) {
      esito =
          'Questo codice non vale: controlla di averlo scritto bene o '
          'chiedine uno nuovo.';
    } else if (_erroreVerifica != null) {
      esito = _erroreVerifica;
    }

    return AppScaffold(
      // La testata porta il titolo: la barra in alto resta vuota.
      appBar: AppBar(),
      body: ListView(
        padding: const EdgeInsets.only(bottom: AppSpacing.s32),
        children: [
          const TestataPagina(
            titolo: 'Entra nel club',
            sottotitolo:
                'Il responsabile del club ti ha mandato un codice: scrivilo '
                'qui con il tuo nome.',
          ),
          const SizedBox(height: AppSpacing.s28),
          AppTextField(
            etichetta: 'Codice',
            controller: _codiceController,
            onChanged: _codiceCambiato,
          ),
          if (esito != null) ...[
            const SizedBox(height: AppSpacing.s8),
            Text(
              esito,
              style: AppTypography.piccolo.copyWith(
                color: esitoPositivo ? colori.testo : colori.testoSecondario,
                fontWeight: esitoPositivo ? FontWeight.w600 : null,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.s16),
          AppTextField(
            etichetta: 'Il tuo nome',
            controller: _nomeController,
            onChanged: (_) => setState(() => _errore = null),
            onFieldSubmitted: (_) => pronto ? _entra() : null,
          ),
          const SizedBox(height: AppSpacing.s24),
          PrimaryButton(
            label: 'Entra',
            isLoading: _entrando,
            onPressed: pronto ? _entra : null,
          ),
          if (_errore != null) ...[
            const SizedBox(height: AppSpacing.s12),
            Text(
              _errore!,
              style: AppTypography.piccolo.copyWith(color: colori.rosso),
            ),
          ],
        ],
      ),
    );
  }
}
