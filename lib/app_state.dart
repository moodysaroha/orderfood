import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'models.dart';

class AppState extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  UserProfile user = UserProfile(
    id: 'unknown',
    name: 'Guest',
    email: '',
    role: UserRole.unknown,
    coins: 0,
    rescuePasses: 5,
    isSubscribed: false,
  );

  bool _isUserLoaded = false;
  bool get isUserLoaded => _isUserLoaded;

  int totalAutoDeductions = 0;
  int totalConsumed = 0;

  List<Vendor> vendors = [];

  DateTime _currentTime = DateTime.now();
  DateTime get currentTime => _currentTime;

  void setSimulatedTime(int hour, int minute) {
    final now = DateTime.now();
    _currentTime = DateTime(now.year, now.month, now.day, hour, minute);
    _checkLogic();
    notifyListeners();
  }

  void resetToRealTime() {
    _currentTime = DateTime.now();
    _checkLogic();
    notifyListeners();
  }

  AppState() {
    _loadMenuData();
    Timer.periodic(const Duration(seconds: 10), (timer) {
      if (_currentTime.year == DateTime.now().year) {
        _currentTime = DateTime.now();
        _checkLogic();
        notifyListeners();
      }
    });
  }

  void _loadMenuData() {
    // Simulated JSON data loading
    const String jsonString = '''
    [
      {
        "id": "v1",
        "name": "Oven Express",
        "logoUrl": "https://example.com/logo1.png",
        "menu": [
          {"id": "m1", "name": "Chole Bhature", "description": "Classic North Indian delight", "category": "Breakfast", "vendorId": "v1", "priceInCoins": 1.0, "isSoldOut": false},
          {"id": "m2", "name": "Paneer Wrap", "description": "Spicy paneer in a soft tortilla", "category": "Snacks", "vendorId": "v1", "priceInCoins": 1.0, "isSoldOut": false},
          {"id": "m5", "name": "Masala Dosa", "description": "Crispy crepe with potato filling", "category": "Breakfast", "vendorId": "v1", "priceInCoins": 1.0, "isSoldOut": true}
        ]
      },
      {
        "id": "v2",
        "name": "Kitchen Atte",
        "logoUrl": "https://example.com/logo2.png",
        "menu": [
          {"id": "m3", "name": "Thali", "description": "Full meal with dal, rice, and sabzi", "category": "Lunch", "vendorId": "v2", "priceInCoins": 1.0, "isSoldOut": false},
          {"id": "m4", "name": "Veg Burger", "description": "Classic veg patty burger", "category": "Snacks", "vendorId": "v2", "priceInCoins": 1.0, "isSoldOut": false}
        ]
      }
    ]
    ''';
    
    final List<dynamic> list = jsonDecode(jsonString);
    vendors = list.map((v) => Vendor.fromJson(v)).toList();
    notifyListeners();
  }

  Future<void> toggleItemStock(String vendorId, String mealId) async {
    final vendor = vendors.firstWhere((v) => v.id == vendorId);
    final meal = vendor.menu.firstWhere((m) => m.id == mealId);
    meal.isSoldOut = !meal.isSoldOut;
    notifyListeners();
  }

  Future<void> loadUserFromFirestore(User firebaseUser) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(firebaseUser.uid)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        user = UserProfile(
          id: firebaseUser.uid,
          name: data['name'] ?? firebaseUser.displayName ?? 'User',
          email: data['email'] ?? firebaseUser.email ?? '',
          role: _parseRole(data['role']),
          profileImage: data['photoURL'],
          coins: data['coins'] ?? 0,
          rescuePasses: data['rescuePasses'] ?? 5,
          isSubscribed: data['isSubscribed'] ?? false,
          lockedMealId: data['lockedMealId'],
          lockedVendorId: data['lockedVendorId'],
          currentMealStatus: _parseMealStatus(data['currentMealStatus']),
        );
      } else {
        user = UserProfile(
          id: firebaseUser.uid,
          name: firebaseUser.displayName ?? 'User',
          email: firebaseUser.email ?? '',
          role: UserRole.unknown,
          profileImage: firebaseUser.photoURL,
          coins: 0,
          rescuePasses: 5,
          isSubscribed: false,
        );
        await _firestore.collection('users').doc(firebaseUser.uid).set({
          'name': user.name,
          'email': user.email,
          'role': user.role.name,
          'photoURL': user.profileImage,
          'coins': user.coins,
          'rescuePasses': user.rescuePasses,
          'isSubscribed': user.isSubscribed,
          'currentMealStatus': user.currentMealStatus.name,
        });
      }

      _isUserLoaded = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading user: $e');
    }
  }

  UserRole _parseRole(String? role) {
    if (role == null) return UserRole.unknown;
    return UserRole.values.firstWhere(
      (e) => e.name == role,
      orElse: () => UserRole.unknown,
    );
  }

  MealStatus _parseMealStatus(String? status) {
    if (status == null) return MealStatus.available;
    return MealStatus.values.firstWhere(
      (e) => e.name == status,
      orElse: () => MealStatus.available,
    );
  }

  void clearUser() {
    user = UserProfile(id: 'unknown', name: 'Guest', email: '', role: UserRole.unknown, coins: 0);
    _isUserLoaded = false;
    notifyListeners();
  }

  Future<void> _syncToFirestore(Map<String, dynamic> fields) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      await _firestore.collection('users').doc(uid).set(fields, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Sync error: $e');
    }
  }

  void _checkLogic() {
    // Time limit logic disabled for testing
    /*
    final hour = _currentTime.hour;
    final minute = _currentTime.minute;

    if (user.role == UserRole.student &&
        user.isSubscribed &&
        (hour > 11 || (hour == 11 && minute >= 1)) &&
        user.lockedMealId == null &&
        user.currentMealStatus == MealStatus.available) {
      if (user.coins > 0) {
        user.coins -= 1;
        user.currentMealStatus = MealStatus.expired;
        totalAutoDeductions++;
        _syncToFirestore({
          'coins': user.coins,
          'currentMealStatus': user.currentMealStatus.name,
        });
      }
    }

    if (hour == 0 && minute == 0 && user.currentMealStatus != MealStatus.available) {
      user.lockedMealId = null;
      user.lockedVendorId = null;
      user.currentMealStatus = MealStatus.available;
      _syncToFirestore({
        'lockedMealId': null,
        'lockedVendorId': null,
        'currentMealStatus': MealStatus.available.name,
      });
    }
    */
  }

  bool isLockWindow() => true; // Always open for testing
  bool isPickupWindow() => true; // Always open for testing

  String getTimerMessage() {
    return "Time limits disabled for testing";
  }

  Future<void> subscribe() async {
    user.isSubscribed = true;
    user.coins += 90; 
    await _syncToFirestore({
      'isSubscribed': true,
      'coins': user.coins,
    });
    notifyListeners();
  }

  String? lockMeal(String vendorId, String mealId) {
    if (user.coins <= 0) return "Not enough coins! Please subscribe.";

    final vendor = vendors.firstWhere((v) => v.id == vendorId);
    final meal = vendor.menu.firstWhere((m) => m.id == mealId);
    
    if (meal.isSoldOut) return "Sorry, this item is sold out!";

    user.lockedMealId = mealId;
    user.lockedVendorId = vendorId;
    user.coins -= 1;
    user.currentMealStatus = MealStatus.locked;
    
    _syncToFirestore({
      'coins': user.coins,
      'lockedMealId': mealId,
      'lockedVendorId': vendorId,
      'currentMealStatus': user.currentMealStatus.name,
    });
    
    notifyListeners();
    return null;
  }

  void useRescuePass() {
    if (user.currentMealStatus == MealStatus.expired &&
        user.rescuePasses > 0) {
      user.rescuePasses -= 1;
      user.coins += 1;
      user.currentMealStatus = MealStatus.available;
      _syncToFirestore({
        'rescuePasses': user.rescuePasses,
        'coins': user.coins,
        'currentMealStatus': user.currentMealStatus.name,
      });
      notifyListeners();
    }
  }

  void consumeMeal() {
    user.currentMealStatus = MealStatus.consumed;
    totalConsumed++;
    _syncToFirestore({'currentMealStatus': user.currentMealStatus.name});
    notifyListeners();
  }
}
