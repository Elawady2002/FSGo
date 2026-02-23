import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/city_entity.dart';
import '../entities/university_entity.dart';/// University repository interface
abstract class UniversityRepository {
  /// Get all active cities
  Future<Either<Failure, List<CityEntity>>> getCities();

  /// Get universities by city ID
  Future<Either<Failure, List<UniversityEntity>>> getUniversitiesByCity(
    String cityId,
  );

  /// Get a specific university by ID
  Future<Either<Failure, UniversityEntity>> getUniversityById(String id);
}
