import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/services/supabase_service.dart';
import '../../models/clinician_models.dart';

class EpisodeHistoryPage extends StatefulWidget {
  final PatientSummary patient;

  const EpisodeHistoryPage({
    super.key,
    required this.patient,
  });

  @override
  State<EpisodeHistoryPage> createState() => _EpisodeHistoryPageState();
}

class _EpisodeHistoryPageState extends State<EpisodeHistoryPage> {
  List<Map<String, dynamic>> _episodes = [];
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
          .from('symptom_logs')
          .select()
          .eq('patient_id', widget.patient.patientId)
          .order('timestamp', ascending: false);

      setState(() {
        _episodes = List<Map<String, dynamic>>.from(response);
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
          'Episode History',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black87),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _episodes.isEmpty
              ? _buildEmptyState()
              : _buildEpisodeList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.timeline,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            const Text(
              'No episodes recorded',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'This patient has not logged any symptom episodes yet.',
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

  Widget _buildEpisodeList() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _episodes.length,
        itemBuilder: (context, index) {
          return _buildEpisodeCard(_episodes[index]);
        },
      ),
    );
  }

  Widget _buildEpisodeCard(Map<String, dynamic> episode) {
    final timestamp = DateTime.tryParse(episode['timestamp'] as String? ?? '');
    final symptoms = List<String>.from(episode['symptoms'] as List? ?? []);
    final severity = episode['severity'] as int? ?? 0;
    final timeOfDay = episode['time_of_day'] as String?;
    final activityType = episode['activity_type'] as String?;
    final otherDetails = episode['other_details'] as String?;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
        ),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.all(16),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          title: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      timestamp != null
                          ? DateFormat('EEEE, MMM d, yyyy').format(timestamp)
                          : 'Unknown date',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      timestamp != null
                          ? DateFormat('h:mm a').format(timestamp)
                          : 'Unknown time',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              _buildSeverityBadge(severity),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              if (symptoms.isNotEmpty)
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: symptoms
                      .map((s) => _buildSymptomChip(s))
                      .toList(),
                ),
            ],
          ),
          children: [
            const Divider(height: 24),
            _buildDetailsSection(timeOfDay, activityType, otherDetails),
          ],
        ),
      ),
    );
  }

  Widget _buildSeverityBadge(int severity) {
    Color color;
    String label;

    if (severity >= 7) {
      color = Colors.red;
      label = 'Severe';
    } else if (severity >= 4) {
      color = Colors.orange;
      label = 'Moderate';
    } else {
      color = Colors.green;
      label = 'Mild';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '$label ($severity/10)',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSymptomChip(String symptom) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF20B2AA).withOpacity(0.1),
        border: Border.all(color: const Color(0xFF20B2AA)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        symptom,
        style: const TextStyle(
          fontSize: 12,
          color: Color(0xFF20B2AA),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildDetailsSection(
    String? timeOfDay,
    String? activityType,
    String? otherDetails,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (timeOfDay != null && timeOfDay.isNotEmpty)
          _buildDetailRow(
            Icons.access_time,
            'Time of Day',
            timeOfDay,
          ),
        if (activityType != null && activityType.isNotEmpty) ...[
          const SizedBox(height: 12),
          _buildDetailRow(
            Icons.directions_walk,
            'Activity',
            activityType,
          ),
        ],
        if (otherDetails != null && otherDetails.isNotEmpty) ...[
          const SizedBox(height: 12),
          _buildDetailRow(
            Icons.note_alt_outlined,
            'Additional Details',
            otherDetails,
          ),
        ],
        if (timeOfDay == null &&
            activityType == null &&
            (otherDetails == null || otherDetails.isEmpty))
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'No additional details recorded',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: const Color(0xFF2196F3),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
