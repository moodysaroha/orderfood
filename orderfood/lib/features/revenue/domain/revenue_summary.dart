class RevenueSummary {
  final int totalOrderCount;
  final int grossRevenueInPaise;
  final int totalCommissionInPaise;
  final int netRevenueInPaise;
  final String currency;
  final String grossRevenueFormatted;
  final String totalCommissionFormatted;
  final String netRevenueFormatted;

  RevenueSummary({
    required this.totalOrderCount,
    required this.grossRevenueInPaise,
    required this.totalCommissionInPaise,
    required this.netRevenueInPaise,
    required this.currency,
    required this.grossRevenueFormatted,
    required this.totalCommissionFormatted,
    required this.netRevenueFormatted,
  });

  factory RevenueSummary.fromJson(Map<String, dynamic> json) {
    return RevenueSummary(
      totalOrderCount: json['totalOrderCount'] as int? ?? 0,
      grossRevenueInPaise: json['grossRevenueInPaise'] as int? ?? 0,
      totalCommissionInPaise: json['totalCommissionInPaise'] as int? ?? 0,
      netRevenueInPaise: json['netRevenueInPaise'] as int? ?? 0,
      currency: json['currency'] as String? ?? 'INR',
      grossRevenueFormatted: json['grossRevenueFormatted'] as String? ?? '₹0.00',
      totalCommissionFormatted: json['totalCommissionFormatted'] as String? ?? '₹0.00',
      netRevenueFormatted: json['netRevenueFormatted'] as String? ?? '₹0.00',
    );
  }

  static RevenueSummary empty() => RevenueSummary(
    totalOrderCount: 0, grossRevenueInPaise: 0, totalCommissionInPaise: 0,
    netRevenueInPaise: 0, currency: 'INR', grossRevenueFormatted: '₹0.00',
    totalCommissionFormatted: '₹0.00', netRevenueFormatted: '₹0.00',
  );
}
