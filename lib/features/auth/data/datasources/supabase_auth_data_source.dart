import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/logger_service.dart';
import '../../../../core/domain/entities/user_entity.dart';
import '../models/user_model.dart';
import 'auth_data_source.dart';

/// Supabase implementation of [AuthDataSource].
/// Handles all direct communication with Supabase Auth.
class SupabaseAuthDataSource implements AuthDataSource {
  final SupabaseClient _client;

  SupabaseAuthDataSource(this._client);

  /// Sign up a new user with email and password
  Future<UserModel> signUp({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    String? studentId,
    String? universityId,
    String userType = 'driver',
    String? officeName,
    String? stationName,
  }) async {
    try {
      // Sign up with Supabase Auth
      final authResponse = await _client.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName,
          'phone': phone,
          'student_id': studentId,
          'university_id': universityId,
          'user_type': userType,
        },
      );

      if (authResponse.user == null) {
        throw Exception('Failed to create user account');
      }

      final userId = authResponse.user!.id;
      final isVerified = authResponse.session != null;

      // Insert user data into users table and return it immediately
      final userData = {
        'id': userId,
        'email': email,
        'phone': phone,
        'full_name': fullName,
        'student_id': studentId,
        'university_id': universityId,
        'user_type': userType,
        'is_verified': isVerified,
        'created_at': DateTime.now().toIso8601String(),
        'office_name': officeName,
        'station_name': stationName,
      };

      try {
        await _client.from('users').insert(userData);

        // Return user from local data to avoid RLS race conditions
        return UserModel.fromJson(userData);
      } on PostgrestException catch (e) {
        // 23505 = unique violation — a Supabase trigger already inserted the
        // row before our manual insert. Fetch the existing record and return it.
        if (e.code == '23505') {
          final existing = await _client
              .from('users')
              .select()
              .eq('id', userId)
              .maybeSingle();
          if (existing != null) {
            return UserModel.fromJson(existing);
          }
        }
        rethrow;
      }
    } on AuthException catch (e) {
      throw Exception('Authentication error: ${e.message}');
    } on PostgrestException catch (e) {
      if (e.message.contains('users_email_key')) {
        throw Exception('البريد الإلكتروني مسجل بالفعل. الرجاء تسجيل الدخول.');
      }
      throw Exception('Database error: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error during sign up: $e');
    }
  }

  /// Sign in an existing user with email and password
  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final authResponse = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (authResponse.user == null) {
        throw Exception('Failed to sign in');
      }

      final userId = authResponse.user!.id;

      // Fetch user data from users table
      final response = await _client
          .from('users')
          .select()
          .eq('id', userId)
          .maybeSingle(); // Use maybeSingle() to handle 0 or 1 results

      if (response == null) {
        // Attempt to recover user data from Auth metadata if missing in public table
        LoggerService.warning(
          'User $userId not found in public.users table. Attempting recovery...',
        );

        final user = authResponse.user!;
        final metadata = user.userMetadata;

        if (metadata == null || !metadata.containsKey('full_name')) {
          throw Exception(
            'حساب المستخدم غير موجود في قاعدة البيانات، ولا توجد بيانات كافية لاستعادته. يرجى التواصل مع الدعم.',
          );
        }

        // Reconstruct user data
        final recoveredUserData = {
          'id': userId,
          'email': email,
          'phone': metadata['phone'] ?? '',
          'full_name': metadata['full_name'] ?? '',
          'student_id': metadata['student_id'],
          'university_id': metadata['university_id'],
          'user_type': 'student',
          'is_verified': true, // Since they just logged in successfully
          'created_at': DateTime.now().toIso8601String(),
        };

        try {
          await _client.from('users').insert(recoveredUserData);
          LoggerService.info('User $userId recovered to public.users table');
          return UserModel.fromJson(recoveredUserData);
        } on PostgrestException catch (e) {
          // Trigger already inserted the row — just fetch it
          if (e.code == '23505') {
            final existing = await _client
                .from('users')
                .select()
                .eq('id', userId)
                .maybeSingle();
            if (existing != null) return UserModel.fromJson(existing);
          }
          LoggerService.error('Failed to recover user', error: e);
          throw Exception(
            'حساب المستخدم غير موجود في قاعدة البيانات. فشلت محاولة الاستعادة التلقائية. يرجى التواصل مع الدعم.',
          );
        } catch (recoveryError) {
          LoggerService.error('Failed to recover user', error: recoveryError);
          throw Exception(
            'حساب المستخدم غير موجود في قاعدة البيانات. فشلت محاولة الاستعادة التلقائية. يرجى التواصل مع الدعم.',
          );
        }
      }

      return UserModel.fromJson(response);
    } on AuthException catch (e) {
      if (e.message.contains('Invalid login credentials')) {
        throw Exception(
          'بيانات الدخول غير صحيحة، أو لم يتم تفعيل البريد الإلكتروني.',
        );
      }
      throw Exception('Authentication error: ${e.message}');
    } on PostgrestException catch (e) {
      LoggerService.error(
        'Database error in signIn: ${e.message}. Code: ${e.code}, Details: ${e.details}',
        error: e,
      );
      throw Exception('Database error: ${e.message}');
    } catch (e) {
      LoggerService.error('Unexpected error in signIn', error: e);
      throw Exception('Unexpected error during sign in: $e');
    }
  }

  /// Sign out the current user
  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } on AuthException catch (e) {
      throw Exception('Sign out error: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error during sign out: $e');
    }
  }

  /// Get the currently authenticated user
  Future<UserModel?> getCurrentUser() async {
    try {
      final session = _client.auth.currentSession;
      if (session == null) {
        return null;
      }

      final userId = session.user.id;

      final response = await _client
          .from('users')
          .select()
          .eq('id', userId)
          .maybeSingle(); // Use maybeSingle() instead of single() to handle 0 or 1 results

      if (response == null) {
        // User not found in database, but has auth session
        // This shouldn't happen, but we'll return null gracefully
        LoggerService.warning(
          'User $userId has auth session but no database record',
        );
        return null;
      }

      return UserModel.fromJson(response);
    } on PostgrestException catch (e) {
      LoggerService.error(
        'Database error in getCurrentUser: ${e.message}. Code: ${e.code}, Details: ${e.details}',
        error: e,
      );
      throw Exception('Database error: ${e.message}');
    } catch (e) {
      LoggerService.error('Unexpected error in getCurrentUser', error: e);
      // No user authenticated
      return null;
    }
  }

  /// Stream of authentication state changes
  Stream<UserModel?> authStateChanges() {
    return _client.auth.onAuthStateChange.asyncExpand((data) async* {
      final session = data.session;
      if (session == null) {
        yield null;
        return;
      }

      try {
        final authUser = session.user;
        final metadata = authUser.userMetadata ?? {};

        // 1. Emit initial user data from Auth metadata immediately to avoid blocking the UI
        LoggerService.info(
          'Auth: Emitting initial user from metadata for ${authUser.id}',
        );
        yield UserModel(
          id: authUser.id,
          email: authUser.email ?? '',
          phone: metadata['phone'] ?? '',
          fullName: metadata['full_name'] ?? 'مستخدم',
          userType: UserType.fromJson(metadata['user_type'] ?? 'student'),
          studentId: metadata['student_id'],
          universityId: metadata['university_id'],
          avatarUrl: metadata['avatar_url'],
          isVerified: true,
          createdAt: DateTime.tryParse(authUser.createdAt) ?? DateTime.now(),
        );

        // 2. Fetch full profile from DB in background
        final userId = authUser.id;
        final response = await _client
            .from('users')
            .select()
            .eq('id', userId)
            .maybeSingle();

        if (response != null) {
          LoggerService.info('Auth: Full profile loaded for $userId');
          yield UserModel.fromJson(response);
        } else {
          LoggerService.warning('Auth: No database record found for $userId');
        }
      } catch (e) {
        LoggerService.error('Error in authStateChanges', error: e);
        // We already yielded the metadata version, so the app is at least usable
      }
    });
  }

  /// Verify OTP code
  Future<UserModel> verifyOtp({
    required String email,
    required String otp,
  }) async {
    try {
      final authResponse = await _client.auth.verifyOTP(
        email: email,
        token: otp,
        type: OtpType.signup,
      );

      if (authResponse.user == null) {
        throw Exception('Failed to verify OTP');
      }

      final userId = authResponse.user!.id;

      // Update user verification status
      await _client
          .from('users')
          .update({'is_verified': true})
          .eq('id', userId);

      // Fetch updated user data
      final response = await _client
          .from('users')
          .select()
          .eq('id', userId)
          .maybeSingle(); // Use maybeSingle() to handle 0 or 1 results

      if (response == null) {
        throw Exception('فشل في جلب بيانات المستخدم بعد التحقق.');
      }

      return UserModel.fromJson(response);
    } on AuthException catch (e) {
      throw Exception('OTP verification error: ${e.message}');
    } on PostgrestException catch (e) {
      LoggerService.error('Database error in verifyOtp: ${e.message}');
      throw Exception('Database error: ${e.message}');
    } catch (e) {
      LoggerService.error('Unexpected error in verifyOtp', error: e);
      throw Exception('Unexpected error during OTP verification: $e');
    }
  }

  /// Resend OTP code
  Future<void> resendOtp({required String email}) async {
    try {
      await _client.auth.resend(type: OtpType.signup, email: email);
    } on AuthException catch (e) {
      throw Exception('Failed to resend OTP: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error while resending OTP: $e');
    }
  }

  /// Send password reset email
  Future<void> resetPassword({required String email}) async {
    try {
      await _client.auth.resetPasswordForEmail(email);
    } on AuthException catch (e) {
      throw Exception('Failed to send reset password email: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error during password reset: $e');
    }
  }

  /// Update user profile
  Future<UserModel> updateProfile({
    required String userId,
    required String fullName,
    required String phone,
    String? avatarUrl,
  }) async {
    try {
      final updates = {
        'full_name': fullName,
        'phone': phone,
        'avatar_url': avatarUrl, // Always include, even if null
      };

      // Update user data in users table
      final response = await _client
          .from('users')
          .update(updates)
          .eq('id', userId)
          .select()
          .maybeSingle(); // Use maybeSingle() to handle 0 or 1 results

      if (response == null) {
        throw Exception('فشل في تحديث بيانات المستخدم.');
      }

      // Also update Supabase Auth metadata if needed
      await _client.auth.updateUser(UserAttributes(data: updates));

      return UserModel.fromJson(response);
    } on PostgrestException catch (e) {
      LoggerService.error(
        'Database error in updateProfile: ${e.message}. Code: ${e.code}, Details: ${e.details}',
        error: e,
      );
      throw Exception('Database error: ${e.message}');
    } on AuthException catch (e) {
      throw Exception('Auth update error: ${e.message}');
    } catch (e) {
      LoggerService.error('Unexpected error in updateProfile', error: e);
      throw Exception('Unexpected error during profile update: $e');
    }
  }

  /// Upload profile image
  Future<String> uploadProfileImage({
    required File image,
    required String userId,
  }) async {
    try {
      final fileExt = image.path.split('.').last;
      final fileName =
          '$userId/avatar_${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      final filePath = fileName;

      await _client.storage
          .from('avatars')
          .upload(
            filePath,
            image,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
          );

      final imageUrl = _client.storage.from('avatars').getPublicUrl(filePath);
      return imageUrl;
    } on StorageException catch (e) {
      throw Exception('Storage error: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error during image upload: $e');
    }
  }
}
