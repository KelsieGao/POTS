import 'dart:async';
import 'package:ihealth_hr/ihealth_hr.dart';
import 'package:permission_handler/permission_handler.dart';

/// Service to handle iHealth KN-550BT Blood Pressure Monitor integration
class IHealthService {
  static final IHealthService _instance = IHealthService._internal();
  factory IHealthService() => _instance;
  IHealthService._internal();

  // ihealth_hr package uses static methods
  
  // Stream controllers for BP data
  final _bpStreamController = StreamController<BloodPressureReading>.broadcast();
  Stream<BloodPressureReading> get bpStream => _bpStreamController.stream;

  bool _isConnected = false;
  bool get isConnected => _isConnected;

  /// Initialize the iHealth SDK
  Future<void> initialize() async {
    try {
      // Initialize the plugin
      // Note: ihealth_hr may not need explicit initialization
    } catch (e) {
      print('Error initializing iHealth SDK: $e');
    }
  }

  /// Request necessary permissions for Bluetooth scanning
  Future<bool> requestPermissions() async {
    try {
      // Request Bluetooth and Location permissions
      final bluetoothScan = await Permission.bluetoothScan.request();
      final bluetoothConnect = await Permission.bluetoothConnect.request();
      final location = await Permission.location.request();
      
      return bluetoothScan.isGranted && 
             bluetoothConnect.isGranted && 
             location.isGranted;
    } catch (e) {
      print('Error requesting permissions: $e');
      return false;
    }
  }

  StreamSubscription? _deviceStreamSubscription;
  final _discoveredDevices = <BluetoothDevice>[];

  /// Scan for iHealth KN-550BT devices
  Future<List<BluetoothDevice>> scanForDevices() async {
    try {
      // Request permissions first
      final hasPermissions = await requestPermissions();
      if (!hasPermissions) {
        throw Exception('Bluetooth and Location permissions are required');
      }
      
      // Clear previous results
      _discoveredDevices.clear();
      
      // Cancel existing stream subscription
      await _deviceStreamSubscription?.cancel();
      
      // Listen to device stream to collect discovered devices
      _deviceStreamSubscription = IhealthHrPlugin.deviceStatusStream.listen((event) {
        print('Device event received: $event');
        
        if (event is Map) {
          // Parse device discovery events
          // The actual format needs to be verified with the device
          final deviceName = event['name']?.toString() ?? 'Unknown';
          final deviceAddress = event['address']?.toString() ?? '';
          
          if (deviceAddress.isNotEmpty) {
            final device = BluetoothDevice(
              name: deviceName,
              address: deviceAddress,
              rssi: (event['rssi'] as int?) ?? 0,
            );
            // Add to discovered devices if not already present
            if (!_discoveredDevices.any((d) => d.address == deviceAddress)) {
              _discoveredDevices.add(device);
            }
          }
        }
      });
      
      // Start scanning using the package's static method
      await IhealthHrPlugin.startScan();
      
      // Wait a bit for devices to be discovered
      await Future.delayed(const Duration(seconds: 5));
      
      // Stop scanning
      await IhealthHrPlugin.stopScan();
      
      // Cancel stream subscription
      await _deviceStreamSubscription?.cancel();
      _deviceStreamSubscription = null;
      
      return List.from(_discoveredDevices);
    } catch (e) {
      print('Error scanning for devices: $e');
      await _deviceStreamSubscription?.cancel();
      _deviceStreamSubscription = null;
      return [];
    }
  }

  /// Connect to a specific device
  Future<bool> connectDevice(String deviceAddress) async {
    try {
      // Note: The package API needs to be verified with actual device testing
      // This is a placeholder implementation
      _isConnected = true;
      
      // Setup listener for BP readings from the device
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
    // Listen for blood pressure readings from device stream
    // Note: This needs to be tested with actual device to confirm event format
    IhealthHrPlugin.deviceStatusStream.listen((event) {
      if (event is Map) {
        // Parse device event data
        // Adjust based on actual event format
        final reading = BloodPressureReading(
          systolic: event['systolic'] ?? 0,
          diastolic: event['diastolic'] ?? 0,
          heartRate: event['heartRate'] ?? 0,
        );
        _bpStreamController.add(reading);
      }
    });
  }

  /// Disconnect from the device
  Future<void> disconnect() async {
    try {
      await IhealthHrPlugin.stopScan();
      _isConnected = false;
    } catch (e) {
      print('Error disconnecting: $e');
    }
  }

  /// Get device battery level
  Future<int?> getBatteryLevel() async {
    try {
      // Note: Battery level method needs to be added to the package
      return null;
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
