import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/ui_config_model.dart';

class UIService {
  UIService._internal();
  static final UIService instance = UIService._internal();

  final _db = FirebaseFirestore.instance;
  
  // Single document for home page config
  DocumentReference<Map<String, dynamic>> get _homeConfigRef =>
      _db.collection('ui_configs').doc('home_page');

  /// Get Home Page Configuration
  Stream<HomeConfig> getHomeConfigStream() {
    return _homeConfigRef.snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) {
        return HomeConfig.empty();
      }
      return HomeConfig.fromMap(doc.data()!);
    });
  }

  /// Get Home Config Future (one-time read)
  Future<HomeConfig> getHomeConfig() async {
    final doc = await _homeConfigRef.get();
    if (!doc.exists || doc.data() == null) {
      return HomeConfig.empty();
    }
    return HomeConfig.fromMap(doc.data()!);
  }

  /// Save Home Page Configuration
  Future<void> saveHomeConfig(HomeConfig config) async {
    try {
      await _homeConfigRef.set(config.toMap(), SetOptions(merge: true));
    } catch (e) {
      // Replaced AppLogger with print for now
      print('Error saving home config: $e');
      rethrow;
    }
  }

  /// Update Banners Only
  Future<void> updateBanners(List<BannerItem> banners) async {
    await _homeConfigRef.set({
      'banners': banners.map((b) => b.toMap()).toList(),
    }, SetOptions(merge: true));
  }

  /// Update Announcement Only
  Future<void> updateAnnouncement(AnnouncementConfig announcement) async {
    await _homeConfigRef.set({
      'announcement': announcement.toMap(),
    }, SetOptions(merge: true));
  }

  /// Update Flash Sale Only
  Future<void> updateFlashSale(FlashSaleConfig flashSale) async {
    await _homeConfigRef.set({
      'flashSale': flashSale.toMap(),
    }, SetOptions(merge: true));
  }

  /// Update Promo Banner Only
  Future<void> updatePromoBanner(PromoBannerConfig promoBanner) async {
    await _homeConfigRef.set({
      'promoBanner': promoBanner.toMap(),
    }, SetOptions(merge: true));
  }
}
