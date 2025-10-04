import 'package:flutter/foundation.dart';
import 'package:polar/polar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:pots/core/services/supabase_service.dart';
import 'package:pots/models/generated_classes.dart';

class HeartRateService {
  HeartRateService({SupabaseClient? client})
    : _client = client ?? SupabaseService.client;

  final SupabaseClient _client;

  Future<void> saveSample({
    required String patientId,
    required String deviceId,
    required DateTime recordedAt,
    required PolarHrSample sample,
  }) async {
    debugPrint(
      '[HR] saving sample at ${recordedAt.toIso8601String()} with quality ${sample.ppgQuality}',
    );
    final payload = HeartrateData.insert(
      patientId: patientId,
      deviceId: deviceId,
      recordedAt: recordedAt,
      heartRate: sample.hr,
      rrAvailable: sample.rrsMs.isNotEmpty,
      rrIntervalMs: sample.rrsMs.isNotEmpty ? sample.rrsMs.last : null,
      contactStatus: sample.contactStatus,
      contactStatusSupported: sample.contactStatusSupported,
      signalQuality: sample.ppgQuality,
      createdAt: DateTime.now(),
    );

    await _client.from(HeartrateData.table_name).insert(payload);
  }
}
