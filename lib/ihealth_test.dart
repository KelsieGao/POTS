import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

class IHealthTestPage extends StatefulWidget {
  const IHealthTestPage({super.key});

  @override
  State<IHealthTestPage> createState() => _IHealthTestPageState();
}

class _IHealthTestPageState extends State<IHealthTestPage> {
  static const platform = MethodChannel('com.kelsie.potsive/ihealth');
  static const events = EventChannel('com.kelsie.potsive/ihealth/events');
  
  String _status = 'Waiting...';
  bool _isInitialized = false;
  bool _isLoading = false;
  bool _isScanning = false;
  String? _connectedAddress;
  List<Map<String, dynamic>> _devices = const [];
  Map<String, dynamic>? _lastReading;
  StreamSubscription? _eventSub;
  bool _useSdk = true;
  String? _selectedMac;

  @override
  void initState() {
    super.initState();
    _initIHealth();
    _eventSub = events.receiveBroadcastStream().listen((event) {
      if (event is Map) {
        final reading = event.map((k, v) => MapEntry(k.toString(), v));
        if (reading['event'] == 'scan') {
          final mac = reading['mac']?.toString();
          final rssi = reading['rssi'] as int?;
          if (mac != null) {
            final name = reading['deviceType']?.toString() ?? 'KN-550BT';
            final device = {
              'name': name,
              'address': mac,
              'rssi': rssi ?? 0,
            };
            setState(() {
              final list = [..._devices];
              final idx = list.indexWhere((d) => d['address'] == mac);
              if (idx >= 0) list[idx] = device; else list.add(device);
              list.sort((a, b) => (b['rssi'] as int).compareTo(a['rssi'] as int));
              _devices = list;
            });
          }
        } else if (reading['event'] == 'bpOfflineData') {
          // Show the last record quickly
          final recs = reading['records'];
          if (recs is List && recs.isNotEmpty) {
            final last = Map<String, dynamic>.from(recs.last as Map);
            setState(() {
              _lastReading = last;
              _status = 'BP: ${last['systolic']}/${last['diastolic']}  HR: ${last['heartRate']}';
            });
          }
        } else if (reading.containsKey('systolic') && reading.containsKey('diastolic')) {
          setState(() {
            _lastReading = Map<String, dynamic>.from(reading);
            _status = 'BP: ${reading['systolic']}/${reading['diastolic']}'
                '${reading['heartRate'] != null ? '  HR ${reading['heartRate']}' : ''}';
          });
        }
      }
    }, onError: (_) {});
  }

  @override
  void dispose() {
    _eventSub?.cancel();
    super.dispose();
  }

  Future<void> _initIHealth() async {
    setState(() {
      _isLoading = true;
      _status = 'Initializing iHealth SDK...';
    });

    try {
      final bool result = await platform.invokeMethod('initIHealth');
      setState(() {
        _isInitialized = result;
        _status = result 
            ? 'SDK initialized successfully' 
            : 'SDK initialization failed';
        _isLoading = false;
      });
    } on PlatformException catch (e) {
      setState(() {
        _status = 'Error: ${e.message}';
        _isInitialized = false;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _status = 'Unknown error: $e';
        _isInitialized = false;
        _isLoading = false;
      });
    }
  }

  Future<bool> _ensurePermissions() async {
    final scan = await Permission.bluetoothScan.request();
    final connect = await Permission.bluetoothConnect.request();
    final loc = await Permission.location.request();
    return scan.isGranted && connect.isGranted && loc.isGranted;
  }

  Future<void> _scanDevices() async {
    if (_isScanning) return;
    final ok = await _ensurePermissions();
    if (!ok) {
      setState(() => _status = 'Bluetooth permissions denied');
      return;
    }
    setState(() {
      _isScanning = true;
      _status = _useSdk ? 'Scanning via SDK...' : 'Scanning for BLE devices...';
    });
    try {
      if (_useSdk) {
        _devices = const [];
        await platform.invokeMethod('sdkStartDiscovery');
        await Future.delayed(const Duration(seconds: 6));
        await platform.invokeMethod('sdkStopDiscovery');
        setState(() {
          _status = 'Found ${_devices.length} device(s)';
        });
      } else {
        final List<dynamic> list = await platform.invokeMethod('scanBleOnce');
        final devices = list
            .whereType<Map>()
            .map((e) => e.map((k, v) => MapEntry(k.toString(), v)))
            .cast<Map<String, dynamic>>()
            .toList()
          ..sort((a, b) => (b['rssi'] as int?)?.compareTo(a['rssi'] as int? ?? 0) ?? 0);
        setState(() {
          _devices = devices;
          _status = 'Found ${devices.length} device(s)';
        });
      }
    } on PlatformException catch (e) {
      setState(() => _status = 'Scan error: ${e.code} ${e.message}');
    } catch (e) {
      setState(() => _status = 'Scan error: $e');
    } finally {
      setState(() => _isScanning = false);
    }
  }

  Future<void> _connect(String address) async {
    setState(() {
      _status = 'Connecting to $address...';
    });
    try {
      bool ok = false;
      if (_useSdk) {
        await platform.invokeMethod('sdkConnect', {'mac': address});
        ok = true;
        _selectedMac = address;
      } else {
        ok = await platform.invokeMethod('connectToDevice', {'address': address});
      }
      setState(() {
        _connectedAddress = ok ? address : null;
        _status = ok ? 'Connected to $address' : 'Failed to connect to $address';
      });
    } on PlatformException catch (e) {
      setState(() => _status = 'Connect error: ${e.code} ${e.message}');
    } catch (e) {
      setState(() => _status = 'Connect error: $e');
    }
  }

  Future<void> _disconnect() async {
    try {
      if (_useSdk && _connectedAddress != null) {
        await platform.invokeMethod('sdkDisconnect', {'mac': _connectedAddress});
      } else {
        await platform.invokeMethod('disconnectDevice');
      }
      setState(() {
        _connectedAddress = null;
        _status = 'Disconnected';
      });
    } catch (_) {}
  }

  Future<void> _getOfflineNum() async {
    if (!_useSdk || _connectedAddress == null) return;
    try { await platform.invokeMethod('sdkGetOfflineNum', {'mac': _connectedAddress}); } catch (_) {}
  }

  Future<void> _getOfflineData() async {
    if (!_useSdk || _connectedAddress == null) return;
    try { await platform.invokeMethod('sdkGetOfflineData', {'mac': _connectedAddress}); } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('iHealth SDK Test'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _isInitialized ? Icons.check_circle : Icons.error,
                          color: _isInitialized ? Colors.green : Colors.red,
                          size: 32,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _isInitialized ? 'SDK Ready' : 'SDK Error',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          _isLoading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const SizedBox(width: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _status,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _initIHealth,
                    icon: const Icon(Icons.vpn_key),
                    label: const Text('Auth SDK'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isScanning ? null : _scanDevices,
                    icon: const Icon(Icons.bluetooth_searching),
                    label: Text(_isScanning ? 'Scanning...' : (_useSdk ? 'SDK Scan' : 'BLE Scan')),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_connectedAddress != null && _useSdk)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _getOfflineNum,
                      label: const Text('Get Count'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _getOfflineData,
                      icon: const Icon(Icons.download),
                      label: const Text('Get Data'),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
              },
              icon: const Icon(Icons.arrow_back),
              label: const Text('Back to Home'),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _devices.isEmpty
                  ? Center(
                      child: Text(
                        _isScanning ? 'Scanning...' : 'No devices found yet',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    )
                  : ListView.separated(
                      itemCount: _devices.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final d = _devices[index];
                        final name = d['name']?.toString() ?? 'Unknown';
                        final address = d['address']?.toString() ?? '';
                        final rssi = d['rssi']?.toString() ?? '';
                        final connected = _connectedAddress == address;
                        return ListTile(
                          leading: Icon(
                            connected ? Icons.bluetooth_connected : Icons.bluetooth,
                            color: connected ? Colors.green : null,
                          ),
                          title: Text(name),
                          subtitle: Text('$address  ·  RSSI $rssi'),
                          trailing: connected
                              ? TextButton(
                                  onPressed: _disconnect,
                                  child: const Text('Disconnect'),
                                )
                              : TextButton(
                                  onPressed: () => _connect(address),
                                  child: const Text('Connect'),
                                ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 12),
            if (_lastReading != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    'Last Reading: ${_lastReading!['systolic']}/${_lastReading!['diastolic']} mmHg'
                    '${_lastReading!['heartRate'] != null ? '  •  HR ${_lastReading!['heartRate']} bpm' : ''}',
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
