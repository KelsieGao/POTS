import 'package:flutter/material.dart';

import 'providers/patient_signup_controller.dart';
import 'widgets/patient_signup_form.dart';

class PatientSignupPage extends StatefulWidget {
  const PatientSignupPage({super.key, required this.controller});

  final PatientSignupController controller;

  @override
  State<PatientSignupPage> createState() => _PatientSignupPageState();
}

class _PatientSignupPageState extends State<PatientSignupPage> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_handleControllerUpdate);
  }

  void _handleControllerUpdate() {
    if (!mounted) {
      return;
    }
    if (widget.controller.status == PatientSignupStatus.completed) {
      Navigator.of(context).maybePop();
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleControllerUpdate);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Patient Profile')),
      body: PatientSignupForm(controller: widget.controller),
    );
  }
}
