import 'package:cloud_firestore/cloud_firestore.dart';

class BannerItem {
  String id;
  String imageUrl;
  String actionType; // 'web', 'category', 'product'
  String actionValue; // url, categoryId, productId
  double aspectRatio;

  BannerItem({
    required this.id,
    required this.imageUrl,
    this.actionType = 'none',
    this.actionValue = '',
    this.aspectRatio = 2.0, // 2:1 default
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'imageUrl': imageUrl,
      'actionType': actionType,
      'actionValue': actionValue,
      'aspectRatio': aspectRatio,
    };
  }

  factory BannerItem.fromMap(Map<String, dynamic> map) {
    return BannerItem(
      id: map['id'] as String? ?? '',
      imageUrl: map['imageUrl'] as String? ?? '',
      actionType: map['actionType'] as String? ?? 'none',
      actionValue: map['actionValue'] as String? ?? '',
      aspectRatio: (map['aspectRatio'] as num?)?.toDouble() ?? 2.0,
    );
  }
}

class AnnouncementConfig {
  String content;
  String textColor;
  String backgroundColor;
  String? icon;
  bool clickable;

  AnnouncementConfig({
    this.content = 'Free Shipping & Returns',
    this.textColor = '#FF0000',
    this.backgroundColor = '#FFF0F5',
    this.icon,
    this.clickable = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'content': content,
      'textColor': textColor,
      'backgroundColor': backgroundColor,
      'icon': icon,
      'clickable': clickable,
    };
  }

  factory AnnouncementConfig.fromMap(Map<String, dynamic> map) {
    return AnnouncementConfig(
      content: map['content'] as String? ?? '',
      textColor: map['textColor'] as String? ?? '#FF0000',
      backgroundColor: map['backgroundColor'] as String? ?? '#FFF0F5',
      icon: map['icon'] as String?,
      clickable: map['clickable'] as bool? ?? false,
    );
  }
}

class FlashSaleConfig {
  String title;
  DateTime? endTime;
  String type; // 'manual', 'auto'
  List<String> productIds;
  String? code;
  double? discountValue;
  String discountType;
  bool isActive;
  int limit;
  List<String> usedUserIds;
  List<Map<String, dynamic>> usageHistory;

  FlashSaleConfig({
    this.title = 'Flash Sale',
    this.endTime,
    this.type = 'auto',
    this.productIds = const [],
    this.code,
    this.discountValue,
    this.discountType = 'percent',
    this.isActive = false,
    this.limit = 0,
    this.usedUserIds = const [],
    this.usageHistory = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'endTime': endTime != null ? Timestamp.fromDate(endTime!) : null,
      'type': type,
      'productIds': productIds,
      'code': code,
      'discountValue': discountValue,
      'discountType': discountType,
      'isActive': isActive,
      'limit': limit,
      'usedUserIds': usedUserIds,
      'usageHistory': usageHistory,
    };
  }

  factory FlashSaleConfig.fromMap(Map<String, dynamic> map) {
    return FlashSaleConfig(
      title: map['title'] as String? ?? 'Flash Sale',
      endTime: (map['endTime'] as Timestamp?)?.toDate(),
      type: map['type'] as String? ?? 'auto',
      productIds: List<String>.from(map['productIds'] as List<dynamic>? ?? []),
      code: map['code'] as String?,
      discountValue: (map['discountValue'] as num?)?.toDouble(),
      discountType: map['discountType'] as String? ?? 'percent',
      isActive: map['isActive'] as bool? ?? false,
      limit: map['limit'] as int? ?? 0,
      usedUserIds: map['usedUserIds'] != null 
          ? List<String>.from(map['usedUserIds']) 
          : [],
      usageHistory: map['usageHistory'] != null 
          ? List<Map<String, dynamic>>.from(map['usageHistory']) 
          : [],
    );
  }
}

class PromoBannerConfig {
  String imageUrl;
  String? title;
  String? subtitle;
  String? destination;

  PromoBannerConfig({
    this.imageUrl = '',
    this.title,
    this.subtitle,
    this.destination,
  });

  Map<String, dynamic> toMap() {
    return {
      'imageUrl': imageUrl,
      'title': title,
      'subtitle': subtitle,
      'destination': destination,
    };
  }

  factory PromoBannerConfig.fromMap(Map<String, dynamic> map) {
    return PromoBannerConfig(
      imageUrl: map['imageUrl'] as String? ?? '',
      title: map['title'] as String?,
      subtitle: map['subtitle'] as String?,
      destination: map['destination'] as String?,
    );
  }
}

class HomeConfig {
  List<BannerItem> banners;
  AnnouncementConfig announcement;
  FlashSaleConfig flashSale;
  PromoBannerConfig promoBanner;

  HomeConfig({
    required this.banners,
    required this.announcement,
    required this.flashSale,
    required this.promoBanner,
  });

  Map<String, dynamic> toMap() {
    return {
      'banners': banners.map((b) => b.toMap()).toList(),
      'announcement': announcement.toMap(),
      'flashSale': flashSale.toMap(),
      'promoBanner': promoBanner.toMap(),
    };
  }

  factory HomeConfig.fromMap(Map<String, dynamic> map) {
    return HomeConfig(
      banners: (map['banners'] as List<dynamic>? ?? [])
          .map((b) => BannerItem.fromMap(b as Map<String, dynamic>))
          .toList(),
      announcement: AnnouncementConfig.fromMap(
        map['announcement'] as Map<String, dynamic>? ?? {},
      ),
      flashSale: FlashSaleConfig.fromMap(
        map['flashSale'] as Map<String, dynamic>? ?? {},
      ),
      promoBanner: PromoBannerConfig.fromMap(
        map['promoBanner'] as Map<String, dynamic>? ?? {},
      ),
    );
  }
  
  static HomeConfig empty() {
    return HomeConfig(
      banners: [],
      announcement: AnnouncementConfig(),
      flashSale: FlashSaleConfig(),
      promoBanner: PromoBannerConfig(),
    );
  }
}
