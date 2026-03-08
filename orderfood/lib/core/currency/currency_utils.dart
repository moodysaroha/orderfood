/// Currency utilities for INR (Indian Rupee).
/// All monetary values from the backend arrive as integers in paise (1 INR = 100 paise).
class CurrencyUtils {
  CurrencyUtils._();

  static double paiseToRupees(int paise) => paise / 100.0;
  static int rupeesToPaise(double rupees) => (rupees * 100).round();

  static String formatPaise(int paise) {
    final rupees = paiseToRupees(paise);
    // Indian number formatting: 1,00,000.00
    if (rupees >= 100000) {
      final lakhs = rupees / 100000;
      return '₹${lakhs.toStringAsFixed(2)}L';
    }
    return '₹${rupees.toStringAsFixed(2)}';
  }

  static String formatPaiseCompact(int paise) {
    final rupees = paiseToRupees(paise);
    if (rupees >= 10000000) return '₹${(rupees / 10000000).toStringAsFixed(1)}Cr';
    if (rupees >= 100000) return '₹${(rupees / 100000).toStringAsFixed(1)}L';
    if (rupees >= 1000) return '₹${(rupees / 1000).toStringAsFixed(1)}K';
    return '₹${rupees.toStringAsFixed(0)}';
  }
}
