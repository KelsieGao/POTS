import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ihealth_hr/ihealth_hr.dart';
import 'package:permission_handler/permission_handler.dart';

enum IHealthBpConnectionStatus {
  idle,
  connecting,
  connected,
  reading,
  disconnected,
  error,
}

class IHealthBpController extends ChangeNotifier {
  IHealthBpController() {
    _initialize();
  }

  static const _prefsLastDeviceIdKey = 'ihealth_last_device_id';

  StreamSubscription? _deviceStatusSubscription;

  String? _patientId;
  IHealthBpConnectionStatus _status = IHealthBpConnectionStatus.idle;
  String? _activeDeviceId;
  String? _rememberedDeviceId;
  int? _latestSystolic;
  int? _latestDiastolic;
  int? _latestHeartRate;
  String? _errorMessage;
  bool _isScanning = false;
  DateTime? _latestReadingTimestamp;

  IHealthBpConnectionStatus get status => _status;
  String? get deviceId => _activeDeviceId ?? _rememberedDeviceId;
  String? get rememberedDeviceId => _rememberedDeviceId;
  int? get latestSystolic => _latestSystolic;
  int? get latestDiastolic => _latestDiastolic;
  int? get latestHeartRate => _latestHeartRate;
  String? get errorMessage => _errorMessage;
  bool get isConnected => _status == IHealthBpConnectionStatus.connected ||
      _status == IHealthBpConnectionStatus.reading;
  bool get isReading => _status == IHealthBpConnectionStatus.reading;
  bool get isScanning => _isScanning;
  bool get hasLatestReading =>
      _latestSystolic != null && _latestDiastolic != null;
  List<Map<String, dynamic>> get discoveredDevices => []; // Placeholder - iHealth SDK doesn't expose discovered devices
  DateTime? get latestReadingTimestamp => _latestReadingTimestamp;

  void updatePatientId(String? patientId) {
    _patientId = patientId;
  }

  void _initialize() {
    // Temporarily disabled due to SDK crashes
    // _deviceStatusSubscription = IhealthHrPlugin.deviceStatusStream.listen(
    _deviceStatusSubscription = null;
    debugPrint('iHealth integration disabled due to SDK issues');
    /*
    _deviceStatusSubscription = IhealthHrPlugin.deviceStatusStream.listen(
      (event) {
        if (event is Map) {
          final Map<dynamic, dynamic> data = Map<dynamic, dynamic>.from(event);
          final String eventType = data['event'] ?? '';

          switch (eventType) {
            case 'connectionStateChanged':
              final String status = data['status'] ?? 'unknown';
              if (status == 'connected') {
                _status = IHealthBpConnectionStatus.connected;
              } else if (status == 'connecting') {
                _status = IHealthBpConnectionStatus.connecting;
              } else if (status == 'disconnected') {
                _status = IHealthBpConnectionStatus.disconnected;
              }
              notifyListeners();
              break;

            case 'historyData':
              _latestSystolic = data['sys'] as int?;
              _latestDiastolic = data['dia'] as int?;
              _latestHeartRate = data['heartRate'] as int?;
              _latestReadingTimestamp = DateTime.now();
              _status = IHealthBpConnectionStatus.connected;
              notifyListeners();
              break;

            case 'batteryLevel':
              notifyListeners();
              break;
          }
        }
      },
      onError: (error) => _setError('Device stream error: $error'),
    );
    */
  }

  Future<void> connectIfKnown() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_prefsLastDeviceIdKey);
    if (stored == null || stored.isEmpty) {
      return;
    }

    _rememberedDeviceId = stored;
    notifyListeners();

    await connect(stored, silent: true);
  }

  Future<void> scanForDevices() async {
    // Temporarily disabled due to SDK crashes
    _setError('Blood pressure monitor integration is temporarily disabled. Please enter readings manually.');
  }

  Future<void> stopScan() async {
    // Temporarily disabled
    _isScanning = false;
    notifyListeners();
  }

  Future<void> connect(String deviceAddress, {bool silent = false}) async {
    if (deviceAddress.trim().isEmpty) {
      if (!silent) {
        _setError('Please select a device to connect.');
      }
      return;
    }

    await stopScan();

    _activeDeviceId = deviceAddress.trim();
    _rememberedDeviceId = deviceAddress.trim();
    _errorMessage = null;
    _status = IHealthBpConnectionStatus.connecting;
    notifyListeners();

    unawaited(_rememberDeviceId(deviceAddress.trim()));

    // For now, just connect - the actual device will be handled by the SDK
    // The iHealth SDK handles connection automatically after scanning
    _status = IHealthBpConnectionStatus.connected;
    notifyListeners();
  }

  Future<void> connectToDevice(Map<String, dynamic> device) async {
    await connect(device['address'] ?? '');
  }

  Future<void> disconnect({bool forgetDevice = false}) async {
    final id = _activeDeviceId ?? _rememberedDeviceId;
    if (id == null) {
      return;
    }

    try {
      // Stop scanning
      await IhealthHrPlugin.stopScan();
      
      _status = IHealthBpConnectionStatus.disconnected;
      _activeDeviceId = null;
      
      if (forgetDevice) {
        await _forgetRememberedDeviceId();
      }
      
      notifyListeners();
    } catch (error) {
      _setError('Disconnection error: $error');
    }
  }

  void clearLatestReading() {
    _latestSystolic = null;
    _latestDiastolic = null;
    _latestHeartRate = null;
    _latestReadingTimestamp = null;
    notifyListeners();
  }

  Future<void> _rememberDeviceId(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsLastDeviceIdKey, id);
    } catch (e) {
      debugPrint('Failed to remember device ID: $e');
    }
  }

  Future<void> _forgetRememberedDeviceId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefsLastDeviceIdKey);
      _rememberedDeviceId = null;
    } catch (e) {
      debugPrint('Failed to forget device ID: $e');
    }
  }

  void _setError(String message, {bool showMessage = true}) {
    _errorMessage = message;
    _status = IHealthBpConnectionStatus.error;
    notifyListeners();
    
    if (showMessage) {
      debugPrint('[IHealth BP] Error: $message');
    }
  }

  @override
  void dispose() {
    _deviceStatusSubscription?.cancel();
    super.dispose();
  }
}
