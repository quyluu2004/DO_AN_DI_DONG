import 'package:flutter/material.dart';
import '../../models/ui_config_model.dart';
import '../../services/ui_service.dart';
import 'banner_manager.dart';
import 'announcement_manager.dart';
import 'flash_sale_manager.dart';
import 'promo_manager.dart';

class AdminInterfaceScreen extends StatelessWidget {
  const AdminInterfaceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<HomeConfig>(
      future: UIService.instance.getHomeConfig(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          return Center(child: Text('Lỗi tải cấu hình: ${snapshot.error}'));
        }

        final config = snapshot.data ?? HomeConfig.empty();

        return DefaultTabController(
          length: 4,
          child: Column(
            children: [
              const TabBar(
                labelColor: Colors.black,
                tabs: [
                  Tab(text: 'Banner'),
                  Tab(text: 'Announcement'),
                  Tab(text: 'Flash Sale'),
                  Tab(text: 'Promo'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: BannerManager(initialBanners: config.banners),
                    ),
                    SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: AnnouncementManager(initialConfig: config.announcement),
                    ),
                    SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: FlashSaleManager(initialConfig: config.flashSale),
                    ),
                    SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: PromoManager(initialConfig: config.promoBanner),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
