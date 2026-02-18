import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/city_model.dart';
import '../models/university_model.dart';
import '../models/station_model.dart';
import '../models/route_model.dart';
import '../models/schedule_model.dart';

abstract class HomeRemoteDataSource {
  Future<List<CityModel>> getCities();
  Future<List<UniversityModel>> getUniversities(String cityId);
  Future<List<StationModel>> getStations(
    String cityId,
  ); // Changed from universityId to cityId
  Future<List<RouteModel>> getRoutes(String universityId);
  Future<List<StationModel>> getAllStations();
  Future<List<UniversityModel>> getAllUniversities();
  Future<List<ScheduleModel>> getSchedules(String routeId);
}

class HomeRemoteDataSourceImpl implements HomeRemoteDataSource {
  final SupabaseClient _client;

  HomeRemoteDataSourceImpl(this._client);

  @override
  Future<List<CityModel>> getCities() async {
    final response = await _client
        .from('cities')
        .select()
        .eq('is_active', true)
        .order('name_ar');

    return (response as List).map((e) => CityModel.fromJson(e)).toList();
  }

  @override
  Future<List<UniversityModel>> getUniversities(String cityId) async {
    final response = await _client
        .from('universities')
        .select()
        .eq('city_id', cityId)
        .eq('is_active', true)
        .order('name_ar');

    return (response as List).map((e) => UniversityModel.fromJson(e)).toList();
  }

  @override
  Future<List<StationModel>> getStations(String cityId) async {
    // Changed from universityId to cityId
    final response = await _client
        .from('stations')
        .select()
        .eq('city_id', cityId) // Changed from university_id to city_id
        .eq('is_active', true)
        .order('name_ar');

    return (response as List).map((e) => StationModel.fromJson(e)).toList();
  }

  @override
  Future<List<RouteModel>> getRoutes(String universityId) async {
    final response = await _client
        .from('routes')
        .select()
        .eq('university_id', universityId)
        .eq('is_active', true)
        .order('route_name_ar');

    return (response as List).map((e) => RouteModel.fromJson(e)).toList();
  }

  @override
  Future<List<ScheduleModel>> getSchedules(String routeId) async {
    final response = await _client
        .from('schedules')
        .select()
        .eq('route_id', routeId)
        .eq('is_active', true)
        .order('departure_time');

    return (response as List).map((e) => ScheduleModel.fromJson(e)).toList();
  }

  @override
  Future<List<StationModel>> getAllStations() async {
    final response = await _client
        .from('stations')
        .select()
        .eq('is_active', true)
        .order('name_ar');

    return (response as List).map((e) => StationModel.fromJson(e)).toList();
  }

  @override
  Future<List<UniversityModel>> getAllUniversities() async {
    final response = await _client
        .from('universities')
        .select()
        .eq('is_active', true)
        .order('name_ar');

    return (response as List).map((e) => UniversityModel.fromJson(e)).toList();
  }
}
