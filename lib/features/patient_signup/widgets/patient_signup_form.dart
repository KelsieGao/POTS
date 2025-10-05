import 'dart:async';

import 'package:flutter/material.dart';

import '../models/patient_form_data.dart';
import '../providers/patient_signup_controller.dart';

class PatientSignupForm extends StatefulWidget {
  const PatientSignupForm({super.key, required this.controller});

  final PatientSignupController controller;

  @override
  State<PatientSignupForm> createState() => _PatientSignupFormState();
}

class _PatientSignupFormState extends State<PatientSignupForm> {
  final _formKey = GlobalKey<FormState>();
  late PatientFormData _data;

  @override
  void initState() {
    super.initState();
    _data = widget.controller.data;
    widget.controller.addListener(_handleControllerUpdate);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleControllerUpdate);
    super.dispose();
  }

  void _handleControllerUpdate() {
    if (!mounted) {
      return;
    }
    setState(() {
      _data = widget.controller.data;
    });
  }

  Future<void> _submit() async {
    final form = _formKey.currentState;
    if (form == null) {
      return;
    }

    if (!form.validate()) {
      return;
    }
    form.save();
    await widget.controller.submit();
  }

  @override
  Widget build(BuildContext context) {
    final status = widget.controller.status;
    final isSubmitting = status == PatientSignupStatus.submitting;
    final hasError = status == PatientSignupStatus.error;

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'Welcome! Let’s get to know you.',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Fill out the details below to create your profile.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          _buildNameRow(),
          const SizedBox(height: 16),
          _buildDateOfBirthField(context),
          const SizedBox(height: 16),
          _buildEmailField(),
          const SizedBox(height: 16),
          _buildPhoneField(),
          const SizedBox(height: 16),
          _buildHeightWeightRow(),
          const SizedBox(height: 16),
          _buildPrimaryPhysicianField(),
          const SizedBox(height: 16),
          _buildSexAssignedAtBirthField(),
          const SizedBox(height: 16),
          _buildReasonField(),
          const SizedBox(height: 24),
          if (hasError && widget.controller.errorMessage != null)
            _ErrorBanner(message: widget.controller.errorMessage!),
          if (hasError && widget.controller.errorMessage != null)
            const SizedBox(height: 16),
          FilledButton(
            onPressed: isSubmitting ? null : _submit,
            child: isSubmitting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Continue'),
          ),
        ],
      ),
    );
  }

  Widget _buildNameRow() {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            initialValue: _data.firstName,
            decoration: const InputDecoration(
              labelText: 'First Name',
              border: OutlineInputBorder(),
            ),
            textCapitalization: TextCapitalization.words,
            validator: (value) =>
                value == null || value.trim().isEmpty ? 'Required' : null,
            onSaved: (value) {
              widget.controller.updateData(
                _data.copyWith(firstName: value?.trim() ?? ''),
              );
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: TextFormField(
            initialValue: _data.lastName,
            decoration: const InputDecoration(
              labelText: 'Last Name',
              border: OutlineInputBorder(),
            ),
            textCapitalization: TextCapitalization.words,
            validator: (value) =>
                value == null || value.trim().isEmpty ? 'Required' : null,
            onSaved: (value) {
              widget.controller.updateData(
                _data.copyWith(lastName: value?.trim() ?? ''),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDateOfBirthField(BuildContext context) {
    return InkWell(
      onTap: () async {
        final selected = await showDatePicker(
          context: context,
          initialDate: _data.dateOfBirth,
          firstDate: DateTime(1900),
          lastDate: DateTime.now(),
        );
        if (selected != null) {
          widget.controller.updateData(_data.copyWith(dateOfBirth: selected));
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Date of Birth',
          border: OutlineInputBorder(),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              MaterialLocalizations.of(
                context,
              ).formatMediumDate(_data.dateOfBirth),
            ),
            const Icon(Icons.calendar_today),
          ],
        ),
      ),
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      initialValue: _data.email,
      decoration: const InputDecoration(
        labelText: 'Email (optional)',
        border: OutlineInputBorder(),
      ),
      keyboardType: TextInputType.emailAddress,
      onSaved: (value) {
        widget.controller.updateData(
          _data.copyWith(email: value?.trim() ?? ''),
        );
      },
    );
  }

  Widget _buildPhoneField() {
    return TextFormField(
      initialValue: _data.phone,
      decoration: const InputDecoration(
        labelText: 'Phone (optional)',
        border: OutlineInputBorder(),
      ),
      keyboardType: TextInputType.phone,
      onSaved: (value) {
        widget.controller.updateData(
          _data.copyWith(phone: value?.trim() ?? ''),
        );
      },
    );
  }

  Widget _buildHeightWeightRow() {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            initialValue: _data.heightCm?.toString() ?? '',
            decoration: const InputDecoration(
              labelText: 'Height (cm)',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            onSaved: (value) {
              final parsed = int.tryParse(value ?? '');
              widget.controller.updateData(_data.copyWith(heightCm: parsed));
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: TextFormField(
            initialValue: _data.weightKg?.toString() ?? '',
            decoration: const InputDecoration(
              labelText: 'Weight (kg)',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            onSaved: (value) {
              final parsed = double.tryParse(value ?? '');
              widget.controller.updateData(_data.copyWith(weightKg: parsed));
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPrimaryPhysicianField() {
    return TextFormField(
      initialValue: _data.primaryCarePhysician,
      decoration: const InputDecoration(
        labelText: 'Primary Care Physician (optional)',
        border: OutlineInputBorder(),
      ),
      onSaved: (value) {
        widget.controller.updateData(
          _data.copyWith(primaryCarePhysician: value?.trim() ?? ''),
        );
      },
    );
  }

  Widget _buildSexAssignedAtBirthField() {
    return DropdownButtonFormField<String>(
      initialValue: _data.sexAssignedAtBirth,
      decoration: const InputDecoration(
        labelText: 'Sex assigned at birth',
        border: OutlineInputBorder(),
      ),
      items: sexAssignedAtBirthOptions
          .map(
            (value) =>
                DropdownMenuItem<String>(value: value, child: Text(value)),
          )
          .toList(),
      validator: (value) => value == null ? 'Required' : null,
      onChanged: (value) {
        widget.controller.updateData(_data.copyWith(sexAssignedAtBirth: value));
      },
    );
  }

  Widget _buildReasonField() {
    return DropdownButtonFormField<String>(
      initialValue: _data.reasonForUsingApp,
      decoration: const InputDecoration(
        labelText: 'Why are you using this app?',
        border: OutlineInputBorder(),
      ),
      items: reasonForUsingAppOptions
          .map(
            (value) =>
                DropdownMenuItem<String>(value: value, child: Text(value)),
          )
          .toList(),
      validator: (value) => value == null ? 'Required' : null,
      onChanged: (value) {
        widget.controller.updateData(_data.copyWith(reasonForUsingApp: value));
      },
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        message,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onErrorContainer,
        ),
      ),
    );
  }
}
