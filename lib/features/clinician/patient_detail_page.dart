import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/services/supabase_service.dart';
import '../../models/clinician_models.dart';
import 'voss_results_page.dart';
import 'episode_history_page.dart';

class PatientDetailPage extends StatefulWidget {
  final Clinician clinician;
  final PatientSummary patient;

  const PatientDetailPage({
    super.key,
    required this.clinician,
    required this.patient,
  });

  @override
  State<PatientDetailPage> createState() => _PatientDetailPageState();
}

class _PatientDetailPageState extends State<PatientDetailPage> {
  Map<String, dynamic>? _patientData;
  List<Map<String, dynamic>> _standupTests = [];
  List<Map<String, dynamic>> _symptomLogs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final patientResponse = await SupabaseService.client
          .from('patients')
          .select()
          .eq('id', widget.patient.patientId)
          .maybeSingle();

      final testsResponse = await SupabaseService.client
          .from('standup_tests')
          .select()
          .eq('patient_id', widget.patient.patientId)
          .order('created_at', ascending: false);

      final symptomsResponse = await SupabaseService.client
          .from('symptom_logs')
          .select()
          .eq('patient_id', widget.patient.patientId)
          .order('timestamp', ascending: false)
          .limit(10);

      setState(() {
        _patientData = patientResponse;
        _standupTests = List<Map<String, dynamic>>.from(testsResponse);
        _symptomLogs = List<Map<String, dynamic>>.from(symptomsResponse);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.patient.fullName,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Code: ${widget.patient.patientCode}',
              style: const TextStyle(
                color: Colors.black54,
                fontSize: 12,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
        actions: [
          _buildStatusChip(),
          const SizedBox(width: 16),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSummaryCards(),
                    const SizedBox(height: 24),
                    _buildActionButtons(),
                    const SizedBox(height: 24),
                    _buildTestsSection(),
                    const SizedBox(height: 24),
                    _buildRecentSymptomsSection(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatusChip() {
    Color backgroundColor;
    Color textColor;

    switch (widget.patient.status) {
      case PatientStatus.active:
        backgroundColor = Colors.green.shade50;
        textColor = Colors.green.shade700;
        break;
      case PatientStatus.completed:
        backgroundColor = Colors.blue.shade50;
        textColor = Colors.blue.shade700;
        break;
      case PatientStatus.inactive:
        backgroundColor = Colors.grey.shade50;
        textColor = Colors.grey.shade700;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        widget.patient.status.label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildSummaryCards() {
    final avgHeartRate = _calculateAverageHeartRate();
    final avgBpSupine = _calculateAverageBP(isSupine: true);
    final avgBpStanding = _calculateAverageBP(isSupine: false);
    final episodeCount = _symptomLogs.length;

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.3,
      children: [
        _buildSummaryCard(
          'Avg Heart Rate',
          avgHeartRate > 0 ? '$avgHeartRate BPM' : 'No data',
          '5-day monitoring',
          const Color(0xFF20B2AA),
          Icons.favorite,
        ),
        _buildSummaryCard(
          'Avg BP (Lying)',
          avgBpSupine.isNotEmpty ? avgBpSupine : 'No data',
          'Baseline measurements',
          const Color(0xFF9C27B0),
          Icons.speed,
        ),
        _buildSummaryCard(
          'Avg BP (Standing)',
          avgBpStanding.isNotEmpty ? avgBpStanding : 'No data',
          'Orthostatic measurements',
          const Color(0xFFFF9800),
          Icons.speed,
        ),
        _buildSummaryCard(
          'Episodes Logged',
          '$episodeCount',
          'During monitoring',
          const Color(0xFFF44336),
          Icons.timeline,
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    String subtitle,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 24),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _viewVossResults,
            icon: const Icon(Icons.assignment),
            label: const Text('VOSS Survey'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: const BorderSide(color: Color(0xFF2196F3)),
              foregroundColor: const Color(0xFF2196F3),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _viewEpisodeHistory,
            icon: const Icon(Icons.history),
            label: const Text('Episodes'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: const BorderSide(color: Color(0xFF2196F3)),
              foregroundColor: const Color(0xFF2196F3),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTestsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Stand-Up Test Results',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        if (_standupTests.isEmpty)
          _buildEmptyState('No tests recorded yet', Icons.assignment_outlined)
        else
          ..._standupTests.map((test) => _buildTestCard(test)).toList(),
      ],
    );
  }

  Widget _buildTestCard(Map<String, dynamic> test) {
    final date = DateTime.tryParse(test['created_at'] as String? ?? '');
    final supineSystolic = test['supine_systolic'] as int?;
    final supineDiastolic = test['supine_diastolic'] as int?;
    final supineHr = test['supine_hr'] as int?;
    final standing1MinHr = test['standing_1min_hr'] as int?;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  date != null
                      ? DateFormat('MMM d, yyyy • h:mm a').format(date)
                      : 'Unknown date',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildTestMetric(
                    'Supine BP',
                    supineSystolic != null && supineDiastolic != null
                        ? '$supineSystolic/$supineDiastolic'
                        : 'N/A',
                  ),
                ),
                Expanded(
                  child: _buildTestMetric(
                    'Supine HR',
                    supineHr != null ? '$supineHr bpm' : 'N/A',
                  ),
                ),
                Expanded(
                  child: _buildTestMetric(
                    'Standing HR',
                    standing1MinHr != null ? '$standing1MinHr bpm' : 'N/A',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestMetric(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildRecentSymptomsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Symptoms',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            if (_symptomLogs.isNotEmpty)
              TextButton(
                onPressed: _viewEpisodeHistory,
                child: const Text('View All'),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (_symptomLogs.isEmpty)
          _buildEmptyState('No symptoms logged', Icons.favorite_border)
        else
          ..._symptomLogs.take(3).map((log) => _buildSymptomCard(log)).toList(),
      ],
    );
  }

  Widget _buildSymptomCard(Map<String, dynamic> log) {
    final timestamp = DateTime.tryParse(log['timestamp'] as String? ?? '');
    final symptoms = List<String>.from(log['symptoms'] as List? ?? []);
    final severity = log['severity'] as int? ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  timestamp != null
                      ? DateFormat('MMM d, h:mm a').format(timestamp)
                      : 'Unknown time',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                _buildSeverityBadge(severity),
              ],
            ),
            if (symptoms.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: symptoms
                    .take(5)
                    .map((s) => _buildSymptomChip(s))
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSymptomChip(String symptom) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF20B2AA).withOpacity(0.1),
        border: Border.all(color: const Color(0xFF20B2AA)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        symptom,
        style: const TextStyle(
          fontSize: 11,
          color: Color(0xFF20B2AA),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildSeverityBadge(int severity) {
    Color color;
    if (severity >= 7) {
      color = Colors.red;
    } else if (severity >= 4) {
      color = Colors.orange;
    } else {
      color = Colors.green;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        'Severity: $severity/10',
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(32),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(icon, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  int _calculateAverageHeartRate() {
    if (_standupTests.isEmpty) return 0;

    final heartRates = <int>[];
    for (final test in _standupTests) {
      final supineHr = test['supine_hr'] as int?;
      final standing1MinHr = test['standing_1min_hr'] as int?;
      final standing3MinHr = test['standing_3min_hr'] as int?;

      if (supineHr != null) heartRates.add(supineHr);
      if (standing1MinHr != null) heartRates.add(standing1MinHr);
      if (standing3MinHr != null) heartRates.add(standing3MinHr);
    }

    if (heartRates.isEmpty) return 0;

    return (heartRates.reduce((a, b) => a + b) / heartRates.length).round();
  }

  String _calculateAverageBP({required bool isSupine}) {
    if (_standupTests.isEmpty) return '';

    final systolicValues = <int>[];
    final diastolicValues = <int>[];

    for (final test in _standupTests) {
      final systolic = isSupine
          ? test['supine_systolic'] as int?
          : test['standing_1min_systolic'] as int?;
      final diastolic = isSupine
          ? test['supine_diastolic'] as int?
          : test['standing_1min_diastolic'] as int?;

      if (systolic != null) systolicValues.add(systolic);
      if (diastolic != null) diastolicValues.add(diastolic);
    }

    if (systolicValues.isEmpty || diastolicValues.isEmpty) return '';

    final avgSystolic =
        (systolicValues.reduce((a, b) => a + b) / systolicValues.length)
            .round();
    final avgDiastolic =
        (diastolicValues.reduce((a, b) => a + b) / diastolicValues.length)
            .round();

    return '$avgSystolic/$avgDiastolic';
  }

  void _viewVossResults() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => VossResultsPage(patient: widget.patient),
      ),
    );
  }

  void _viewEpisodeHistory() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EpisodeHistoryPage(patient: widget.patient),
      ),
    );
  }
}
