import 'dart:async';

import 'package:flutter/material.dart';

import 'ihealth_bp_controller.dart';

class IHealthConnectionSheet extends StatefulWidget {
  const IHealthConnectionSheet({super.key, required this.controller});

  final IHealthBpController controller;

  @override
  State<IHealthConnectionSheet> createState() => _IHealthConnectionSheetState();
}

class _IHealthConnectionSheetState extends State<IHealthConnectionSheet> {
  bool _dismissed = false;

  IHealthBpController get _controller => widget.controller;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_handleControllerUpdate);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_controller.isScanning) {
        unawaited(_controller.scanForDevices());
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
        (status == IHealthBpConnectionStatus.connected ||
            status == IHealthBpConnectionStatus.reading)) {
      _dismissed = true;
      Navigator.of(context).maybePop(true);
    }
  }

  Future<void> _toggleScan() async {
    if (_controller.isScanning) {
      await _controller.stopScan();
    } else {
      await _controller.scanForDevices();
    }
  }

  Widget _buildInstruction(String number, String text, ThemeData theme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodyMedium,
          ),
        ),
      ],
    );
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
    final devices = _controller.discoveredDevices;
    final isScanning = _controller.isScanning;
    final errorMessage = _controller.errorMessage;
    final status = _controller.status;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  Icons.bloodtype,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Connect iHealth BP Monitor',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(false),
                ),
              ],
            ),
          ),
          // Setup Instructions
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.primary.withOpacity(0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.help_outline,
                      color: theme.colorScheme.primary,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Setup Instructions',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildInstruction(
                  '1',
                  'Press the M button on your iHealth blood pressure monitor to turn on Bluetooth.',
                  theme,
                ),
                const SizedBox(height: 8),
                _buildInstruction(
                  '2',
                  'Keep the device nearby (within 3 feet) during scanning.',
                  theme,
                ),
                const SizedBox(height: 8),
                _buildInstruction(
                  '3',
                  'Make sure Bluetooth is enabled on your phone.',
                  theme,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (errorMessage != null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error, color: Colors.red.shade700, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        errorMessage,
                        style: TextStyle(color: Colors.red.shade700),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          const Divider(),
          Flexible(
            child: devices.isEmpty && !isScanning
                ? Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.bluetooth_searching,
                          size: 64,
                          color: theme.colorScheme.onSurface.withOpacity(0.38),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No devices found',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Make sure your iHealth device is turned on and in range',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.bluetooth_searching,
                          size: 64,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Scanning for iHealth devices...',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Make sure to press the M button on your device',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _toggleScan,
                    icon: Icon(
                      isScanning ? Icons.stop : Icons.refresh,
                    ),
                    label: Text(isScanning ? 'Stop Scan' : 'Scan Again'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: status == IHealthBpConnectionStatus.reading
                        ? null
                        : () {
                            Navigator.of(context).pop(false);
                          },
                    icon: const Icon(Icons.skip_next),
                    label: const Text('Skip for Now'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
