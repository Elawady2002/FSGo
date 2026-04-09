import '../../domain/entities/city_entity.dart';
import '../../domain/repositories/city_repository.dart';
import '../datasources/city_data_source.dart';

class CityRepositoryImpl implements CityRepository {
  final CityDataSource _dataSource;

  CityRepositoryImpl(this._dataSource);

  @override
  Future<List<CityEntity>> getCities() async {
    return await _dataSource.getCities();
  }
}
