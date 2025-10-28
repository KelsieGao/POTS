import 'package:flutter/material.dart';
import 'package:pots/shared/ihealth_kn550_service.dart';
// import 'package:pots/features/ihealth/ihealth_bp_controller.dart'; // TODO: Re-implement with native SDK
// import 'package:pots/features/ihealth/ihealth_connection_sheet.dart'; // TODO: Re-implement with native SDK

class AutomatedBpInput extends StatefulWidget {
  const AutomatedBpInput({
    super.key,
    required this.title,
    required this.instruction,
    required this.onSubmit,
    required this.latestHr,
    // this.ihealthBpController, // TODO: Re-implement with native SDK
    this.autoSubmitDelay = const Duration(seconds: 2),
  });

  final String title;
  final String instruction;
  final void Function(int systolic, int diastolic) onSubmit;
  final int? latestHr;
  // final IHealthBpController? ihealthBpController; // TODO: Re-implement with native SDK
  final Duration autoSubmitDelay;

  @override
  State<AutomatedBpInput> createState() => _AutomatedBpInputState();
}

class _AutomatedBpInputState extends State<AutomatedBpInput> {
  final _systolicController = TextEditingController();
  final _diastolicController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isAutoSubmitting = false;
  bool _hasAutoSubmitted = false;
  bool _isFetchingFromDevice = false;
  
  @override
  void initState() {
    super.initState();
    _systolicController.addListener(_onTextChanged);
    _diastolicController.addListener(_onTextChanged);
    // TODO: Re-implement with native SDK
    /*
    if (widget.ihealthBpController != null) {
      widget.ihealthBpController!.addListener(_handleBpUpdate);
    }
    */
  }
  
  @override
  void dispose() {
    _systolicController.removeListener(_onTextChanged);
    _diastolicController.removeListener(_onTextChanged);
    _systolicController.dispose();
    _diastolicController.dispose();
    // widget.ihealthBpController?.removeListener(_handleBpUpdate); // TODO: Re-implement with native SDK
    super.dispose();
  }
  
  void _onTextChanged() {
    setState(() {
      // Update state to enable/disable button based on text
    });
  }

  void _handleBpUpdate() {
    if (!mounted) return;
    
    // TODO: Re-implement with native SDK
    /*
    // If using iHealth and we have a NEW reading, update and submit
    if (widget.ihealthBpController != null && 
        widget.ihealthBpController!.hasLatestReading &&
        !_hasAutoSubmitted) {
      final systolic = widget.ihealthBpController!.latestSystolic;
      final diastolic = widget.ihealthBpController!.latestDiastolic;
      
      if (systolic != null && diastolic != null) {
        setState(() {
          _systolicController.text = systolic.toString();
          _diastolicController.text = diastolic.toString();
        });
        
        // Auto-submit when we get a device reading
        _autoSubmitDeviceReading();
        _hasAutoSubmitted = true;
      }
    }
    */
    
    if (mounted) {
      setState(() {});
    }
  }

  void _autoSubmitDeviceReading() {
    if (_isAutoSubmitting) return;
    
    final systolic = _systolicController.text.trim();
    final diastolic = _diastolicController.text.trim();
    
    if (systolic.isNotEmpty && diastolic.isNotEmpty) {
      // Validate the inputs
      if (_validateInt(systolic) == null && _validateInt(diastolic) == null) {
        setState(() {
          _isAutoSubmitting = true;
        });
        
        // Auto-submit after delay when reading comes from device
        Future.delayed(widget.autoSubmitDelay, () {
          if (mounted && _isAutoSubmitting) {
            widget.onSubmit(int.parse(systolic), int.parse(diastolic));
          }
        });
      }
    }
  }

  void _checkAndAutoSubmit() {
    if (_isAutoSubmitting) return;
    
    final systolic = _systolicController.text.trim();
    final diastolic = _diastolicController.text.trim();
    
    if (systolic.isNotEmpty && diastolic.isNotEmpty) {
      // Validate the inputs
      if (_validateInt(systolic) == null && _validateInt(diastolic) == null) {
        setState(() {
          _isAutoSubmitting = true;
        });
        
        // Auto-submit after delay
        Future.delayed(widget.autoSubmitDelay, () {
          if (mounted) {
            widget.onSubmit(int.parse(systolic), int.parse(diastolic));
          }
        });
      }
    }
  }

  // Removed auto-submit functionality - now requires manual button press

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.title,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 12),
          Text(
            widget.instruction,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 24),
          
          // iHealth Device Status (disabled - use manual entry)
          // if (widget.ihealthBpController != null) _buildIHealthStatus(context),
          
          const SizedBox(height: 8),
          
          // BP Input Fields
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _systolicController,
                  decoration: const InputDecoration(
                    labelText: 'Systolic (mmHg)',
                    border: OutlineInputBorder(),
                    suffixText: 'mmHg',
                  ),
                  keyboardType: TextInputType.number,
                  validator: _validateInt,
                  textInputAction: TextInputAction.next,
                  onEditingComplete: () {
                    FocusScope.of(context).nextFocus();
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _diastolicController,
                  decoration: const InputDecoration(
                    labelText: 'Diastolic (mmHg)',
                    border: OutlineInputBorder(),
                    suffixText: 'mmHg',
                  ),
                  keyboardType: TextInputType.number,
                  validator: _validateInt,
                  textInputAction: TextInputAction.done,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Heart Rate Display
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.favorite, color: Colors.red),
                const SizedBox(width: 8),
                Text(
                  'Heart Rate: ${widget.latestHr != null ? '${widget.latestHr} bpm' : 'Monitoring...'}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          
          const Spacer(),
          
          // Status Display
          _buildStatusDisplay(context),
          
          const SizedBox(height: 16),
          
          // Submit / Fetch from device
          FilledButton(
            onPressed: _isFetchingFromDevice
                ? null
                : () async {
                    if (!mounted) return;
                    setState(() => _isFetchingFromDevice = true);
                    try {
                      final svc = IHealthKn550Service.instance;
                      final latest = await svc.fetchLatest(totalTimeout: const Duration(seconds: 8));
                      if (latest != null) {
                        _systolicController.text = latest.systolic.toString();
                        _diastolicController.text = latest.diastolic.toString();
                      }
                    } catch (_) {}
                    finally {
                      if (!mounted) return;
                      setState(() => _isFetchingFromDevice = false);
                    }

                    if (_formKey.currentState?.validate() ?? false) {
                      final systolic = _systolicController.text.trim();
                      final diastolic = _diastolicController.text.trim();
                      widget.onSubmit(int.parse(systolic), int.parse(diastolic));
                    }
                  },
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: Text(_isFetchingFromDevice ? 'Fetching from cuff...' : 'Done'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusDisplay(BuildContext context) {
    final systolic = _systolicController.text.trim();
    final diastolic = _diastolicController.text.trim();
    
    if (systolic.isEmpty && diastolic.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.blue.shade200),
        ),
        child: Row(
          children: [
            const Icon(Icons.bloodtype, color: Colors.blue),
            const SizedBox(width: 8),
            const Text('Please take your blood pressure reading'),
          ],
        ),
      );
    } else if (systolic.isNotEmpty && diastolic.isNotEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.green.shade200),
        ),
        child: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green),
            const SizedBox(width: 8),
            Text('BP: $systolic/$diastolic mmHg - Ready to continue'),
          ],
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.orange.shade200),
        ),
        child: Row(
          children: [
            const Icon(Icons.schedule, color: Colors.orange),
            const SizedBox(width: 8),
            const Text('Please enter both systolic and diastolic values'),
          ],
        ),
      );
    }
  }

  String? _validateInt(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Required';
    }
    final parsed = int.tryParse(value.trim());
    if (parsed == null) {
      return 'Enter a number';
    }
    if (parsed < 50 || parsed > 250) {
      return 'Invalid range';
    }
    return null;
  }

  Widget _buildIHealthStatus(BuildContext context) {
    // TODO: Re-implement with native SDK
    return const SizedBox.shrink();
    /*
    final controller = widget.ihealthBpController!;
    final status = controller.status;
    final isConnected = controller.isConnected;

    Color color;
    IconData icon;
    String text;

    if (isConnected && controller.hasLatestReading) {
      color = Colors.green.shade700;
      icon = Icons.check_circle;
      text = 'iHealth connected - Reading: ${controller.latestSystolic}/${controller.latestDiastolic} mmHg';
    } else if (isConnected) {
      color = Colors.blue.shade700;
      icon = Icons.bluetooth_connected;
      text = 'iHealth connected - Waiting for reading...';
    } else if (status == IHealthBpConnectionStatus.connecting) {
      color = Colors.orange.shade700;
      icon = Icons.bluetooth_searching;
      text = 'Connecting to iHealth device...';
    } else if (controller.errorMessage != null) {
      color = Colors.red.shade700;
      icon = Icons.error;
      text = 'iHealth: ${controller.errorMessage}';
    } else if (status == IHealthBpConnectionStatus.disconnected) {
      color = Colors.grey.shade700;
      icon = Icons.edit;
      text = 'Enter BP readings manually';
    } else {
      color = Colors.blue.shade700;
      icon = Icons.bloodtype;
      text = 'Waiting for BP reading...';
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
        ],
      ),
    );
    */
  }
}
