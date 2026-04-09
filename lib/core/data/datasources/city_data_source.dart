import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/city_model.dart';

abstract class CityDataSource {
  Future<List<CityModel>> getCities();
}

class SupabaseCityDataSource implements CityDataSource {
  final SupabaseClient _client;

  SupabaseCityDataSource(this._client);

  @override
  Future<List<CityModel>> getCities() async {
    try {
      final response = await _client
          .from('cities')
          .select()
          .eq('is_active', true)
          .order('governorate')
          .order('name_ar');

      return (response as List).map((json) => CityModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch cities: $e');
    }
  }
}
