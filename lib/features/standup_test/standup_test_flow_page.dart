import 'dart:async';
import 'package:flutter/material.dart';

import 'package:pots/features/polar/polar_heart_rate_controller.dart';
import 'package:pots/features/ihealth/ihealth_bp_controller.dart';
import 'package:pots/features/standup_test/models/standup_test_data.dart';
import 'package:pots/features/standup_test/pages/safety_acknowledgment_page.dart';
import 'package:pots/features/standup_test/services/safety_service.dart';

import 'controllers/standup_test_controller.dart';
import 'widgets/countdown_display.dart';
import 'widgets/pots_instruction_video.dart';
import 'widgets/automated_bp_input.dart';

class StandupTestFlowPage extends StatefulWidget {
  const StandupTestFlowPage({
    super.key,
    required this.polarController,
    required this.ihealthBpController,
    required this.patientId,
    this.demoMode = true,
  });

  final PolarHeartRateController polarController;
  final IHealthBpController ihealthBpController;
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
      ihealthBpController: widget.ihealthBpController,
      patientId: widget.patientId,
      demoMode: widget.demoMode,
    )..addListener(_handleUpdate);
    
    // Initialize iHealth connection
    _initializeIHealth();
    
    // Check for safety acknowledgment before starting
    _checkSafetyAcknowledgment();
  }
  
  Future<void> _initializeIHealth() async {
    // Connect to iHealth device if known
    await widget.ihealthBpController.connectIfKnown();
    // Update patient ID
    widget.ihealthBpController.updatePatientId(widget.patientId);
  }

  void _handleUpdate() {
    if (!mounted) return;
    final step = _controller.step;
    if (step == StandupStep.completed) {
      Navigator.of(context).pop(true);
    }
    setState(() {});
  }

  Future<void> _checkSafetyAcknowledgment() async {
    try {
      final hasValidAcknowledgment = await SafetyService.hasValidSafetyAcknowledgment(widget.patientId);
      if (!hasValidAcknowledgment && mounted) {
        await _showSafetyAcknowledgment();
      }
    } catch (e) {
      print('Error checking safety acknowledgment: $e');
      // Continue with test even if check fails
    }
  }

  Future<void> _showSafetyAcknowledgment() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SafetyAcknowledgmentPage(
          patientId: widget.patientId,
          onCompleted: () {
            // Safety acknowledgment completed, continue with test
          },
        ),
      ),
    );
  }

  Future<void> _showCancelConfirmation() async {
    final shouldCancel = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Test'),
        content: const Text(
          'Are you sure you want to cancel the test? All progress will be lost.\n\n'
          'If you are feeling unwell, please sit down and rest immediately.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Continue Test'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Cancel Test'),
          ),
        ],
      ),
    );

    if (shouldCancel == true && mounted) {
      _controller.cancelTest();
      Navigator.of(context).pop(false); // Return false to indicate test was cancelled
    }
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
          // Emergency cancel button - always visible
          IconButton(
            onPressed: _showCancelConfirmation,
            icon: const Icon(Icons.stop),
            tooltip: 'Cancel Test',
            style: IconButton.styleFrom(
              foregroundColor: Colors.red,
            ),
          ),
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
          onCancel: _showCancelConfirmation,
          showSafetyReminder: true,
        );
      case StandupStep.supineEntry:
        return AutomatedBpInput(
          title: 'Supine Blood Pressure Reading',
          instruction: 'Take your blood pressure while lying down. Enter both values to continue automatically.',
          onSubmit: (systolic, diastolic) {
            _controller.setSupineBp(systolic: systolic, diastolic: diastolic);
          },
          latestHr: _controller.latestHeartRate,
          ihealthBpController: widget.ihealthBpController,
        );
      case StandupStep.standPrep:
        return _StandPrepStep(
          onNext: () {
            _controller.next();
          },
        );
      case StandupStep.standingCountdown1:
        return _CountdownStep(
          title: 'Standing · 1 minute',
          description: 'Remain standing. We\'ll capture a reading at 1 minute.',
          remaining: _controller.remaining,
          latestHr: _controller.latestHeartRate,
          onSkip: _controller.demoMode ? _controller.skipCurrentStep : null,
          onCancel: _showCancelConfirmation,
          showSafetyReminder: true,
        );
      case StandupStep.standingEntry1:
        return AutomatedBpInput(
          title: '1-Minute Standing Blood Pressure',
          instruction: 'You\'ve been standing for 1 minute. Take your blood pressure reading now.',
          onSubmit: (systolic, diastolic) {
            _controller.setStanding1Min(
              systolic: systolic,
              diastolic: diastolic,
            );
          },
          latestHr: _controller.latestHeartRate,
          ihealthBpController: widget.ihealthBpController,
        );
      case StandupStep.standingCountdownTo3:
        // Check if we just finished BP input - show continue prompt instead
        if (!_controller.isCountdownActive) {
          return _NextStepPrompt(
            title: 'BP Recorded',
            description: 'Continue to next countdown.',
            onNext: () {
              _controller.startStandingCountdownTo3();
            },
          );
        }
        return _CountdownStep(
          title: 'Standing · up to 3 minutes',
          description:
              'Keep standing. We\'ll prompt for another reading at 3 minutes.',
          remaining: _controller.remaining,
          latestHr: _controller.latestHeartRate,
          onSkip: _controller.demoMode ? _controller.skipCurrentStep : null,
          onCancel: _showCancelConfirmation,
          showSafetyReminder: true,
        );
      case StandupStep.standingEntry3:
        return AutomatedBpInput(
          title: '3-Minute Standing Blood Pressure',
          instruction: 'You\'ve been standing for 3 minutes. Take your blood pressure reading now.',
          onSubmit: (systolic, diastolic) {
            _controller.setStanding3Min(
              systolic: systolic,
              diastolic: diastolic,
            );
          },
          latestHr: _controller.latestHeartRate,
          ihealthBpController: widget.ihealthBpController,
        );
      case StandupStep.standingCountdownTo5:
        // Check if we just finished BP input - show continue prompt instead
        if (!_controller.isCountdownActive) {
          return _NextStepPrompt(
            title: 'BP Recorded',
            description: 'Continue to next countdown.',
            onNext: () {
              _controller.startStandingCountdownTo5();
            },
          );
        }
        return _CountdownStep(
          title: 'Standing · up to 5 minutes',
          description:
              'We\'ll record your heart rate automatically at the 5-minute mark. Continue standing.',
          remaining: _controller.remaining,
          latestHr: _controller.latestHeartRate,
          onSkip: _controller.demoMode ? _controller.skipCurrentStep : null,
          onCancel: _showCancelConfirmation,
          showSafetyReminder: true,
        );
      case StandupStep.standingCountdownTo10:
        return _CountdownStep(
          title: 'Standing · up to 10 minutes',
          description:
              'Almost there! We\'ll capture your heart rate at 10 minutes before finishing.',
          remaining: _controller.remaining,
          latestHr: _controller.latestHeartRate,
          onSkip: _controller.demoMode ? _controller.skipCurrentStep : null,
          onCancel: _showCancelConfirmation,
          showSafetyReminder: true,
        );
      case StandupStep.summary:
        return _SummaryStep(
          data: _controller.data,
          onSubmit: () {
            // Notes are saved automatically in _SummaryStepState._submit
            _controller.submit();
          },
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
                // Safety warning at the top
                Card(
                  color: Theme.of(context).colorScheme.errorContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.warning_amber_rounded,
                              color: Theme.of(context).colorScheme.onErrorContainer,
                              size: 24,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Safety First',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onErrorContainer,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '• Have someone nearby if you have a history of fainting\n'
                          '• Stop immediately if you feel dizzy or unwell\n'
                          '• Ensure a safe environment with no obstacles\n'
                          '• Use the red cancel button if you need to stop',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onErrorContainer,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const PotsVideoPlaceholder(),
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
                  '4. We\'ll prompt you for additional readings while you remain standing.\n\n'
                  'The test will take approximately 20-25 minutes to complete.',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: onStart,
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: const Text('Begin Test'),
        ),
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
    this.onCancel,
    this.showSafetyReminder = false,
  });

  final String title;
  final String description;
  final Duration? remaining;
  final int? latestHr;
  final VoidCallback? onSkip;
  final VoidCallback? onCancel;
  final bool showSafetyReminder;

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
        if (showSafetyReminder) ...[
          const SizedBox(height: 24),
          Card(
            color: Theme.of(context).colorScheme.errorContainer.withOpacity(0.1),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: Theme.of(context).colorScheme.error,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'If you feel dizzy or unwell, sit down immediately and cancel the test.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.error,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: 24),
        Row(
          children: [
            if (onCancel != null) ...[
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onCancel,
                  icon: const Icon(Icons.stop),
                  label: const Text('Cancel Test'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                  ),
                ),
              ),
              const SizedBox(width: 12),
            ],
            if (onSkip != null) ...[
              Expanded(
                child: TextButton(
                  onPressed: onSkip,
                  child: const Text('Skip timer (demo)'),
                ),
              ),
            ],
          ],
        ),
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

class _AutomaticInstructionStep extends StatefulWidget {
  const _AutomaticInstructionStep({
    required this.title,
    required this.description,
    required this.countdownDuration,
    required this.onComplete,
  });

  final String title;
  final String description;
  final Duration countdownDuration;
  final VoidCallback onComplete;

  @override
  State<_AutomaticInstructionStep> createState() => _AutomaticInstructionStepState();
}

class _AutomaticInstructionStepState extends State<_AutomaticInstructionStep> {
  late Duration _remaining;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _remaining = widget.countdownDuration;
    _startCountdown();
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _remaining = Duration(seconds: _remaining.inSeconds - 1);
        });
        
        if (_remaining.inSeconds <= 0) {
          timer.cancel();
          widget.onComplete();
        }
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          widget.title, 
          style: Theme.of(context).textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          widget.description, 
          style: Theme.of(context).textTheme.bodyLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        
        // Countdown Display
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              const Icon(
                Icons.timer,
                size: 48,
                color: Colors.orange,
              ),
              const SizedBox(height: 16),
              Text(
                '${_remaining.inSeconds}',
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'seconds remaining',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Progress indicator
        LinearProgressIndicator(
          value: 1.0 - (_remaining.inSeconds / widget.countdownDuration.inSeconds),
          backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
          valueColor: AlwaysStoppedAnimation<Color>(
            Theme.of(context).colorScheme.primary,
          ),
        ),
        
        const Spacer(),
        
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.blue),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Continuing automatically...',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.blue.shade700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SummaryStep extends StatefulWidget {
  const _SummaryStep({required this.data, required this.onSubmit});

  final StandupTestData data;
  final VoidCallback onSubmit;

  @override
  State<_SummaryStep> createState() => _SummaryStepState();
}

class _SummaryStepState extends State<_SummaryStep> {
  late final TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController(text: widget.data.notes ?? '');
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _submit() {
    // Save notes to data before submitting
    widget.data.notes = _notesController.text.trim().isEmpty 
        ? null 
        : _notesController.text.trim();
    widget.onSubmit();
  }

  @override
  Widget build(BuildContext context) {
    // Debug print to see what data we have
    print('Summary data:');
    print('  Supine: ${widget.data.supineSystolic}/${widget.data.supineDiastolic}');
    print('  1min: ${widget.data.standing1MinSystolic}/${widget.data.standing1MinDiastolic}');
    print('  3min: ${widget.data.standing3MinSystolic}/${widget.data.standing3MinDiastolic}');
    
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
                bp: _bp(widget.data.supineSystolic, widget.data.supineDiastolic),
                hr: widget.data.supineHr,
              ),
              _SummaryTile(
                title: 'Standing · 1 min',
                bp: _bp(widget.data.standing1MinSystolic, widget.data.standing1MinDiastolic),
                hr: widget.data.standing1MinHr,
              ),
              _SummaryTile(
                title: 'Standing · 3 min',
                bp: _bp(widget.data.standing3MinSystolic, widget.data.standing3MinDiastolic),
                hr: widget.data.standing3MinHr,
              ),
              _SummaryTile(
                title: 'Standing · 5 min (HR)',
                bp: null,
                hr: widget.data.standing5MinHr,
              ),
              _SummaryTile(
                title: 'Standing · 10 min (HR)',
                bp: null,
                hr: widget.data.standing10MinHr,
              ),
              const SizedBox(height: 24),
              _NotesSection(controller: _notesController),
            ],
          ),
        ),
        FilledButton(
          onPressed: _submit, 
          child: const Text('Submit test'),
        ),
      ],
    );
  }

  String? _bp(int? systolic, int? diastolic) {
    if (systolic == null || diastolic == null) return null;
    return '$systolic / $diastolic mmHg';
  }
}

class _NotesSection extends StatelessWidget {
  const _NotesSection({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Notes (Optional)',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'Add any notes about this test...',
            border: OutlineInputBorder(),
            filled: true,
            fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
          ),
        ),
      ],
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({required this.title, required this.bp, required this.hr});

  final String title;
  final String? bp;
  final int? hr;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          if (bp != null || hr != null) ...[
            if (bp != null)
              Text(
                'BP: $bp',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            if (bp != null && hr != null)
              const SizedBox(height: 4),
            if (hr != null)
              Text(
                'HR: $hr bpm',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
          ]
          else
            Text(
              'No data captured',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
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

class _StandPrepStep extends StatelessWidget {
  const _StandPrepStep({required this.onNext});

  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(
          Icons.arrow_upward,
          size: 64,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 24),
        Text(
          'Stand Up Now',
          style: Theme.of(context).textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          'Please stand up carefully. You may lean on a wall if needed. Keep still while standing.',
          style: Theme.of(context).textTheme.bodyLarge,
          textAlign: TextAlign.center,
        ),
        const Spacer(),
        FilledButton(
          onPressed: onNext,
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: const Text('I\'m Standing - Continue'),
        ),
      ],
    );
  }
}

class _NextStepPrompt extends StatelessWidget {
  const _NextStepPrompt({
    required this.title,
    required this.description,
    required this.onNext,
  });

  final String title;
  final String description;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(
          Icons.check_circle,
          size: 64,
          color: Colors.green,
        ),
        const SizedBox(height: 24),
        Text(
          title,
          style: Theme.of(context).textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          description,
          style: Theme.of(context).textTheme.bodyLarge,
          textAlign: TextAlign.center,
        ),
        const Spacer(),
        FilledButton(
          onPressed: onNext,
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: const Text('Continue'),
        ),
      ],
    );
  }
}
