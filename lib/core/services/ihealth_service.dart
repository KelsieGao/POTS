import 'dart:async';
import 'package:ihealth_sdk/ihealth_sdk.dart';

/// Service to handle iHealth KN-550BT Blood Pressure Monitor integration
class IHealthService {
  static final IHealthService _instance = IHealthService._internal();
  factory IHealthService() => _instance;
  IHealthService._internal();

  final _ihealthPlugin = IhealthSdk();
  
  // Stream controllers for BP data
  final _bpStreamController = StreamController<BloodPressureReading>.broadcast();
  Stream<BloodPressureReading> get bpStream => _bpStreamController.stream;

  bool _isConnected = false;
  bool get isConnected => _isConnected;

  /// Initialize the iHealth SDK
  Future<void> initialize() async {
    try {
      // Initialize the plugin
      // Note: You may need to add app credentials if the SDK requires them
    } catch (e) {
      print('Error initializing iHealth SDK: $e');
    }
  }

  /// Scan for iHealth KN-550BT devices
  Future<List<BluetoothDevice>> scanForDevices() async {
    try {
      final devices = await _ihealthPlugin.scanForDevices();
      return devices;
    } catch (e) {
      print('Error scanning for devices: $e');
      return [];
    }
  }

  /// Connect to a specific device
  Future<bool> connectDevice(String deviceAddress) async {
    try {
      await _ihealthPlugin.connectDevice(deviceAddress);
      _isConnected = true;
      
      // Listen for BP readings
      _setupBPListener();
      
      return true;
    } catch (e) {
      print('Error connecting to device: $e');
      _isConnected = false;
      return false;
    }
  }

  /// Setup listener for BP readings
  void _setupBPListener() {
    // The iHealth SDK should provide a stream or callback for BP readings
    // This is a placeholder - adjust based on actual SDK API
    _ihealthPlugin.onBloodPressureReading.listen((reading) {
      _bpStreamController.add(reading);
    });
  }

  /// Disconnect from the device
  Future<void> disconnect() async {
    try {
      await _ihealthPlugin.disconnect();
      _isConnected = false;
    } catch (e) {
      print('Error disconnecting: $e');
    }
  }

  /// Get device battery level
  Future<int?> getBatteryLevel() async {
    try {
      return await _ihealthPlugin.getBatteryLevel();
    } catch (e) {
      print('Error getting battery level: $e');
      return null;
    }
  }

  /// Cleanup
  void dispose() {
    _bpStreamController.close();
  }
}

/// Data model for blood pressure readings
class BloodPressureReading {
  final int systolic;
  final int diastolic;
  final int heartRate;
  final DateTime timestamp;

  BloodPressureReading({
    required this.systolic,
    required this.diastolic,
    required this.heartRate,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'systolic': systolic,
        'diastolic': diastolic,
        'heartRate': heartRate,
        'timestamp': timestamp.toIso8601String(),
      };
}

/// Placeholder for Bluetooth device model from SDK
class BluetoothDevice {
  final String name;
  final String address;
  final int rssi;

  BluetoothDevice({
    required this.name,
    required this.address,
    required this.rssi,
  });
}
