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
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 34),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight - 44),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _started
                    ? VoiceCard(muted: _muted, typedQuestion: _typedQuestion)
                    : const VoiceReadyCard(),
                const SizedBox(height: 20),
                ListeningPrompt(started: _started, muted: _muted),
                const SizedBox(height: 22),
                if (_showKeyboard) ...[
                  VoiceQuestionComposer(
                    controller: _questionController,
                    onSubmit: _submitQuestion,
                  ),
                  const SizedBox(height: 22),
                ],
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    RoundActionButton(
                      tooltip: _muted ? 'Unmute microphone' : 'Mute microphone',
                      icon: _muted
                          ? Icons.mic_off_outlined
                          : Icons.mic_none_rounded,
                      selected: _started && !_muted,
                      onPressed: _started
                          ? () => setState(() => _muted = !_muted)
                          : null,
                    ),
                    _started
                        ? StopButton(
                            onPressed: () => setState(() {
                              _started = false;
                              _muted = false;
                            }),
                          )
                        : StartButton(
                            onPressed: () => setState(() => _started = true),
                          ),
                    RoundActionButton(
                      tooltip: 'Type a question',
                      icon: Icons.keyboard_alt_outlined,
                      selected: _showKeyboard,
                      onPressed: () {
                        setState(() => _showKeyboard = !_showKeyboard);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class VoiceReadyCard extends StatelessWidget {
  const VoiceReadyCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 360),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: .06)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 126,
            height: 126,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.panel,
              border: Border.all(color: AppColors.cyan.withValues(alpha: .32)),
            ),
            child: const Icon(
              Icons.mic_none_rounded,
              color: AppColors.cyan,
              size: 48,
            ),
          ),
          const SizedBox(height: 28),
          const Text(
            'Ready for voice tutoring',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.text,
              fontSize: 26,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Start when you are ready, or use the keyboard to type your question.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.muted, fontSize: 16, height: 1.45),
          ),
        ],
      ),
    );
  }
}

class VoiceCard extends StatelessWidget {
  const VoiceCard({
    super.key,
    required this.muted,
    required this.typedQuestion,
  });

  final bool muted;
  final String typedQuestion;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 360),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(36),
        border: Border.all(color: Colors.white.withValues(alpha: .06)),
        boxShadow: [
          BoxShadow(
            color: AppColors.cyan.withValues(alpha: muted ? .04 : .1),
            blurRadius: 42,
            offset: const Offset(0, 24),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(child: CustomPaint(painter: VoiceRingsPainter())),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              VoiceOrb(muted: muted),
              const SizedBox(height: 34),
              Text(
                muted
                    ? 'Microphone muted'
                    : '"I am listening,\nSeypa."',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 29,
                  height: 1.18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (typedQuestion.isNotEmpty) ...[
                const SizedBox(height: 14),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    typedQuestion,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.cyan,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              AudioBars(active: !muted),
            ],
          ),
        ],
      ),
    );
  }
}

class VoiceOrb extends StatelessWidget {
  const VoiceOrb({super.key, required this.muted});

  final bool muted;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 142,
      height: 142,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: SweepGradient(
          colors: muted
              ? const [
                  AppColors.line,
                  AppColors.muted,
                  AppColors.line,
                  AppColors.line,
                ]
              : const [
                  AppColors.cyan,
                  Color(0xFFB9F7FF),
                  Color(0xFF9AD7FF),
                  AppColors.cyan,
                ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.cyan.withValues(alpha: muted ? .08 : .24),
            blurRadius: 26,
          ),
        ],
      ),
      padding: const EdgeInsets.all(10),
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF132D3E),
          shape: BoxShape.circle,
        ),
        child: Icon(
          muted ? Icons.mic_off_outlined : Icons.graphic_eq_rounded,
          color: muted ? AppColors.muted : AppColors.cyan,
        ),
      ),
    );
  }
}

class VoiceRingsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * .37);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = AppColors.cyan.withValues(alpha: .12);

    for (final radius in [92.0, 136.0, 178.0]) {
      canvas.drawCircle(center, radius, paint);
    }

    final squarePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = Colors.white.withValues(alpha: .025);
    canvas.drawRect(
      Rect.fromCenter(center: center, width: 176, height: 176),
      squarePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class AudioBars extends StatelessWidget {
  const AudioBars({super.key, required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    const heights = [24.0, 29.0, 36.0, 28.0, 52.0, 34.0, 31.0, 26.0, 46.0];
    return SizedBox(
      height: 58,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final height in heights)
            Container(
              width: 8,
              height: active ? height : 18,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: active ? AppColors.cyan : AppColors.line,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
        ],
      ),
    );
  }
}

class ListeningPrompt extends StatelessWidget {
  const ListeningPrompt({
    super.key,
    required this.started,
    required this.muted,
  });

  final bool started;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final text = !started
        ? 'Tap Start to begin voice tutoring.'
        : muted
            ? 'Muted. Tap the microphone when you want to talk.'
            : 'What can I help with, Seypa?';

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.panel,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: Colors.white.withValues(alpha: .06)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.circle,
              color: started && !muted ? AppColors.cyan : AppColors.peach,
              size: 11,
            ),
            const SizedBox(width: 14),
            Flexible(
              child: Text(
                text,
                style: const TextStyle(color: AppColors.subtle, fontSize: 18),
              ),
            ),
          ],
        ),
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
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
      decoration: BoxDecoration(
        color: AppColors.panel,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
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
                hintText: 'Type your question...',
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

class RoundActionButton extends StatelessWidget {
  const RoundActionButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.selected = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 74,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          shape: const CircleBorder(),
          side: BorderSide(color: selected ? AppColors.cyan : AppColors.line),
          foregroundColor: selected ? AppColors.cyan : AppColors.muted,
          backgroundColor: AppColors.panel.withValues(alpha: .4),
        ),
        child: Icon(icon, semanticLabel: tooltip),
      ),
    );
  }
}

class StartButton extends StatelessWidget {
  const StartButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      key: const Key('voice-start-button'),
      onPressed: onPressed,
      icon: const Icon(Icons.play_arrow_rounded, size: 24),
      label: const Text('Start'),
      style: FilledButton.styleFrom(
        fixedSize: const Size(164, 74),
        backgroundColor: AppColors.blue,
        foregroundColor: Colors.white,
        textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
      ),
    );
  }
}

class StopButton extends StatelessWidget {
  const StopButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.stop_circle_outlined, size: 20),
      label: const Text('Stop'),
      style: FilledButton.styleFrom(
        fixedSize: const Size(164, 74),
        backgroundColor: AppColors.peach,
        foregroundColor: const Color(0xFF7D1E20),
        textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
        elevation: 18,
        shadowColor: AppColors.peach.withValues(alpha: .26),
      ),
    );
  }
}
