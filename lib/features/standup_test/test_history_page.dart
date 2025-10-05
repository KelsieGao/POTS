import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:pots/models/generated_classes.dart';
import 'services/standup_test_service.dart';

class TestHistoryPage extends StatefulWidget {
  const TestHistoryPage({
    super.key,
    required this.patientId,
  });

  final String patientId;

  @override
  State<TestHistoryPage> createState() => _TestHistoryPageState();
}

class _TestHistoryPageState extends State<TestHistoryPage> {
  final StandupTestService _service = StandupTestService();
  late Future<List<StandupTests>> _testsFuture;

  @override
  void initState() {
    super.initState();
    _testsFuture = _service.getTestHistory(patientId: widget.patientId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _testsFuture = _service.getTestHistory(patientId: widget.patientId);
              });
            },
          ),
        ],
      ),
      body: FutureBuilder<List<StandupTests>>(
        future: _testsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to load test history',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${snapshot.error}',
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () {
                      setState(() {
                        _testsFuture = _service.getTestHistory(patientId: widget.patientId);
                      });
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final tests = snapshot.data ?? [];

          if (tests.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.assignment_outlined,
                    size: 64,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No tests completed yet',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Complete your first sit/stand test to see your history here.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: tests.length,
            itemBuilder: (context, index) {
              final test = tests[index];
              return _TestHistoryCard(test: test);
            },
          );
        },
      ),
    );
  }
}

class _TestHistoryCard extends StatelessWidget {
  const _TestHistoryCard({required this.test});

  final StandupTests test;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, yyyy');
    final timeFormat = DateFormat('h:mm a');

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        title: Row(
          children: [
            Icon(
              Icons.favorite,
              color: Theme.of(context).colorScheme.primary,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Sit/Stand Test',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              dateFormat.format(test.testDate),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (test.testTime != null)
              Text(
                timeFormat.format(test.testTime!),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTestResults(context),
                if (test.notes != null && test.notes!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildNotes(context),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTestResults(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Test Results',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        _buildResultRow(context, 'Supine BP', test.supineSystolic, test.supineDiastolic),
        _buildResultRow(context, 'Supine HR', test.supineHr, null, unit: 'bpm'),
        const SizedBox(height: 8),
        _buildResultRow(context, '1-min Standing BP', test.standing1minSystolic, test.standing1minDiastolic),
        _buildResultRow(context, '1-min Standing HR', test.standing1minHr, null, unit: 'bpm'),
        const SizedBox(height: 8),
        _buildResultRow(context, '3-min Standing BP', test.standing3minSystolic, test.standing3minDiastolic),
        _buildResultRow(context, '3-min Standing HR', test.standing3minHr, null, unit: 'bpm'),
        const SizedBox(height: 8),
        _buildResultRow(context, '5-min Standing HR', test.standing5minHr, null, unit: 'bpm'),
        _buildResultRow(context, '10-min Standing HR', test.standing10minHr, null, unit: 'bpm'),
      ],
    );
  }

  Widget _buildResultRow(BuildContext context, String label, int? value1, int? value2, {String? unit}) {
    String? displayValue;
    if (value1 != null && value2 != null) {
      displayValue = '$value1/$value2';
    } else if (value1 != null) {
      displayValue = value1.toString();
    }

    if (displayValue != null && unit != null) {
      displayValue += ' $unit';
    } else if (displayValue != null && value2 == null) {
      displayValue += ' mmHg';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          Text(
            displayValue ?? 'Not recorded',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
              color: displayValue != null 
                  ? Theme.of(context).colorScheme.onSurface
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotes(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Notes',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            test.notes!,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ],
    );
  }
}
