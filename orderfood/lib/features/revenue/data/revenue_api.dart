import '../../../core/network/api_client.dart';
import '../domain/revenue_summary.dart';
import '../domain/revenue_entry.dart';

class RevenueApi {
  final ApiClient _api;

  RevenueApi(this._api);

  Future<RevenueSummary> getTodaySummary() async {
    final res = await _api.get('/revenue/today');
    return RevenueSummary.fromJson(res.data['data']);
  }

  Future<RevenueSummary> getOverallSummary() async {
    final res = await _api.get('/revenue/overall');
    return RevenueSummary.fromJson(res.data['data']);
  }

  Future<RevenueSummary> getSummaryByRange(DateTime from, DateTime to) async {
    final res = await _api.get('/revenue/summary', queryParams: {
      'from': from.toIso8601String().split('T').first,
      'to': to.toIso8601String().split('T').first,
    });
    return RevenueSummary.fromJson(res.data['data']);
  }

  Future<PaginatedRevenueEntries> getEntries({int page = 1, int limit = 20}) async {
    final res = await _api.get('/revenue/entries', queryParams: {'page': page, 'limit': limit});
    return PaginatedRevenueEntries.fromJson(res.data['data']);
  }
}
