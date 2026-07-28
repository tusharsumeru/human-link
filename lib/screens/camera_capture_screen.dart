import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// The result handed back from the camera screen: the captured file and whether
/// it is a video (true) or a still photo (false).
class CaptureResult {
  const CaptureResult(this.path, this.isVideo);
  final String path;
  final bool isVideo;
}

/// How long a recording is allowed to run before it auto-stops.
const _maxRecordSeconds = 30;

/// Full-screen live camera. Interaction is one button:
///  - a single tap takes a photo, and
///  - a press-and-hold records video, auto-stopping at [_maxRecordSeconds]
///    (or when the finger lifts, whichever comes first).
/// Pops a [CaptureResult] on capture, or null if the user backs out.
class CameraCaptureScreen extends StatefulWidget {
  const CameraCaptureScreen({super.key});

  @override
  State<CameraCaptureScreen> createState() => _CameraCaptureScreenState();
}

class _CameraCaptureScreenState extends State<CameraCaptureScreen>
    with WidgetsBindingObserver {
  List<CameraDescription> _cameras = const [];
  CameraController? _controller;
  int _cameraIndex = 0;
  bool _initializing = true;
  String? _error;

  bool _isRecording = false;
  bool _busy = false; // guards taps while a capture is in flight
  Timer? _autoStopTimer;
  Timer? _tick;
  double _recordProgress = 0; // 0..1 for the ring around the shutter
  DateTime? _recordStartedAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setup();
  }

  Future<void> _setup() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() {
          _initializing = false;
          _error = 'No camera available on this device.';
        });
        return;
      }
      _cameras = cameras;
      // Prefer the back camera for the first frame.
      _cameraIndex = cameras.indexWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
      );
      if (_cameraIndex < 0) _cameraIndex = 0;
      await _startController(_cameras[_cameraIndex]);
    } catch (e) {
      if (mounted) {
        setState(() {
          _initializing = false;
          _error = 'Camera unavailable: $e';
        });
      }
    }
  }

  Future<void> _startController(CameraDescription description) async {
    final controller = CameraController(
      description,
      ResolutionPreset.high,
      enableAudio: true, // needed for video recording
    );
    _controller = controller;
    try {
      await controller.initialize();
    } catch (e) {
      if (mounted) {
        setState(() {
          _initializing = false;
          _error = e is CameraException
              ? 'Camera permission is required. Enable it in Settings.'
              : 'Could not start the camera: $e';
        });
      }
      return;
    }
    if (mounted) setState(() => _initializing = false);
  }

  Future<void> _flipCamera() async {
    if (_cameras.length < 2 || _isRecording || _busy) return;
    setState(() => _initializing = true);
    _cameraIndex = (_cameraIndex + 1) % _cameras.length;
    await _controller?.dispose();
    await _startController(_cameras[_cameraIndex]);
  }

  // ── capture ────────────────────────────────────────────────────────────────

  Future<void> _takePhoto() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    if (_busy || _isRecording) return;
    setState(() => _busy = true);
    try {
      final file = await controller.takePicture();
      if (mounted) Navigator.of(context).pop(CaptureResult(file.path, false));
    } catch (e) {
      _showError('Could not take the photo.');
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _startRecording() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    if (_busy || _isRecording) return;
    setState(() => _busy = true);
    try {
      await controller.startVideoRecording();
      _recordStartedAt = DateTime.now();
      setState(() {
        _isRecording = true;
        _busy = false;
        _recordProgress = 0;
      });
      // Hard cap: stop automatically at the limit.
      _autoStopTimer = Timer(
        const Duration(seconds: _maxRecordSeconds),
        _stopRecording,
      );
      // Drive the progress ring.
      _tick = Timer.periodic(const Duration(milliseconds: 100), (_) {
        final started = _recordStartedAt;
        if (started == null) return;
        final elapsed = DateTime.now().difference(started).inMilliseconds;
        setState(() {
          _recordProgress =
              (elapsed / (_maxRecordSeconds * 1000)).clamp(0, 1).toDouble();
        });
      });
    } catch (e) {
      _showError('Could not start recording.');
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _stopRecording() async {
    final controller = _controller;
    if (controller == null || !_isRecording) return;
    _autoStopTimer?.cancel();
    _tick?.cancel();
    // Guard against a double stop (finger lift + auto-stop racing).
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final file = await controller.stopVideoRecording();
      if (mounted) Navigator.of(context).pop(CaptureResult(file.path, true));
    } catch (e) {
      _showError('Could not save the recording.');
      if (mounted) {
        setState(() {
          _isRecording = false;
          _busy = false;
          _recordProgress = 0;
        });
      }
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  // ── lifecycle ────────────────────────────────────────────────────────────────

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    // Release the camera when backgrounded; rebuild when we return.
    if (state == AppLifecycleState.inactive) {
      if (_isRecording) _stopRecording();
      controller.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _startController(_cameras[_cameraIndex]);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _autoStopTimer?.cancel();
    _tick?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  // ── UI ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            _buildPreview(),
            // Close button.
            Positioned(
              top: 8,
              left: 8,
              child: IconButton(
                icon: const Icon(Icons.close_rounded,
                    color: Colors.white, size: 28),
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            ),
            // Recording timer chip.
            if (_isRecording)
              Positioned(
                top: 14,
                left: 0,
                right: 0,
                child: Center(child: _recordingChip()),
              ),
            // Flip camera.
            if (_cameras.length > 1 && !_isRecording)
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  icon: const Icon(Icons.cameraswitch_rounded,
                      color: Colors.white, size: 26),
                  onPressed: _flipCamera,
                ),
              ),
            // Shutter + hint.
            Positioned(
              left: 0,
              right: 0,
              bottom: 28,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _isRecording
                        ? 'Release to stop'
                        : 'Tap for photo  ·  Hold to record',
                    style: body(13, color: Colors.white),
                  ),
                  const SizedBox(height: 14),
                  _shutter(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreview() {
    if (_initializing) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Text(
            _error!,
            textAlign: TextAlign.center,
            style: body(15, color: Colors.white),
          ),
        ),
      );
    }
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return const SizedBox.shrink();
    }
    return Center(child: CameraPreview(controller));
  }

  Widget _recordingChip() {
    final started = _recordStartedAt;
    final secs = started == null
        ? 0
        : DateTime.now().difference(started).inSeconds;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
                color: Color(0xFFEF4444), shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text('0:${secs.toString().padLeft(2, '0')} / 0:$_maxRecordSeconds',
              style: body(12, color: Colors.white)),
        ],
      ),
    );
  }

  Widget _shutter() {
    final disabled = _initializing || _error != null;
    return GestureDetector(
      onTap: disabled ? null : _takePhoto,
      onLongPressStart: disabled ? null : (_) => _startRecording(),
      onLongPressEnd: disabled ? null : (_) => _stopRecording(),
      child: SizedBox(
        width: 84,
        height: 84,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Progress ring while recording.
            if (_isRecording)
              SizedBox(
                width: 84,
                height: 84,
                child: CircularProgressIndicator(
                  value: _recordProgress,
                  strokeWidth: 4,
                  backgroundColor: Colors.white24,
                  valueColor:
                      const AlwaysStoppedAnimation(Color(0xFFEF4444)),
                ),
              ),
            // Outer ring.
            Container(
              width: 74,
              height: 74,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 4),
              ),
            ),
            // Inner disc — red square-ish while recording, white circle idle.
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: _isRecording ? 32 : 60,
              height: _isRecording ? 32 : 60,
              decoration: BoxDecoration(
                color: _isRecording ? const Color(0xFFEF4444) : Colors.white,
                borderRadius:
                    BorderRadius.circular(_isRecording ? 8 : 999),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
