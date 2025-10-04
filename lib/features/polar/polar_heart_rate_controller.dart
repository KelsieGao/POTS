import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:polar/polar.dart';
import 'package:pots/features/polar/services/heart_rate_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum PolarConnectionStatus {
  idle,
  connecting,
  connected,
  streaming,
  disconnected,
  error,
}

class PolarHeartRateController extends ChangeNotifier {
  PolarHeartRateController({Polar? polar, HeartRateService? heartRateService})
    : _polar = polar ?? Polar(),
      _heartRateService = heartRateService ?? HeartRateService() {
    _featureReadySub = _polar.sdkFeatureReady.listen(_handleFeatureReadyEvent);
    _connectingSub = _polar.deviceConnecting.listen(
      _handleDeviceConnectingEvent,
    );
    _connectedSub = _polar.deviceConnected.listen(_handleDeviceConnectedEvent);
    _disconnectedSub = _polar.deviceDisconnected.listen(
      _handleDeviceDisconnectedEvent,
    );
    _persistenceTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => _persistLatestSample(),
    );
  }

  static const _prefsLastDeviceIdKey = 'polar_last_device_id';

  final Polar _polar;
  final HeartRateService _heartRateService;

  StreamSubscription<PolarSdkFeatureReadyEvent>? _featureReadySub;
  StreamSubscription<PolarDeviceInfo>? _connectingSub;
  StreamSubscription<PolarDeviceInfo>? _connectedSub;
  StreamSubscription<PolarDeviceDisconnectedEvent>? _disconnectedSub;
  StreamSubscription<PolarHrData>? _hrSubscription;
  StreamSubscription<PolarDeviceInfo>? _searchSubscription;

  Timer? _persistenceTimer;

  SharedPreferences? _prefs;
  bool _attemptedReconnect = false;

  String? _patientId;
  PolarHrSample? _latestSample;
  DateTime? _latestSampleTimestamp;
  DateTime? _lastPersistedSampleTimestamp;
  bool _isPersisting = false;

  final List<PolarDeviceInfo> _discoveredDevices = [];

  PolarConnectionStatus _status = PolarConnectionStatus.idle;
  String? _activeDeviceId;
  String? _rememberedDeviceId;
  int? _heartRateBpm;
  String? _errorMessage;
  bool _isScanning = false;

  PolarConnectionStatus get status => _status;
  String? get deviceId => _activeDeviceId ?? _rememberedDeviceId;
  String? get rememberedDeviceId => _rememberedDeviceId;
  int? get heartRate => _heartRateBpm;
  String? get errorMessage => _errorMessage;
  bool get isStreaming => _status == PolarConnectionStatus.streaming;
  bool get isBusy => _status == PolarConnectionStatus.connecting || _isScanning;
  bool get isScanning => _isScanning;
  List<PolarDeviceInfo> get discoveredDevices =>
      List.unmodifiable(_discoveredDevices);

  void updatePatientId(String? patientId) {
    _patientId = patientId;
  }

  Future<void> connectToDevice(PolarDeviceInfo device) async {
    await connect(device.deviceId);
  }

  Future<void> connect(String identifier, {bool silent = false}) async {
    final trimmed = identifier.trim();
    if (trimmed.isEmpty) {
      _setError(
        'Select a Polar device to connect.',
        preserveStatus: true,
        showMessage: !silent,
      );
      return;
    }

    await stopScan();

    _activeDeviceId = trimmed;
    _rememberedDeviceId = trimmed;
    _errorMessage = null;
    _status = PolarConnectionStatus.connecting;
    notifyListeners();

    unawaited(_rememberDeviceId(trimmed));

    try {
      await _polar.connectToDevice(trimmed);
    } catch (error) {
      _setError(
        'Failed to initiate connection: $error',
        preserveStatus: silent,
        showMessage: !silent,
      );
    }
  }

  Future<void> connectIfKnown() async {
    if (_attemptedReconnect) {
      return;
    }
    _attemptedReconnect = true;

    final prefs = await _ensurePrefs();
    final stored = prefs.getString(_prefsLastDeviceIdKey);
    if (stored == null || stored.isEmpty) {
      return;
    }

    _rememberedDeviceId = stored;
    notifyListeners();

    await connect(stored, silent: true);
  }

  Future<void> disconnect({bool forgetDevice = false}) async {
    final id = _activeDeviceId;
    if (id == null) {
      return;
    }

    try {
      await _polar.disconnectFromDevice(id);
    } catch (error) {
      _setError('Failed to disconnect: $error');
    }

    await _stopStreaming();
    _status = PolarConnectionStatus.disconnected;
    _activeDeviceId = null;
    if (forgetDevice) {
      await _forgetRememberedDeviceId();
    }
    notifyListeners();
  }

  Future<void> startScan() async {
    if (_isScanning) {
      return;
    }

    try {
      await _polar.requestPermissions();
    } catch (error) {
      _setError('Permission request failed: $error', preserveStatus: true);
      return;
    }

    _isScanning = true;
    _errorMessage = null;
    _discoveredDevices.clear();
    notifyListeners();

    _searchSubscription = _polar.searchForDevice().listen(
      (device) {
        final index = _discoveredDevices.indexWhere(
          (element) => element.deviceId == device.deviceId,
        );
        if (index == -1) {
          _discoveredDevices.add(device);
        } else {
          _discoveredDevices[index] = device;
        }
        notifyListeners();
      },
      onError: (Object error, StackTrace stackTrace) {
        _isScanning = false;
        _searchSubscription = null;
        _setError('Device search error: $error', preserveStatus: true);
      },
      onDone: () {
        _isScanning = false;
        _searchSubscription = null;
        notifyListeners();
      },
    );
  }

  Future<void> stopScan() async {
    if (!_isScanning) {
      return;
    }

    await _searchSubscription?.cancel();
    _searchSubscription = null;
    _isScanning = false;
    notifyListeners();
  }

  void _handleDeviceConnectingEvent(PolarDeviceInfo info) {
    if (!_matchesActiveDevice(info.deviceId)) {
      return;
    }
    _status = PolarConnectionStatus.connecting;
    notifyListeners();
  }

  void _handleDeviceConnectedEvent(PolarDeviceInfo info) {
    if (!_matchesActiveDevice(info.deviceId)) {
      return;
    }
    _status = PolarConnectionStatus.connected;
    notifyListeners();
  }

  void _handleDeviceDisconnectedEvent(PolarDeviceDisconnectedEvent event) {
    if (!_matchesActiveDevice(event.info.deviceId)) {
      return;
    }

    _activeDeviceId = null;
    _errorMessage = event.pairingError
        ? 'Pairing error reported by device. Retry the connection.'
        : null;
    _status = PolarConnectionStatus.disconnected;
    unawaited(_stopStreaming());
    notifyListeners();
  }

  void _handleFeatureReadyEvent(PolarSdkFeatureReadyEvent event) {
    if (!_matchesActiveDevice(event.identifier)) {
      return;
    }

    if (event.feature == PolarSdkFeature.onlineStreaming) {
      unawaited(_beginHeartRateStream());
    }
  }

  Future<void> _beginHeartRateStream() async {
    final id = _activeDeviceId;
    if (id == null || _hrSubscription != null) {
      return;
    }

    try {
      final availableTypes = await _polar.getAvailableOnlineStreamDataTypes(id);
      if (!availableTypes.contains(PolarDataType.hr)) {
        final hrTypes = await _polar.getAvailableHrServiceDataTypes(id);
        if (!hrTypes.contains(PolarDataType.hr)) {
          _setError('Heart rate streaming is not supported on this device.');
          return;
        }
      }

      _hrSubscription = _polar
          .startHrStreaming(id)
          .listen(
            (event) {
              if (event.samples.isEmpty) {
                return;
              }
              final sample = event.samples.last;
              _latestSample = sample;
              _latestSampleTimestamp = DateTime.now();
              _heartRateBpm = sample.hr;
              _status = PolarConnectionStatus.streaming;
              debugPrint(
                '[HR] ${_latestSampleTimestamp?.toIso8601String()} bpm=${sample.hr} sampleCount=${event.samples.length}',
              );
              notifyListeners();
            },
            onError: (Object error, StackTrace stackTrace) {
              _setError('Heart rate stream error: $error');
            },
            onDone: () {
              _status = PolarConnectionStatus.connected;
              notifyListeners();
            },
          );
    } catch (error) {
      _setError('Unable to start heart rate stream: $error');
    }
  }

  Future<void> _persistLatestSample() async {
    if (_isPersisting) {
      return;
    }
    final sample = _latestSample;
    final recordedAt = _latestSampleTimestamp;
    final patientId = _patientId;
    final deviceId = _activeDeviceId ?? _rememberedDeviceId;
    if (sample == null ||
        recordedAt == null ||
        patientId == null ||
        deviceId == null) {
      return;
    }
    if (_lastPersistedSampleTimestamp != null &&
        !recordedAt.isAfter(_lastPersistedSampleTimestamp!)) {
      return;
    }
    _isPersisting = true;
    try {
      await _heartRateService.saveSample(
        patientId: patientId,
        deviceId: deviceId,
        recordedAt: recordedAt,
        sample: sample,
      );
      _lastPersistedSampleTimestamp = recordedAt;
      debugPrint('[HR] persisted sample at ${recordedAt.toIso8601String()}');
    } catch (error, stackTrace) {
      debugPrint('Failed to persist heart rate sample: $error\n$stackTrace');
    } finally {
      _isPersisting = false;
    }
  }

  bool _matchesActiveDevice(String identifier) {
    final id = _activeDeviceId;
    if (id == null) {
      return false;
    }
    return id.toUpperCase() == identifier.toUpperCase();
  }

  Future<SharedPreferences> _ensurePrefs() async {
    return _prefs ??= await SharedPreferences.getInstance();
  }

  Future<void> _rememberDeviceId(String id) async {
    final prefs = await _ensurePrefs();
    await prefs.setString(_prefsLastDeviceIdKey, id);
    _rememberedDeviceId = id;
  }

  Future<void> _forgetRememberedDeviceId() async {
    final prefs = await _ensurePrefs();
    await prefs.remove(_prefsLastDeviceIdKey);
    _rememberedDeviceId = null;
  }

  void _setError(
    String message, {
    bool preserveStatus = false,
    bool showMessage = true,
  }) {
    if (showMessage) {
      _errorMessage = message;
    }
    if (!preserveStatus) {
      _status = PolarConnectionStatus.error;
    }
    notifyListeners();
  }

  Future<void> _stopStreaming() async {
    await _hrSubscription?.cancel();
    _hrSubscription = null;
    _heartRateBpm = null;
  }

  @override
  void dispose() {
    _featureReadySub?.cancel();
    _connectingSub?.cancel();
    _connectedSub?.cancel();
    _disconnectedSub?.cancel();
    _hrSubscription?.cancel();
    _searchSubscription?.cancel();
    _persistenceTimer?.cancel();
    super.dispose();
  }
}

extension PolarConnectionStatusX on PolarConnectionStatus {
  String get label {
    switch (this) {
      case PolarConnectionStatus.idle:
        return 'Idle';
      case PolarConnectionStatus.connecting:
        return 'Connecting';
      case PolarConnectionStatus.connected:
        return 'Connected';
      case PolarConnectionStatus.streaming:
        return 'Streaming';
      case PolarConnectionStatus.disconnected:
        return 'Disconnected';
      case PolarConnectionStatus.error:
        return 'Error';
    }
  }
}
