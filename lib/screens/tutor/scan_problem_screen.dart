import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../features/visual_tutor/data/scan_problem_repository.dart';

class ScanProblemScreen extends StatefulWidget {
  const ScanProblemScreen({
    super.key,
    this.repository,
    this.imagePicker,
    this.imageValidator,
    this.processingStarter,
  });

  final ScanProblemRepository? repository;
  final Future<XFile?> Function(ImageSource source)? imagePicker;

  /// Test seam only; production always uses decoded-image validation below.
  final Future<void> Function(Uint8List bytes)? imageValidator;

  /// Test seam only; production yields once before showing OCR processing.
  final Future<void> Function()? processingStarter;

  @override
  State<ScanProblemScreen> createState() => _ScanProblemScreenState();
}

class _ScanProblemScreenState extends State<ScanProblemScreen> {
  static const _maxBytes = 8 * 1024 * 1024;
  final _picker = ImagePicker();
  final _textController = TextEditingController();
  late final ScanProblemRepository _repository;
  XFile? _image;
  Uint8List? _bytes;
  _ScanState _state = _ScanState.pick;
  String? _error;
  List<String> _mathCandidates = const [];

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? ScanProblemRepository();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _pick(ImageSource source) async {
    setState(() => _error = null);
    try {
      final image =
          await (widget.imagePicker?.call(source) ??
              _picker.pickImage(
                source: source,
                imageQuality: 92,
                maxWidth: 2400,
                maxHeight: 2400,
              ));
      if (image == null) return;
      final bytes = await image.readAsBytes();
      if (bytes.isEmpty || bytes.length > _maxBytes) {
        throw _ScanException(
          'Choose a clear JPG, PNG, or WEBP image under 8 MB.',
        );
      }
      await (widget.imageValidator ?? _validateDimensions)(bytes);
      // Browser pickers do not consistently preserve a filename or MIME type.
      // Identify the supported image format from its signature as a safe
      // fallback; this is more trustworthy than accepting an unknown type.
      final contentType =
          _contentType(image.name) ??
          _contentTypeFromBytes(bytes) ??
          image.mimeType;
      if (!_isAllowedContentType(contentType)) {
        throw _ScanException('Use a JPG, PNG, or WEBP image.');
      }
      if (!mounted) return;
      setState(() {
        _image = image;
        _bytes = bytes;
        _state = _ScanState.preview;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        final denied =
            error.toString().toLowerCase().contains('denied') ||
            error.toString().toLowerCase().contains('permission');
        _state = denied ? _ScanState.permissionDenied : _ScanState.pick;
        _error = error is _ScanException
            ? error.message
            : (denied
                  ? 'Camera or photo-library access was denied. Allow access and try again.'
                  : 'We could not open the camera or photo library. Try again.');
      });
    }
  }

  Future<void> _validateDimensions(Uint8List bytes) async {
    try {
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final width = frame.image.width;
      final height = frame.image.height;
      frame.image.dispose();
      codec.dispose();
      if (width < 160 || height < 160) {
        throw const _ScanException(
          'Image is too small to read. Use a clearer photo.',
        );
      }
      if (width * height > 12000000) {
        throw const _ScanException(
          'Image dimensions are too large. Choose an image under 12 megapixels.',
        );
      }
    } on _ScanException {
      rethrow;
    } catch (_) {
      throw const _ScanException('This file is not a readable image.');
    }
  }

  Future<void> _process() async {
    final image = _image;
    final bytes = _bytes;
    if (image == null || bytes == null) return;
    final contentType =
        _contentType(image.name) ??
        _contentTypeFromBytes(bytes) ??
        image.mimeType;
    if (!_isAllowedContentType(contentType)) return;
    setState(() {
      _state = _ScanState.uploading;
      _error = null;
    });
    try {
      // Yield once so the accessibility-visible uploading state is rendered
      // before a potentially slow network request starts.
      await (widget.processingStarter?.call() ??
          Future<void>.delayed(Duration.zero));
      if (mounted) setState(() => _state = _ScanState.processing);
      final result = await _repository.scan(
        bytes: bytes,
        filename: image.name,
        contentType: contentType!,
      );
      if (result.detectedText.isEmpty) {
        throw _ScanException(
          'We could not read a question. Use a clearer, well-lit image.',
        );
      }
      if (!mounted) return;
      setState(() {
        _textController.text = result.detectedText;
        _mathCandidates = result.mathExpressionCandidates;
        _state = _ScanState.correct;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        final scanError = error is ScanProblemException ? error : null;
        _state = scanError?.code == 'UNREADABLE_IMAGE'
            ? _ScanState.unreadable
            : scanError?.code == 'AI_UNAVAILABLE'
            ? _ScanState.aiUnavailable
            : _ScanState.failure;
        _error = error is _ScanException
            ? error.message
            : scanError?.message ??
                  'We could not read this image. Try a sharper photo with the whole question visible.';
      });
    }
  }

  void _confirm() {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      setState(
        () => _error = 'Enter or correct the question before continuing.',
      );
      return;
    }
    Navigator.of(context).pop(text);
  }

  String? _contentType(String name) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    return null;
  }

  String? _contentTypeFromBytes(Uint8List bytes) {
    if (bytes.length >= 8 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47 &&
        bytes[4] == 0x0D &&
        bytes[5] == 0x0A &&
        bytes[6] == 0x1A &&
        bytes[7] == 0x0A) {
      return 'image/png';
    }
    if (bytes.length >= 3 &&
        bytes[0] == 0xFF &&
        bytes[1] == 0xD8 &&
        bytes[2] == 0xFF) {
      return 'image/jpeg';
    }
    if (bytes.length >= 12 &&
        bytes[0] == 0x52 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x46 &&
        bytes[8] == 0x57 &&
        bytes[9] == 0x45 &&
        bytes[10] == 0x42 &&
        bytes[11] == 0x50) {
      return 'image/webp';
    }
    return null;
  }

  bool _isAllowedContentType(String? value) =>
      value == 'image/jpeg' || value == 'image/png' || value == 'image/webp';

  @override
  Widget build(BuildContext context) {
    final image = _image;
    return Scaffold(
      appBar: AppBar(title: const Text('Scan a problem')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (image != null)
              Expanded(child: Image.memory(_bytes!, fit: BoxFit.contain))
            else
              const Expanded(
                child: Center(
                  child: Text(
                    'Take a clear photo or choose one from your library.',
                  ),
                ),
              ),
            if (_state == _ScanState.preview)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  'Preview your image. Retake it or read the visible question.',
                  key: Key('scan-preview'),
                ),
              ),
            if (_state == _ScanState.processing)
              const Padding(
                key: Key('scan-processing'),
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              ),
            if (_state == _ScanState.uploading)
              const Padding(
                key: Key('scan-uploading'),
                padding: EdgeInsets.all(16),
                child: Center(child: Text('Uploading your image securely...')),
              ),
            if (_state == _ScanState.correct) ...[
              const Text(
                key: Key('scan-editable-correction'),
                'Check and correct the detected question before sending it.',
              ),
              const SizedBox(height: 8),
              if (_mathCandidates.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    'Visible math candidates: ${_mathCandidates.join('  •  ')}\nThese are OCR text, not solved or normalized math.',
                  ),
                ),
              TextField(
                key: const Key('scan-detected-text'),
                controller: _textController,
                minLines: 3,
                maxLines: 7,
                decoration: const InputDecoration(border: OutlineInputBorder()),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 16),
            if (_state == _ScanState.permissionDenied)
              const Text(
                'Permission denied. Allow camera or photo access in settings, then try again.',
                key: Key('scan-permission-denied'),
              ),
            if (_state == _ScanState.unreadable)
              const Text(
                'This image is unreadable. Retake it with the whole question in focus.',
                key: Key('scan-unreadable-image'),
              ),
            if (_state == _ScanState.aiUnavailable)
              const Text(
                'Image reading is unavailable right now.',
                key: Key('scan-ai-unavailable'),
              ),
            if (_state == _ScanState.failure)
              const Text(
                'We could not process this image. You can retry the same image or retake it.',
                key: Key('scan-failure'),
              ),
            if (_state == _ScanState.pick ||
                _state == _ScanState.permissionDenied)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _pick(ImageSource.gallery),
                      child: Semantics(
                        label: 'Choose a problem photo from your library',
                        child: Text('Choose photo'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => _pick(ImageSource.camera),
                      child: Semantics(
                        label: 'Take a photo of a problem with the camera',
                        child: Text('Use camera'),
                      ),
                    ),
                  ),
                ],
              )
            else if (_state == _ScanState.preview ||
                _state == _ScanState.failure ||
                _state == _ScanState.unreadable ||
                _state == _ScanState.aiUnavailable)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _pick(ImageSource.camera),
                      child: Semantics(
                        label: 'Retake the problem photo',
                        child: Text('Retake'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _process,
                      child: Semantics(
                        label: _state == _ScanState.preview
                            ? 'Upload this image and read the visible question'
                            : 'Retry reading the current problem image',
                        child: Text(
                          _state == _ScanState.preview
                              ? 'Read question'
                              : 'Retry this image',
                        ),
                      ),
                    ),
                  ),
                ],
              )
            else if (_state == _ScanState.correct)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _pick(ImageSource.gallery),
                      child: const Text('Choose another'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _confirm,
                      child: Semantics(
                        label: 'Confirm corrected question and start tutoring',
                        child: Text('Start tutoring'),
                      ),
                    ),
                  ),
                ],
              )
            else
              const SizedBox.shrink(),
          ],
        ),
      ),
    );
  }
}

enum _ScanState {
  pick,
  permissionDenied,
  preview,
  uploading,
  processing,
  correct,
  unreadable,
  aiUnavailable,
  failure,
}

class _ScanException implements Exception {
  const _ScanException(this.message);
  final String message;
}
