import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/supabase_service.dart';
import '../../core/services/auth_service.dart';
import '../patient_signup/local/patient_storage.dart';
import '../voss_questionnaire/voss_questionnaire_page.dart';

class PatientProfileCompletionPage extends StatefulWidget {
  const PatientProfileCompletionPage({super.key});

  @override
  State<PatientProfileCompletionPage> createState() => _PatientProfileCompletionPageState();
}

class _PatientProfileCompletionPageState extends State<PatientProfileCompletionPage> {
  final _formKey = GlobalKey<FormState>();
  
  final _phoneController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _physicianController = TextEditingController();
  final _clinicianCodeController = TextEditingController();
  
  DateTime _dateOfBirth = DateTime(1990, 1, 1);
  String? _selectedSex;
  String? _selectedReason;
  
  bool _isLoading = false;
  String? _errorMessage;
  
  @override
  void dispose() {
    _phoneController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _physicianController.dispose();
    _clinicianCodeController.dispose();
    super.dispose();
  }
  
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    if (_selectedSex == null || _selectedReason == null) {
      setState(() {
        _errorMessage = 'Please complete all required fields';
      });
      return;
    }
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final userId = AuthService.currentUser?.id;
      if (userId == null) {
        throw Exception('User not logged in');
      }
      
      // Update patient profile
      final client = SupabaseService.client;
      final now = DateTime.now().toIso8601String();
      
      // Check if patient exists first
      final existing = await client
          .from('patients')
          .select()
          .eq('id', userId)
          .maybeSingle();
      
      if (existing == null) {
        throw Exception('Patient profile not found. Please contact support.');
      }
      
      await client.from('patients').update({
        'date_of_birth': _dateOfBirth.toIso8601String(),
        'phone': _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        'height_cm': _heightController.text.trim().isEmpty ? null : int.tryParse(_heightController.text.trim()),
        'weight_kg': _weightController.text.trim().isEmpty ? null : double.tryParse(_weightController.text.trim()),
        'primary_care_physician': _physicianController.text.trim().isEmpty ? null : _physicianController.text.trim(),
        'sex_assigned_at_birth': _selectedSex!,
        'reason_for_using_app': _selectedReason!,
        'updated_at': now,
      }).eq('id', userId);
      
      // Link to clinician if code is provided
      final clinicianCode = _clinicianCodeController.text.trim();
      if (clinicianCode.isNotEmpty) {
        try {
          // Check if the code exists
          final codeExists = await client
              .from('physician_codes')
              .select()
              .eq('code', clinicianCode)
              .eq('is_active', true)
              .maybeSingle();
          
          if (codeExists != null) {
            // Create the link
            await client.from('physician_patient_links').insert({
              'physician_code': clinicianCode,
              'patient_id': userId,
              'status': 'active',
            });
          } else {
            // Code doesn't exist - show warning but continue
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Clinician code not found. Profile saved without clinician link.'),
                  backgroundColor: Colors.orange,
                ),
              );
            }
          }
        } catch (e) {
          // Ignore linkage errors - profile is still saved
          print('Error linking to clinician: $e');
        }
      }
      
      // Save patient ID for later use
      final storage = await PatientStorage.create();
      await storage.savePatientId(userId);
      
      if (mounted) {
        // Navigate to VOSS questionnaire instead of home
        await Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => VossQuestionnairePage(patientId: userId),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Complete Your Profile'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF20B2AA),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Almost Done!',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Complete your profile to get started',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 32),
              // Date of Birth
              InkWell(
                onTap: () async {
                  final selected = await showDatePicker(
                    context: context,
                    initialDate: _dateOfBirth,
                    firstDate: DateTime(1900),
                    lastDate: DateTime.now(),
                  );
                  if (selected != null) {
                    setState(() {
                      _dateOfBirth = selected;
                    });
                  }
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Date of Birth *',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(DateFormat('yyyy-MM-dd').format(_dateOfBirth)),
                      const Icon(Icons.calendar_today),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Phone
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Phone Number (optional)',
                  prefixIcon: const Icon(Icons.phone),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Height and Weight
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _heightController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Height (cm, optional)',
                        prefixIcon: const Icon(Icons.height),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _weightController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Weight (kg, optional)',
                        prefixIcon: const Icon(Icons.monitor_weight),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Primary Care Physician
              TextFormField(
                controller: _physicianController,
                decoration: InputDecoration(
                  labelText: 'Primary Care Physician (optional)',
                  prefixIcon: const Icon(Icons.medical_services),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Clinician Code
              TextFormField(
                controller: _clinicianCodeController,
                decoration: InputDecoration(
                  labelText: 'Clinician Code (optional)',
                  hintText: 'Enter 6-digit code from your clinician',
                  prefixIcon: const Icon(Icons.vpn_key),
                  helperText: 'If your clinician gave you a code, enter it here to link your account.',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                maxLength: 6,
                buildCounter: (context, {required currentLength, required isFocused, maxLength}) {
                  return null; // Hide counter
                },
              ),
              const SizedBox(height: 16),
              // Sex assigned at birth dropdown
              DropdownButtonFormField<String>(
                value: _selectedSex,
                decoration: InputDecoration(
                  labelText: 'Sex assigned at birth *',
                  prefixIcon: const Icon(Icons.person),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: ['Male', 'Female', 'Other', 'Prefer not to say']
                    .map((value) => DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        ))
                    .toList(),
                validator: (value) {
                  if (value == null) {
                    return 'Please select sex assigned at birth';
                  }
                  return null;
                },
                onChanged: (value) {
                  setState(() {
                    _selectedSex = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              // Reason for using app dropdown
              DropdownButtonFormField<String>(
                value: _selectedReason,
                decoration: InputDecoration(
                  labelText: 'Why are you using this app? *',
                  prefixIcon: const Icon(Icons.info),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: ['Doctor referral', 'I suspect I have POTS', 'Other']
                    .map((value) => DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        ))
                    .toList(),
                validator: (value) {
                  if (value == null) {
                    return 'Please select a reason';
                  }
                  return null;
                },
                onChanged: (value) {
                  setState(() {
                    _selectedReason = value;
                  });
                },
              ),
              const SizedBox(height: 24),
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red[300]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red[700]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: Colors.red[700]),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF20B2AA),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text(
                        'Complete Profile',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

