import '../entities/city_entity.dart';

abstract class CityRepository {
  Future<List<CityEntity>> getCities();
}
