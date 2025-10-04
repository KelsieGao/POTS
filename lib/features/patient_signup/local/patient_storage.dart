import 'package:shared_preferences/shared_preferences.dart';

class PatientStorage {
  PatientStorage(this._prefs);

  static const _patientIdKey = 'patient_id';
  static const _vossCompletedKey = 'voss_completed';

  final SharedPreferences _prefs;

  static Future<PatientStorage> create() async {
    final prefs = await SharedPreferences.getInstance();
    return PatientStorage(prefs);
  }

  String? get patientId => _prefs.getString(_patientIdKey);
  bool get hasCompletedVoss => _prefs.getBool(_vossCompletedKey) ?? false;

  Future<void> savePatientId(String id) async {
    await _prefs.setString(_patientIdKey, id);
  }

  Future<void> setVossCompleted(bool value) async {
    await _prefs.setBool(_vossCompletedKey, value);
  }

  Future<void> clear() async {
    await _prefs.remove(_patientIdKey);
    await _prefs.remove(_vossCompletedKey);
  }
}
