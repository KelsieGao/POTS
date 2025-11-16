import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/services/supabase_service.dart';
import '../../models/generated_classes.dart';
import '../standup_test/services/standup_test_service.dart';
import '../../core/services/patient_progress_service.dart';

/// Builds and shares a clinician-style PDF report with key patient data.
class ReportService {
  ReportService({SupabaseClient? client})
      : _client = client ?? SupabaseService.client;

  final SupabaseClient _client;
  final StandupTestService _testService = StandupTestService();

  Future<void> exportPatientReport(String patientId) async {
    final bytes = await _buildReportBytes(patientId);
    final now = DateTime.now();
    final filename =
        'POTSure_Clinician_Report_${DateFormat('yyyyMMdd_HHmm').format(now)}.pdf';
    await Printing.sharePdf(bytes: bytes, filename: filename);
  }

  Future<Uint8List> _buildReportBytes(String patientId) async {
    // Fetch data robustly (each in its own try/catch so one failure won't abort)
    Map<String, dynamic>? patientJson;
    try {
      final response = await _client
          .from(Patients.table_name)
          .select()
          .eq(Patients.c_id, patientId)
          .order('updated_at', ascending: false)
          .limit(1);
      if (response is List && response.isNotEmpty) {
        patientJson = Map<String, dynamic>.from(response.first);
      }
    } catch (_) {}

    List<StandupTests> tests = const <StandupTests>[];
    try {
      tests = await _testService.getTestHistory(patientId: patientId, limit: 10);
    } catch (_) {}

    PatientProgress progress = await PatientProgressService.getProgress(patientId);

    Map<String, dynamic>? vossJson;
    try {
      final vossList = await _client
          .from(VossQuestionnaires.table_name)
          .select()
          .eq('patient_id', patientId)
          .order('completed_at', ascending: false)
          .limit(1);
      if (vossList is List && vossList.isNotEmpty) {
        vossJson = Map<String, dynamic>.from(vossList.first);
      }
    } catch (_) {}

    // Recent symptoms
    List<SymptomLogs> symptoms = const <SymptomLogs>[];
    try {
      final res = await _client
          .from(SymptomLogs.table_name)
          .select()
          .eq('patient_id', patientId)
          .order('logged_at', ascending: false)
          .limit(10);
      if (res is List) {
        symptoms = res.map((j) => SymptomLogs.fromJson(j)).toList();
      }
    } catch (_) {}

    final patient = patientJson != null ? Patients.fromJson(patientJson) : null;

    final pdf = pw.Document();
    final primary = PdfColor.fromHex('#20B2AA');
    final gray = PdfColors.grey700;

    pw.Widget header() {
      return pw.Container(
        padding: const pw.EdgeInsets.only(bottom: 8),
        decoration: pw.BoxDecoration(
          border: pw.Border(
            bottom: pw.BorderSide(color: PdfColors.grey300, width: 1),
          ),
        ),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Container(
              width: 28,
              height: 28,
              decoration:
                  pw.BoxDecoration(color: primary, shape: pw.BoxShape.circle),
            ),
            pw.SizedBox(width: 10),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('POTSure Clinician Report',
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                      color: primary,
                    )),
                pw.Text(DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now()),
                    style: pw.TextStyle(fontSize: 10, color: gray)),
              ],
            ),
            pw.Spacer(),
            if (patient != null)
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text('${patient.firstName} ${patient.lastName}',
                      style: pw.TextStyle(
                          fontSize: 12, fontWeight: pw.FontWeight.bold)),
                  pw.Text(
                    'DOB: ${DateFormat('yyyy-MM-dd').format(patient.dateOfBirth)}',
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                  if (patient.email != null)
                    pw.Text('${patient.email}', style: const pw.TextStyle(fontSize: 10)),
                ],
              ),
          ],
        ),
      );
    }

    pw.Widget progressCard() {
      return pw.Container(
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          borderRadius: pw.BorderRadius.circular(8),
          border: pw.Border.all(color: PdfColors.grey300),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('Summary',
                style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    color: primary)),
            pw.SizedBox(height: 6),
            pw.Row(children: [
              _kv('Stand-up tests', '${progress.testsCompleted}/${progress.maxTests}'),
              pw.SizedBox(width: 16),
              _kv('Symptoms logged', '${progress.symptomsLogged}'),
              pw.SizedBox(width: 16),
              _kv('VOSS', progress.vossCompleted ? 'Completed' : 'Not completed'),
              pw.SizedBox(width: 16),
              _kv('Profile', progress.profileComplete ? 'Complete' : 'Incomplete'),
            ]),
            pw.SizedBox(height: 4),
            _kv('Total tests performed', '${progress.testsCompleted}'),
          ],
        ),
      );
    }

    pw.Widget testsTable() {
      final headers = <String>[
        'Date',
        'Supine HR',
        'Supine BP',
        '1min HR',
        '1min BP',
        '3min HR',
        '3min BP',
        'ΔHR 1m',
        'ΔHR 3m',
      ];
      final data = tests.map((t) {
        String bp(int? s, int? d) => s != null && d != null ? '$s/$d' : '—';
        // Combine date + time (time-of-day stored separately); avoid 1970 date.
        DateTime baseDate = t.testDate;
        if (baseDate.year <= 1971) {
          baseDate = t.createdAt ?? DateTime.now();
        }
        final combined = DateTime(baseDate.year, baseDate.month, baseDate.day,
            t.testTime.hour, t.testTime.minute, t.testTime.second);
        String fmt(DateTime dt) => DateFormat('yyyy-MM-dd HH:mm').format(dt);
        return [
          fmt(combined),
          t.supineHr?.toString() ?? '—',
          bp(t.supineSystolic, t.supineDiastolic),
          t.standing1minHr?.toString() ?? '—',
          bp(t.standing1minSystolic, t.standing1minDiastolic),
          t.standing3minHr?.toString() ?? '—',
          bp(t.standing3minSystolic, t.standing3minDiastolic),
          t.hrIncrease1min?.toString() ?? '—',
          t.hrIncrease3min?.toString() ?? '—',
        ];
      }).toList();

      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('Recent Sit/Stand Tests',
              style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: primary)),
          pw.SizedBox(height: 4),
          pw.Text(
            'Showing up to the most recent ${tests.length} of ${progress.testsCompleted} tests',
            style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
          ),
          pw.SizedBox(height: 6),
          pw.TableHelper.fromTextArray(
            headers: headers,
            data: data,
            headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold, color: PdfColors.white),
            headerDecoration: pw.BoxDecoration(color: primary),
            cellAlignment: pw.Alignment.centerLeft,
            cellPadding: const pw.EdgeInsets.symmetric(
                horizontal: 6, vertical: 8),
            headerPadding:
                const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 8),
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            rowDecoration: const pw.BoxDecoration(),
          ),
        ],
      );
    }

    pw.Widget vossSection() {
      return pw.Container(
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          borderRadius: pw.BorderRadius.circular(8),
          border: pw.Border.all(color: PdfColors.grey300),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('VOSS Questionnaire',
                style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    color: primary)),
            pw.SizedBox(height: 6),
            if (vossJson == null)
              pw.Text('No questionnaire submitted.')
            else
              pw.Row(
                children: [
                  _kv('Completed',
                      DateFormat('yyyy-MM-dd').format(DateTime.parse(vossJson['completed_at']))),
                  pw.SizedBox(width: 16),
                  _kv('Total Score', '${vossJson['total_score'] ?? '—'}'),
                ],
              ),
          ],
        ),
      );
    }

    pw.Widget symptomsSection() {
      if (symptoms.isEmpty) {
        return pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            borderRadius: pw.BorderRadius.circular(8),
            border: pw.Border.all(color: PdfColors.grey300),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Recent Symptoms',
                  style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                      color: primary)),
              pw.SizedBox(height: 6),
              pw.Text('No symptom logs found.'),
            ],
          ),
        );
      }

      // Windowed summaries (last N days)
      const int windowDays = 5;
      final cutoff = DateTime.now().subtract(const Duration(days: windowDays));
      final window = symptoms.where((s) => s.loggedAt.isAfter(cutoff)).toList();
      // If window is empty (e.g., no recent), fallback to all fetched symptoms
      final source = window.isNotEmpty ? window : symptoms;

      final categories = <String>[
        'Dizziness',
        'Palpitations',
        'Fatigue',
        'Brain Fog',
        'Fainting',
      ];

      int countFor(String type) =>
          source.where((s) => s.symptomType == type).length;

      double? avgMinutes(String type) {
        final durations = source
            .where((s) => s.symptomType == type && s.durationMinutes != null)
            .map((s) => s.durationMinutes!.toDouble())
            .toList();
        if (durations.isEmpty) return null;
        return durations.reduce((a, b) => a + b) / durations.length;
      }

      final totalEpisodes = source.length;

      final rows = symptoms.map((s) {
        final ts = DateFormat('yyyy-MM-dd HH:mm').format(s.loggedAt);
        String bp = '—';
        if (s.bpDuringSymptomSystolic != null && s.bpDuringSymptomDiastolic != null) {
          bp = '${s.bpDuringSymptomSystolic}/${s.bpDuringSymptomDiastolic}';
        }
        return [
          ts,
          s.symptomType,
          s.severity.toString(),
          s.hrDuringSymptom?.toString() ?? '—',
          bp,
          s.notes == null ? '—' : (s.notes!.length > 40 ? s.notes!.substring(0, 40) + '…' : s.notes!),
        ];
      }).toList();

      return pw.Container(
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          borderRadius: pw.BorderRadius.circular(8),
          border: pw.Border.all(color: PdfColors.grey300),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('Recent Symptoms',
                style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    color: primary)),
            pw.SizedBox(height: 6),
            // Summary cards
            pw.Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final type in categories)
                  _summaryCard(
                    title: type,
                    count: countFor(type),
                    avgMinutes: avgMinutes(type),
                    accent: PdfColor.fromHex('#8E44AD'),
                  ),
                _summaryCard(
                  title: 'Total Episodes',
                  count: totalEpisodes,
                  subtitle: '($windowDays days)',
                  accent: PdfColor.fromHex('#8E44AD'),
                ),
              ],
            ),
            pw.SizedBox(height: 6),
            pw.TableHelper.fromTextArray(
              headers: const [
                'When',
                'Type',
                'Severity',
                'HR',
                'BP',
                'Notes',
              ],
              data: rows,
              headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold, color: PdfColors.white),
              headerDecoration: pw.BoxDecoration(color: primary),
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              cellPadding:
                  const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
              headerPadding:
                  const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 8),
              cellAlignment: pw.Alignment.centerLeft,
            ),
          ],
        ),
      );
    }

    pdf.addPage(
      pw.MultiPage(
        margin: const pw.EdgeInsets.all(24),
        build: (context) => [
          header(),
          pw.SizedBox(height: 12),
          progressCard(),
          pw.SizedBox(height: 16),
          testsTable(),
          pw.SizedBox(height: 16),
          vossSection(),
          pw.SizedBox(height: 16),
          symptomsSection(),
          pw.SizedBox(height: 18),
          pw.Text(
            'This report was generated by POTSure. Values are captured from supported devices and user inputs.',
            style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
          ),
        ],
        footer: (context) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text('Page ${context.pageNumber} of ${context.pagesCount}',
              style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
        ),
      ),
    );

    return pdf.save();
  }

  pw.Widget _kv(String key, String value) {
    return pw.Row(
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        pw.Text('$key: ',
            style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold, color: PdfColors.grey800)),
        pw.Text(value),
      ],
    );
  }

  pw.Widget _summaryCard({
    required String title,
    required int count,
    double? avgMinutes,
    String? subtitle,
    PdfColor accent = PdfColors.blue,
  }) {
    final hasAvg = avgMinutes != null;
    final avgText =
        hasAvg ? '(Avg ${avgMinutes!.toStringAsFixed(1)} min)' : (count == 0 ? '(No episodes)' : '');
    return pw.Container(
      width: 170,
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: PdfColors.grey300),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            height: 3,
            decoration:
                pw.BoxDecoration(color: accent, borderRadius: pw.BorderRadius.circular(2)),
          ),
          pw.SizedBox(height: 8),
          pw.Text('$count',
              style: pw.TextStyle(
                fontSize: 22,
                fontWeight: pw.FontWeight.bold,
              )),
          pw.SizedBox(height: 2),
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            [avgText, if (subtitle != null) subtitle].where((s) => s != null && s.isNotEmpty).join(' '),
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
          ),
        ],
      ),
    );
  }
}


