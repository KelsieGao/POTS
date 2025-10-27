import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pots/features/standup_test/standup_test_flow_page.dart';
import 'package:pots/features/standup_test/test_history_page.dart';
import 'package:pots/features/voss_questionnaire/voss_questionnaire_page.dart';
import 'package:pots/features/symptom_logging/symptom_selection_page.dart';
import 'package:pots/features/symptom_logging/symptom_history_page.dart';

import '../../core/services/auth_service.dart';
import '../../core/services/supabase_service.dart';
import '../../core/services/patient_progress_service.dart';
import '../auth/patient_profile_completion_page.dart';
import '../auth/sign_in_page.dart';
import '../patient_signup/patient_signup_page.dart';
import '../patient_signup/providers/patient_signup_controller.dart';
import '../patient_signup/local/patient_storage.dart';
import '../ihealth/ihealth_bp_controller.dart';
import '../ihealth/ihealth_connection_sheet.dart';
import 'polar_connection_sheet.dart';
import 'polar_heart_rate_controller.dart';

class PolarHeartRatePage extends StatefulWidget {
  const PolarHeartRatePage({super.key});

  @override
  State<PolarHeartRatePage> createState() => _PolarHeartRatePageState();
}

class _PolarHeartRatePageState extends State<PolarHeartRatePage> {
  late final PolarHeartRateController _polarController;
  late final IHealthBpController _ihealthBpController;
  late final PatientSignupController _patientController;
  bool _initialized = false;
  PatientProgress? _progress;

  @override
  void initState() {
    super.initState();
    _polarController = PolarHeartRateController();
    _polarController.addListener(_handlePolarUpdate);
    _ihealthBpController = IHealthBpController();
    _ihealthBpController.addListener(_handlePolarUpdate);
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
    
    // Get the user ID from Supabase Auth
    final userId = AuthService.currentUser?.id;
    
    if (userId == null) {
      // Not signed in - redirect to sign in
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => const SignInPage(),
          ),
        );
      }
      return;
    }
    
    // Check if patient record exists in database
    final hasPatientRecord = await _checkPatientRecordExists(userId);
    
    if (!hasPatientRecord) {
      // Patient record doesn't exist - must complete profile
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => const PatientProfileCompletionPage(),
          ),
        );
      }
      return;
    }
    
    // Save patient ID to storage for compatibility
    final storage = await PatientStorage.create();
    await storage.savePatientId(userId);
    
    // Set up controllers
    _polarController.updatePatientId(userId);
    _ihealthBpController.updatePatientId(userId);
    
    // Check if profile is complete (reason_for_using_app should not be "Other" if incomplete)
    final isProfileComplete = await _checkProfileComplete();
    if (!isProfileComplete) {
      // Redirect to profile completion
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => const PatientProfileCompletionPage(),
          ),
        );
      }
      return;
    }
    
    // Check VOSS completion
    final hasCompletedVoss = await _patientController.hasCompletedVoss();
    if (!hasCompletedVoss && userId != null) {
      await _openVossQuestionnaire(userId);
    }
    
    // Connect to devices if available
    unawaited(_polarController.connectIfKnown());
    unawaited(_ihealthBpController.connectIfKnown());
    
    // Load progress
    await _loadProgress();
    
    setState(() {
      _initialized = true;
    });
  }

  Future<bool> _checkPatientRecordExists(String userId) async {
    try {
      final client = SupabaseService.client;
      final response = await client
          .from('patients')
          .select('id')
          .eq('id', userId)
          .maybeSingle();
      return response != null;
    } catch (e) {
      return false;
    }
  }

  Future<bool> _checkProfileComplete() async {
    try {
      final userId = AuthService.currentUser?.id;
      if (userId == null) return false;
      
      final client = SupabaseService.client;
      final response = await client
          .from('patients')
          .select('reason_for_using_app')
          .eq('id', userId)
          .single();
      
      // Profile is complete if we have the field and it's not just a placeholder
      return response['reason_for_using_app'] != null && 
             response['reason_for_using_app'] != '';
    } catch (e) {
      return false;
    }
  }

  Future<void> _loadProgress() async {
    final patientId = _patientController.patientId;
    if (patientId != null) {
      final progress = await PatientProgressService.getProgress(patientId);
      if (mounted) {
        setState(() {
          _progress = progress;
        });
      }
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await AuthService.signOut();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const SignInPage()),
          (route) => false,
        );
      }
    }
  }

  Future<void> _editProfile() async {
    final userId = AuthService.currentUser?.id;
    if (userId != null) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const PatientProfileCompletionPage(),
        ),
      );
      // Reload progress after profile update
      await _loadProgress();
    }
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
    _ihealthBpController.removeListener(_handlePolarUpdate);
    _ihealthBpController.dispose();
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
          ihealthBpController: _ihealthBpController,
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

  Future<void> _openIHealthConnectionSheet() async {
    FocusScope.of(context).unfocus();
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => IHealthConnectionSheet(controller: _ihealthBpController),
    );

    if (!mounted || result != true) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('iHealth device connected'),
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
        title: const Text('POTS Monitor'),
        actions: [
          IconButton(
            onPressed: _editProfile,
            icon: const Icon(Icons.person),
            tooltip: 'Edit Profile',
          ),
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout),
            tooltip: 'Log Out',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
            if (_progress != null) ...[
              _ProgressCard(progress: _progress!),
              const SizedBox(height: 24),
            ],
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
            const SizedBox(height: 24),
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
            // iHealth BP monitor temporarily disabled due to SDK issues
            // const SizedBox(height: 24),
            // FilledButton.icon(
            //   onPressed: () => _openIHealthConnectionSheet(),
            //   icon: const Icon(Icons.bloodtype),
            //   label: const Text('Connect Blood Pressure Monitor'),
            //   style: FilledButton.styleFrom(
            //     backgroundColor: Colors.red.shade600,
            //   ),
            // ),
            const SizedBox(height: 24),
            ],
          ),
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

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.progress});

  final PatientProgress progress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final testPercentage = progress.testProgress / progress.maxTests;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF20B2AA).withOpacity(0.1),
            const Color(0xFF2196F3).withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF20B2AA).withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Your Progress',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                progress.testProgressText,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF20B2AA),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: testPercentage,
              minHeight: 8,
              backgroundColor: Colors.grey.shade200,
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF20B2AA)),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              _ProgressItem(
                icon: Icons.assignment,
                label: 'Stand-up Tests',
                value: '${progress.testsCompleted}/${progress.maxTests}',
                completed: progress.testsCompleted > 0,
              ),
              _ProgressItem(
                icon: Icons.favorite,
                label: 'Symptoms Logged',
                value: '${progress.symptomsLogged}',
                completed: progress.symptomsLogged > 0,
              ),
              _ProgressItem(
                icon: Icons.quiz,
                label: 'VOSS Questionnaire',
                value: progress.vossCompleted ? 'Completed' : 'Not completed',
                completed: progress.vossCompleted,
              ),
              _ProgressItem(
                icon: Icons.person,
                label: 'Profile',
                value: progress.profileComplete ? 'Complete' : 'Incomplete',
                completed: progress.profileComplete,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProgressItem extends StatelessWidget {
  const _ProgressItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.completed,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool completed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: completed 
            ? const Color(0xFF20B2AA).withOpacity(0.1)
            : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: completed 
              ? const Color(0xFF20B2AA).withOpacity(0.3)
              : Colors.grey.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: completed ? const Color(0xFF20B2AA) : Colors.grey,
          ),
          const SizedBox(width: 6),
          Text(
            '$label: $value',
            style: TextStyle(
              fontSize: 12,
              fontWeight: completed ? FontWeight.w600 : FontWeight.normal,
              color: completed ? const Color(0xFF20B2AA) : Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }
}
