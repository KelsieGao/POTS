import '../../core/services/clinician_service.dart';

Future<void> seedTestClinician() async {
  try {
    final clinician = await ClinicianService.createClinician(
      code: 'TEST123',
      name: 'Dr. Test Clinician',
      email: 'test.clinician@example.com',
    );

    print('Test clinician created successfully!');
    print('Clinician Code: ${clinician.clinicianCode}');
    print('Clinician ID: ${clinician.id}');
    print('Name: ${clinician.name}');
    print('\nYou can now log in with code: TEST123');
  } catch (e) {
    print('Error creating test clinician: $e');
  }
}
