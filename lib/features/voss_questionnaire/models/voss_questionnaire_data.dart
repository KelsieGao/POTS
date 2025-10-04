class VossQuestion {
  const VossQuestion({required this.id, required this.label});

  final String id;
  final String label;
}

const vossQuestions = <VossQuestion>[
  VossQuestion(id: 'mental_clouding', label: 'Mental clouding ("brain fog")'),
  VossQuestion(id: 'blurred_vision', label: 'Blurred vision'),
  VossQuestion(id: 'shortness_of_breath', label: 'Shortness of breath'),
  VossQuestion(id: 'rapid_heartbeat', label: 'Rapid heartbeat / palpitations'),
  VossQuestion(id: 'tremulousness', label: 'Tremulousness (shakiness)'),
  VossQuestion(id: 'chest_discomfort', label: 'Chest discomfort'),
  VossQuestion(id: 'headache', label: 'Headache'),
  VossQuestion(id: 'light_headedness', label: 'Light-headedness / dizziness'),
  VossQuestion(id: 'nausea', label: 'Nausea'),
];

class VossQuestionnaireData {
  VossQuestionnaireData({Map<String, int>? responses})
    : responses = {
        for (final question in vossQuestions)
          question.id: responses?[question.id] ?? 0,
      };

  final Map<String, int> responses;

  int get totalScore => responses.values.fold(0, (sum, value) => sum + value);

  VossQuestionnaireData copyWithResponse(String id, int value) {
    final updated = Map<String, int>.from(responses)..[id] = value;
    return VossQuestionnaireData(responses: updated);
  }
}
