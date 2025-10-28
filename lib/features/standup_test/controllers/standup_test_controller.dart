import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:pots/features/polar/polar_heart_rate_controller.dart';
// import 'package:pots/features/ihealth/ihealth_bp_controller.dart'; // TODO: Re-implement with native SDK

import '../models/standup_test_data.dart';
import '../services/standup_test_service.dart';
import 'package:pots/shared/ihealth_kn550_service.dart';

enum StandupStep {
  intro,
  supineCountdown,
  supineEntry,
  standPrep,
  standingCountdown1,
  standingEntry1,
  standingCountdownTo3,
  standingEntry3,
  standingCountdownTo5,
  standingCountdownTo10,
  summary,
  submitting,
  completed,
  error,
}

class StandupTestController extends ChangeNotifier {
  StandupTestController({
    required this.polarController,
    // required this.ihealthBpController, // TODO: Re-implement with native SDK
    required this.patientId,
    this.demoMode = true,
    StandupTestService? service,
  }) : _service = service ?? StandupTestService();

  final PolarHeartRateController polarController;
  // final IHealthBpController ihealthBpController; // TODO: Re-implement with native SDK
  final String patientId;
  final bool demoMode;
  final StandupTestService _service;

  final StandupTestData data = StandupTestData();

  StandupStep step = StandupStep.intro;
  Duration? remaining;

  Timer? _timer;

  // De-dup marker per session
  DateTime? _lastBpSyncedAt;

  bool get isCountdownActive => _timer != null;

  /// Fetch latest KN‑550BT reading and return (or null on timeout/none).
  Future<Map<String, int>?> fetchLatestBpReading({Duration timeout = const Duration(seconds: 8)}) async {
    try {
      final rec = await IHealthKn550Service.instance.fetchLatest(totalTimeout: timeout);
      if (rec == null) return null;
      _lastBpSyncedAt = rec.time;
      return {
        'systolic': rec.systolic,
        'diastolic': rec.diastolic,
        'heartRate': rec.heartRate,
      };
    } catch (_) {
      return null;
    }
  }
  int? get latestHeartRate => polarController.heartRate;

  String? errorMessage;

  void next() {
    switch (step) {
      case StandupStep.intro:
        _startSupineCountdown();
        break;
      case StandupStep.standPrep:
        _startStandingCountdown1();
        break;
      case StandupStep.summary:
        submit();
        break;
      default:
        break;
    }
  }

  void setSupineBp({int? systolic, int? diastolic}) {
    // Only set values if they are provided (not null and > 0)
    data.supineSystolic = systolic != null && systolic > 0 ? systolic : null;
    data.supineDiastolic = diastolic != null && diastolic > 0 ? diastolic : null;
    data.supineHr = latestHeartRate;
    
    debugPrint('Supine BP set: ${data.supineSystolic}/${data.supineDiastolic}');
    
    // Automatically advance to stand prep after BP entry
    step = StandupStep.standPrep;
    notifyListeners();
    
    // NO auto-advance - user must manually proceed
  }

  void setStanding1Min({int? systolic, int? diastolic}) {
    // Only set values if they are provided (not null and > 0)
    data.standing1MinSystolic = systolic != null && systolic > 0 ? systolic : null;
    data.standing1MinDiastolic = diastolic != null && diastolic > 0 ? diastolic : null;
    data.standing1MinHr = latestHeartRate;
    
    debugPrint('Standing 1min BP set: ${data.standing1MinSystolic}/${data.standing1MinDiastolic}');
    
    // Show a "ready" prompt - user clicks continue button
    step = StandupStep.standingCountdownTo3;
    notifyListeners();
  }

  void setStanding3Min({int? systolic, int? diastolic}) {
    // Only set values if they are provided (not null and > 0)
    data.standing3MinSystolic = systolic != null && systolic > 0 ? systolic : null;
    data.standing3MinDiastolic = diastolic != null && diastolic > 0 ? diastolic : null;
    data.standing3MinHr = latestHeartRate;
    
    debugPrint('Standing 3min BP set: ${data.standing3MinSystolic}/${data.standing3MinDiastolic}');
    
    // Show a "ready" prompt - user clicks continue button
    step = StandupStep.standingCountdownTo5;
    notifyListeners();
  }

  void cancelCountdown() {
    _timer?.cancel();
    _timer = null;
    remaining = null;
    notifyListeners();
  }

  void cancelTest() {
    cancelCountdown();
    step = StandupStep.completed; // Mark as completed to exit
    notifyListeners();
  }

  void _startSupineCountdown() {
    data.startedAt = DateTime.now();
    step = StandupStep.supineCountdown;
    _startTimer(const Duration(minutes: 10), _completeSupineCountdown);
  }

  void _completeSupineCountdown() {
    cancelCountdown();
    data.supineHr = latestHeartRate;
    step = StandupStep.supineEntry;
    notifyListeners();
    
    // NO auto-advance - user must click "Confirm & Continue" on BP input
  }

  void _startStandingCountdown1() {
    step = StandupStep.standingCountdown1;
    _startTimer(const Duration(minutes: 1), _completeStanding1Countdown);
  }

  void _completeStanding1Countdown() {
    cancelCountdown();
    data.standing1MinHr = latestHeartRate;
    step = StandupStep.standingEntry1;
    notifyListeners();
    
    // NO auto-advance - user must click "Confirm & Continue" on BP input
  }

  void _startStandingCountdownTo3() {
    step = StandupStep.standingCountdownTo3;
    _startTimer(const Duration(minutes: 2), _completeStanding3Countdown);
  }
  
  void startStandingCountdownTo3() {
    _startStandingCountdownTo3();
  }

  void _completeStanding3Countdown() {
    cancelCountdown();
    data.standing3MinHr = latestHeartRate;
    step = StandupStep.standingEntry3;
    notifyListeners();
    
    // NO auto-advance - user must click "Confirm & Continue" on BP input
  }

  void _startStandingCountdownTo5() {
    step = StandupStep.standingCountdownTo5;
    _startTimer(const Duration(minutes: 2), _completeStanding5Countdown);
  }
  
  void startStandingCountdownTo5() {
    _startStandingCountdownTo5();
  }

  void _completeStanding5Countdown() {
    cancelCountdown();
    data.standing5MinHr = latestHeartRate;
    _startStandingCountdownTo10();
  }

  void _startStandingCountdownTo10() {
    step = StandupStep.standingCountdownTo10;
    _startTimer(const Duration(minutes: 5), _completeStanding10Countdown);
  }

  void _completeStanding10Countdown() {
    cancelCountdown();
    data.standing10MinHr = latestHeartRate;
    step = StandupStep.summary;
    notifyListeners();
    
    // NO auto-submit - user must manually submit
  }
  
  // Add method for final BP reading (optional 10-minute reading)
  void setStanding10Min({int? systolic, int? diastolic}) {
    // Use values from iHealth controller if provided, otherwise use passed values
    // final sys = systolic ?? ihealthBpController.latestSystolic ?? 0; // TODO: Re-implement with native SDK
    // final dia = diastolic ?? ihealthBpController.latestDiastolic ?? 0; // TODO: Re-implement with native SDK
    final sys = systolic ?? 0;
    final dia = diastolic ?? 0;
    
    data.standing10MinSystolic = sys;
    data.standing10MinDiastolic = dia;
    data.standing10MinHr = latestHeartRate;
    
    // Automatically submit after final reading
    step = StandupStep.summary;
    notifyListeners();
    
    Timer(const Duration(seconds: 3), () {
      if (step == StandupStep.summary) {
        submit();
      }
    });
  }

  void _startTimer(Duration duration, VoidCallback onComplete) {
    cancelCountdown();
    remaining = duration;
    notifyListeners();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final seconds = remaining!.inSeconds - 1;
      if (seconds <= 0) {
        timer.cancel();
        _timer = null;
        remaining = null;
        notifyListeners();
        onComplete();
      } else {
        remaining = Duration(seconds: seconds);
        notifyListeners();
      }
    });
  }

  void skipCurrentStep() {
    if (!demoMode) {
      return;
    }
    switch (step) {
      case StandupStep.supineCountdown:
        _completeSupineCountdown();
        break;
      case StandupStep.standingCountdown1:
        _completeStanding1Countdown();
        break;
      case StandupStep.standingCountdownTo3:
        _completeStanding3Countdown();
        break;
      case StandupStep.standingCountdownTo5:
        _completeStanding5Countdown();
        break;
      case StandupStep.standingCountdownTo10:
        _completeStanding10Countdown();
        break;
      default:
        break;
    }
  }

  Future<void> submit() async {
    if (step == StandupStep.submitting) return;
    step = StandupStep.submitting;
    notifyListeners();
    try {
      await _service.submit(patientId: patientId, data: data);
      step = StandupStep.completed;
    } catch (error, stackTrace) {
      debugPrint('Standup test submission failed: $error\n$stackTrace');
      errorMessage = 'Failed to save test. Please try again.';
      step = StandupStep.error;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    cancelCountdown();
    super.dispose();
  }
}
