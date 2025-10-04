import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:pots/features/polar/polar_heart_rate_controller.dart';

import '../models/standup_test_data.dart';
import '../services/standup_test_service.dart';

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
    required this.patientId,
    this.demoMode = true,
    StandupTestService? service,
  }) : _service = service ?? StandupTestService();

  final PolarHeartRateController polarController;
  final String patientId;
  final bool demoMode;
  final StandupTestService _service;

  final StandupTestData data = StandupTestData();

  StandupStep step = StandupStep.intro;
  Duration? remaining;

  Timer? _timer;

  bool get isCountdownActive => _timer != null;
  int? get latestHeartRate => polarController.heartRate;

  String? errorMessage;

  void next() {
    switch (step) {
      case StandupStep.intro:
        _startSupineCountdown();
        break;
      case StandupStep.supineEntry:
        step = StandupStep.standPrep;
        notifyListeners();
        break;
      case StandupStep.standPrep:
        _startStandingCountdown1();
        break;
      case StandupStep.standingEntry1:
        _startStandingCountdownTo3();
        break;
      case StandupStep.standingEntry3:
        _startStandingCountdownTo5();
        break;
      case StandupStep.summary:
        submit();
        break;
      default:
        break;
    }
  }

  void setSupineBp({required int systolic, required int diastolic}) {
    data.supineSystolic = systolic;
    data.supineDiastolic = diastolic;
    data.supineHr = latestHeartRate;
    step = StandupStep.supineEntry;
    notifyListeners();
  }

  void setStanding1Min({required int systolic, required int diastolic}) {
    data.standing1MinSystolic = systolic;
    data.standing1MinDiastolic = diastolic;
    data.standing1MinHr = latestHeartRate;
    step = StandupStep.standingEntry1;
    notifyListeners();
  }

  void setStanding3Min({required int systolic, required int diastolic}) {
    data.standing3MinSystolic = systolic;
    data.standing3MinDiastolic = diastolic;
    data.standing3MinHr = latestHeartRate;
    step = StandupStep.standingEntry3;
    notifyListeners();
  }

  void cancelCountdown() {
    _timer?.cancel();
    _timer = null;
    remaining = null;
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
  }

  void _startStandingCountdownTo3() {
    step = StandupStep.standingCountdownTo3;
    _startTimer(const Duration(minutes: 2), _completeStanding3Countdown);
  }

  void _completeStanding3Countdown() {
    cancelCountdown();
    data.standing3MinHr = latestHeartRate;
    step = StandupStep.standingEntry3;
    notifyListeners();
  }

  void _startStandingCountdownTo5() {
    step = StandupStep.standingCountdownTo5;
    _startTimer(const Duration(minutes: 2), _completeStanding5Countdown);
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
