import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/datasources/city_data_source.dart';
import '../data/repositories/city_repository_impl.dart';
import '../domain/entities/city_entity.dart';
import '../domain/repositories/city_repository.dart';

final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

final cityDataSourceProvider = Provider<CityDataSource>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return SupabaseCityDataSource(client);
});

final cityRepositoryProvider = Provider<CityRepository>((ref) {
  final dataSource = ref.watch(cityDataSourceProvider);
  return CityRepositoryImpl(dataSource);
});

final citiesProvider = FutureProvider<List<CityEntity>>((ref) async {
  final repository = ref.watch(cityRepositoryProvider);
  return await repository.getCities();
});
