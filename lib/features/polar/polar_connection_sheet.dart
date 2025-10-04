import 'dart:async';

import 'package:flutter/material.dart';
import 'package:polar/polar.dart';

import 'polar_heart_rate_controller.dart';

class PolarConnectionSheet extends StatefulWidget {
  const PolarConnectionSheet({super.key, required this.controller});

  final PolarHeartRateController controller;

  @override
  State<PolarConnectionSheet> createState() => _PolarConnectionSheetState();
}

class _PolarConnectionSheetState extends State<PolarConnectionSheet> {
  bool _dismissed = false;

  PolarHeartRateController get _controller => widget.controller;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_handleControllerUpdate);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_controller.isScanning) {
        unawaited(_controller.startScan());
      }
    });
  }

  void _handleControllerUpdate() {
    if (!mounted) {
      return;
    }
    setState(() {});

    final status = _controller.status;
    if (!_dismissed &&
        (status == PolarConnectionStatus.connected ||
            status == PolarConnectionStatus.streaming)) {
      _dismissed = true;
      Navigator.of(context).maybePop(true);
    }
  }

  Future<void> _toggleScan() async {
    if (_controller.isScanning) {
      await _controller.stopScan();
    } else {
      await _controller.startScan();
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_handleControllerUpdate);
    unawaited(_controller.stopScan());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusLabel = _controller.status.label;
    final devices = _controller.discoveredDevices;
    final isScanning = _controller.isScanning;
    final error = _controller.errorMessage;

    final bottomPadding = MediaQuery.of(context).viewPadding.bottom;
    final sheetHeight = (MediaQuery.of(context).size.height * 0.7).clamp(
      320.0,
      560.0,
    );

    return SafeArea(
      child: SizedBox(
        height: sheetHeight,
        child: Padding(
          padding: EdgeInsets.fromLTRB(24, 16, 24, 16 + bottomPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 48,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.dividerColor,
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('Connect Polar Device', style: theme.textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(
                'Scan for nearby sensors and tap one to connect. The last connected device reconnects automatically.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Chip(label: Text('Status: $statusLabel')),
                  if (_controller.deviceId != null)
                    Chip(label: Text('Device: ${_controller.deviceId}')),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  FilledButton.icon(
                    onPressed: _toggleScan,
                    icon: Icon(isScanning ? Icons.stop : Icons.search),
                    label: Text(isScanning ? 'Stop Scan' : 'Scan for Devices'),
                  ),
                  const SizedBox(width: 12),
                  if (isScanning) const _ScanningIndicator(),
                ],
              ),
              if (error != null) ...[
                const SizedBox(height: 12),
                _ErrorBanner(message: error),
              ],
              const SizedBox(height: 16),
              Expanded(
                child: devices.isEmpty
                    ? const _EmptyDiscoveryState()
                    : ListView.separated(
                        itemCount: devices.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final device = devices[index];
                          return _DiscoveredDeviceTile(
                            device: device,
                            isActive: _isDeviceActive(device),
                            status: _controller.status,
                            onTap: () => _controller.connectToDevice(device),
                          );
                        },
                      ),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.center,
                child: TextButton(
                  onPressed: () => Navigator.of(context).maybePop(false),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _isDeviceActive(PolarDeviceInfo device) {
    final current = _controller.deviceId;
    if (current == null) {
      return false;
    }
    return current.toUpperCase() == device.deviceId.toUpperCase();
  }
}

class _DiscoveredDeviceTile extends StatelessWidget {
  const _DiscoveredDeviceTile({
    required this.device,
    required this.isActive,
    required this.status,
    required this.onTap,
  });

  final PolarDeviceInfo device;
  final bool isActive;
  final PolarConnectionStatus status;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isStreaming = status == PolarConnectionStatus.streaming;

    return ListTile(
      leading: const Icon(Icons.watch),
      title: Text(device.name.isEmpty ? 'Polar Sensor' : device.name),
      subtitle: Text('ID: ${device.deviceId} · ${device.rssi} dBm'),
      trailing: isActive
          ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Icon(
                  isStreaming ? Icons.favorite : Icons.check_circle,
                  color: isStreaming
                      ? theme.colorScheme.error
                      : theme.colorScheme.primary,
                ),
                const SizedBox(height: 4),
                Text(
                  isStreaming ? 'Streaming' : 'Selected',
                  style: theme.textTheme.labelSmall,
                ),
              ],
            )
          : const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

class _ScanningIndicator extends StatelessWidget {
  const _ScanningIndicator();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        SizedBox(width: 8),
        Text('Scanning...'),
      ],
    );
  }
}

class _EmptyDiscoveryState extends StatelessWidget {
  const _EmptyDiscoveryState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.search, size: 48, color: Colors.grey),
          SizedBox(height: 12),
          Text(
            'No devices discovered yet. Move your Polar device nearby and stay on this screen.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        message,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onErrorContainer,
        ),
      ),
    );
  }
}
