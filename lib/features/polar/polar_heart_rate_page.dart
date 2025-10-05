import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pots/features/standup_test/standup_test_flow_page.dart';
import 'package:pots/features/standup_test/test_history_page.dart';
import 'package:pots/features/voss_questionnaire/voss_questionnaire_page.dart';
import 'package:pots/features/symptom_logging/symptom_selection_page.dart';
import 'package:pots/features/symptom_logging/symptom_history_page.dart';

import '../patient_signup/patient_signup_page.dart';
import '../patient_signup/providers/patient_signup_controller.dart';
import 'polar_connection_sheet.dart';
import 'polar_heart_rate_controller.dart';

class PolarHeartRatePage extends StatefulWidget {
  const PolarHeartRatePage({super.key});

  @override
  State<PolarHeartRatePage> createState() => _PolarHeartRatePageState();
}

class _PolarHeartRatePageState extends State<PolarHeartRatePage> {
  late final PolarHeartRateController _polarController;
  late final PatientSignupController _patientController;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _polarController = PolarHeartRateController();
    _polarController.addListener(_handlePolarUpdate);
    _patientController = PatientSignupController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _initialize();
    });
  }

  Future<void> _initialize() async {
    await _patientController.initialize();
    final hasPatient = await _patientController.hasPatient();
    final patientId = _patientController.patientId;
    _polarController.updatePatientId(patientId);
    final hasCompletedVoss = await _patientController.hasCompletedVoss();
    if (!mounted) {
      return;
    }
    if (!hasPatient) {
      await _openSignup();
    } else {
      if (!hasCompletedVoss && patientId != null) {
        await _openVossQuestionnaire(patientId);
      }
      unawaited(_polarController.connectIfKnown());
    }
    setState(() {
      _initialized = true;
    });
  }

  void _handlePolarUpdate() {
    if (!mounted) {
      return;
    }
    setState(() {});
  }

  @override
  void dispose() {
    _polarController.removeListener(_handlePolarUpdate);
    _polarController.dispose();
    _patientController.dispose();
    super.dispose();
  }

  Future<void> _openSignup() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => PatientSignupPage(controller: _patientController),
      ),
    );
    if (!mounted) {
      return;
    }

    if (_patientController.status == PatientSignupStatus.completed) {
      final patientId = _patientController.patientId;
      _polarController.updatePatientId(patientId);
      if (patientId != null) {
        await _openVossQuestionnaire(patientId);
      }
      unawaited(_polarController.connectIfKnown());
    }
  }

  Future<bool> _openVossQuestionnaire(String patientId) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => VossQuestionnairePage(patientId: patientId),
      ),
    );
    final completed = result == true;
    if (completed) {
      await _patientController.markVossCompleted();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Questionnaire submitted'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
    return completed;
  }

  Future<void> _startStandupTest() async {
    await _patientController.initialize();
    final patientId = _patientController.patientId;
    if (patientId == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Create a patient profile before starting the test.'),
        ),
      );
      return;
    }
    if (!mounted) return;
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => StandupTestFlowPage(
          polarController: _polarController,
          patientId: patientId,
          demoMode: kDebugMode,
        ),
      ),
    );
    if (!mounted) return;
    if (result == true) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Stand-up test saved')));
    }
  }

  Future<void> _openConnectionSheet() async {
    FocusScope.of(context).unfocus();
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => PolarConnectionSheet(controller: _polarController),
    );

    if (!mounted || result != true) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Polar device connected'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final theme = Theme.of(context);
    final bpm = _polarController.heartRate;
    final statusLabel = _polarController.status.label;
    final deviceId = _polarController.deviceId;
    final error = _polarController.errorMessage;
    final isStreaming = _polarController.isStreaming;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Polar Heart Rate'),
        actions: [
          IconButton(
            onPressed: _openSignup,
            icon: const Icon(Icons.person),
            tooltip: 'Patient profile',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _HeartRateCard(bpm: bpm, streaming: isStreaming),
            const SizedBox(height: 24),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Chip(label: Text('Status: $statusLabel')),
                if (deviceId != null) Chip(label: Text('Device: $deviceId')),
              ],
            ),
            const SizedBox(height: 16),
            if (error != null) _ErrorNotice(message: error),
            if (error != null) const SizedBox(height: 16),
            Text(
              'This app reconnects to your last Polar device automatically when it is nearby.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _startStandupTest,
              icon: const Icon(Icons.accessibility_new),
              label: const Text('Start Sit/Stand Protocol'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _startSymptomLogging,
                    icon: const Icon(Icons.favorite_border),
                    label: const Text('Log Symptoms'),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF20B2AA),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _viewSymptomHistory,
                    icon: const Icon(Icons.history),
                    label: const Text('History'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF20B2AA),
                      side: const BorderSide(color: Color(0xFF20B2AA)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _viewTestHistory,
              icon: const Icon(Icons.assignment_outlined),
              label: const Text('Test History'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.primary,
                side: BorderSide(color: Theme.of(context).colorScheme.primary),
              ),
            ),
            const SizedBox(height: 16),
            const Spacer(),
            FilledButton.icon(
              onPressed: _polarController.isBusy ? null : _openConnectionSheet,
              icon: const Icon(Icons.bluetooth_searching),
              label: Text(
                _polarController.isStreaming
                    ? 'Manage Polar Connection'
                    : 'Connect Polar Device',
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _shouldAllowDisconnect()
                  ? _polarController.disconnect
                  : null,
              child: const Text('Disconnect'),
            ),
          ],
        ),
      ),
    );
  }

  bool _shouldAllowDisconnect() {
    final status = _polarController.status;
    return status == PolarConnectionStatus.connected ||
        status == PolarConnectionStatus.streaming;
  }

  Future<void> _startSymptomLogging() async {
    final patientId = _patientController.patientId;
    if (patientId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please create a patient profile first'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SymptomSelectionPage(patientId: patientId),
      ),
    );
  }

  Future<void> _viewSymptomHistory() async {
    final patientId = _patientController.patientId;
    if (patientId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please create a patient profile first'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SymptomHistoryPage(patientId: patientId),
      ),
    );
  }

  Future<void> _viewTestHistory() async {
    final patientId = _patientController.patientId;
    if (patientId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please create a patient profile first'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => TestHistoryPage(patientId: patientId),
      ),
    );
  }
}

class _HeartRateCard extends StatelessWidget {
  const _HeartRateCard({required this.bpm, required this.streaming});

  final int? bpm;
  final bool streaming;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = streaming
        ? theme.colorScheme.error
        : theme.colorScheme.primary;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            streaming ? Icons.favorite : Icons.monitor_heart,
            size: 72,
            color: color,
          ),
          const SizedBox(height: 12),
          if (bpm != null)
            Text(
              '$bpm bpm',
              style: theme.textTheme.displayMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            )
          else
            Text(
              'Waiting for heart rate...',
              style: theme.textTheme.titleMedium,
            ),
        ],
      ),
    );
  }
}

class _ErrorNotice extends StatelessWidget {
  const _ErrorNotice({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(16),
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
