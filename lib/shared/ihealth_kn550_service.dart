import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';

class BpRecord {
  final DateTime time;
  final int systolic;
  final int diastolic;
  final int heartRate;
  final String? dataId;
  final bool? arrhythmia;
  final bool? bodyMovement;
  final bool? timeCalibration;

  BpRecord({
    required this.time,
    required this.systolic,
    required this.diastolic,
    required this.heartRate,
    this.dataId,
    this.arrhythmia,
    this.bodyMovement,
    this.timeCalibration,
  });
}

/// Thin wrapper around the Android iHealth KN‑550BT bridge
class IHealthKn550Service {
  IHealthKn550Service._() {
    _eventsSub = _events.receiveBroadcastStream().listen(_handleEvent, onError: (_) {});
  }

  static final IHealthKn550Service instance = IHealthKn550Service._();

  static const MethodChannel _channel = MethodChannel('com.kelsie.potsive/ihealth');
  static const EventChannel _events = EventChannel('com.kelsie.potsive/ihealth/events');

  StreamSubscription? _eventsSub;

  String? _lastConnectedMac;
  String? get lastConnectedMac => _lastConnectedMac;

  // De-dupe markers (in-memory v1)
  String? _lastSyncedDataId;
  DateTime? _lastSyncedTime;

  // Completers for request/response
  Completer<int>? _numCompleter;
  Completer<List<BpRecord>>? _dataCompleter;

  void _handleEvent(dynamic event) {
    if (event is Map) {
      final map = event.map((k, v) => MapEntry(k.toString(), v));
      final type = map['event']?.toString();
      if (type == 'connection') {
        final mac = map['mac']?.toString();
        final status = map['status'] as int?;
        if (mac != null && status != null && status == 1) {
          _lastConnectedMac = mac;
        }
      } else if (type == 'bpOfflineNum') {
        final count = (map['count'] as int?) ?? 0;
        _numCompleter?.complete(count);
        _numCompleter = null;
      } else if (type == 'bpOfflineData') {
        final List<dynamic> recs = (map['records'] as List?) ?? const [];
        final parsed = <BpRecord>[];
        for (final r in recs) {
          if (r is Map) {
            final m = r.map((k, v) => MapEntry(k.toString(), v));
            final timeStr = m['time']?.toString();
            DateTime t;
            try {
              t = DateTime.parse(timeStr ?? '');
            } catch (_) {
              t = DateTime.now();
            }
            parsed.add(BpRecord(
              time: t,
              systolic: (m['systolic'] as int?) ?? (m['sys'] as int? ?? 0),
              diastolic: (m['diastolic'] as int?) ?? (m['dia'] as int? ?? 0),
              heartRate: (m['heartRate'] as int?) ?? (m['pulse_bp'] as int? ?? 0),
              dataId: m['dataID']?.toString(),
              arrhythmia: m['arrhythmia'] as bool?,
              bodyMovement: m['body_movement'] as bool?,
              timeCalibration: m['time_calibration'] as bool?,
            ));
          }
        }
        _dataCompleter?.complete(parsed);
        _dataCompleter = null;
      }
    } else if (event is String) {
      // No-op; native always sends Map
    }
  }

  Future<int> getOfflineCount(String mac, {Duration timeout = const Duration(seconds: 6)}) async {
    _numCompleter?.completeError(StateError('superseded'));
    _numCompleter = Completer<int>();
    await _channel.invokeMethod('sdkGetOfflineNum', {'mac': mac});
    return _numCompleter!.future.timeout(timeout, onTimeout: () => 0);
  }

  Future<List<BpRecord>> getOfflineData(String mac, {Duration timeout = const Duration(seconds: 8)}) async {
    _dataCompleter?.completeError(StateError('superseded'));
    _dataCompleter = Completer<List<BpRecord>>();
    await _channel.invokeMethod('sdkGetOfflineData', {'mac': mac});
    return _dataCompleter!.future.timeout(timeout, onTimeout: () => const []);
  }

  Future<void> transferFinished(String mac) async {
    try {
      await _channel.invokeMethod('sdkTransferFinished', {'mac': mac});
    } catch (_) {}
  }

  /// Convenience: fetch the latest unsynced BP record and mark synced.
  Future<BpRecord?> fetchLatest({String? mac, Duration totalTimeout = const Duration(seconds: 8)}) async {
    final target = mac ?? _lastConnectedMac;
    if (target == null || target.isEmpty) return null;

    final count = await getOfflineCount(target, timeout: Duration(milliseconds: (totalTimeout.inMilliseconds * 0.35).round()));
    if (count <= 0) return null;
    final data = await getOfflineData(target, timeout: Duration(milliseconds: (totalTimeout.inMilliseconds * 0.65).round()));
    if (data.isEmpty) return null;

    // pick newest by time
    data.sort((a, b) => a.time.compareTo(b.time));
    final latest = data.last;

    // de-dup by dataID or time
    if (_lastSyncedDataId != null && latest.dataId != null && latest.dataId == _lastSyncedDataId) {
      return null;
    }
    if (_lastSyncedDataId == null && _lastSyncedTime != null && !latest.time.isAfter(_lastSyncedTime!)) {
      return null;
    }

    _lastSyncedDataId = latest.dataId;
    _lastSyncedTime = latest.time;

    // best-effort clear
    unawaited(transferFinished(target));
    return latest;
  }
}


