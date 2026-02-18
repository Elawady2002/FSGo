import 'dart:io';
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/domain/entities/user_entity.dart';

/// Authentication repository interface
/// This defines the contract for authentication operations
abstract class AuthRepository {
  /// Sign up a new user with email and password
  Future<Either<Failure, UserEntity>> signUp({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    String? studentId,
    String? universityId,
  });

  /// Sign in an existing user with email and password
  Future<Either<Failure, UserEntity>> signIn({
    required String email,
    required String password,
  });

  /// Sign out the current user
  Future<Either<Failure, void>> signOut();

  /// Get the currently authenticated user
  /// Returns null if no user is authenticated
  Future<Either<Failure, UserEntity?>> getCurrentUser();

  /// Stream of authentication state changes
  /// Emits null when user is signed out, and UserEntity when signed in
  Stream<UserEntity?> authStateChanges();

  /// Verify OTP code
  Future<Either<Failure, UserEntity>> verifyOtp({
    required String email,
    required String otp,
  });

  /// Resend OTP code
  Future<Either<Failure, void>> resendOtp({required String email});

  /// Send password reset email
  Future<Either<Failure, void>> resetPassword({required String email});

  /// Update user profile
  Future<Either<Failure, UserEntity>> updateProfile({
    required String userId,
    required String fullName,
    required String phone,
    String? avatarUrl,
  });

  /// Upload profile image
  Future<Either<Failure, String>> uploadProfileImage({
    required File image,
    required String userId,
  });
}
