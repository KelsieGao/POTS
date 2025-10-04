import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:pots/core/services/supabase_service.dart';
import 'package:pots/models/generated_classes.dart';

import '../models/standup_test_data.dart';

class StandupTestService {
  StandupTestService({SupabaseClient? client})
    : _client = client ?? SupabaseService.client;

  final SupabaseClient _client;

  Future<void> submit({
    required String patientId,
    required StandupTestData data,
  }) async {
    final now = DateTime.now();

    final payload = StandupTests.insert(
      patientId: patientId,
      testDate: DateTime(now.year, now.month, now.day),
      testTime: now,
      supineHr: data.supineHr,
      supineSystolic: data.supineSystolic,
      supineDiastolic: data.supineDiastolic,
      supineDurationMinutes: data.supineDurationMinutes,
      standing1minHr: data.standing1MinHr,
      standing1minSystolic: data.standing1MinSystolic,
      standing1minDiastolic: data.standing1MinDiastolic,
      standing3minHr: data.standing3MinHr,
      standing3minSystolic: data.standing3MinSystolic,
      standing3minDiastolic: data.standing3MinDiastolic,
      standing5minHr: data.standing5MinHr,
      standing10minHr: data.standing10MinHr,
      notes: data.notes,
      createdAt: now,
    );

    await _client.from(StandupTests.table_name).insert(payload);
  }
}
