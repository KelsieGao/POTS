import 'package:flutter/material.dart';
import '../../core/services/supabase_service.dart';
import '../../models/clinician_models.dart';

class VossResultsPage extends StatefulWidget {
  final PatientSummary patient;

  const VossResultsPage({
    super.key,
    required this.patient,
  });

  @override
  State<VossResultsPage> createState() => _VossResultsPageState();
}

class _VossResultsPageState extends State<VossResultsPage> {
  Map<String, dynamic>? _vossData;
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
      final response = await SupabaseService.client
          .from('voss_questionnaires')
          .select()
          .eq('patient_id', widget.patient.patientId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      setState(() {
        _vossData = response;
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
        title: const Text(
          'VOSS Survey Results',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _vossData == null
              ? _buildNoDataState()
              : _buildResults(),
    );
  }

  Widget _buildNoDataState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.assignment_outlined,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            const Text(
              'No VOSS survey data',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'This patient has not completed the VOSS questionnaire yet.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.black38,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResults() {
    final totalScore = _vossData?['total_score'] as int? ?? 0;
    final maxScore = 90;
    final percentage = (totalScore / maxScore * 100).round();

    final severity = _getSeverity(totalScore);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildScoreCard(totalScore, maxScore, percentage),
          const SizedBox(height: 16),
          _buildSeverityCard(severity),
          const SizedBox(height: 16),
          _buildProgressBar(totalScore, maxScore),
          const SizedBox(height: 24),
          _buildInterpretation(severity),
          const SizedBox(height: 24),
          _buildAboutVoss(),
        ],
      ),
    );
  }

  Widget _buildScoreCard(int score, int maxScore, int percentage) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF2196F3),
            Color(0xFF00BCD4),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Total VOSS Score',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '$score',
            style: const TextStyle(
              fontSize: 64,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'out of $maxScore maximum',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '$percentage%',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeverityCard(Map<String, dynamic> severity) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: severity['color'] as Color,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: (severity['color'] as Color).withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            severity['icon'] as IconData,
            color: Colors.white,
            size: 32,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  severity['label'] as String,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  severity['range'] as String,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(int score, int maxScore) {
    return Container(
      padding: const EdgeInsets.all(20),
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
        children: [
          const Text(
            'Score Scale',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          Stack(
            children: [
              Container(
                height: 40,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Colors.green,
                      Colors.yellow,
                      Colors.orange,
                      Colors.red,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              Positioned(
                left: (score / maxScore * MediaQuery.of(context).size.width *
                        0.85)
                    .clamp(0, MediaQuery.of(context).size.width * 0.85),
                top: -10,
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '$score',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      width: 2,
                      height: 50,
                      color: Colors.black87,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildScaleLabel('0\nNone', Alignment.centerLeft),
              _buildScaleLabel('45\nModerate', Alignment.center),
              _buildScaleLabel('90\nSevere', Alignment.centerRight),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScaleLabel(String text, Alignment alignment) {
    return Expanded(
      child: Align(
        alignment: alignment,
        child: Text(
          text,
          textAlign: alignment == Alignment.centerLeft
              ? TextAlign.left
              : alignment == Alignment.centerRight
                  ? TextAlign.right
                  : TextAlign.center,
          style: const TextStyle(
            fontSize: 11,
            color: Colors.black54,
          ),
        ),
      ),
    );
  }

  Widget _buildInterpretation(Map<String, dynamic> severity) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2196F3).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF2196F3).withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.info_outline,
                color: Color(0xFF2196F3),
                size: 24,
              ),
              const SizedBox(width: 8),
              const Text(
                'Clinical Interpretation',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2196F3),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            severity['interpretation'] as String,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutVoss() {
    return Container(
      padding: const EdgeInsets.all(20),
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
        children: [
          const Text(
            'About VOSS',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          _buildInfoPoint('Measures orthostatic symptom severity'),
          _buildInfoPoint('Score range: 0-90 points'),
          _buildInfoPoint('Higher scores indicate greater symptom burden'),
          _buildInfoPoint('Used for POTS diagnosis and monitoring'),
        ],
      ),
    );
  }

  Widget _buildInfoPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.check_circle,
            size: 18,
            color: Color(0xFF20B2AA),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _getSeverity(int score) {
    if (score >= 45) {
      return {
        'label': 'High Symptom Burden',
        'range': 'Score 45-90',
        'color': Colors.red,
        'icon': Icons.warning,
        'interpretation':
            'This score indicates a high level of orthostatic symptoms. '
            'Significant impact on daily activities is expected. '
            'Comprehensive treatment and close monitoring are recommended.',
      };
    } else if (score >= 25) {
      return {
        'label': 'Moderate Symptom Burden',
        'range': 'Score 25-44',
        'color': Colors.orange,
        'icon': Icons.error_outline,
        'interpretation':
            'This score indicates a moderate level of orthostatic symptoms. '
            'Daily activities may be affected. '
            'Treatment strategies and lifestyle modifications should be discussed.',
      };
    } else {
      return {
        'label': 'Mild Symptom Burden',
        'range': 'Score 0-24',
        'color': Colors.green,
        'icon': Icons.check_circle,
        'interpretation':
            'This score indicates a mild level of orthostatic symptoms. '
            'Symptoms are present but generally manageable. '
            'Continue monitoring and maintain current treatment plan.',
      };
    }
  }
}
