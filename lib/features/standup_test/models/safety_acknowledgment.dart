import 'package:freezed_annotation/freezed_annotation.dart';

part 'safety_acknowledgment.freezed.dart';
part 'safety_acknowledgment.g.dart';

@freezed
class SafetyAcknowledgment with _$SafetyAcknowledgment {
  const factory SafetyAcknowledgment({
    required String id,
    required String patientId,
    required DateTime acknowledgedAt,
    required bool riskAcknowledged,
    required bool liabilityAcknowledgment,
    required bool safetyWarningsRead,
    required bool companionRecommended,
    required bool emergencyContactProvided,
    String? emergencyContactName,
    String? emergencyContactPhone,
    String? medicalConditions,
    String? medications,
    String? testId, // Link to specific test if applicable
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _SafetyAcknowledgment;

  factory SafetyAcknowledgment.fromJson(Map<String, dynamic> json) =>
      _$SafetyAcknowledgmentFromJson(json);
}
