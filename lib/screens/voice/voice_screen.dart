import 'package:flutter/material.dart';
import '../../core/app_colors.dart';

class VoiceScreen extends StatelessWidget {
  const VoiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight - 44),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const VoiceCard(),
                const SizedBox(height: 20),
                const ListeningPrompt(),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: const [
                    RoundActionButton(icon: Icons.mic_off_outlined),
                    StopButton(),
                    RoundActionButton(icon: Icons.keyboard_alt_outlined),
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

class VoiceCard extends StatelessWidget {
  const VoiceCard({super.key});

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
            color: AppColors.cyan.withValues(alpha: .1),
            blurRadius: 42,
            offset: const Offset(0, 24),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: CustomPaint(painter: VoiceRingsPainter()),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const VoiceOrb(),
              const SizedBox(height: 34),
              Text(
                '"ខ្ញុំកំពុងស្តាប់អ្នក,\nSeypa."',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.text,
                  fontSize: 29,
                  height: 1.18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 20),
              const AudioBars(),
            ],
          ),
        ],
      ),
    );
  }
}

class VoiceOrb extends StatelessWidget {
  const VoiceOrb({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 142,
      height: 142,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const SweepGradient(
          colors: [
            AppColors.cyan,
            Color(0xFFB9F7FF),
            Color(0xFF9AD7FF),
            AppColors.cyan,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.cyan.withValues(alpha: .24),
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
        child: const Icon(Icons.graphic_eq_rounded, color: AppColors.cyan),
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
  const AudioBars({super.key});

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
              height: height,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: AppColors.cyan,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
        ],
      ),
    );
  }
}

class ListeningPrompt extends StatelessWidget {
  const ListeningPrompt({super.key});

  @override
  Widget build(BuildContext context) {
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
          children: const [
            Icon(Icons.circle, color: AppColors.peach, size: 11),
            SizedBox(width: 14),
            Flexible(
              child: Text(
              'តើខ្ញុំអាចជួយអ្វីបាន, Seypa?',
              style: TextStyle(color: AppColors.subtle, fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RoundActionButton extends StatelessWidget {
  const RoundActionButton({super.key, required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 74,
      child: OutlinedButton(
        onPressed: () {},
        style: OutlinedButton.styleFrom(
          shape: const CircleBorder(),
          side: BorderSide(color: AppColors.line),
          foregroundColor: AppColors.muted,
          backgroundColor: AppColors.panel.withValues(alpha: .4),
        ),
        child: Icon(icon),
      ),
    );
  }
}

class StopButton extends StatelessWidget {
  const StopButton({super.key});

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: () {},
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
