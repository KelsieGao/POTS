import 'dart:async';

import 'package:flutter/material.dart';

import 'models/voss_questionnaire_data.dart';
import 'providers/voss_questionnaire_controller.dart';

class VossQuestionnairePage extends StatefulWidget {
  const VossQuestionnairePage({super.key, required this.patientId});

  final String patientId;

  @override
  State<VossQuestionnairePage> createState() => _VossQuestionnairePageState();
}

class _VossQuestionnairePageState extends State<VossQuestionnairePage> {
  late final VossQuestionnaireController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VossQuestionnaireController(patientId: widget.patientId);
    _controller.addListener(_handleControllerUpdate);
  }

  void _handleControllerUpdate() {
    if (!mounted) {
      return;
    }
    setState(() {});
    if (_controller.status == VossQuestionnaireStatus.completed) {
      Navigator.of(context).maybePop(true);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_handleControllerUpdate);
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    await _controller.submit();
  }

  @override
  Widget build(BuildContext context) {
    final status = _controller.status;
    final isSubmitting = status == VossQuestionnaireStatus.submitting;
    final hasError = status == VossQuestionnaireStatus.error;

    return Scaffold(
      appBar: AppBar(title: const Text('VOSS Questionnaire')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'Rate each symptom from 0 (none) to 10 (severe).',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 24),
          for (final question in vossQuestions) ...[
            _SymptomSelector(
              question: question,
              value: _controller.data.responses[question.id] ?? 0,
              onChanged: (value) =>
                  _controller.updateResponse(question.id, value),
            ),
            const SizedBox(height: 20),
          ],
          _TotalScoreDisplay(total: _controller.data.totalScore),
          const SizedBox(height: 24),
          if (hasError && _controller.errorMessage != null)
            _ErrorBanner(message: _controller.errorMessage!),
          if (hasError && _controller.errorMessage != null)
            const SizedBox(height: 12),
          FilledButton(
            onPressed: isSubmitting ? null : _submit,
            child: isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Submit'),
          ),
        ],
      ),
    );
  }
}

class _SymptomSelector extends StatelessWidget {
  const _SymptomSelector({
    required this.question,
    required this.value,
    required this.onChanged,
  });

  final VossQuestion question;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(question.label, style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var score = 0; score <= 10; score++)
              ChoiceChip(
                label: Text(score.toString()),
                selected: value == score,
                onSelected: (_) => onChanged(score),
              ),
          ],
        ),
      ],
    );
  }
}

class _TotalScoreDisplay extends StatelessWidget {
  const _TotalScoreDisplay({required this.total});

  final int total;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Total score', style: Theme.of(context).textTheme.titleMedium),
            Text(
              total.toString(),
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        message,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onErrorContainer,
        ),
      ),
    );
  }
}
