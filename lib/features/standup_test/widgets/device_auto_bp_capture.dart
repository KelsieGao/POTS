import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:pots/shared/ihealth_kn550_service.dart';

class DeviceAutoBpCapture extends StatefulWidget {
  const DeviceAutoBpCapture({
    super.key,
    required this.title,
    required this.message,
    required this.onCaptured,
    this.pollInterval = const Duration(seconds: 2),
    this.timeout,
  });

  final String title;
  final String message;
  final void Function(int systolic, int diastolic) onCaptured;
  final Duration pollInterval;
  final Duration? timeout;

  @override
  State<DeviceAutoBpCapture> createState() => _DeviceAutoBpCaptureState();
}

class _DeviceAutoBpCaptureState extends State<DeviceAutoBpCapture> {
  Timer? _timer;
  bool _fetchInFlight = false;
  int _elapsedSec = 0;
  int _lastConnectAttemptSec = -10;
  bool _manualConnecting = false;
  Timer? _reminderTimer;
  final FlutterTts _tts = FlutterTts();

  @override
  void initState() {
    super.initState();
    _initAndMaybeConnect();
    _startPolling();
    _startAudioPrompt();
  }

  void _initAndMaybeConnect() {
    // Kick off SDK init and background reconnect (best effort)
    Future(() async {
      final svc = IHealthKn550Service.instance;
      await svc.initialize();
      final mac = svc.lastConnectedMac;
      if (mac != null && mac.isNotEmpty && !svc.isConnected) {
        await svc.connect(mac);
      }
      if (mounted) setState(() {});
    });
  }

  void _startAudioPrompt() {
    // Speak an immediate instruction and then repeat periodically until captured
    Future(() async {
      try {
        await _tts.setLanguage('en-US');
        await _tts.setVolume(1.0);
        await _tts.setSpeechRate(0.45);
        await _tts.setPitch(1.0);
        await _tts.speak('Please press START on your blood pressure device now');
      } catch (_) {}
    });
    _reminderTimer?.cancel();
    _reminderTimer = Timer.periodic(const Duration(seconds: 80), (_) async {
      try {
        await _tts.speak('Please press START on your blood pressure device now');
      } catch (_) {}
    });
  }

  void _startPolling() {
    _timer?.cancel();
    _elapsedSec = 0;
    _timer = Timer.periodic(widget.pollInterval, (timer) async {
      if (!mounted) return;
      _elapsedSec += widget.pollInterval.inSeconds;
      // Periodic reconnect attempt if we now know a MAC
      final svc = IHealthKn550Service.instance;
      final mac = svc.lastConnectedMac;
      if ((mac != null && mac.isNotEmpty) && !svc.isConnected && (_elapsedSec - _lastConnectAttemptSec) >= 10) {
        _lastConnectAttemptSec = _elapsedSec;
        try { await svc.connect(mac); } catch (_) {}
      }
      if (widget.timeout != null && _elapsedSec >= widget.timeout!.inSeconds) {
        timer.cancel();
        return;
      }
      if (_fetchInFlight) return;
      _fetchInFlight = true;
      try {
        final latest = await svc.fetchLatest(totalTimeout: const Duration(seconds: 5));
        if (!mounted) return;
        if (latest != null) {
          _reminderTimer?.cancel();
          widget.onCaptured(latest.systolic, latest.diastolic);
          timer.cancel();
        }
        // Fallback: try fetching full offline list and use newest
        if (latest == null) {
          final knownMac = svc.lastConnectedMac;
          if (knownMac != null && knownMac.isNotEmpty) {
            final list = await svc.getOfflineData(knownMac, timeout: const Duration(seconds: 5));
            if (!mounted) return;
            if (list.isNotEmpty) {
              list.sort((a, b) => a.time.compareTo(b.time));
              final last = list.last;
              _reminderTimer?.cancel();
              widget.onCaptured(last.systolic, last.diastolic);
              timer.cancel();
            }
          }
        }
      } catch (_) {
        // ignore
      } finally {
        _fetchInFlight = false;
        if (mounted) setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _reminderTimer?.cancel();
    try { _tts.stop(); } catch (_) {}
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mac = IHealthKn550Service.instance.lastConnectedMac;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(widget.title, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 12),
        Text(widget.message, style: Theme.of(context).textTheme.bodyLarge),
        const SizedBox(height: 24),
        // Only show the connection helper if we have no remembered device.
        if (!IHealthKn550Service.instance.isConnected && (mac == null || mac.isEmpty))
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.bluetooth, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    (mac == null || mac.isEmpty)
                        ? 'No cuff remembered. Open the iHealth screen to connect.'
                        : 'Not connected. Tap Connect to re-link to $mac.',
                  ),
                ),
                if (mac != null && mac.isNotEmpty)
                  OutlinedButton(
                    onPressed: _manualConnecting
                        ? null
                        : () async {
                            setState(() => _manualConnecting = true);
                            try { await IHealthKn550Service.instance.connect(mac); } catch (_) {}
                            if (mounted) setState(() => _manualConnecting = false);
                          },
                    child: Text(_manualConnecting ? 'Connecting…' : 'Connect'),
                  )
                else
                  TextButton(
                    onPressed: () { Navigator.of(context).pushNamed('/ihealth-test'); },
                    child: const Text('Open iHealth'),
                  ),
              ],
            ),
          ),
        Center(
          child: Column(
            children: [
              const CircularProgressIndicator(strokeWidth: 2),
              const SizedBox(height: 8),
              Text('Waiting for cuff reading... ${_elapsedSec}s',
                  style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 4),
              if (IHealthKn550Service.instance.isConnected && (mac != null && mac.isNotEmpty))
                Text(
                  'Connected to $mac',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
            ],
          ),
        ),
      ],
    );
  }
}


