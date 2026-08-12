import 'package:flutter/material.dart';

import '../../core/app_colors.dart';

class VoiceScreen extends StatefulWidget {
  const VoiceScreen({super.key});

  @override
  State<VoiceScreen> createState() => _VoiceScreenState();
}

class _VoiceScreenState extends State<VoiceScreen> {
  final TextEditingController _questionController = TextEditingController();
  bool _started = false;
  bool _muted = false;
  bool _showKeyboard = false;
  String _typedQuestion = '';

  @override
  void dispose() {
    _questionController.dispose();
    super.dispose();
  }

  void _submitQuestion() {
    final text = _questionController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _typedQuestion = text;
      _questionController.clear();
      _showKeyboard = false;
      _started = true;
      _muted = false;
    });
  }

  void _toggleStarted() {
    setState(() {
      _started = !_started;
      if (!_started) {
        _muted = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 22),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight - 38),
            child: Column(
              children: [
                TeachingWhiteboard(
                  started: _started,
                  muted: _muted,
                  typedQuestion: _typedQuestion,
                ),
                const SizedBox(height: 14),
                TutorDialogue(started: _started, muted: _muted),
                const SizedBox(height: 14),
                if (_showKeyboard) ...[
                  VoiceQuestionComposer(
                    controller: _questionController,
                    onSubmit: _submitQuestion,
                  ),
                  const SizedBox(height: 14),
                ],
                VoiceControlDock(
                  started: _started,
                  muted: _muted,
                  keyboardOpen: _showKeyboard,
                  onStartStop: _toggleStarted,
                  onMute: _started
                      ? () => setState(() => _muted = !_muted)
                      : null,
                  onKeyboard: () {
                    setState(() => _showKeyboard = !_showKeyboard);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class TeachingWhiteboard extends StatelessWidget {
  const TeachingWhiteboard({
    super.key,
    required this.started,
    required this.muted,
    required this.typedQuestion,
  });

  final bool started;
  final bool muted;
  final String typedQuestion;

  @override
  Widget build(BuildContext context) {
    final prompt = typedQuestion.isEmpty
        ? 'What is the integral of e^x?'
        : typedQuestion;

    return Container(
      width: double.infinity,
      height: 420,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEE),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFF0E7D3), width: 1.4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .28),
            blurRadius: 28,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(painter: WhiteboardGridPainter()),
          ),
          const Positioned(
            right: 12,
            bottom: 18,
            child: _FaintFlag(),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _WhiteboardTopStrip(started: started, muted: muted),
              const SizedBox(height: 18),
              Text(
                'Ready for voice tutoring',
                style: TextStyle(
                  color: const Color(0xFF1F2B3E).withValues(alpha: .58),
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: .8,
                ),
              ),
              const SizedBox(height: 16),
              const _EquationLine(text: 'f(x) = e^x', color: Color(0xFF283349)),
              const SizedBox(height: 10),
              const _EquationLine(
                text: 'd/dx e^x = e^x',
                color: Color(0xFF7C879C),
                small: true,
              ),
              const SizedBox(height: 34),
              Text(
                prompt,
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF3D89FF),
                  fontSize: 24,
                  height: 1.25,
                  fontWeight: FontWeight.w700,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const Spacer(),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Expanded(
                    child: _EquationLine(
                      text: 'Integral e^x dx =',
                      color: Color(0xFF253149),
                      large: true,
                    ),
                  ),
                  const SizedBox(width: 10),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 72,
                    height: 72,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .42),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: started
                            ? AppColors.blue
                            : const Color(0xFF7F8898),
                        width: 2,
                        strokeAlign: BorderSide.strokeAlignInside,
                      ),
                    ),
                    child: Text(
                      started ? 'e^x' : '?',
                      style: TextStyle(
                        color: started
                            ? const Color(0xFF3D89FF)
                            : const Color(0xFF7F8898),
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _TeachingHint(started: started, muted: muted),
            ],
          ),
        ],
      ),
    );
  }
}

class _WhiteboardTopStrip extends StatelessWidget {
  const _WhiteboardTopStrip({required this.started, required this.muted});

  final bool started;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final statusColor = !started
        ? const Color(0xFF7F8898)
        : muted
            ? AppColors.peach
            : AppColors.cyan;
    final statusText = !started
        ? 'WAITING FOR YOU'
        : muted
            ? 'MIC MUTED'
            : 'EXPLAINING';

    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0xFFF7F2E5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.school_outlined, color: statusColor, size: 23),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                statusText,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: statusColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 3),
              const Text(
                'Instant virtual teaching board',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Color(0xFF6F7889),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const _LiveDot(),
      ],
    );
  }
}

class _EquationLine extends StatelessWidget {
  const _EquationLine({
    required this.text,
    required this.color,
    this.small = false,
    this.large = false,
  });

  final String text;
  final Color color;
  final bool small;
  final bool large;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: color,
        fontSize: large ? 24 : (small ? 18 : 22),
        height: 1.25,
        fontWeight: FontWeight.w700,
        fontStyle: FontStyle.italic,
      ),
    );
  }
}

class _TeachingHint extends StatelessWidget {
  const _TeachingHint({required this.started, required this.muted});

  final bool started;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final text = !started
        ? 'Tap Start and I will teach on the board instantly.'
        : muted
            ? 'Unmute when you want to answer out loud.'
            : 'Notice the answer stays the same after differentiating.';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .64),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEDE4CE)),
      ),
      child: Row(
        children: [
          Icon(
            started ? Icons.auto_awesome_rounded : Icons.touch_app_outlined,
            color: AppColors.blue,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Color(0xFF4E596B),
                fontSize: 13,
                height: 1.3,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TutorDialogue extends StatelessWidget {
  const TutorDialogue({super.key, required this.started, required this.muted});

  final bool started;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final text = !started
        ? '"Tap Start and ask your question. I will write the lesson as we talk."'
        : muted
            ? '"I paused listening. Your whiteboard stays ready."'
            : '"Now, tell me what step you want to understand next."';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        color: AppColors.panel.withValues(alpha: .9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: .06)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.cyan.withValues(alpha: .12),
            ),
            child: const Icon(
              Icons.chat_bubble_outline_rounded,
              color: AppColors.cyan,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.subtle,
                fontSize: 15,
                height: 1.45,
                fontWeight: FontWeight.w700,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class VoiceQuestionComposer extends StatelessWidget {
  const VoiceQuestionComposer({
    super.key,
    required this.controller,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0E1422),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cyan.withValues(alpha: .18)),
      ),
      child: Row(
        children: [
          const Icon(Icons.edit_note_rounded, color: AppColors.muted, size: 22),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              key: const Key('voice-question-field'),
              controller: controller,
              minLines: 1,
              maxLines: 3,
              style: const TextStyle(color: AppColors.text),
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onSubmit(),
              decoration: const InputDecoration(
                hintText: 'Type a follow-up...',
                hintStyle: TextStyle(color: AppColors.muted),
                border: InputBorder.none,
              ),
            ),
          ),
          IconButton.filled(
            tooltip: 'Send question',
            onPressed: onSubmit,
            style: IconButton.styleFrom(backgroundColor: AppColors.blue),
            icon: const Icon(Icons.send_rounded),
          ),
        ],
      ),
    );
  }
}

class VoiceControlDock extends StatelessWidget {
  const VoiceControlDock({
    super.key,
    required this.started,
    required this.muted,
    required this.keyboardOpen,
    required this.onStartStop,
    required this.onMute,
    required this.onKeyboard,
  });

  final bool started;
  final bool muted;
  final bool keyboardOpen;
  final VoidCallback onStartStop;
  final VoidCallback? onMute;
  final VoidCallback onKeyboard;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TeachingToolButton(
            tooltip: muted ? 'Unmute microphone' : 'Mute microphone',
            icon: muted ? Icons.mic_off_rounded : Icons.mic_none_rounded,
            label: muted ? 'Unmute' : 'Mute',
            selected: started && !muted,
            danger: muted,
            onPressed: onMute,
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 94,
          child: StartButton(
            started: started,
            onPressed: onStartStop,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: TeachingToolButton(
            tooltip: keyboardOpen ? 'Close keyboard' : 'Type a question',
            icon: Icons.keyboard_alt_outlined,
            label: keyboardOpen ? 'Close' : 'Keyboard',
            selected: keyboardOpen,
            onPressed: onKeyboard,
          ),
        ),
      ],
    );
  }
}

class TeachingToolButton extends StatelessWidget {
  const TeachingToolButton({
    super.key,
    required this.tooltip,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onPressed,
    this.danger = false,
  });

  final String tooltip;
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback? onPressed;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final color = danger
        ? AppColors.peach
        : selected
            ? AppColors.cyan
            : AppColors.muted;

    return Tooltip(
      message: tooltip,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          fixedSize: const Size.fromHeight(68),
          side: BorderSide(color: color.withValues(alpha: selected ? .86 : .28)),
          foregroundColor: color,
          backgroundColor: selected
              ? color.withValues(alpha: .13)
              : const Color(0xFF162034),
          disabledForegroundColor: AppColors.muted.withValues(alpha: .42),
          disabledBackgroundColor: const Color(0xFF111827),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 23),
            const SizedBox(height: 5),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                maxLines: 1,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class StartButton extends StatelessWidget {
  const StartButton({
    super.key,
    required this.started,
    required this.onPressed,
  });

  final bool started;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: started ? 'Stop instant call' : 'Start instant call',
      child: FilledButton(
        key: const Key('voice-start-button'),
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          fixedSize: const Size.fromHeight(76),
          padding: EdgeInsets.zero,
          backgroundColor: started ? AppColors.peach : AppColors.cyan,
          foregroundColor: started ? const Color(0xFF62191A) : Colors.black,
          shape: const CircleBorder(),
          elevation: 18,
          shadowColor:
              (started ? AppColors.peach : AppColors.cyan).withValues(alpha: .28),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              started ? Icons.stop_rounded : Icons.mic_rounded,
              size: 28,
            ),
            const SizedBox(height: 2),
            Text(
              started ? 'Stop' : 'Start',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900),
            ),
          ],
        ),
      ),
    );
  }
}

class _LiveDot extends StatelessWidget {
  const _LiveDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: AppColors.cyan,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.cyan.withValues(alpha: .38),
            blurRadius: 12,
          ),
        ],
      ),
    );
  }
}

class _FaintFlag extends StatelessWidget {
  const _FaintFlag();

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: .12,
      child: Icon(
        Icons.flag_rounded,
        color: const Color(0xFF253149),
        size: 54,
      ),
    );
  }
}

class WhiteboardGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = const Color(0xFFEDE2CE).withValues(alpha: .2)
      ..strokeWidth = 1;
    for (var y = 26.0; y < size.height; y += 34) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final rulePaint = Paint()
      ..color = const Color(0xFFDCB9A4).withValues(alpha: .18)
      ..strokeWidth = 1.2;
    canvas.drawLine(const Offset(26, 0), Offset(26, size.height), rulePaint);

    final markerPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..color = AppColors.blue.withValues(alpha: .52);
    final path = Path()
      ..moveTo(size.width * .17, size.height * .58)
      ..quadraticBezierTo(
        size.width * .32,
        size.height * .51,
        size.width * .46,
        size.height * .57,
      )
      ..quadraticBezierTo(
        size.width * .57,
        size.height * .63,
        size.width * .72,
        size.height * .55,
      );
    canvas.drawPath(path, markerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
