class RevenueEntry {
  final String id;
  final String vendorId;
  final String orderId;
  final int grossAmountInPaise;
  final int commissionInPaise;
  final int netAmountInPaise;
  final String currency;
  final DateTime createdAt;

  RevenueEntry({
    required this.id,
    required this.vendorId,
    required this.orderId,
    required this.grossAmountInPaise,
    required this.commissionInPaise,
    required this.netAmountInPaise,
    required this.currency,
    required this.createdAt,
  });

  factory RevenueEntry.fromJson(Map<String, dynamic> json) {
    return RevenueEntry(
      id: json['id'] as String,
      vendorId: json['vendorId'] as String,
      orderId: json['orderId'] as String,
      grossAmountInPaise: json['grossAmountInPaise'] as int,
      commissionInPaise: json['commissionInPaise'] as int,
      netAmountInPaise: json['netAmountInPaise'] as int,
      currency: json['currency'] as String? ?? 'INR',
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

class PaginatedRevenueEntries {
  final List<RevenueEntry> data;
  final int total;
  final int page;
  final int limit;
  final int totalPages;

  PaginatedRevenueEntries({
    required this.data, required this.total, required this.page,
    required this.limit, required this.totalPages,
  });

  factory PaginatedRevenueEntries.fromJson(Map<String, dynamic> json) {
    return PaginatedRevenueEntries(
      data: (json['data'] as List).map((e) => RevenueEntry.fromJson(e)).toList(),
      total: json['total'] as int,
      page: json['page'] as int,
      limit: json['limit'] as int,
      totalPages: json['totalPages'] as int,
    );
  }
}
