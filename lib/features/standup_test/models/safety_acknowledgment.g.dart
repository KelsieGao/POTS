// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'safety_acknowledgment.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$SafetyAcknowledgmentImpl _$$SafetyAcknowledgmentImplFromJson(
  Map<String, dynamic> json,
) => _$SafetyAcknowledgmentImpl(
  id: json['id'] as String,
  patientId: json['patient_id'] as String,
  acknowledgedAt: DateTime.parse(json['acknowledged_at'] as String),
  riskAcknowledged: json['risk_acknowledged'] as bool,
  liabilityAcknowledgment: json['liability_acknowledged'] as bool,
  safetyWarningsRead: json['safety_warnings_read'] as bool,
  companionRecommended: json['companion_recommended'] as bool,
  emergencyContactProvided: json['emergency_contact_provided'] as bool,
  emergencyContactName: json['emergency_contact_name'] as String?,
  emergencyContactPhone: json['emergency_contact_phone'] as String?,
  medicalConditions: json['medical_conditions'] as String?,
  medications: json['medications'] as String?,
  testId: json['test_id'] as String?,
  createdAt: json['created_at'] == null
      ? null
      : DateTime.parse(json['created_at'] as String),
  updatedAt: json['updated_at'] == null
      ? null
      : DateTime.parse(json['updated_at'] as String),
);

Map<String, dynamic> _$$SafetyAcknowledgmentImplToJson(
  _$SafetyAcknowledgmentImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'patient_id': instance.patientId,
  'acknowledged_at': instance.acknowledgedAt.toIso8601String(),
  'risk_acknowledged': instance.riskAcknowledged,
  'liability_acknowledged': instance.liabilityAcknowledgment,
  'safety_warnings_read': instance.safetyWarningsRead,
  'companion_recommended': instance.companionRecommended,
  'emergency_contact_provided': instance.emergencyContactProvided,
  'emergency_contact_name': instance.emergencyContactName,
  'emergency_contact_phone': instance.emergencyContactPhone,
  'medical_conditions': instance.medicalConditions,
  'medications': instance.medications,
  'test_id': instance.testId,
  'created_at': instance.createdAt?.toIso8601String(),
  'updated_at': instance.updatedAt?.toIso8601String(),
};
