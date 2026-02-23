import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/city_model.dart';
import '../models/university_model.dart';
import '../models/boarding_station_model.dart';
import '../models/arrival_station_model.dart';
import '../models/route_model.dart';
import '../models/schedule_model.dart';

abstract class HomeRemoteDataSource {
  Future<List<CityModel>> getCities();
  Future<List<UniversityModel>> getUniversities(String cityId);
  Future<List<BoardingStationModel>> getBoardingStations(String cityId);
  Future<List<ArrivalStationModel>> getArrivalStations(String boardingStationId);
  Future<List<RouteModel>> getRoutes(String universityId);
  Future<List<BoardingStationModel>> getAllBoardingStations();
  Future<List<ArrivalStationModel>> getAllArrivalStations();
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
  Future<List<BoardingStationModel>> getBoardingStations(String cityId) async {
    final response = await _client
        .from('boarding_stations')
        .select()
        .eq('city_id', cityId)
        .order('name_ar');

    return (response as List).map((e) => BoardingStationModel.fromJson(e)).toList();
  }

  @override
  Future<List<ArrivalStationModel>> getArrivalStations(String boardingStationId) async {
    final response = await _client
        .from('arrival_stations')
        .select()
        .eq('boarding_station_id', boardingStationId)
        .order('name_ar');

    return (response as List).map((e) => ArrivalStationModel.fromJson(e)).toList();
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
  Future<List<BoardingStationModel>> getAllBoardingStations() async {
    final response = await _client
        .from('boarding_stations')
        .select()
        .order('name_ar');

    return (response as List).map((e) => BoardingStationModel.fromJson(e)).toList();
  }

  @override
  Future<List<ArrivalStationModel>> getAllArrivalStations() async {
    final response = await _client
        .from('arrival_stations')
        .select()
        .order('name_ar');

    return (response as List).map((e) => ArrivalStationModel.fromJson(e)).toList();
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
