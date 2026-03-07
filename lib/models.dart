enum MealStatus {
  available,
  locked,
  consumed,
  expired,
  reclaimed,
}

enum UserRole {
  student,
  vendor,
  admin,
  unknown,
}

class Meal {
  final String id;
  final String name;
  final String description;
  final String category;
  final String vendorId;
  final double priceInCoins;
  bool isSoldOut;

  Meal({
    required this.id,
    required this.name,
    this.description = "",
    this.category = "General",
    required this.vendorId,
    this.priceInCoins = 1.0,
    this.isSoldOut = false,
  });

  factory Meal.fromJson(Map<String, dynamic> json) {
    return Meal(
      id: json['id'] ?? "",
      name: json['name'] ?? "Unknown Meal",
      description: json['description'] ?? "",
      category: json['category'] ?? "General",
      vendorId: json['vendorId'] ?? "",
      priceInCoins: (json['priceInCoins'] ?? 1.0).toDouble(),
      isSoldOut: json['isSoldOut'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category,
      'vendorId': vendorId,
      'priceInCoins': priceInCoins,
      'isSoldOut': isSoldOut,
    };
  }
}

class Vendor {
  final String id;
  final String name;
  final String? logoUrl;
  final List<Meal> menu;

  Vendor({
    required this.id,
    required this.name,
    this.logoUrl,
    required this.menu,
  });

  factory Vendor.fromJson(Map<String, dynamic> json) {
    return Vendor(
      id: json['id'] ?? "",
      name: json['name'] ?? "Unknown Vendor",
      logoUrl: json['logoUrl'],
      menu: (json['menu'] as List?)?.map((m) => Meal.fromJson(m)).toList() ?? [],
    );
  }
}

class UserProfile {
  final String id;
  final String name;
  final String email;
  final UserRole role;
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
    this.role = UserRole.unknown,
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
