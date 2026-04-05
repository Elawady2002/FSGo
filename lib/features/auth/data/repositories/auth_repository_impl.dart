import 'dart:io';
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_data_source.dart';

/// Implementation of AuthRepository using Supabase
class AuthRepositoryImpl implements AuthRepository {
  final AuthDataSource _dataSource;

  AuthRepositoryImpl(this._dataSource);

  @override
  Future<Either<Failure, UserEntity>> signUp({
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
      final user = await _dataSource.signUp(
        email: email,
        password: password,
        fullName: fullName,
        phone: phone,
        studentId: studentId,
        universityId: universityId,
        userType: userType,
        officeName: officeName,
        stationName: stationName,
      );
      return Right(user.toEntity());
    } catch (e) {
      return Left(_handleError(e));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final user = await _dataSource.signIn(email: email, password: password);
      return Right(user.toEntity());
    } catch (e) {
      return Left(_handleError(e));
    }
  }

  @override
  Future<Either<Failure, void>> signOut() async {
    try {
      await _dataSource.signOut();
      return const Right(null);
    } catch (e) {
      return Left(_handleError(e));
    }
  }

  @override
  Future<Either<Failure, UserEntity?>> getCurrentUser() async {
    try {
      final user = await _dataSource.getCurrentUser();
      return Right(user?.toEntity());
    } catch (e) {
      return Left(_handleError(e));
    }
  }

  @override
  Stream<UserEntity?> authStateChanges() {
    return _dataSource.authStateChanges().map((user) => user?.toEntity());
  }

  @override
  Future<Either<Failure, UserEntity>> verifyOtp({
    required String email,
    required String otp,
  }) async {
    try {
      final user = await _dataSource.verifyOtp(email: email, otp: otp);
      return Right(user.toEntity());
    } catch (e) {
      return Left(_handleError(e));
    }
  }

  @override
  Future<Either<Failure, void>> resendOtp({required String email}) async {
    try {
      await _dataSource.resendOtp(email: email);
      return const Right(null);
    } catch (e) {
      return Left(_handleError(e));
    }
  }

  @override
  Future<Either<Failure, void>> resetPassword({required String email}) async {
    try {
      await _dataSource.resetPassword(email: email);
      return const Right(null);
    } catch (e) {
      return Left(_handleError(e));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> updateProfile({
    required String userId,
    required String fullName,
    required String phone,
    String? avatarUrl,
  }) async {
    try {
      final user = await _dataSource.updateProfile(
        userId: userId,
        fullName: fullName,
        phone: phone,
        avatarUrl: avatarUrl,
      );
      return Right(user.toEntity());
    } catch (e) {
      return Left(_handleError(e));
    }
  }

  @override
  Future<Either<Failure, String>> uploadProfileImage({
    required File image,
    required String userId,
  }) async {
    try {
      final imageUrl = await _dataSource.uploadProfileImage(
        image: image,
        userId: userId,
      );
      return Right(imageUrl);
    } catch (e) {
      return Left(_handleError(e));
    }
  }

  /// Handle errors and convert to appropriate Failure types
  Failure _handleError(Object error) {
    final errorMessage = error.toString();

    if (errorMessage.contains('Authentication error')) {
      return AuthFailure(message: errorMessage);
    } else if (errorMessage.contains('Database error')) {
      return ServerFailure(message: errorMessage);
    } else if (errorMessage.contains('network') ||
        errorMessage.contains('connection')) {
      return NetworkFailure(message: errorMessage);
    } else {
      return UnknownFailure(message: errorMessage);
    }
  }
}
