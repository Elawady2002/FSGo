import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/repositories/reservation_repository.dart';

final reservationRepositoryProvider = Provider<ReservationRepository>((ref) {
  return ReservationRepository(Supabase.instance.client);
});

final fleetReservationsProvider =
    FutureProvider.family<List<ReservationSummary>, DateTime>((ref, date) {
  final repo = ref.watch(reservationRepositoryProvider);
  return repo.getReservationsForDate(date);
});
