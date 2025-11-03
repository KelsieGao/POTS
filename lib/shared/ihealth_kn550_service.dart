import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    unawaited(_loadLastMac());
  }

  static final IHealthKn550Service instance = IHealthKn550Service._();

  static const MethodChannel _channel = MethodChannel('com.kelsie.potsive/ihealth');
  static const EventChannel _events = EventChannel('com.kelsie.potsive/ihealth/events');

  StreamSubscription? _eventsSub;

  String? _lastConnectedMac;
  String? get lastConnectedMac => _lastConnectedMac;
  void setLastConnectedMac(String mac) {
    _lastConnectedMac = mac;
    unawaited(_persistLastMac(mac));
  }

  bool _initialized = false;
  bool get isInitialized => _initialized;
  bool _isConnected = false;
  bool get isConnected => _isConnected;

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
        if (mac != null && status != null) {
          if (status == 1) {
            _lastConnectedMac = mac;
            _isConnected = true;
            unawaited(_persistLastMac(mac));
          } else {
            _isConnected = false;
          }
        }
      } else if (type == 'bpOfflineNum') {
        final count = (map['count'] as int?) ?? 0;
        try { _numCompleter?.complete(count); } catch (_) {}
        _numCompleter = null;
      } else if (type == 'bpOfflineData' || type == 'historicaldata_bp') {
        final List<dynamic> recs = (map['records'] as List?) ?? (map['data'] as List?) ?? const [];
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
        try { _dataCompleter?.complete(parsed); } catch (_) {}
        _dataCompleter = null;
      }
    } else if (event is String) {
      // No-op; native always sends Map
    }
  }

  Future<int> getOfflineCount(String mac, {Duration timeout = const Duration(seconds: 6)}) async {
    try { _numCompleter?.complete(0); } catch (_) {}
    _numCompleter = Completer<int>();
    await _channel.invokeMethod('sdkGetOfflineNum', {'mac': mac});
    try {
      return await _numCompleter!.future.timeout(timeout, onTimeout: () => 0);
    } catch (_) {
      return 0;
    }
  }

  Future<List<BpRecord>> getOfflineData(String mac, {Duration timeout = const Duration(seconds: 8)}) async {
    try { _dataCompleter?.complete(const <BpRecord>[]); } catch (_) {}
    _dataCompleter = Completer<List<BpRecord>>();
    await _channel.invokeMethod('sdkGetOfflineData', {'mac': mac});
    try {
      return await _dataCompleter!.future.timeout(timeout, onTimeout: () => const []);
    } catch (_) {
      return const [];
    }
  }

  Future<void> transferFinished(String mac) async {
    try {
      await _channel.invokeMethod('sdkTransferFinished', {'mac': mac});
    } catch (_) {}
  }

  Future<bool> initialize() async {
    if (_initialized) return true;
    try {
      final ok = await _channel.invokeMethod<bool>('initIHealth') ?? false;
      _initialized = ok;
      return ok;
    } catch (_) {
      _initialized = false;
      return false;
    }
  }

  Future<void> connect(String mac) async {
    if (mac.isEmpty) return;
    try {
      await _channel.invokeMethod('sdkConnect', {'mac': mac});
    } catch (_) {}
  }

  Future<void> disconnect({String? mac}) async {
    final target = mac ?? _lastConnectedMac;
    if (target == null || target.isEmpty) return;
    try {
      await _channel.invokeMethod('sdkDisconnect', {'mac': target});
    } catch (_) {}
    _isConnected = false;
  }

  /// Convenience: fetch the latest unsynced BP record and mark synced.
  Future<BpRecord?> fetchLatest({String? mac, Duration totalTimeout = const Duration(seconds: 8)}) async {
    try {
      final target = mac ?? _lastConnectedMac;
      if (target == null || target.isEmpty) return null;

      await _loadLastSynced(target);

      final count = await getOfflineCount(target, timeout: Duration(milliseconds: (totalTimeout.inMilliseconds * 0.35).round()));
      if (count <= 0) return null;
      final data = await getOfflineData(target, timeout: Duration(milliseconds: (totalTimeout.inMilliseconds * 0.65).round()));
      if (data.isEmpty) return null;

      data.sort((a, b) => a.time.compareTo(b.time));
      final latest = data.last;

      if (_lastSyncedDataId != null && latest.dataId != null && latest.dataId == _lastSyncedDataId) {
        return null;
      }
      if (_lastSyncedDataId == null && _lastSyncedTime != null && !latest.time.isAfter(_lastSyncedTime!)) {
        return null;
      }

      _lastSyncedDataId = latest.dataId;
      _lastSyncedTime = latest.time;
      unawaited(_saveLastSynced(target, _lastSyncedDataId, _lastSyncedTime));
      unawaited(transferFinished(target));
      return latest;
    } catch (_) {
      return null;
    }
  }

  Future<void> _loadLastSynced(String mac) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _lastSyncedDataId = prefs.getString('kn550_last_data_id_$mac');
      final ts = prefs.getInt('kn550_last_time_ms_$mac');
      _lastSyncedTime = ts != null ? DateTime.fromMillisecondsSinceEpoch(ts) : null;
    } catch (_) {}
  }

  Future<void> _saveLastSynced(String mac, String? dataId, DateTime? time) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (dataId != null) {
        await prefs.setString('kn550_last_data_id_$mac', dataId);
      }
      if (time != null) {
        await prefs.setInt('kn550_last_time_ms_$mac', time.millisecondsSinceEpoch);
      }
    } catch (_) {}
  }

  Future<void> _persistLastMac(String mac) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('kn550_last_mac', mac);
    } catch (_) {}
  }

  Future<void> _loadLastMac() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _lastConnectedMac = prefs.getString('kn550_last_mac') ?? _lastConnectedMac;
    } catch (_) {}
  }
}


