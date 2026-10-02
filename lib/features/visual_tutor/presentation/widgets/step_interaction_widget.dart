import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations.dart';

/// Accessible response controls for a single Socratic teaching step.
class StepInteractionWidget extends StatefulWidget {
  const StepInteractionWidget({
    super.key,
    required this.responseType,
    required this.question,
    required this.onSubmit,
    required this.onHint,
    required this.onSkip,
    this.choices = const [],
    this.isLoading = false,
    this.feedback,
  });

  final String responseType;
  final String question;
  final ValueChanged<String> onSubmit;
  final VoidCallback onHint;
  final VoidCallback onSkip;
  final List<String> choices;
  final bool isLoading;
  final String? feedback;

  @override
  State<StepInteractionWidget> createState() => _StepInteractionWidgetState();
}

class _StepInteractionWidgetState extends State<StepInteractionWidget> {
  final _controller = TextEditingController();
  String? _selected;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final numeric = widget.responseType == 'numeric';
    final multipleChoice = widget.responseType == 'multiple_choice';
    return Semantics(
      liveRegion: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(widget.question, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          if (multipleChoice && widget.choices.isNotEmpty)
            RadioGroup<String>(
              groupValue: _selected,
              onChanged: (value) {
                if (!widget.isLoading) setState(() => _selected = value);
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final choice in widget.choices)
                    RadioListTile<String>(
                      value: choice,
                      title: Text(choice),
                      enabled: !widget.isLoading,
                    ),
                ],
              ),
            )
          else if (widget.responseType == 'draw' ||
              widget.responseType == 'handwriting')
            const _DrawingUnavailableNotice()
          else
            TextField(
              controller: _controller,
              enabled: !widget.isLoading,
              keyboardType: numeric
                  ? const TextInputType.numberWithOptions(
                      decimal: true,
                      signed: true,
                    )
                  : TextInputType.text,
              minLines: numeric ? 1 : 2,
              maxLines: numeric ? 1 : 4,
              decoration: InputDecoration(
                labelText: numeric ? 'Your numeric answer' : 'Your explanation',
                border: const OutlineInputBorder(),
              ),
            ),
          if (widget.feedback != null) ...[
            const SizedBox(height: 8),
            Text(
              widget.feedback!,
              style: TextStyle(color: Theme.of(context).colorScheme.primary),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              TextButton(
                onPressed: widget.isLoading ? null : widget.onHint,
                child: Text(AppLocalizations.of(context).hint),
              ),
              const Spacer(),
              TextButton(
                onPressed: widget.isLoading ? null : widget.onSkip,
                child: Text(AppLocalizations.of(context).skip),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: widget.isLoading
                    ? null
                    : () => widget.onSubmit(_selected ?? _controller.text),
                child: widget.isLoading
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(AppLocalizations.of(context).submit),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DrawingUnavailableNotice extends StatelessWidget {
  const _DrawingUnavailableNotice();
  @override
  Widget build(BuildContext context) => const Text(
    'Drawing input will open the handwriting board in the next release. You can describe your drawing for now.',
  );
}
