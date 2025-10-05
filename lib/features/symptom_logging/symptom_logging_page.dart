import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/symptom_models.dart';
import '../../core/services/symptom_service.dart';

class SymptomLoggingPage extends StatefulWidget {
  final String patientId;
  final List<String> selectedSymptoms;

  const SymptomLoggingPage({
    super.key,
    required this.patientId,
    required this.selectedSymptoms,
  });

  @override
  State<SymptomLoggingPage> createState() => _SymptomLoggingPageState();
}

class _SymptomLoggingPageState extends State<SymptomLoggingPage> {
  double _severity = 5.0;
  final TextEditingController _timeOfDayController = TextEditingController();
  final TextEditingController _activityController = TextEditingController();
  final TextEditingController _detailsController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _timeOfDayController.text = DateFormat('h:mm a').format(DateTime.now());
  }

  @override
  void dispose() {
    _timeOfDayController.dispose();
    _activityController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Log Symptoms',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Selected Symptoms Display
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE0E0E0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Selected Symptoms:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: widget.selectedSymptoms.map((symptomId) {
                      final symptom = PredefinedSymptoms.getSymptomById(symptomId);
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F8F5),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFF20B2AA),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              symptom?.emoji ?? '😷',
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              symptom?.name ?? symptomId,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF20B2AA),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Severity Section
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE0E0E0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Severity (1 = mild, 10 = severe)',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Severity Slider
                  Row(
                    children: [
                      const Text(
                        '1',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF7F8C8D),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Expanded(
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: const Color(0xFF20B2AA),
                            inactiveTrackColor: const Color(0xFFE0E0E0),
                            thumbColor: const Color(0xFF20B2AA),
                            overlayColor: const Color(0xFF20B2AA).withOpacity(0.2),
                            valueIndicatorColor: const Color(0xFF20B2AA),
                            valueIndicatorTextStyle: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          child: Slider(
                            value: _severity,
                            min: 1,
                            max: 10,
                            divisions: 9,
                            label: _severity.round().toString(),
                            onChanged: (value) {
                              setState(() {
                                _severity = value;
                              });
                            },
                          ),
                        ),
                      ),
                      const Text(
                        '10',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF7F8C8D),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  
                  // Current Severity Display
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF20B2AA).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFF20B2AA),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        'Severity: ${_severity.round()}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF20B2AA),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Time of Day
            _buildInputField(
              controller: _timeOfDayController,
              label: 'Time of Day',
              hint: '1:37pm, 11:55am, etc...',
              icon: Icons.access_time,
            ),
            
            const SizedBox(height: 16),
            
            // Activity Type
            _buildInputField(
              controller: _activityController,
              label: 'Activity Type',
              hint: 'e.g., Standing, Walking, Sitting, Exercise...',
              icon: Icons.directions_walk,
            ),
            
            const SizedBox(height: 16),
            
            // Other Details
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE0E0E0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.note_alt_outlined,
                        color: Color(0xFF7F8C8D),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Other Details',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _detailsController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText: 'Any additional details, triggers, or context...',
                      border: OutlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFFE0E0E0)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFF20B2AA)),
                      ),
                      contentPadding: EdgeInsets.all(12),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _logSymptoms,
                    icon: const Icon(Icons.favorite, color: Colors.white),
                    label: const Text(
                      'Log Symptoms',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF27AE60),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _startEpisodeTracking,
                    icon: const Icon(Icons.timer, color: Colors.white),
                    label: const Text(
                      'Start Episode Tracking',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3498DB),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: const Color(0xFF7F8C8D),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2C3E50),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: hint,
              border: const OutlineInputBorder(
                borderSide: BorderSide(color: Color(0xFFE0E0E0)),
              ),
              focusedBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF20B2AA)),
              ),
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _logSymptoms() async {
    if (widget.selectedSymptoms.isEmpty) {
      _showSnackBar('Please select at least one symptom', isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final now = DateTime.now();
      final symptomLog = SymptomLog(
        id: '', // This will be removed before sending to Supabase
        patientId: widget.patientId,
        timestamp: now,
        symptoms: widget.selectedSymptoms,
        severity: _severity.round(),
        timeOfDay: _timeOfDayController.text.trim().isNotEmpty 
            ? _timeOfDayController.text.trim() 
            : null,
        activityType: _activityController.text.trim().isNotEmpty 
            ? _activityController.text.trim() 
            : null,
        otherDetails: _detailsController.text.trim().isNotEmpty 
            ? _detailsController.text.trim() 
            : null,
        createdAt: now,
        updatedAt: now,
      );

      await SymptomService.saveSymptomLog(symptomLog);
      
      _showSnackBar('Symptoms logged successfully!');
      
      // Navigate back to main screen
      Navigator.of(context).popUntil((route) => route.isFirst);
      
    } catch (e) {
      _showSnackBar('Failed to log symptoms: $e', isError: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _startEpisodeTracking() async {
    // For now, just log symptoms and show a message about episode tracking
    await _logSymptoms();
    _showSnackBar('Episode tracking started! Monitor your symptoms over time.');
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
