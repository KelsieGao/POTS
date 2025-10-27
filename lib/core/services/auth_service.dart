import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

class AuthService {
  static SupabaseClient get _client => SupabaseService.client;
  
  /// Get current user
  static User? get currentUser => _client.auth.currentUser;
  
  /// Check if user is signed in
  static bool get isSignedIn => currentUser != null;
  
  /// Get current session
  static Session? get currentSession => _client.auth.currentSession;
  
  /// Send OTP code to email
  static Future<void> sendOTP({required String email}) async {
    try {
      await _client.auth.signInWithOtp(
        email: email,
        shouldCreateUser: false, // Don't create user, just send code
      );
    } catch (e) {
      throw Exception('Failed to send OTP code: $e');
    }
  }

  /// Sign up and send OTP code (for email verification)
  static Future<User> signUpAndSendOTP({
    required String email,
    required String password,
    String? firstName,
    String? lastName,
  }) async {
    try {
      // Create user account with email confirmation
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: {
          'first_name': firstName,
          'last_name': lastName,
        },
      );
      
      if (response.user == null) {
        throw Exception('Failed to create user');
      }
      
      // If email confirmation is enabled, send OTP code
      await _client.auth.signInWithOtp(
        email: email,
        shouldCreateUser: false,
      );
      
      return response.user!;
    } catch (e) {
      throw Exception('Failed to sign up: $e');
    }
  }
  
  /// Update user password after email verification
  static Future<void> updatePassword(String newPassword) async {
    try {
      await _client.auth.updateUser(
        UserAttributes(password: newPassword),
      );
    } catch (e) {
      throw Exception('Failed to update password: $e');
    }
  }
  
  /// Get current user (for checking if signed in)
  User? get currentUserInstance => _client.auth.currentUser;
  
  /// Verify email with code using OTP
  static Future<void> verifyEmail(String code) async {
    try {
      final response = await _client.auth.verifyOTP(
        type: OtpType.signup,
        token: code,
      );
      
      if (response.user == null) {
        throw Exception('Failed to verify email');
      }
    } catch (e) {
      throw Exception('Failed to verify email: $e');
    }
  }
  
  /// Sign in with email and password
  static Future<Session> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      
      if (response.session == null) {
        throw Exception('Sign in failed');
      }
      
      return response.session!;
    } catch (e) {
      throw Exception('Invalid email or password');
    }
  }
  
  /// Sign out
  static Future<void> signOut() async {
    await _client.auth.signOut();
  }
  
  /// Create basic patient profile after signup (minimal fields)
  static Future<void> createBasicPatientProfile({
    required String userId,
    required String firstName,
    required String lastName,
  }) async {
    try {
      final now = DateTime.now();
      
      // First, check if patient already exists
      final existing = await _client
          .from('patients')
          .select()
          .eq('id', userId)
          .maybeSingle();
      
      if (existing != null) {
        // Patient already exists, just return
        return;
      }
      
      // Create new patient record
      await _client.from('patients').insert({
        'id': userId,
        'first_name': firstName,
        'last_name': lastName,
        'date_of_birth': now.toIso8601String(), // Placeholder, will be updated
        'sex_assigned_at_birth': 'Other', // Placeholder, will be updated
        'reason_for_using_app': 'Other', // Placeholder, will be updated
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to create patient profile: $e');
    }
  }

  /// Create patient profile after signup
  static Future<void> createPatientProfile({
    required String userId,
    required String firstName,
    required String lastName,
    DateTime? dateOfBirth,
    String? sexAssignedAtBirth,
    String? reasonForUsingApp,
  }) async {
    try {
      final now = DateTime.now().toIso8601String();
      await _client.from('patients').insert({
        'id': userId,
        'first_name': firstName,
        'last_name': lastName,
        'date_of_birth': dateOfBirth?.toIso8601String() ?? now,
        'sex_assigned_at_birth': sexAssignedAtBirth ?? 'Other',
        'reason_for_using_app': reasonForUsingApp ?? 'Other',
        'created_at': now,
        'updated_at': now,
      });
    } catch (e) {
      throw Exception('Failed to create patient profile: $e');
    }
  }
  
  /// Resend verification email
  static Future<void> resendVerificationEmail() async {
    try {
      await _client.auth.resend(
        type: OtpType.email,
      );
    } catch (e) {
      throw Exception('Failed to resend verification email: $e');
    }
  }
}

