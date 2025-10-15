import 'package:flutter/material.dart';
import '../../core/services/clinician_service.dart';
import '../../models/clinician_models.dart';
import 'clinician_home_page.dart';

class ClinicianCodeEntryPage extends StatefulWidget {
  const ClinicianCodeEntryPage({super.key});

  @override
  State<ClinicianCodeEntryPage> createState() => _ClinicianCodeEntryPageState();
}

class _ClinicianCodeEntryPageState extends State<ClinicianCodeEntryPage> {
  String _code = '';
  bool _isLoading = false;
  bool _showHelp = false;
  String? _errorMessage;

  static const int _minCodeLength = 6;

  void _onNumberPressed(String number) {
    if (_code.length < 12) {
      setState(() {
        _code += number;
        _errorMessage = null;
      });
    }
  }

  void _onDeletePressed() {
    if (_code.isNotEmpty) {
      setState(() {
        _code = _code.substring(0, _code.length - 1);
        _errorMessage = null;
      });
    }
  }

  void _onClearPressed() {
    setState(() {
      _code = '';
      _errorMessage = null;
    });
  }

  Future<void> _onSubmit() async {
    if (_code.length < _minCodeLength) {
      setState(() {
        _errorMessage = 'Code must be at least $_minCodeLength characters';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final clinician = await ClinicianService.authenticateWithCode(_code);

      if (!mounted) return;

      if (clinician == null) {
        setState(() {
          _errorMessage = 'Invalid clinician code. Please try again.';
          _isLoading = false;
        });
        return;
      }

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => ClinicianHomePage(clinician: clinician),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = 'Authentication failed. Please try again.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF2196F3),
              Color(0xFF00BCD4),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 400),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildHeader(),
                          const SizedBox(height: 32),
                          _buildCodeDisplay(),
                          if (_errorMessage != null) ...[
                            const SizedBox(height: 16),
                            _buildErrorMessage(),
                          ],
                          const SizedBox(height: 32),
                          _buildKeypad(),
                          const SizedBox(height: 24),
                          _buildSubmitButton(),
                          const SizedBox(height: 16),
                          _buildHelpSection(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.verified_user,
            size: 64,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Clinician Access',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Enter your clinician code',
          style: TextStyle(
            fontSize: 16,
            color: Colors.white.withOpacity(0.9),
          ),
        ),
      ],
    );
  }

  Widget _buildCodeDisplay() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        _code.isEmpty ? '______' : _code.toUpperCase(),
        style: const TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          letterSpacing: 8,
          fontFamily: 'monospace',
          color: Color(0xFF2196F3),
        ),
      ),
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade300),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _errorMessage!,
              style: TextStyle(
                color: Colors.red.shade700,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeypad() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
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
          _buildKeypadRow(['1', '2', '3']),
          const SizedBox(height: 12),
          _buildKeypadRow(['4', '5', '6']),
          const SizedBox(height: 12),
          _buildKeypadRow(['7', '8', '9']),
          const SizedBox(height: 12),
          _buildKeypadRow(['CLEAR', '0', 'DEL']),
        ],
      ),
    );
  }

  Widget _buildKeypadRow(List<String> keys) {
    return Row(
      children: keys.map((key) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: _buildKeypadButton(key),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildKeypadButton(String label) {
    final isSpecial = label == 'CLEAR' || label == 'DEL';

    return Material(
      color: isSpecial ? Colors.grey.shade200 : const Color(0xFF2196F3),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () {
          if (label == 'CLEAR') {
            _onClearPressed();
          } else if (label == 'DEL') {
            _onDeletePressed();
          } else {
            _onNumberPressed(label);
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 60,
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: isSpecial ? 14 : 24,
              fontWeight: FontWeight.bold,
              color: isSpecial ? Colors.grey.shade700 : Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading || _code.length < _minCodeLength
            ? null
            : _onSubmit,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF2196F3),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
        ),
        child: _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Text(
                'Sign In',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  Widget _buildHelpSection() {
    return Column(
      children: [
        TextButton.icon(
          onPressed: () {
            setState(() {
              _showHelp = !_showHelp;
            });
          },
          icon: Icon(
            _showHelp ? Icons.expand_less : Icons.expand_more,
            color: Colors.white,
          ),
          label: const Text(
            'Where do I find my code?',
            style: TextStyle(color: Colors.white),
          ),
        ),
        if (_showHelp) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'Your clinician code should be provided by your '
              'organization administrator. If you don\'t have a code, '
              'please contact support.',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ],
    );
  }
}
