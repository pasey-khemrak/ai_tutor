import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/adaptive_colors.dart';
import '../../core/app_colors.dart';
import '../auth/rean_logo_mark.dart';

enum _VoiceLessonStage { waiting, listening, writing, explaining, solved }

class VoiceScreen extends StatefulWidget {
  const VoiceScreen({super.key});

  @override
  State<VoiceScreen> createState() => _VoiceScreenState();
}

class _VoiceScreenState extends State<VoiceScreen> {
  final TextEditingController _questionController = TextEditingController();
  final List<Timer> _timers = [];
  _VoiceLessonStage? _stage = _VoiceLessonStage.waiting;
  bool _muted = false;
  bool _keyboardOpen = false;
  String _question = 'What is the integral of e^x?';

  _VoiceLessonStage get _safeStage => _stage ?? _VoiceLessonStage.waiting;

  @override
  void dispose() {
    for (final timer in _timers) {
      timer.cancel();
    }
    _questionController.dispose();
    super.dispose();
  }

  void _startInstantLesson({String? question}) {
    for (final timer in _timers) {
      timer.cancel();
    }
    _timers.clear();

    setState(() {
      if (question != null && question.trim().isNotEmpty) {
        _question = question.trim();
      }
      _stage = _VoiceLessonStage.listening;
      _muted = false;
      _keyboardOpen = false;
    });

    _timers.add(Timer(const Duration(milliseconds: 550), () {
      if (!mounted) return;
      setState(() => _stage = _VoiceLessonStage.writing);
    }));
    _timers.add(Timer(const Duration(milliseconds: 1300), () {
      if (!mounted) return;
      setState(() => _stage = _VoiceLessonStage.explaining);
    }));
  }

  void _toggleCall() {
    final stage = _safeStage;
    if (stage == _VoiceLessonStage.waiting ||
        stage == _VoiceLessonStage.solved) {
      _startInstantLesson();
      return;
    }

    for (final timer in _timers) {
      timer.cancel();
    }
    _timers.clear();
    setState(() {
      _stage = _VoiceLessonStage.waiting;
      _muted = false;
    });
  }

  void _submitTypedQuestion() {
    final text = _questionController.text.trim();
    if (text.isEmpty) return;
    _questionController.clear();
    _startInstantLesson(question: text);
  }

  void _showVisualExample() {
    setState(() {
      _question = 'How does amplitude change a sine graph?';
      _stage = _VoiceLessonStage.explaining;
      _muted = false;
      _keyboardOpen = false;
    });
  }

  void _showSolution() {
    setState(() {
      _stage = _VoiceLessonStage.solved;
      _muted = false;
      _keyboardOpen = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isLight = AdaptiveColors.isLight(context);
    final stage = _safeStage;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: isLight ? const Color(0xFFF6F8FF) : AppColors.background,
      ),
      child: Column(
        children: [
          _VoiceCallHeader(stage: stage),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 14, 22, 18),
              child: Column(
                children: [
                  _LiveWhiteboard(
                    stage: stage,
                    question: _question,
                    onShowSolution: _showSolution,
                  ),
                  const SizedBox(height: 14),
                  _TeacherPanel(
                    stage: stage,
                    muted: _muted,
                    onHint: () => _startInstantLesson(question: _question),
                    onExplainDifferent: _showVisualExample,
                    onShowSolution: _showSolution,
                  ),
                  if (_keyboardOpen) ...[
                    const SizedBox(height: 12),
                    _FollowUpComposer(
                      controller: _questionController,
                      onSubmit: _submitTypedQuestion,
                    ),
                  ],
                ],
              ),
            ),
          ),
          _CallControls(
            stage: stage,
            muted: _muted,
            keyboardOpen: _keyboardOpen,
            onMic: _toggleCall,
            onMute: () => setState(() => _muted = !_muted),
            onKeyboard: () => setState(() => _keyboardOpen = !_keyboardOpen),
          ),
        ],
      ),
    );
  }
}

class _VoiceCallHeader extends StatelessWidget {
  const _VoiceCallHeader({required this.stage});

  final _VoiceLessonStage stage;

  @override
  Widget build(BuildContext context) {
    final status = switch (stage) {
      _VoiceLessonStage.waiting => 'Waiting for you',
      _VoiceLessonStage.listening => 'Listening...',
      _VoiceLessonStage.writing => 'Writing...',
      _VoiceLessonStage.explaining => 'Explaining',
      _VoiceLessonStage.solved => 'Problem solved',
    };
    final statusColor = switch (stage) {
      _VoiceLessonStage.waiting => AppColors.cyan,
      _VoiceLessonStage.listening => AppColors.cyan,
      _VoiceLessonStage.writing => const Color(0xFF8BA0FF),
      _VoiceLessonStage.explaining => AppColors.cyan,
      _VoiceLessonStage.solved => const Color(0xFF72E38D),
    };

    return Container(
      height: 86,
      padding: const EdgeInsets.fromLTRB(20, 10, 16, 10),
      decoration: const BoxDecoration(
        color: Color(0xFF08111F),
        border: Border(bottom: BorderSide(color: Color(0xFF18233A))),
      ),
      child: Row(
        children: [
          const ReanLogoMark(size: 48, showGlow: false),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Rean AI Tutor',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  status,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Lesson menu',
            onPressed: () {},
            icon: const Icon(Icons.menu_rounded, color: Color(0xFF5E6B80)),
          ),
        ],
      ),
    );
  }
}

class _LiveWhiteboard extends StatelessWidget {
  const _LiveWhiteboard({
    required this.stage,
    required this.question,
    required this.onShowSolution,
  });

  final _VoiceLessonStage stage;
  final String question;
  final VoidCallback onShowSolution;

  @override
  Widget build(BuildContext context) {
    final isLight = AdaptiveColors.isLight(context);
    final boardColor = isLight ? const Color(0xFFFFFBEE) : const Color(0xFFFFFBEE);
    final showSine = question.toLowerCase().contains('sine') ||
        question.toLowerCase().contains('sin');

    return Container(
      width: double.infinity,
      height: 360,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: boardColor,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFEDE3CF), width: 1.4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isLight ? .10 : .34),
            blurRadius: 30,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: showSine
                  ? _SineBoardPainter(stage: stage)
                  : _IntegralBoardPainter(stage: stage),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: 82,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 220),
              opacity: stage == _VoiceLessonStage.waiting ||
                      stage == _VoiceLessonStage.listening
                  ? 1
                  : .28,
              child: Text(
                question,
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF3D89FF),
                  fontSize: 24,
                  height: 1.25,
                  fontWeight: FontWeight.w800,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ),
          if (stage == _VoiceLessonStage.solved)
            Positioned(
              left: 0,
              right: 0,
              bottom: 22,
              child: _FinalAnswerCard(onNext: onShowSolution),
            ),
        ],
      ),
    );
  }
}

class _TeacherPanel extends StatelessWidget {
  const _TeacherPanel({
    required this.stage,
    required this.muted,
    required this.onHint,
    required this.onExplainDifferent,
    required this.onShowSolution,
  });

  final _VoiceLessonStage stage;
  final bool muted;
  final VoidCallback onHint;
  final VoidCallback onExplainDifferent;
  final VoidCallback onShowSolution;

  @override
  Widget build(BuildContext context) {
    final isLight = AdaptiveColors.isLight(context);
    final panelColor = isLight ? Colors.white : AppColors.panel;
    final textColor = AdaptiveColors.text(context);
    final mutedColor = AdaptiveColors.muted(context);
    final lineColor = AdaptiveColors.line(context);
    final message = switch (stage) {
      _VoiceLessonStage.waiting =>
        'Tap the microphone and ask me a question. I will write and explain as we go.',
      _VoiceLessonStage.listening =>
        muted ? 'I am paused while your mic is muted.' : 'I am listening. Tell me the problem.',
      _VoiceLessonStage.writing =>
        'Let me write the first steps on the board.',
      _VoiceLessonStage.explaining =>
        'Use integration by parts: choose u = x, and dv = e^x dx.',
      _VoiceLessonStage.solved =>
        'Great work. The final answer is ready, and we can practice a similar one.',
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: panelColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: lineColor),
      ),
      child: Column(
        children: [
          Text(
            '"$message"',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: textColor,
              fontSize: 16,
              height: 1.4,
              fontWeight: FontWeight.w800,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _TeacherActionButton(
                  icon: Icons.lightbulb_outline_rounded,
                  label: 'Hint',
                  onPressed: onHint,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _TeacherActionButton(
                  icon: Icons.shuffle_rounded,
                  label: 'Explain Differently',
                  onPressed: onExplainDifferent,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _TeacherActionButton(
                  icon: Icons.visibility_rounded,
                  label: 'Show Visually',
                  onPressed: onShowSolution,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Instant lesson mode',
            style: TextStyle(
              color: mutedColor,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _TeacherActionButton extends StatelessWidget {
  const _TeacherActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final isLight = AdaptiveColors.isLight(context);
    return SizedBox(
      height: 58,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: isLight ? const Color(0xFF31405C) : AppColors.text,
          backgroundColor: isLight ? const Color(0xFFF4F7FF) : const Color(0xFF172238),
          side: BorderSide(color: AdaptiveColors.line(context)),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: AppColors.cyan),
            const SizedBox(height: 4),
            FittedBox(
              child: Text(
                label,
                maxLines: 1,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FollowUpComposer extends StatelessWidget {
  const _FollowUpComposer({
    required this.controller,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      minLines: 1,
      maxLines: 3,
      textInputAction: TextInputAction.send,
      onSubmitted: (_) => onSubmit(),
      style: TextStyle(
        color: AdaptiveColors.text(context),
        fontSize: 15,
        fontWeight: FontWeight.w700,
      ),
      decoration: InputDecoration(
        hintText: 'Ask a follow-up...',
        hintStyle: TextStyle(color: AdaptiveColors.muted(context)),
        filled: true,
        fillColor: AdaptiveColors.panel(context),
        suffixIcon: IconButton(
          tooltip: 'Send follow-up',
          onPressed: onSubmit,
          icon: const Icon(Icons.send_rounded),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AdaptiveColors.line(context)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AdaptiveColors.line(context)),
        ),
      ),
    );
  }
}

class _CallControls extends StatelessWidget {
  const _CallControls({
    required this.stage,
    required this.muted,
    required this.keyboardOpen,
    required this.onMic,
    required this.onMute,
    required this.onKeyboard,
  });

  final _VoiceLessonStage stage;
  final bool muted;
  final bool keyboardOpen;
  final VoidCallback onMic;
  final VoidCallback onMute;
  final VoidCallback onKeyboard;

  @override
  Widget build(BuildContext context) {
    final isActive = stage != _VoiceLessonStage.waiting &&
        stage != _VoiceLessonStage.solved;
    final isLight = AdaptiveColors.isLight(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 18),
      decoration: BoxDecoration(
        color: isLight ? Colors.white : AppColors.panel,
        border: Border(top: BorderSide(color: AdaptiveColors.line(context))),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _RoundControlButton(
              tooltip: muted ? 'Unmute microphone' : 'Mute microphone',
              icon: muted ? Icons.mic_rounded : Icons.mic_off_rounded,
              selected: muted,
              enabled: isActive,
              onPressed: onMute,
            ),
            _MicButton(active: isActive, onPressed: onMic),
            _RoundControlButton(
              tooltip: 'Type a follow-up',
              icon: Icons.keyboard_rounded,
              selected: keyboardOpen,
              enabled: true,
              onPressed: onKeyboard,
            ),
          ],
        ),
      ),
    );
  }
}

class _MicButton extends StatelessWidget {
  const _MicButton({required this.active, required this.onPressed});

  final bool active;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.peach : AppColors.cyan;
    return Container(
      width: 78,
      height: 78,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: .55),
            blurRadius: 28,
            spreadRadius: 2,
          ),
        ],
      ),
      child: IconButton(
        tooltip: active ? 'End voice lesson' : 'Start voice lesson',
        onPressed: onPressed,
        style: IconButton.styleFrom(
          backgroundColor: color,
          foregroundColor: const Color(0xFF07111E),
          shape: const CircleBorder(),
        ),
        icon: Icon(active ? Icons.call_end_rounded : Icons.mic_rounded, size: 34),
      ),
    );
  }
}

class _RoundControlButton extends StatelessWidget {
  const _RoundControlButton({
    required this.tooltip,
    required this.icon,
    required this.selected,
    required this.enabled,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final bool selected;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final isLight = AdaptiveColors.isLight(context);
    final background = selected
        ? AppColors.cyan
        : isLight
        ? const Color(0xFFF0F4FF)
        : const Color(0xFF172238);
    final foreground = selected
        ? const Color(0xFF07111E)
        : enabled
        ? AdaptiveColors.text(context)
        : AdaptiveColors.muted(context).withValues(alpha: .5);

    return SizedBox.square(
      dimension: 56,
      child: IconButton(
        tooltip: tooltip,
        onPressed: enabled ? onPressed : null,
        style: IconButton.styleFrom(
          backgroundColor: background,
          disabledBackgroundColor: background.withValues(alpha: .55),
          foregroundColor: foreground,
          shape: const CircleBorder(),
        ),
        icon: Icon(icon),
      ),
    );
  }
}

class _FinalAnswerCard extends StatelessWidget {
  const _FinalAnswerCard({required this.onNext});

  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF07111E),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cyan, width: 2),
      ),
      child: Column(
        children: [
          const Text(
            'FINAL RESULT',
            style: TextStyle(
              color: AppColors.cyan,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'e^x + C',
            style: TextStyle(
              color: AppColors.cyan,
              fontSize: 28,
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 10),
          FilledButton.icon(
            onPressed: onNext,
            icon: const Icon(Icons.arrow_forward_rounded),
            label: const Text('Next Practice'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.cyan,
              foregroundColor: const Color(0xFF07111E),
            ),
          ),
        ],
      ),
    );
  }
}

class _IntegralBoardPainter extends CustomPainter {
  const _IntegralBoardPainter({required this.stage});

  final _VoiceLessonStage stage;

  @override
  void paint(Canvas canvas, Size size) {
    final ink = Paint()
      ..color = const Color(0xFF253149)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final blue = Paint()
      ..color = const Color(0xFF3D89FF)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final faint = Paint()
      ..color = const Color(0xFFE9E2D1)
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawLine(Offset(size.width * .08, 42), Offset(size.width * .92, 42), faint);
    _drawIntegral(canvas, Offset(size.width * .12, 48), 74, ink);
    _drawText(canvas, 'e^x dx', Offset(size.width * .28, 72), 27, const Color(0xFF253149));

    if (stage.index >= _VoiceLessonStage.writing.index) {
      _drawText(canvas, '= e^x + C', Offset(size.width * .16, 160), 30, const Color(0xFF253149));
      canvas.drawLine(Offset(size.width * .16, 204), Offset(size.width * .34, 204), blue);
      _drawText(canvas, 'same derivative', Offset(size.width * .40, 205), 16, const Color(0xFF3D89FF));
    }

    if (stage.index >= _VoiceLessonStage.explaining.index) {
      final rect = Rect.fromLTWH(size.width * .62, 205, 80, 76);
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(14)),
        Paint()
          ..color = const Color(0xFFECE7D8)
          ..style = PaintingStyle.fill,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(14)),
        Paint()
          ..color = const Color(0xFF7C879C)
          ..strokeWidth = 3
          ..style = PaintingStyle.stroke,
      );
      _drawText(canvas, '?', Offset(rect.left + 30, rect.top + 50), 30, const Color(0xFF7C879C));
      _drawText(canvas, 'The antiderivative keeps e^x.', Offset(size.width * .08, size.height - 34), 18, const Color(0xFF3D89FF));
    }
  }

  void _drawIntegral(Canvas canvas, Offset origin, double height, Paint paint) {
    final path = Path()
      ..moveTo(origin.dx + 20, origin.dy)
      ..cubicTo(origin.dx - 8, origin.dy + 10, origin.dx + 34, origin.dy + 32, origin.dx + 4, origin.dy + height)
      ..cubicTo(origin.dx - 8, origin.dy + height + 16, origin.dx + 14, origin.dy + height + 22, origin.dx + 28, origin.dy + height + 6);
    canvas.drawPath(path, paint);
  }

  void _drawText(Canvas canvas, String text, Offset offset, double size, Color color) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: size,
          fontWeight: FontWeight.w700,
          fontStyle: FontStyle.italic,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant _IntegralBoardPainter oldDelegate) {
    return oldDelegate.stage != stage;
  }
}

class _SineBoardPainter extends CustomPainter {
  const _SineBoardPainter({required this.stage});

  final _VoiceLessonStage stage;

  @override
  void paint(Canvas canvas, Size size) {
    final axis = Paint()
      ..color = const Color(0xFF253149)
      ..strokeWidth = 2;
    final wave = Paint()
      ..color = const Color(0xFF3D89FF)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    _drawText(canvas, 'f(x) = sin(x)', Offset(size.width * .12, 38), 22, const Color(0xFF253149));
    canvas.drawLine(Offset(size.width * .12, 175), Offset(size.width * .88, 175), axis);
    canvas.drawLine(Offset(size.width * .62, 78), Offset(size.width * .62, 270), axis);

    final path = Path();
    for (var i = 0; i <= 120; i++) {
      final t = i / 120;
      final x = size.width * (.16 + .68 * t);
      final y = 175 - 42 * MathLike.sin(t * 6.28);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, wave);

    if (stage.index >= _VoiceLessonStage.explaining.index) {
      canvas.drawCircle(Offset(size.width * .66, 175), 8, Paint()..color = AppColors.cyan);
      _drawText(canvas, 'Amplitude = 1', Offset(size.width * .66, 128), 16, const Color(0xFF3D89FF));
      _drawText(canvas, 'Peak', Offset(size.width * .45, 82), 16, const Color(0xFF3D89FF));
      _drawText(canvas, 'Trough', Offset(size.width * .66, 244), 16, const Color(0xFF253149));
    }
  }

  void _drawText(Canvas canvas, String text, Offset offset, double size, Color color) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: size,
          fontWeight: FontWeight.w800,
          fontStyle: FontStyle.italic,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant _SineBoardPainter oldDelegate) {
    return oldDelegate.stage != stage;
  }
}

class MathLike {
  const MathLike._();

  static double sin(double radians) {
    var x = radians;
    while (x > 3.141592653589793) {
      x -= 6.283185307179586;
    }
    while (x < -3.141592653589793) {
      x += 6.283185307179586;
    }
    return x - (x * x * x) / 6 + (x * x * x * x * x) / 120;
  }
}
