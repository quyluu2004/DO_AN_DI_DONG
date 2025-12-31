import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FavoriteProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<String> _favoriteIds = [];

  List<String> get favoriteIds => _favoriteIds;

  /// Load favorites from User Collection
  Future<void> loadFavorites() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
        _favoriteIds = [];
        notifyListeners();
        return;
    }

    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (doc.exists) {
        final data = doc.data();
        if (data != null && data.containsKey('favoriteProductIds')) {
          _favoriteIds = List<String>.from(data['favoriteProductIds'] as List<dynamic>);
        } else {
             _favoriteIds = [];
        }
      }
      notifyListeners();
    } catch (e) {
      debugPrint("Error loading favorites: $e");
    }
  }

  /// Toggle favorite status for a product
  Future<void> toggleFavorite(String productId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      // TODO: Handle unauthenticated user (e.g. show toast)
      debugPrint("User not logged in");
      return;
    }

    final isFav = _favoriteIds.contains(productId);

    // Optimistic update
    if (isFav) {
      _favoriteIds.remove(productId);
    } else {
      _favoriteIds.add(productId);
    }
    notifyListeners();

    try {
      await _db.collection('users').doc(uid).update({
        'favoriteProductIds': _favoriteIds,
      });
    } catch (e) {
      // Revert if failed
       if (isFav) {
        _favoriteIds.add(productId);
      } else {
        _favoriteIds.remove(productId);
      }
      notifyListeners();
      debugPrint("Error updating favorite: $e");
      rethrow;
    }
  }

  bool isFavorite(String productId) {
    return _favoriteIds.contains(productId);
  }
  
  /// Clear data on logout
  void clear() {
      _favoriteIds = [];
      notifyListeners();
  }
}
