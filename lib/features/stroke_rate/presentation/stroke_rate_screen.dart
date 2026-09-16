import 'dart:async';
import 'dart:io' show Platform;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../theme/colori_app.dart';
import '../../../widgets/app_scaffold.dart';
import '../../../widgets/error_banner.dart';
import '../../../widgets/loading_skeleton.dart';
import '../../../widgets/primary_button.dart';
import '../../atleti/domain/atleta.dart';

const _durataClip = Duration(seconds: 15);
const _sogliaLikelihood = 0.5;
const _distanzaMinimaPicchi = Duration(milliseconds: 400);

enum _Fase { pronto, registrazione, elaborazione, risultato }

/// Stima sperimentale del ritmo di bracciata da fotocamera: registra ~15s
/// di fotogrammi (senza salvare un video, elaborati man mano che arrivano
/// dallo stream della fotocamera — elaborazione locale sul device, nessun
/// upload), traccia il polso con Google ML Kit Pose Detection e conta i
/// picchi (massimi locali) del suo movimento verticale nel tempo.
///
/// E' una prima versione non validata: spruzzi, più nuotatori
/// nell'inquadratura o un'angolazione scomoda possono rendere la stima
/// inaffidabile. Da verificare sempre con un conteggio manuale prima di
/// fidarsene. Nessun dato viene salvato: il risultato si vede solo a
/// schermo.
class StrokeRateScreen extends StatefulWidget {
  const StrokeRateScreen({required this.atleta, super.key});

  final Atleta atleta;

  @override
  State<StrokeRateScreen> createState() => _StrokeRateScreenState();
}

class _StrokeRateScreenState extends State<StrokeRateScreen> {
  CameraController? _controller;
  PoseDetector? _poseDetector;
  _Fase _fase = _Fase.pronto;
  String? _errore;
  Timer? _timer;
  int _secondiRimasti = _durataClip.inSeconds;
  bool _isDetecting = false;
  final List<_CampionePolso> _campioni = [];
  double? _bracciatePerMinuto;

  @override
  void initState() {
    super.initState();
    _poseDetector = PoseDetector(
      options: PoseDetectorOptions(mode: PoseDetectionMode.stream),
    );
    _inizializzaCamera();
  }

  Future<void> _inizializzaCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (mounted) {
          setState(
            () => _errore =
                'Nessuna fotocamera disponibile su questo dispositivo.',
          );
        }
        return;
      }
      final camera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      final controller = CameraController(
        camera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid
            ? ImageFormatGroup.nv21
            : ImageFormatGroup.bgra8888,
      );
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() => _controller = controller);
    } catch (_) {
      if (mounted) {
        setState(
          () => _errore =
              'Impossibile accedere alla fotocamera: verifica di aver '
              'concesso il permesso nelle impostazioni del dispositivo.',
        );
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller?.dispose();
    _poseDetector?.close();
    super.dispose();
  }

  Future<void> _avviaRegistrazione() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    setState(() {
      _fase = _Fase.registrazione;
      _campioni.clear();
      _secondiRimasti = _durataClip.inSeconds;
      _errore = null;
    });
    final inizio = DateTime.now();
    await controller.startImageStream(_onFrame);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      final trascorsi = DateTime.now().difference(inizio);
      final rimasti = _durataClip.inSeconds - trascorsi.inSeconds;
      if (rimasti <= 0) {
        timer.cancel();
        await _fermaRegistrazione();
      } else if (mounted) {
        setState(() => _secondiRimasti = rimasti);
      }
    });
  }

  void _onFrame(CameraImage image) {
    if (_isDetecting) return;
    _isDetecting = true;
    _elaboraFrame(image).whenComplete(() => _isDetecting = false);
  }

  Future<void> _elaboraFrame(CameraImage image) async {
    final camera = _controller?.description;
    final detector = _poseDetector;
    if (camera == null || detector == null) return;
    final inputImage = _inputImageFromCameraImage(image, camera);
    if (inputImage == null) return;
    try {
      final poses = await detector.processImage(inputImage);
      if (poses.isEmpty) return;
      final pose = poses.first;
      final sinistro = pose.landmarks[PoseLandmarkType.leftWrist];
      final destro = pose.landmarks[PoseLandmarkType.rightWrist];
      _campioni.add(
        _CampionePolso(
          istante: DateTime.now(),
          ySinistro:
              (sinistro != null && sinistro.likelihood >= _sogliaLikelihood)
              ? sinistro.y
              : null,
          yDestro: (destro != null && destro.likelihood >= _sogliaLikelihood)
              ? destro.y
              : null,
        ),
      );
    } catch (_) {
      // Fotogramma singolo non elaborabile: si ignora, si continua con i
      // successivi (non vale la pena interrompere l'intera registrazione).
    }
  }

  Future<void> _fermaRegistrazione() async {
    if (mounted) setState(() => _fase = _Fase.elaborazione);
    try {
      await _controller?.stopImageStream();
    } catch (_) {
      // Puo' gia' non essere in streaming se la fotocamera e' stata persa
      // (es. app in background): non e' un errore da mostrare all'utente.
    }
    final risultato = _calcolaBracciatePerMinuto(_campioni);
    if (!mounted) return;
    setState(() {
      _bracciatePerMinuto = risultato;
      _fase = _Fase.risultato;
    });
  }

  /// Sceglie il polso con piu' campioni validi, lo smussa con una media
  /// mobile per attenuare il rumore del rilevamento, poi conta i massimi
  /// locali (un picco = un ciclo di bracciata di quel braccio) distanziati
  /// almeno [_distanzaMinimaPicchi] per non contare due volte lo stesso
  /// ciclo per via del rumore.
  double? _calcolaBracciatePerMinuto(List<_CampionePolso> campioni) {
    if (campioni.length < 6) return null;

    final conteggioSinistro = campioni.where((c) => c.ySinistro != null).length;
    final conteggioDestro = campioni.where((c) => c.yDestro != null).length;
    final usaSinistro = conteggioSinistro >= conteggioDestro;

    final punti = <(DateTime, double)>[
      for (final c in campioni)
        if ((usaSinistro ? c.ySinistro : c.yDestro) != null)
          (c.istante, (usaSinistro ? c.ySinistro : c.yDestro)!),
    ];
    if (punti.length < 6) return null;

    final lisciati = <(DateTime, double)>[];
    for (var i = 0; i < punti.length; i++) {
      final inizio = (i - 1).clamp(0, punti.length - 1);
      final fine = (i + 1).clamp(0, punti.length - 1);
      var somma = 0.0;
      for (var j = inizio; j <= fine; j++) {
        somma += punti[j].$2;
      }
      lisciati.add((punti[i].$1, somma / (fine - inizio + 1)));
    }

    var picchi = 0;
    DateTime? ultimoPicco;
    for (var i = 1; i < lisciati.length - 1; i++) {
      final precedente = lisciati[i - 1].$2;
      final attuale = lisciati[i].$2;
      final successivo = lisciati[i + 1].$2;
      final eMassimoLocale = attuale > precedente && attuale >= successivo;
      if (!eMassimoLocale) continue;
      final istante = lisciati[i].$1;
      if (ultimoPicco != null &&
          istante.difference(ultimoPicco) < _distanzaMinimaPicchi) {
        continue;
      }
      picchi++;
      ultimoPicco = istante;
    }

    final durataEffettiva =
        punti.last.$1.difference(punti.first.$1).inMilliseconds / 1000.0;
    if (durataEffettiva <= 0 || picchi == 0) return null;
    return picchi / durataEffettiva * 60;
  }

  /// Costruisce l'InputImage per ML Kit da un fotogramma della fotocamera:
  /// richiede che la fotocamera sia stata avviata in formato nv21
  /// (Android) o bgra8888 (iOS), gli unici che arrivano gia' su un solo
  /// piano senza dover ricomporre a mano i piani YUV separati.
  InputImage? _inputImageFromCameraImage(
    CameraImage image,
    CameraDescription camera,
  ) {
    final rotation = InputImageRotationValue.fromRawValue(
      camera.sensorOrientation,
    );
    if (rotation == null) return null;
    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null) return null;
    if (image.planes.length != 1) return null;
    final plane = image.planes.first;

    return InputImage.fromBytes(
      bytes: plane.bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: plane.bytesPerRow,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(title: Text('Bracciate — ${widget.atleta.nomeCompleto}')),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    final colori = context.colori;
    if (_errore != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.s24),
          child: ErrorBanner(messaggio: _errore!),
        ),
      );
    }
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const LoadingSkeleton(width: 280, height: 200),
            const SizedBox(height: AppSpacing.s12),
            Text(
              'Avvio fotocamera...',
              style: AppTypography.corpo.copyWith(color: colori.testo),
            ),
          ],
        ),
      );
    }

    switch (_fase) {
      case _Fase.pronto:
        return Column(
          children: [
            Expanded(child: CameraPreview(controller)),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.s16),
              child: Column(
                children: [
                  Text(
                    'Inquadra il nuotatore per tutta la corsia, poi tocca '
                    '"Registra": la clip dura 15 secondi. Stima '
                    'sperimentale: verificala sempre con un conteggio '
                    'manuale.',
                    style: AppTypography.piccolo.copyWith(
                      color: colori.testoSecondario,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.s12),
                  PrimaryButton(
                    label: 'Registra',
                    icon: Icons.fiber_manual_record,
                    onPressed: _avviaRegistrazione,
                  ),
                ],
              ),
            ),
          ],
        );
      case _Fase.registrazione:
        return Column(
          children: [
            Expanded(child: CameraPreview(controller)),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.s16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.circle, size: 12, color: colori.rosso),
                  const SizedBox(width: AppSpacing.s8),
                  Text(
                    '$_secondiRimasti s',
                    style: AppTypography.display.copyWith(color: colori.testo),
                  ),
                ],
              ),
            ),
          ],
        );
      case _Fase.elaborazione:
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const LoadingSkeleton(width: 200, height: 16),
              const SizedBox(height: AppSpacing.s12),
              Text(
                'Elaborazione...',
                style: AppTypography.corpo.copyWith(color: colori.testo),
              ),
            ],
          ),
        );
      case _Fase.risultato:
        final valore = _bracciatePerMinuto;
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.s24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  valore == null
                      ? 'Non sono riuscito a rilevare un ritmo di bracciata '
                            'chiaro. Riprova inquadrando meglio il '
                            'nuotatore, possibilmente da bordo vasca a '
                            'livello dell\'acqua.'
                      : '${valore.round()} bracciate/min',
                  style:
                      (valore == null
                              ? AppTypography.titolo
                              : AppTypography.display)
                          .copyWith(color: colori.testo),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.s8),
                Text(
                  'Stima sperimentale dal movimento del polso: verifica '
                  'sempre con un conteggio manuale prima di fidartene. '
                  'Il risultato non viene salvato.',
                  style: AppTypography.piccolo.copyWith(
                    color: colori.testoSecondario,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.s16),
                PrimaryButton(
                  label: 'Ripeti',
                  icon: Icons.refresh,
                  expanded: false,
                  onPressed: () => setState(() => _fase = _Fase.pronto),
                ),
              ],
            ),
          ),
        );
    }
  }
}

class _CampionePolso {
  const _CampionePolso({required this.istante, this.ySinistro, this.yDestro});

  final DateTime istante;
  final double? ySinistro;
  final double? yDestro;
}
