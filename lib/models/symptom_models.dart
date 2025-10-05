import 'package:supabase_flutter/supabase_flutter.dart';

class SymptomLog {
  final String id;
  final String patientId;
  final DateTime timestamp;
  final List<String> symptoms;
  final int severity;
  final String? timeOfDay;
  final String? activityType;
  final String? otherDetails;
  final DateTime createdAt;
  final DateTime updatedAt;

  SymptomLog({
    required this.id,
    required this.patientId,
    required this.timestamp,
    required this.symptoms,
    required this.severity,
    this.timeOfDay,
    this.activityType,
    this.otherDetails,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SymptomLog.fromJson(Map<String, dynamic> json) {
    return SymptomLog(
      id: json['id'] as String,
      patientId: json['patient_id'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      symptoms: List<String>.from(json['symptoms'] as List),
      severity: json['severity'] as int,
      timeOfDay: json['time_of_day'] as String?,
      activityType: json['activity_type'] as String?,
      otherDetails: json['other_details'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patient_id': patientId,
      'timestamp': timestamp.toIso8601String(),
      'symptoms': symptoms,
      'severity': severity,
      'time_of_day': timeOfDay,
      'activity_type': activityType,
      'other_details': otherDetails,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  SymptomLog copyWith({
    String? id,
    String? patientId,
    DateTime? timestamp,
    List<String>? symptoms,
    int? severity,
    String? timeOfDay,
    String? activityType,
    String? otherDetails,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SymptomLog(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      timestamp: timestamp ?? this.timestamp,
      symptoms: symptoms ?? this.symptoms,
      severity: severity ?? this.severity,
      timeOfDay: timeOfDay ?? this.timeOfDay,
      activityType: activityType ?? this.activityType,
      otherDetails: otherDetails ?? this.otherDetails,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class Symptom {
  final String id;
  final String name;
  final String emoji;
  final bool isCustom;

  Symptom({
    required this.id,
    required this.name,
    required this.emoji,
    this.isCustom = false,
  });

  factory Symptom.fromJson(Map<String, dynamic> json) {
    return Symptom(
      id: json['id'] as String,
      name: json['name'] as String,
      emoji: json['emoji'] as String,
      isCustom: json['is_custom'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'emoji': emoji,
      'is_custom': isCustom,
    };
  }
}

// Predefined symptoms based on POTS common symptoms
class PredefinedSymptoms {
  static final List<Symptom> symptoms = [
    Symptom(id: 'dizziness', name: 'Dizziness', emoji: '😵‍💫'),
    Symptom(id: 'lightheaded', name: 'Lightheaded', emoji: '🤯'),
    Symptom(id: 'fatigue', name: 'Fatigue', emoji: '😴'),
    Symptom(id: 'palpitations', name: 'Palpitations', emoji: '💗'),
    Symptom(id: 'chest_pain', name: 'Chest Pain', emoji: '❤️'),
    Symptom(id: 'shortness_breath', name: 'Shortness of Breath', emoji: '🫁'),
    Symptom(id: 'nausea', name: 'Nausea', emoji: '🤢'),
    Symptom(id: 'headache', name: 'Headache', emoji: '🤕'),
    Symptom(id: 'brain_fog', name: 'Brain Fog', emoji: '☁️'),
    Symptom(id: 'tremor', name: 'Tremor/Shaking', emoji: '🤲'),
    Symptom(id: 'heat_intolerance', name: 'Heat Intolerance', emoji: '🌡️'),
    Symptom(id: 'exercise_intolerance', name: 'Exercise Intolerance', emoji: '🏃‍♀️'),
    Symptom(id: 'sleep_issues', name: 'Sleep Issues', emoji: '😵'),
    Symptom(id: 'digestive_issues', name: 'Digestive Issues', emoji: '🤮'),
    Symptom(id: 'anxiety', name: 'Anxiety', emoji: '😰'),
  ];

  static Symptom? getSymptomById(String id) {
    try {
      return symptoms.firstWhere((symptom) => symptom.id == id);
    } catch (e) {
      return null;
    }
  }
}
