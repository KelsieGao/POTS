import 'package:flutter/material.dart';
import 'package:pots/features/standup_test/models/safety_acknowledgment.dart';
import 'package:pots/features/standup_test/services/safety_service.dart';
import 'package:uuid/uuid.dart';

class SafetyAcknowledgmentPage extends StatefulWidget {
  const SafetyAcknowledgmentPage({
    super.key,
    required this.patientId,
    this.testId,
    this.onCompleted,
  });

  final String patientId;
  final String? testId;
  final VoidCallback? onCompleted;

  @override
  State<SafetyAcknowledgmentPage> createState() => _SafetyAcknowledgmentPageState();
}

class _SafetyAcknowledgmentPageState extends State<SafetyAcknowledgmentPage> {
  final _formKey = GlobalKey<FormState>();
  final _emergencyNameController = TextEditingController();
  final _emergencyPhoneController = TextEditingController();
  final _medicalConditionsController = TextEditingController();
  final _medicationsController = TextEditingController();

  bool _riskAcknowledged = false;
  bool _liabilityAcknowledged = false;
  bool _safetyWarningsRead = false;
  bool _companionRecommended = false;
  bool _emergencyContactProvided = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _emergencyNameController.dispose();
    _emergencyPhoneController.dispose();
    _medicalConditionsController.dispose();
    _medicationsController.dispose();
    super.dispose();
  }

  Future<void> _submitAcknowledgment() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_riskAcknowledged || !_liabilityAcknowledged || !_safetyWarningsRead) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please acknowledge all required safety warnings.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final acknowledgment = SafetyAcknowledgment(
        id: const Uuid().v4(),
        patientId: widget.patientId,
        acknowledgedAt: DateTime.now(),
        riskAcknowledged: _riskAcknowledged,
        liabilityAcknowledgment: _liabilityAcknowledged,
        safetyWarningsRead: _safetyWarningsRead,
        companionRecommended: _companionRecommended,
        emergencyContactProvided: _emergencyContactProvided,
        emergencyContactName: _emergencyContactProvided 
            ? _emergencyNameController.text.trim() 
            : null,
        emergencyContactPhone: _emergencyContactProvided 
            ? _emergencyPhoneController.text.trim() 
            : null,
        medicalConditions: _medicalConditionsController.text.trim().isNotEmpty
            ? _medicalConditionsController.text.trim()
            : null,
        medications: _medicationsController.text.trim().isNotEmpty
            ? _medicationsController.text.trim()
            : null,
        testId: widget.testId,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await SafetyService.saveSafetyAcknowledgment(acknowledgment);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Safety acknowledgment saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        widget.onCompleted?.call();
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save acknowledgment: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Safety Acknowledgment'),
        automaticallyImplyLeading: false,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSafetyWarningCard(),
                  const SizedBox(height: 24),
                  _buildRiskAcknowledgment(),
                  const SizedBox(height: 24),
                  _buildLiabilityDisclaimer(),
                  const SizedBox(height: 24),
                  _buildEmergencyContactSection(),
                  const SizedBox(height: 24),
                  _buildMedicalInfoSection(),
                  const SizedBox(height: 32),
                  _buildActionButtons(),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSafetyWarningCard() {
    return Card(
      color: Theme.of(context).colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: Theme.of(context).colorScheme.onErrorContainer,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Important Safety Information',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onErrorContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '• The sit/stand protocol may cause dizziness, lightheadedness, or fainting\n'
              '• Have a companion present if you have a history of fainting\n'
              '• Stop the test immediately if you feel unwell\n'
              '• Ensure you are in a safe environment with no obstacles\n'
              '• Do not perform this test if you are feeling unwell today\n'
              '• Consult your doctor before performing this test if you have heart conditions',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onErrorContainer,
              ),
            ),
            const SizedBox(height: 12),
            CheckboxListTile(
              value: _safetyWarningsRead,
              onChanged: (value) {
                setState(() => _safetyWarningsRead = value ?? false);
              },
              title: Text(
                'I have read and understand the safety warnings',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onErrorContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              activeColor: Theme.of(context).colorScheme.onErrorContainer,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRiskAcknowledgment() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Risk Acknowledgment',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'I understand that participating in this sit/stand protocol test involves certain risks, including but not limited to:\n\n'
              '• Dizziness or lightheadedness\n'
              '• Fainting or loss of consciousness\n'
              '• Falls or injury\n'
              '• Increased heart rate or blood pressure changes\n'
              '• Worsening of existing symptoms\n\n'
              'I acknowledge these risks and choose to participate voluntarily.',
            ),
            const SizedBox(height: 12),
            CheckboxListTile(
              value: _riskAcknowledged,
              onChanged: (value) {
                setState(() => _riskAcknowledged = value ?? false);
              },
              title: const Text(
                'I acknowledge the risks and voluntarily choose to participate',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLiabilityDisclaimer() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Liability Disclaimer',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'By using this application and participating in the sit/stand protocol test, you agree that:\n\n'
              '• This app is for informational and monitoring purposes only\n'
              '• The test results are not a substitute for professional medical advice\n'
              '• You should consult with your healthcare provider before making any medical decisions\n'
              '• The app developers and company are not responsible for any adverse effects\n'
              '• You participate at your own risk and assume full responsibility for your safety\n\n'
              'The company and its developers are hereby released from any liability arising from your use of this application.',
            ),
            const SizedBox(height: 12),
            CheckboxListTile(
              value: _liabilityAcknowledged,
              onChanged: (value) {
                setState(() => _liabilityAcknowledged = value ?? false);
              },
              title: const Text(
                'I understand and accept the liability disclaimer',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencyContactSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Emergency Contact (Recommended)',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'We recommend having an emergency contact available during the test.',
            ),
            const SizedBox(height: 12),
            CheckboxListTile(
              value: _emergencyContactProvided,
              onChanged: (value) {
                setState(() => _emergencyContactProvided = value ?? false);
              },
              title: const Text(
                'I will have an emergency contact available',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
            if (_emergencyContactProvided) ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: _emergencyNameController,
                decoration: const InputDecoration(
                  labelText: 'Emergency Contact Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (_emergencyContactProvided && 
                      (value == null || value.trim().isEmpty)) {
                    return 'Please provide emergency contact name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emergencyPhoneController,
                decoration: const InputDecoration(
                  labelText: 'Emergency Contact Phone',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (_emergencyContactProvided && 
                      (value == null || value.trim().isEmpty)) {
                    return 'Please provide emergency contact phone';
                  }
                  return null;
                },
              ),
            ],
            const SizedBox(height: 12),
            CheckboxListTile(
              value: _companionRecommended,
              onChanged: (value) {
                setState(() => _companionRecommended = value ?? false);
              },
              title: const Text(
                'I have a companion present during the test',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicalInfoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Medical Information (Optional)',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Please provide any relevant medical conditions or medications that may affect your test results.',
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _medicalConditionsController,
              decoration: const InputDecoration(
                labelText: 'Medical Conditions (Optional)',
                hintText: 'e.g., Heart condition, diabetes, etc.',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _medicationsController,
              decoration: const InputDecoration(
                labelText: 'Current Medications (Optional)',
                hintText: 'e.g., Blood pressure medication, beta blockers, etc.',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton(
          onPressed: _isLoading ? null : _submitAcknowledgment,
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: _isLoading
              ? const CircularProgressIndicator(color: Colors.white)
              : const Text('Acknowledge and Continue'),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}
