import 'package:dartz/dartz.dart';
import '../../../../core/domain/entities/user_entity.dart';
import '../../../../core/error/failures.dart';
import '../repositories/auth_repository.dart';

class SignupUseCase {
  final AuthRepository _repository;

  SignupUseCase(this._repository);

  Future<Either<Failure, UserEntity>> call({
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
  }) =>
      _repository.signUp(
        email: email,
        password: password,
        fullName: fullName,
        phone: phone,
        studentId: studentId,
        universityId: universityId,
        userType: userType,
        officeName: officeName,
        stationName: stationName,
        city: city,
        cityId: cityId,
      );
}
