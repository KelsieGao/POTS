import 'package:flutter/material.dart';

import 'package:pots/features/polar/polar_heart_rate_controller.dart';
import 'package:pots/features/standup_test/models/standup_test_data.dart';

import 'controllers/standup_test_controller.dart';
import 'widgets/countdown_display.dart';

class StandupTestFlowPage extends StatefulWidget {
  const StandupTestFlowPage({
    super.key,
    required this.polarController,
    required this.patientId,
    this.demoMode = true,
  });

  final PolarHeartRateController polarController;
  final String patientId;
  final bool demoMode;

  @override
  State<StandupTestFlowPage> createState() => _StandupTestFlowPageState();
}

class _StandupTestFlowPageState extends State<StandupTestFlowPage> {
  late final StandupTestController _controller;

  final _supineFormKey = GlobalKey<FormState>();
  final _standing1FormKey = GlobalKey<FormState>();
  final _standing3FormKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _controller = StandupTestController(
      polarController: widget.polarController,
      patientId: widget.patientId,
      demoMode: widget.demoMode,
    )..addListener(_handleUpdate);
  }

  void _handleUpdate() {
    if (!mounted) return;
    final step = _controller.step;
    if (step == StandupStep.completed) {
      Navigator.of(context).pop(true);
    }
    setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_handleUpdate);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sit/Stand Protocol'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).maybePop(),
            child: const Text('Close'),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildProgressIndicator(),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24), 
              child: _buildBody(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    final currentStep = _getCurrentStepNumber();
    final totalSteps = 5;
    
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Step $currentStep of $totalSteps',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${(currentStep / totalSteps * 100).round()}%',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: currentStep / totalSteps,
            backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _getCurrentStepDescription(),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  int _getCurrentStepNumber() {
    switch (_controller.step) {
      case StandupStep.intro:
        return 1;
      case StandupStep.supineCountdown:
      case StandupStep.supineEntry:
        return 2;
      case StandupStep.standPrep:
      case StandupStep.standingCountdown1:
      case StandupStep.standingEntry1:
        return 3;
      case StandupStep.standingCountdownTo3:
      case StandupStep.standingEntry3:
        return 4;
      case StandupStep.standingCountdownTo5:
      case StandupStep.standingCountdownTo10:
      case StandupStep.summary:
      case StandupStep.submitting:
        return 5;
      case StandupStep.completed:
      case StandupStep.error:
        return 5;
    }
  }

  String _getCurrentStepDescription() {
    switch (_controller.step) {
      case StandupStep.intro:
        return 'Introduction and preparation';
      case StandupStep.supineCountdown:
        return 'Lying down for 10 minutes';
      case StandupStep.supineEntry:
        return 'Recording supine blood pressure';
      case StandupStep.standPrep:
        return 'Preparing to stand up';
      case StandupStep.standingCountdown1:
        return 'Standing for 1 minute';
      case StandupStep.standingEntry1:
        return 'Recording 1-minute standing BP';
      case StandupStep.standingCountdownTo3:
        return 'Standing up to 3 minutes';
      case StandupStep.standingEntry3:
        return 'Recording 3-minute standing BP';
      case StandupStep.standingCountdownTo5:
        return 'Standing up to 5 minutes';
      case StandupStep.standingCountdownTo10:
        return 'Standing up to 10 minutes';
      case StandupStep.summary:
        return 'Reviewing and submitting results';
      case StandupStep.submitting:
        return 'Submitting test results';
      case StandupStep.completed:
        return 'Test completed successfully';
      case StandupStep.error:
        return 'Test encountered an error';
    }
  }

  Widget _buildBody() {
    switch (_controller.step) {
      case StandupStep.intro:
        return _IntroStep(onStart: _controller.next);
      case StandupStep.supineCountdown:
        return _CountdownStep(
          title: 'Lie down for 10 minutes',
          description:
              'Relax and breathe normally. The app will let you know when it\'s time to take your blood pressure.',
          remaining: _controller.remaining,
          latestHr: _controller.latestHeartRate,
          onSkip: _controller.demoMode ? _controller.skipCurrentStep : null,
        );
      case StandupStep.supineEntry:
        return _SupineEntryForm(
          formKey: _supineFormKey,
          onSubmit: (systolic, diastolic) {
            _controller.setSupineBp(systolic: systolic, diastolic: diastolic);
            _controller.next();
          },
          latestHr: _controller.latestHeartRate,
        );
      case StandupStep.standPrep:
        return _InstructionStep(
          title: 'Stand up',
          description:
              'Please stand up carefully. You may lean on a wall if needed. Keep still while standing.',
          buttonLabel: 'Start standing timer',
          onContinue: _controller.next,
        );
      case StandupStep.standingCountdown1:
        return _CountdownStep(
          title: 'Standing · 1 minute',
          description: 'Remain standing. We\'ll capture a reading at 1 minute.',
          remaining: _controller.remaining,
          latestHr: _controller.latestHeartRate,
          onSkip: _controller.demoMode ? _controller.skipCurrentStep : null,
        );
      case StandupStep.standingEntry1:
        return _StandingEntryForm(
          title: '1-minute blood pressure',
          formKey: _standing1FormKey,
          onSubmit: (systolic, diastolic) {
            _controller.setStanding1Min(
              systolic: systolic,
              diastolic: diastolic,
            );
            _controller.next();
          },
          latestHr: _controller.latestHeartRate,
        );
      case StandupStep.standingCountdownTo3:
        return _CountdownStep(
          title: 'Standing · up to 3 minutes',
          description:
              'Keep standing. We\'ll prompt for another reading at 3 minutes.',
          remaining: _controller.remaining,
          latestHr: _controller.latestHeartRate,
          onSkip: _controller.demoMode ? _controller.skipCurrentStep : null,
        );
      case StandupStep.standingEntry3:
        return _StandingEntryForm(
          title: '3-minute blood pressure',
          formKey: _standing3FormKey,
          onSubmit: (systolic, diastolic) {
            _controller.setStanding3Min(
              systolic: systolic,
              diastolic: diastolic,
            );
            _controller.next();
          },
          latestHr: _controller.latestHeartRate,
        );
      case StandupStep.standingCountdownTo5:
        return _CountdownStep(
          title: 'Standing · up to 5 minutes',
          description:
              'We\'ll record your heart rate automatically at the 5-minute mark. Continue standing.',
          remaining: _controller.remaining,
          latestHr: _controller.latestHeartRate,
          onSkip: _controller.demoMode ? _controller.skipCurrentStep : null,
        );
      case StandupStep.standingCountdownTo10:
        return _CountdownStep(
          title: 'Standing · up to 10 minutes',
          description:
              'Almost there! We\'ll capture your heart rate at 10 minutes before finishing.',
          remaining: _controller.remaining,
          latestHr: _controller.latestHeartRate,
          onSkip: _controller.demoMode ? _controller.skipCurrentStep : null,
        );
      case StandupStep.summary:
        return _SummaryStep(
          data: _controller.data,
          onSubmit: _controller.submit,
        );
      case StandupStep.submitting:
        return const Center(child: CircularProgressIndicator());
      case StandupStep.completed:
        return const SizedBox.shrink();
      case StandupStep.error:
        return _ErrorStep(
          message:
              _controller.errorMessage ??
              'Something went wrong while saving your test.',
          onRetry: _controller.submit,
        );
    }
  }
}

class _IntroStep extends StatelessWidget {
  const _IntroStep({required this.onStart});

  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  alignment: Alignment.center,
                  child: const Text('Instructional video placeholder'),
                ),
                const SizedBox(height: 24),
                Text(
                  'Sit/Stand Test Overview',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                const Text(
                  '1. Put on your blood pressure cuff and Polar heart rate monitor.\n'
                  '2. Lie down for 10 minutes while the timer runs.\n'
                  '3. Take your blood pressure, enter the values, then stand up.\n'
                  '4. We\'ll prompt you for additional readings while you remain standing.',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        FilledButton(onPressed: onStart, child: const Text('Begin')),
      ],
    );
  }
}

class _CountdownStep extends StatelessWidget {
  const _CountdownStep({
    required this.title,
    required this.description,
    required this.remaining,
    required this.latestHr,
    this.onSkip,
  });

  final String title;
  final String description;
  final Duration? remaining;
  final int? latestHr;
  final VoidCallback? onSkip;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 12),
        Text(description, style: Theme.of(context).textTheme.bodyLarge),
        const SizedBox(height: 32),
        if (remaining != null)
          CountdownDisplay(remaining: remaining!)
        else
          const CircularProgressIndicator(),
        const SizedBox(height: 24),
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Latest heart rate',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  latestHr != null ? '$latestHr bpm' : 'Waiting for data…',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (onSkip != null) ...[
          const SizedBox(height: 24),
          TextButton(onPressed: onSkip, child: const Text('Skip timer (demo)')),
        ],
      ],
    );
  }
}

class _SupineEntryForm extends StatefulWidget {
  const _SupineEntryForm({
    required this.formKey,
    required this.onSubmit,
    required this.latestHr,
  });

  final GlobalKey<FormState> formKey;
  final void Function(int systolic, int diastolic) onSubmit;
  final int? latestHr;

  @override
  State<_SupineEntryForm> createState() => _SupineEntryFormState();
}

class _SupineEntryFormState extends State<_SupineEntryForm> {
  String? systolic;
  String? diastolic;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: widget.formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Supine blood pressure',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 12),
          Text(
            'Enter your blood pressure reading taken while lying down.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Systolic (mmHg)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  onSaved: (value) => systolic = value,
                  validator: _validateInt,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Diastolic (mmHg)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  onSaved: (value) => diastolic = value,
                  validator: _validateInt,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Captured heart rate: ${widget.latestHr != null ? '${widget.latestHr} bpm' : 'Not available yet'}',
          ),
          const Spacer(),
          FilledButton(
            onPressed: () {
              final form = widget.formKey.currentState;
              if (form?.validate() ?? false) {
                form!.save();
                widget.onSubmit(int.parse(systolic!), int.parse(diastolic!));
              }
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  String? _validateInt(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Required';
    }
    return int.tryParse(value.trim()) == null ? 'Enter a number' : null;
  }
}

class _StandingEntryForm extends StatefulWidget {
  const _StandingEntryForm({
    required this.title,
    required this.formKey,
    required this.onSubmit,
    required this.latestHr,
  });

  final String title;
  final GlobalKey<FormState> formKey;
  final void Function(int systolic, int diastolic) onSubmit;
  final int? latestHr;

  @override
  State<_StandingEntryForm> createState() => _StandingEntryFormState();
}

class _StandingEntryFormState extends State<_StandingEntryForm> {
  String? systolic;
  String? diastolic;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: widget.formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(widget.title, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 12),
          Text(
            'Record your blood pressure while standing and enter the values below.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Systolic (mmHg)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  onSaved: (value) => systolic = value,
                  validator: _validateInt,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Diastolic (mmHg)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  onSaved: (value) => diastolic = value,
                  validator: _validateInt,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Captured heart rate: ${widget.latestHr != null ? '${widget.latestHr} bpm' : 'Not available yet'}',
          ),
          const Spacer(),
          FilledButton(
            onPressed: () {
              final form = widget.formKey.currentState;
              if (form?.validate() ?? false) {
                form!.save();
                widget.onSubmit(int.parse(systolic!), int.parse(diastolic!));
              }
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  String? _validateInt(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Required';
    }
    return int.tryParse(value.trim()) == null ? 'Enter a number' : null;
  }
}

class _InstructionStep extends StatelessWidget {
  const _InstructionStep({
    required this.title,
    required this.description,
    required this.buttonLabel,
    required this.onContinue,
  });

  final String title;
  final String description;
  final String buttonLabel;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 12),
        Text(description, style: Theme.of(context).textTheme.bodyLarge),
        const Spacer(),
        FilledButton(onPressed: onContinue, child: Text(buttonLabel)),
      ],
    );
  }
}

class _SummaryStep extends StatelessWidget {
  const _SummaryStep({required this.data, required this.onSubmit});

  final StandupTestData data;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Review and submit',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ListView(
            children: [
              _SummaryTile(
                title: 'Supine',
                bp: _bp(data.supineSystolic, data.supineDiastolic),
                hr: data.supineHr,
              ),
              _SummaryTile(
                title: 'Standing · 1 min',
                bp: _bp(data.standing1MinSystolic, data.standing1MinDiastolic),
                hr: data.standing1MinHr,
              ),
              _SummaryTile(
                title: 'Standing · 3 min',
                bp: _bp(data.standing3MinSystolic, data.standing3MinDiastolic),
                hr: data.standing3MinHr,
              ),
              _SummaryTile(
                title: 'Standing · 5 min (HR)',
                bp: null,
                hr: data.standing5MinHr,
              ),
              _SummaryTile(
                title: 'Standing · 10 min (HR)',
                bp: null,
                hr: data.standing10MinHr,
              ),
            ],
          ),
        ),
        FilledButton(onPressed: onSubmit, child: const Text('Submit test')),
      ],
    );
  }

  String? _bp(int? systolic, int? diastolic) {
    if (systolic == null || diastolic == null) return null;
    return '$systolic / $diastolic mmHg';
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({required this.title, required this.bp, required this.hr});

  final String title;
  final String? bp;
  final int? hr;

  @override
  Widget build(BuildContext context) {
    final subtitle = <String>[];
    if (bp != null) subtitle.add(bp!);
    if (hr != null) subtitle.add('$hr bpm');

    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title),
      subtitle: subtitle.isEmpty
          ? const Text('No data captured')
          : Text(subtitle.join(' · ')),
    );
  }
}

class _ErrorStep extends StatelessWidget {
  const _ErrorStep({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(message, style: Theme.of(context).textTheme.bodyLarge),
        const SizedBox(height: 16),
        FilledButton(onPressed: onRetry, child: const Text('Retry')),
      ],
    );
  }
}
