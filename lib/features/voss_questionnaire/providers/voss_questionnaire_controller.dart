import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/voss_questionnaire_data.dart';
import '../services/voss_questionnaire_service.dart';

enum VossQuestionnaireStatus { editing, submitting, completed, error }

class VossQuestionnaireController extends ChangeNotifier {
  VossQuestionnaireController({
    required this.patientId,
    VossQuestionnaireService? service,
  }) : _service = service ?? VossQuestionnaireService();

  final String patientId;
  final VossQuestionnaireService _service;

  VossQuestionnaireData data = VossQuestionnaireData();
  VossQuestionnaireStatus status = VossQuestionnaireStatus.editing;
  String? errorMessage;

  void updateResponse(String id, int value) {
    data = data.copyWithResponse(id, value);
    notifyListeners();
  }

  Future<void> submit() async {
    status = VossQuestionnaireStatus.submitting;
    errorMessage = null;
    notifyListeners();

    try {
      await _service.submit(patientId: patientId, data: data);
      status = VossQuestionnaireStatus.completed;
    } on VossQuestionnaireException catch (error) {
      errorMessage = error.message;
      status = VossQuestionnaireStatus.error;
    } catch (error) {
      errorMessage = 'Unexpected error: $error';
      status = VossQuestionnaireStatus.error;
    }

    notifyListeners();
  }
}
