import 'package:flutter/material.dart';

class AutomatedBpInput extends StatefulWidget {
  const AutomatedBpInput({
    super.key,
    required this.title,
    required this.instruction,
    required this.onSubmit,
    required this.latestHr,
    this.autoSubmitDelay = const Duration(seconds: 2),
  });

  final String title;
  final String instruction;
  final void Function(int systolic, int diastolic) onSubmit;
  final int? latestHr;
  final Duration autoSubmitDelay;

  @override
  State<AutomatedBpInput> createState() => _AutomatedBpInputState();
}

class _AutomatedBpInputState extends State<AutomatedBpInput> {
  final _systolicController = TextEditingController();
  final _diastolicController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isAutoSubmitting = false;

  @override
  void dispose() {
    _systolicController.dispose();
    _diastolicController.dispose();
    super.dispose();
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
                  onChanged: (_) => _checkAndAutoSubmit(),
                  validator: _validateInt,
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
                  onChanged: (_) => _checkAndAutoSubmit(),
                  validator: _validateInt,
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
          
          // Manual Submit Button (as backup)
          if (_isAutoSubmitting)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.timer, color: Colors.green),
                  const SizedBox(width: 8),
                  const Text('Auto-submitting in a moment...'),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      final systolic = _systolicController.text.trim();
                      final diastolic = _diastolicController.text.trim();
                      if (_formKey.currentState?.validate() ?? false) {
                        widget.onSubmit(int.parse(systolic), int.parse(diastolic));
                      }
                    },
                    child: const Text('Submit Now'),
                  ),
                ],
              ),
            )
          else if (_systolicController.text.isNotEmpty && _diastolicController.text.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green),
                  const SizedBox(width: 8),
                  const Text('Ready - will auto-continue shortly'),
                  const Spacer(),
                  FilledButton(
                    onPressed: () {
                      final systolic = _systolicController.text.trim();
                      final diastolic = _diastolicController.text.trim();
                      if (_formKey.currentState?.validate() ?? false) {
                        widget.onSubmit(int.parse(systolic), int.parse(diastolic));
                      }
                    },
                    child: const Text('Submit Now'),
                  ),
                ],
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline),
                  SizedBox(width: 8),
                  Text('Enter both values to continue automatically'),
                ],
              ),
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
}
