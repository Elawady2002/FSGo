import 'dart:io';
import '../models/user_model.dart';

/// Abstract interface for the authentication data source.
/// Consumers depend on this contract, not on the Supabase implementation,
/// making the data source swappable and testable.
abstract class AuthDataSource {
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
    String? city,
    String? cityId,
  });

  Future<UserModel> signIn({
    required String email,
    required String password,
  });

  Future<void> signOut();

  Future<UserModel?> getCurrentUser();

  Stream<UserModel?> authStateChanges();

  Future<UserModel> verifyOtp({
    required String email,
    required String otp,
  });

  Future<void> resendOtp({required String email});

  Future<void> resetPassword({required String email});

  Future<UserModel> updateProfile({
    required String userId,
    required String fullName,
    required String phone,
    String? avatarUrl,
  });

  Future<String> uploadProfileImage({
    required File image,
    required String userId,
  });
}
