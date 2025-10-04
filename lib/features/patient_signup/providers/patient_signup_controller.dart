import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../models/generated_classes.dart';
import '../local/patient_storage.dart';
import '../models/patient_form_data.dart';
import '../services/patient_service.dart';

enum PatientSignupStatus { idle, submitting, completed, error }

class PatientSignupController extends ChangeNotifier {
  PatientSignupController({PatientService? service, PatientStorage? storage})
    : _service = service ?? PatientService(),
      _storage = storage;

  final PatientService _service;
  PatientStorage? _storage;

  PatientFormData data = PatientFormData();
  PatientSignupStatus status = PatientSignupStatus.idle;
  String? errorMessage;
  Patients? createdPatient;

  Future<void> initialize() async {
    _storage ??= await PatientStorage.create();
  }

  Future<bool> hasPatient() async {
    await initialize();
    return _storage?.patientId != null;
  }

  Future<bool> hasCompletedVoss() async {
    await initialize();
    return _storage?.hasCompletedVoss ?? false;
  }

  Future<void> markVossCompleted() async {
    await initialize();
    await _storage?.setVossCompleted(true);
  }

  String? get patientId => createdPatient?.id ?? _storage?.patientId;

  Future<void> submit() async {
    await initialize();

    if (!data.isValid) {
      errorMessage = 'Please complete all required fields.';
      status = PatientSignupStatus.error;
      notifyListeners();
      return;
    }

    status = PatientSignupStatus.submitting;
    errorMessage = null;
    notifyListeners();

    try {
      final patient = await _service.createPatient(data);
      createdPatient = patient;
      await _storage?.savePatientId(patient.id);
      await _storage?.setVossCompleted(false);
      status = PatientSignupStatus.completed;
    } on PatientServiceException catch (error) {
      errorMessage = error.message;
      status = PatientSignupStatus.error;
    } catch (error) {
      errorMessage = 'Unexpected error: $error';
      status = PatientSignupStatus.error;
    }

    notifyListeners();
  }

  void updateData(PatientFormData newData) {
    data = newData;
    notifyListeners();
  }

  Future<void> reset() async {
    data = PatientFormData();
    status = PatientSignupStatus.idle;
    errorMessage = null;
    createdPatient = null;
    await _storage?.clear();
    notifyListeners();
  }
}
