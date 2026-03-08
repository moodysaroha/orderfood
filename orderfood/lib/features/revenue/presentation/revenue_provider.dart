import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../data/revenue_api.dart';
import '../domain/revenue_summary.dart';

final revenueApiProvider = Provider<RevenueApi>((ref) {
  return RevenueApi(ref.read(apiClientProvider));
});

final todayRevenueProvider = FutureProvider<RevenueSummary>((ref) async {
  return ref.read(revenueApiProvider).getTodaySummary();
});

final overallRevenueProvider = FutureProvider<RevenueSummary>((ref) async {
  return ref.read(revenueApiProvider).getOverallSummary();
});
