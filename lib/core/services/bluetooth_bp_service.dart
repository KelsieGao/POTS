import 'dart:async';
import 'dart:convert';

import 'package:flutter_blue_plus/flutter_blue_plus.dart' as blue_plus;

/// Service to handle Blood Pressure Monitor via generic Bluetooth
class BluetoothBpService {
  static final BluetoothBpService _instance = BluetoothBpService._internal();
  factory BluetoothBpService() => _instance;
  BluetoothBpService._internal();

  final _bpStreamController = StreamController<BloodPressureReading>.broadcast();
  Stream<BloodPressureReading> get bpStream => _bpStreamController.stream;

  blue_plus.BluetoothDevice? _connectedDevice;
  bool _isConnected = false;
  bool get isConnected => _isConnected;

  StreamSubscription<List<blue_plus.ScanResult>>? _scanSubscription;

  /// Scan for BP devices
  Stream<BluetoothDevice> scanForDevices() async* {
    // Request permissions
    await requestPermissions();
    
    // Start scanning
    await blue_plus.FlutterBluePlus.startScan(timeout: const Duration(seconds: 15));
    
    // Listen for scan results
    await for (final results in blue_plus.FlutterBluePlus.scanResults) {
      for (final result in results) {
        final device = result.device;
        
        // Filter for iHealth or KN-550BT devices
        final deviceName = device.name.isEmpty ? device.localName : device.name;
        if (deviceName.contains('iHealth') || 
            deviceName.contains('KN-550BT') ||
            deviceName.contains('BP5') ||
            deviceName.contains('BP') ||
            deviceName.isEmpty) { // Show all devices for now
          yield BluetoothDevice(
            name: deviceName.isEmpty ? 'Unknown Device' : deviceName,
            address: device.remoteId.str,
            rssi: result.rssi,
          );
        }
      }
    }
  }

  Future<bool> requestPermissions() async {
    // FlutterBluePlus handles permissions internally
    return true;
  }

  /// Connect to a specific device
  Future<bool> connectDevice(String deviceAddress) async {
    try {
      // Find the device
      final devices = await blue_plus.FlutterBluePlus.connectedDevices;
      blue_plus.BluetoothDevice? device;
      try {
        device = devices.firstWhere((d) => d.remoteId.str == deviceAddress);
      } catch (e) {
        device = null;
      }
      
      if (device == null) {
        // Scan for it
        await blue_plus.FlutterBluePlus.startScan(timeout: const Duration(seconds: 10));
        bool found = false;
        
        await for (final results in blue_plus.FlutterBluePlus.scanResults) {
          for (final result in results) {
            if (result.device.remoteId.str == deviceAddress) {
              device = result.device;
              found = true;
              break;
            }
          }
          if (found) break;
        }
        
        await blue_plus.FlutterBluePlus.stopScan();
        
        if (device == null) return false;
      }

      // Connect to the device
      await device.connect(timeout: const Duration(seconds: 15));
      _connectedDevice = device;
      _isConnected = true;

      // Discover services
      final services = await device.discoverServices();
      
      // Look for Blood Pressure service (0x1810)
      for (final service in services) {
        if (service.uuid.str.toUpperCase().contains('1810')) {
          // Found BP service, read characteristics
          _setupBpListener(service);
          break;
        }
      }

      return true;
    } catch (e) {
      print('Error connecting to device: $e');
      _isConnected = false;
      return false;
    }
  }

  void _setupBpListener(blue_plus.BluetoothService service) {
    // Subscribe to BP measurement characteristic (0x2A35)
    for (final characteristic in service.characteristics) {
      if (characteristic.uuid.str.toUpperCase().contains('2A35')) {
        characteristic.setNotifyValue(true);
        
        characteristic.lastValueStream.listen((value) {
          if (value.isNotEmpty) {
            // Parse BP reading from bytes
            final reading = _parseBpReading(value);
            if (reading != null) {
              _bpStreamController.add(reading);
            }
          }
        });
        
        break;
      }
    }
  }

  BloodPressureReading? _parseBpReading(List<int> bytes) {
    if (bytes.length < 10) return null;
    
    // Parse iHealth BP reading format
    // Format: [flags, systolic_low, systolic_high, diastolic_low, diastolic_high, ...]
    try {
      final systolic = (bytes[2] << 8) | bytes[1];
      final diastolic = (bytes[4] << 8) | bytes[3];
      
      return BloodPressureReading(
        systolic: systolic,
        diastolic: diastolic,
        heartRate: 0, // May not be in this characteristic
      );
    } catch (e) {
      print('Error parsing BP reading: $e');
      return null;
    }
  }

  Future<void> disconnect() async {
    try {
      if (_connectedDevice != null) {
        await _connectedDevice!.disconnect();
      }
      _connectedDevice = null;
      _isConnected = false;
    } catch (e) {
      print('Error disconnecting: $e');
    }
  }

  void dispose() {
    _bpStreamController.close();
    _scanSubscription?.cancel();
    disconnect();
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

/// Bluetooth device model
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

