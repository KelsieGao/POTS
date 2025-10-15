// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'safety_acknowledgment.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

SafetyAcknowledgment _$SafetyAcknowledgmentFromJson(Map<String, dynamic> json) {
  return _SafetyAcknowledgment.fromJson(json);
}

/// @nodoc
mixin _$SafetyAcknowledgment {
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'patient_id')
  String get patientId => throw _privateConstructorUsedError;
  @JsonKey(name: 'acknowledged_at')
  DateTime get acknowledgedAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'risk_acknowledged')
  bool get riskAcknowledged => throw _privateConstructorUsedError;
  @JsonKey(name: 'liability_acknowledged')
  bool get liabilityAcknowledgment => throw _privateConstructorUsedError;
  @JsonKey(name: 'safety_warnings_read')
  bool get safetyWarningsRead => throw _privateConstructorUsedError;
  @JsonKey(name: 'companion_recommended')
  bool get companionRecommended => throw _privateConstructorUsedError;
  @JsonKey(name: 'emergency_contact_provided')
  bool get emergencyContactProvided => throw _privateConstructorUsedError;
  @JsonKey(name: 'emergency_contact_name')
  String? get emergencyContactName => throw _privateConstructorUsedError;
  @JsonKey(name: 'emergency_contact_phone')
  String? get emergencyContactPhone => throw _privateConstructorUsedError;
  @JsonKey(name: 'medical_conditions')
  String? get medicalConditions => throw _privateConstructorUsedError;
  @JsonKey(name: 'medications')
  String? get medications => throw _privateConstructorUsedError;
  @JsonKey(name: 'test_id')
  String? get testId => throw _privateConstructorUsedError; // Link to specific test if applicable
  @JsonKey(name: 'created_at')
  DateTime? get createdAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'updated_at')
  DateTime? get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this SafetyAcknowledgment to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of SafetyAcknowledgment
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SafetyAcknowledgmentCopyWith<SafetyAcknowledgment> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SafetyAcknowledgmentCopyWith<$Res> {
  factory $SafetyAcknowledgmentCopyWith(
    SafetyAcknowledgment value,
    $Res Function(SafetyAcknowledgment) then,
  ) = _$SafetyAcknowledgmentCopyWithImpl<$Res, SafetyAcknowledgment>;
  @useResult
  $Res call({
    String id,
    @JsonKey(name: 'patient_id') String patientId,
    @JsonKey(name: 'acknowledged_at') DateTime acknowledgedAt,
    @JsonKey(name: 'risk_acknowledged') bool riskAcknowledged,
    @JsonKey(name: 'liability_acknowledged') bool liabilityAcknowledgment,
    @JsonKey(name: 'safety_warnings_read') bool safetyWarningsRead,
    @JsonKey(name: 'companion_recommended') bool companionRecommended,
    @JsonKey(name: 'emergency_contact_provided') bool emergencyContactProvided,
    @JsonKey(name: 'emergency_contact_name') String? emergencyContactName,
    @JsonKey(name: 'emergency_contact_phone') String? emergencyContactPhone,
    @JsonKey(name: 'medical_conditions') String? medicalConditions,
    @JsonKey(name: 'medications') String? medications,
    @JsonKey(name: 'test_id') String? testId,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
  });
}

/// @nodoc
class _$SafetyAcknowledgmentCopyWithImpl<
  $Res,
  $Val extends SafetyAcknowledgment
>
    implements $SafetyAcknowledgmentCopyWith<$Res> {
  _$SafetyAcknowledgmentCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SafetyAcknowledgment
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? patientId = null,
    Object? acknowledgedAt = null,
    Object? riskAcknowledged = null,
    Object? liabilityAcknowledgment = null,
    Object? safetyWarningsRead = null,
    Object? companionRecommended = null,
    Object? emergencyContactProvided = null,
    Object? emergencyContactName = freezed,
    Object? emergencyContactPhone = freezed,
    Object? medicalConditions = freezed,
    Object? medications = freezed,
    Object? testId = freezed,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            patientId: null == patientId
                ? _value.patientId
                : patientId // ignore: cast_nullable_to_non_nullable
                      as String,
            acknowledgedAt: null == acknowledgedAt
                ? _value.acknowledgedAt
                : acknowledgedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            riskAcknowledged: null == riskAcknowledged
                ? _value.riskAcknowledged
                : riskAcknowledged // ignore: cast_nullable_to_non_nullable
                      as bool,
            liabilityAcknowledgment: null == liabilityAcknowledgment
                ? _value.liabilityAcknowledgment
                : liabilityAcknowledgment // ignore: cast_nullable_to_non_nullable
                      as bool,
            safetyWarningsRead: null == safetyWarningsRead
                ? _value.safetyWarningsRead
                : safetyWarningsRead // ignore: cast_nullable_to_non_nullable
                      as bool,
            companionRecommended: null == companionRecommended
                ? _value.companionRecommended
                : companionRecommended // ignore: cast_nullable_to_non_nullable
                      as bool,
            emergencyContactProvided: null == emergencyContactProvided
                ? _value.emergencyContactProvided
                : emergencyContactProvided // ignore: cast_nullable_to_non_nullable
                      as bool,
            emergencyContactName: freezed == emergencyContactName
                ? _value.emergencyContactName
                : emergencyContactName // ignore: cast_nullable_to_non_nullable
                      as String?,
            emergencyContactPhone: freezed == emergencyContactPhone
                ? _value.emergencyContactPhone
                : emergencyContactPhone // ignore: cast_nullable_to_non_nullable
                      as String?,
            medicalConditions: freezed == medicalConditions
                ? _value.medicalConditions
                : medicalConditions // ignore: cast_nullable_to_non_nullable
                      as String?,
            medications: freezed == medications
                ? _value.medications
                : medications // ignore: cast_nullable_to_non_nullable
                      as String?,
            testId: freezed == testId
                ? _value.testId
                : testId // ignore: cast_nullable_to_non_nullable
                      as String?,
            createdAt: freezed == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            updatedAt: freezed == updatedAt
                ? _value.updatedAt
                : updatedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$SafetyAcknowledgmentImplCopyWith<$Res>
    implements $SafetyAcknowledgmentCopyWith<$Res> {
  factory _$$SafetyAcknowledgmentImplCopyWith(
    _$SafetyAcknowledgmentImpl value,
    $Res Function(_$SafetyAcknowledgmentImpl) then,
  ) = __$$SafetyAcknowledgmentImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    @JsonKey(name: 'patient_id') String patientId,
    @JsonKey(name: 'acknowledged_at') DateTime acknowledgedAt,
    @JsonKey(name: 'risk_acknowledged') bool riskAcknowledged,
    @JsonKey(name: 'liability_acknowledged') bool liabilityAcknowledgment,
    @JsonKey(name: 'safety_warnings_read') bool safetyWarningsRead,
    @JsonKey(name: 'companion_recommended') bool companionRecommended,
    @JsonKey(name: 'emergency_contact_provided') bool emergencyContactProvided,
    @JsonKey(name: 'emergency_contact_name') String? emergencyContactName,
    @JsonKey(name: 'emergency_contact_phone') String? emergencyContactPhone,
    @JsonKey(name: 'medical_conditions') String? medicalConditions,
    @JsonKey(name: 'medications') String? medications,
    @JsonKey(name: 'test_id') String? testId,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
  });
}

/// @nodoc
class __$$SafetyAcknowledgmentImplCopyWithImpl<$Res>
    extends _$SafetyAcknowledgmentCopyWithImpl<$Res, _$SafetyAcknowledgmentImpl>
    implements _$$SafetyAcknowledgmentImplCopyWith<$Res> {
  __$$SafetyAcknowledgmentImplCopyWithImpl(
    _$SafetyAcknowledgmentImpl _value,
    $Res Function(_$SafetyAcknowledgmentImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of SafetyAcknowledgment
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? patientId = null,
    Object? acknowledgedAt = null,
    Object? riskAcknowledged = null,
    Object? liabilityAcknowledgment = null,
    Object? safetyWarningsRead = null,
    Object? companionRecommended = null,
    Object? emergencyContactProvided = null,
    Object? emergencyContactName = freezed,
    Object? emergencyContactPhone = freezed,
    Object? medicalConditions = freezed,
    Object? medications = freezed,
    Object? testId = freezed,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(
      _$SafetyAcknowledgmentImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        patientId: null == patientId
            ? _value.patientId
            : patientId // ignore: cast_nullable_to_non_nullable
                  as String,
        acknowledgedAt: null == acknowledgedAt
            ? _value.acknowledgedAt
            : acknowledgedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        riskAcknowledged: null == riskAcknowledged
            ? _value.riskAcknowledged
            : riskAcknowledged // ignore: cast_nullable_to_non_nullable
                  as bool,
        liabilityAcknowledgment: null == liabilityAcknowledgment
            ? _value.liabilityAcknowledgment
            : liabilityAcknowledgment // ignore: cast_nullable_to_non_nullable
                  as bool,
        safetyWarningsRead: null == safetyWarningsRead
            ? _value.safetyWarningsRead
            : safetyWarningsRead // ignore: cast_nullable_to_non_nullable
                  as bool,
        companionRecommended: null == companionRecommended
            ? _value.companionRecommended
            : companionRecommended // ignore: cast_nullable_to_non_nullable
                  as bool,
        emergencyContactProvided: null == emergencyContactProvided
            ? _value.emergencyContactProvided
            : emergencyContactProvided // ignore: cast_nullable_to_non_nullable
                  as bool,
        emergencyContactName: freezed == emergencyContactName
            ? _value.emergencyContactName
            : emergencyContactName // ignore: cast_nullable_to_non_nullable
                  as String?,
        emergencyContactPhone: freezed == emergencyContactPhone
            ? _value.emergencyContactPhone
            : emergencyContactPhone // ignore: cast_nullable_to_non_nullable
                  as String?,
        medicalConditions: freezed == medicalConditions
            ? _value.medicalConditions
            : medicalConditions // ignore: cast_nullable_to_non_nullable
                  as String?,
        medications: freezed == medications
            ? _value.medications
            : medications // ignore: cast_nullable_to_non_nullable
                  as String?,
        testId: freezed == testId
            ? _value.testId
            : testId // ignore: cast_nullable_to_non_nullable
                  as String?,
        createdAt: freezed == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        updatedAt: freezed == updatedAt
            ? _value.updatedAt
            : updatedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$SafetyAcknowledgmentImpl implements _SafetyAcknowledgment {
  const _$SafetyAcknowledgmentImpl({
    required this.id,
    @JsonKey(name: 'patient_id') required this.patientId,
    @JsonKey(name: 'acknowledged_at') required this.acknowledgedAt,
    @JsonKey(name: 'risk_acknowledged') required this.riskAcknowledged,
    @JsonKey(name: 'liability_acknowledged')
    required this.liabilityAcknowledgment,
    @JsonKey(name: 'safety_warnings_read') required this.safetyWarningsRead,
    @JsonKey(name: 'companion_recommended') required this.companionRecommended,
    @JsonKey(name: 'emergency_contact_provided')
    required this.emergencyContactProvided,
    @JsonKey(name: 'emergency_contact_name') this.emergencyContactName,
    @JsonKey(name: 'emergency_contact_phone') this.emergencyContactPhone,
    @JsonKey(name: 'medical_conditions') this.medicalConditions,
    @JsonKey(name: 'medications') this.medications,
    @JsonKey(name: 'test_id') this.testId,
    @JsonKey(name: 'created_at') this.createdAt,
    @JsonKey(name: 'updated_at') this.updatedAt,
  });

  factory _$SafetyAcknowledgmentImpl.fromJson(Map<String, dynamic> json) =>
      _$$SafetyAcknowledgmentImplFromJson(json);

  @override
  final String id;
  @override
  @JsonKey(name: 'patient_id')
  final String patientId;
  @override
  @JsonKey(name: 'acknowledged_at')
  final DateTime acknowledgedAt;
  @override
  @JsonKey(name: 'risk_acknowledged')
  final bool riskAcknowledged;
  @override
  @JsonKey(name: 'liability_acknowledged')
  final bool liabilityAcknowledgment;
  @override
  @JsonKey(name: 'safety_warnings_read')
  final bool safetyWarningsRead;
  @override
  @JsonKey(name: 'companion_recommended')
  final bool companionRecommended;
  @override
  @JsonKey(name: 'emergency_contact_provided')
  final bool emergencyContactProvided;
  @override
  @JsonKey(name: 'emergency_contact_name')
  final String? emergencyContactName;
  @override
  @JsonKey(name: 'emergency_contact_phone')
  final String? emergencyContactPhone;
  @override
  @JsonKey(name: 'medical_conditions')
  final String? medicalConditions;
  @override
  @JsonKey(name: 'medications')
  final String? medications;
  @override
  @JsonKey(name: 'test_id')
  final String? testId;
  // Link to specific test if applicable
  @override
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;
  @override
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;

  @override
  String toString() {
    return 'SafetyAcknowledgment(id: $id, patientId: $patientId, acknowledgedAt: $acknowledgedAt, riskAcknowledged: $riskAcknowledged, liabilityAcknowledgment: $liabilityAcknowledgment, safetyWarningsRead: $safetyWarningsRead, companionRecommended: $companionRecommended, emergencyContactProvided: $emergencyContactProvided, emergencyContactName: $emergencyContactName, emergencyContactPhone: $emergencyContactPhone, medicalConditions: $medicalConditions, medications: $medications, testId: $testId, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SafetyAcknowledgmentImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.patientId, patientId) ||
                other.patientId == patientId) &&
            (identical(other.acknowledgedAt, acknowledgedAt) ||
                other.acknowledgedAt == acknowledgedAt) &&
            (identical(other.riskAcknowledged, riskAcknowledged) ||
                other.riskAcknowledged == riskAcknowledged) &&
            (identical(
                  other.liabilityAcknowledgment,
                  liabilityAcknowledgment,
                ) ||
                other.liabilityAcknowledgment == liabilityAcknowledgment) &&
            (identical(other.safetyWarningsRead, safetyWarningsRead) ||
                other.safetyWarningsRead == safetyWarningsRead) &&
            (identical(other.companionRecommended, companionRecommended) ||
                other.companionRecommended == companionRecommended) &&
            (identical(
                  other.emergencyContactProvided,
                  emergencyContactProvided,
                ) ||
                other.emergencyContactProvided == emergencyContactProvided) &&
            (identical(other.emergencyContactName, emergencyContactName) ||
                other.emergencyContactName == emergencyContactName) &&
            (identical(other.emergencyContactPhone, emergencyContactPhone) ||
                other.emergencyContactPhone == emergencyContactPhone) &&
            (identical(other.medicalConditions, medicalConditions) ||
                other.medicalConditions == medicalConditions) &&
            (identical(other.medications, medications) ||
                other.medications == medications) &&
            (identical(other.testId, testId) || other.testId == testId) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    patientId,
    acknowledgedAt,
    riskAcknowledged,
    liabilityAcknowledgment,
    safetyWarningsRead,
    companionRecommended,
    emergencyContactProvided,
    emergencyContactName,
    emergencyContactPhone,
    medicalConditions,
    medications,
    testId,
    createdAt,
    updatedAt,
  );

  /// Create a copy of SafetyAcknowledgment
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SafetyAcknowledgmentImplCopyWith<_$SafetyAcknowledgmentImpl>
  get copyWith =>
      __$$SafetyAcknowledgmentImplCopyWithImpl<_$SafetyAcknowledgmentImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$SafetyAcknowledgmentImplToJson(this);
  }
}

abstract class _SafetyAcknowledgment implements SafetyAcknowledgment {
  const factory _SafetyAcknowledgment({
    required final String id,
    @JsonKey(name: 'patient_id') required final String patientId,
    @JsonKey(name: 'acknowledged_at') required final DateTime acknowledgedAt,
    @JsonKey(name: 'risk_acknowledged') required final bool riskAcknowledged,
    @JsonKey(name: 'liability_acknowledged')
    required final bool liabilityAcknowledgment,
    @JsonKey(name: 'safety_warnings_read')
    required final bool safetyWarningsRead,
    @JsonKey(name: 'companion_recommended')
    required final bool companionRecommended,
    @JsonKey(name: 'emergency_contact_provided')
    required final bool emergencyContactProvided,
    @JsonKey(name: 'emergency_contact_name') final String? emergencyContactName,
    @JsonKey(name: 'emergency_contact_phone')
    final String? emergencyContactPhone,
    @JsonKey(name: 'medical_conditions') final String? medicalConditions,
    @JsonKey(name: 'medications') final String? medications,
    @JsonKey(name: 'test_id') final String? testId,
    @JsonKey(name: 'created_at') final DateTime? createdAt,
    @JsonKey(name: 'updated_at') final DateTime? updatedAt,
  }) = _$SafetyAcknowledgmentImpl;

  factory _SafetyAcknowledgment.fromJson(Map<String, dynamic> json) =
      _$SafetyAcknowledgmentImpl.fromJson;

  @override
  String get id;
  @override
  @JsonKey(name: 'patient_id')
  String get patientId;
  @override
  @JsonKey(name: 'acknowledged_at')
  DateTime get acknowledgedAt;
  @override
  @JsonKey(name: 'risk_acknowledged')
  bool get riskAcknowledged;
  @override
  @JsonKey(name: 'liability_acknowledged')
  bool get liabilityAcknowledgment;
  @override
  @JsonKey(name: 'safety_warnings_read')
  bool get safetyWarningsRead;
  @override
  @JsonKey(name: 'companion_recommended')
  bool get companionRecommended;
  @override
  @JsonKey(name: 'emergency_contact_provided')
  bool get emergencyContactProvided;
  @override
  @JsonKey(name: 'emergency_contact_name')
  String? get emergencyContactName;
  @override
  @JsonKey(name: 'emergency_contact_phone')
  String? get emergencyContactPhone;
  @override
  @JsonKey(name: 'medical_conditions')
  String? get medicalConditions;
  @override
  @JsonKey(name: 'medications')
  String? get medications;
  @override
  @JsonKey(name: 'test_id')
  String? get testId; // Link to specific test if applicable
  @override
  @JsonKey(name: 'created_at')
  DateTime? get createdAt;
  @override
  @JsonKey(name: 'updated_at')
  DateTime? get updatedAt;

  /// Create a copy of SafetyAcknowledgment
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SafetyAcknowledgmentImplCopyWith<_$SafetyAcknowledgmentImpl>
  get copyWith => throw _privateConstructorUsedError;
}
