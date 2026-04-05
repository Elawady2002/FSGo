import 'dart:io';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/domain/entities/user_entity.dart';
import 'auth_providers.dart';

part 'auth_provider.g.dart';

/// Authentication state provider
@riverpod
class Auth extends _$Auth {
  @override
  Stream<UserEntity?> build() {
    return ref.watch(authRepositoryProvider).authStateChanges();
  }

  /// Login with email and password
  Future<String?> login(String email, String password) async {
    final result = await ref
        .read(loginUseCaseProvider)(email: email, password: password);

    return result.fold((failure) => failure.message, (_) => null);
  }

  /// Sign up with email and password
  Future<String?> signup(
    String name,
    String email,
    String password,
    String phone, {
    String? studentId,
    String? universityId,
    String userType = 'driver',
    String? officeName,
    String? stationName,
  }) async {
    final result = await ref.read(signupUseCaseProvider)(
      email: email,
      password: password,
      fullName: name,
      phone: phone,
      studentId: studentId,
      universityId: universityId,
      userType: userType,
      officeName: officeName,
      stationName: stationName,
    );

    return result.fold((failure) => failure.message, (_) => null);
  }

  /// Verify OTP code
  Future<String?> verifyOtp(String otp, String email) async {
    final result = await ref
        .read(authRepositoryProvider)
        .verifyOtp(email: email, otp: otp);

    return result.fold((failure) => failure.message, (_) => null);
  }

  /// Resend OTP code
  Future<String?> resendOtp(String email) async {
    final result = await ref
        .read(authRepositoryProvider)
        .resendOtp(email: email);

    return result.fold((failure) => failure.message, (_) => null);
  }

  /// Send reset password email
  Future<String?> resetPassword(String email) async {
    final result = await ref
        .read(authRepositoryProvider)
        .resetPassword(email: email);

    return result.fold((failure) => failure.message, (_) => null);
  }

  /// Update user profile
  Future<String?> updateProfile({
    required String fullName,
    required String phone,
    String? avatarUrl,
  }) async {
    final currentUser = state.value;
    if (currentUser == null) {
      return 'User not authenticated';
    }

    final result = await ref
        .read(authRepositoryProvider)
        .updateProfile(
          userId: currentUser.id,
          fullName: fullName,
          phone: phone,
          avatarUrl: avatarUrl,
        );

    return result.fold((failure) => failure.message, (_) => null);
  }

  /// Upload profile image
  Future<String?> uploadProfileImage(File image) async {
    final currentUser = state.value;
    if (currentUser == null) {
      return 'User not authenticated';
    }

    // 1. Upload image
    final uploadResult = await ref
        .read(authRepositoryProvider)
        .uploadProfileImage(image: image, userId: currentUser.id);

    return uploadResult.fold((failure) => failure.message, (imageUrl) async {
      // 2. Update user profile with new image URL
      return updateProfile(
        fullName: currentUser.fullName,
        phone: currentUser.phone,
        avatarUrl: imageUrl,
      );
    });
  }

  /// Remove profile image
  Future<String?> removeProfileImage() async {
    final currentUser = state.value;
    if (currentUser == null) {
      return 'User not authenticated';
    }

    // Update user profile with null avatar URL
    return updateProfile(
      fullName: currentUser.fullName,
      phone: currentUser.phone,
      avatarUrl: null,
    );
  }

  /// Logout
  Future<String?> logout() async {
    final result = await ref.read(logoutUseCaseProvider)();

    return result.fold((failure) => failure.message, (_) => null);
  }

  /// Check if user is authenticated (Helper for synchronous checks, but prefer watching state)
  bool get isAuthenticated => state.value != null;

  /// Get current user (Helper)
  UserEntity? get currentUser => state.value;
}
