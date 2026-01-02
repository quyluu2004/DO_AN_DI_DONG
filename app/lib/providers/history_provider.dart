import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HistoryProvider extends ChangeNotifier {
  List<String> _viewedProductIds = [];

  List<String> get viewedProductIds => _viewedProductIds;

  HistoryProvider() {
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    _viewedProductIds = prefs.getStringList('viewed_products') ?? [];
    notifyListeners();
  }

  Future<void> addToHistory(String productId) async {
    // Remove if exists to move it to top (most recent)
    _viewedProductIds.remove(productId);
    
    // Add to start
    _viewedProductIds.insert(0, productId);
    
    // Limit to 50 items
    if (_viewedProductIds.length > 50) {
      _viewedProductIds = _viewedProductIds.sublist(0, 50);
    }
    
    notifyListeners();
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('viewed_products', _viewedProductIds);
  }

  Future<void> clearHistory() async {
    _viewedProductIds.clear();
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('viewed_products');
  }
}
