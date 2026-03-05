enum MealStatus {
  available,
  locked,
  consumed,
  expired,
  reclaimed,
}

class Meal {
  final String id;
  final String name;
  final String vendorId;
  final double priceInCoins;
  bool isSoldOut;

  Meal({
    required this.id,
    required this.name,
    required this.vendorId,
    this.priceInCoins = 1.0,
    this.isSoldOut = false,
  });
}

class Vendor {
  final String id;
  final String name;
  final List<Meal> menu;

  Vendor({
    required this.id,
    required this.name,
    required this.menu,
  });
}

class UserProfile {
  final String id;
  final String name;
  final String email;
  final String? firstName;
  final String? lastName;
  final String? phoneNumber;
  final String? planType;
  final String? profileImage;
  final bool isUserPro;
  int coins;
  int rescuePasses;
  bool isSubscribed;
  String? lockedMealId;
  String? lockedVendorId;
  MealStatus currentMealStatus;

  UserProfile({
    required this.id,
    required this.name,
    required this.email,
    this.firstName,
    this.lastName,
    this.phoneNumber,
    this.planType,
    this.profileImage,
    this.isUserPro = false,
    this.coins = 0,
    this.rescuePasses = 5,
    this.isSubscribed = false,
    this.lockedMealId,
    this.lockedVendorId,
    this.currentMealStatus = MealStatus.available,
  });
}
