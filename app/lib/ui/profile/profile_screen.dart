import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/user_service.dart';
import '../../theme/app_theme.dart';
import '../../services/product_service.dart';
import '../../models/product_model.dart';
import '../../models/order_model.dart'; // [NEW]
import '../../providers/order_provider.dart'; // [NEW]
import '../product/product_detail_screen.dart';
import '../order/order_history_screen.dart';
import '../address/address_list_screen.dart';
import 'my_posts_screen.dart';
import 'history_screen.dart';
import 'favorite_screen.dart';
import '../../providers/favorite_provider.dart';
import '../../providers/history_provider.dart';
import '../loyalty/loyalty_screen.dart'; // [NEW]
import '../../services/loyalty_service.dart'; // [NEW]

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = AuthService.instance.currentUser;
      if (user != null) {
        context.read<OrderProvider>().fetchOrders(user.uid);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            final user = AuthService.instance.currentUser;
            if (user != null) {
              await context.read<OrderProvider>().fetchOrders(user.uid);
            }
          },
          child: CustomScrollView(
            slivers: [
              // 1. Custom Header
              const SliverToBoxAdapter(child: _ProfileHeader()),
              
              // 2. Stats Row (Coupons, Points...)
              const SliverToBoxAdapter(child: _StatsRow()),
              
              const SliverToBoxAdapter(child: Divider(height: 1, thickness: 8, color: Color(0xFFF5F5F5))),

              // 3. My Orders
              const SliverToBoxAdapter(child: _MyOrdersSection()),

              const SliverToBoxAdapter(child: Divider(height: 1, thickness: 8, color: Color(0xFFF5F5F5))),

              // 4. Services Grid
              const SliverToBoxAdapter(child: _ServicesSection()),

              const SliverToBoxAdapter(child: Divider(height: 1, thickness: 8, color: Color(0xFFF5F5F5))),

              // 5. Engagement Strip (Following, History...)
              const SliverToBoxAdapter(child: _EngagementSection()),

              // 6. Recommendations Title
              const SliverToBoxAdapter(
                 child: Padding(
                   padding: EdgeInsets.all(16.0),
                   child: Text(
                     'Gợi ý cho bạn',
                     style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                   ),
                 ),
              ),

              // 7. Recommendations Grid
              const _RecommendationGrid(),
              
              const SliverToBoxAdapter(child: SizedBox(height: 20)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader();

  @override
  Widget build(BuildContext context) {
    // Sử dụng StreamBuilder để lắng nghe thay đổi từ Firestore (Real-time)
    return StreamBuilder<UserModel?>(
      stream: UserService.instance.currentUserProfileStream(),
      builder: (context, snapshot) {
        final userModel = snapshot.data;
        final authUser = AuthService.instance.currentUser;
        
        // Ưu tiên dữ liệu từ Firestore (User Model), fallback sang Auth User
        final displayName = userModel?.fullName ?? authUser?.displayName ?? authUser?.email?.split('@')[0] ?? 'Khách';
        final avatarUrl = userModel?.avatarUrl ?? authUser?.photoURL;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 28,
                backgroundColor: Colors.grey[200],
                backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty)
                    ? NetworkImage(avatarUrl)
                    : null,
                child: (avatarUrl == null || avatarUrl.isEmpty)
                    ? Text(
                        displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U',
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black54),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              
              // Name and Tier
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                             displayName,
                             style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                             maxLines: 1, 
                             overflow: TextOverflow.ellipsis
                          ),
                        ),
                        const SizedBox(width: 4),
                        // Google icon mock
                        const Icon(Icons.g_mobiledata, size: 24, color: Colors.blue), 
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Dynamic Tier Badge
                    Builder(
                      builder: (context) {
                         final tier = userModel?.tier ?? 'member';
                         final tierInfo = LoyaltyService.instance.getTierInfo(tier);
                         
                         return InkWell(
                           onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoyaltyScreen())),
                           child: Container(
                             padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                             decoration: BoxDecoration(
                               color: Colors.black,
                               borderRadius: BorderRadius.circular(12),
                               gradient: LinearGradient(colors: [Colors.black, tierInfo.color.withOpacity(0.8)]),
                             ),
                             child: Row(
                               mainAxisSize: MainAxisSize.min,
                               children: [
                                  Icon(tierInfo.icon, color: Colors.amber, size: 14),
                                  const SizedBox(width: 4),
                                  Text('${tierInfo.name} >', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                               ],
                             ),
                           ),
                         );
                      }
                    )
                  ],
                ),
              ),

              // Action Icons
              IconButton(
                onPressed: () {}, 
                icon: const Icon(Icons.qr_code_scanner), 
                tooltip: 'Quét mã',
              ),
              IconButton(
                onPressed: () {
                   // Settings / Sign out
                   _showSettings(context);
                }, 
                icon: const Icon(Icons.settings_outlined),
                tooltip: 'Cài đặt',
              ),
            ],
          ),
        );
      }
    );
  }

  void _showSettings(BuildContext context) {
     showModalBottomSheet(
       context: context,
       builder: (ctx) => Column(
         mainAxisSize: MainAxisSize.min,
         children: [
           ListTile(
             leading: const Icon(Icons.location_on_outlined),
             title: const Text('Sổ địa chỉ'),
             onTap: () {
               Navigator.pop(ctx);
               Navigator.push(context, MaterialPageRoute(builder: (_) => const AddressListScreen()));
             },
           ),
           ListTile(
             leading: const Icon(Icons.logout, color: Colors.red),
             title: const Text('Đăng xuất', style: TextStyle(color: Colors.red)),
             onTap: () {
               Navigator.pop(ctx);
               AuthService.instance.signOut();
             },
           )
         ],
       )
     );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<UserModel?>(
      stream: UserService.instance.currentUserProfileStream(),
      builder: (context, snapshot) {
        final points = snapshot.data?.points ?? 0;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              const _StatItem(value: '9', label: 'Mã giảm giá'),
              _StatItem(value: '$points', label: 'Điểm'),
              const _StatItem(icon: Icons.account_balance_wallet_outlined, label: 'Ví'),
              const _StatItem(icon: Icons.card_giftcard, label: 'Quà tặng'),
            ],
          ),
        );
      }
    );
  }
}

class _StatItem extends StatelessWidget {
  final String? value;
  final IconData? icon;
  final String label;

  const _StatItem({this.value, this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (value != null)
          Text(value!, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))
        else
          Icon(icon, size: 24, color: Colors.black87),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}

class _MyOrdersSection extends StatelessWidget {
  const _MyOrdersSection();

  @override
  Widget build(BuildContext context) {
    return Consumer<OrderProvider>(
      builder: (context, orderProvider, child) {
        final orders = orderProvider.orders;
        final pendingCount = orders.where((o) => o.status == OrderStatus.pending).length;
        final shippingCount = orders.where((o) => o.status == OrderStatus.shipping).length;
        // final deliveredCount = orders.where((o) => o.status == OrderStatus.delivered).length;
        // final cancelledCount = orders.where((o) => o.status == OrderStatus.cancelled).length;
        
        // Mapping delivered to 'Review' (Đánh giá) section roughly
        final reviewCount = orders.where((o) => o.status == OrderStatus.delivered).length; 

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Đơn hàng của tôi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  InkWell(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OrderHistoryScreen())),
                    child: Row(
                      children: const [
                        Text('Xem tất cả', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        Icon(Icons.chevron_right, size: 16, color: Colors.grey),
                      ],
                    ),
                  )
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _TaskIcon(
                    icon: Icons.credit_card, 
                    label: 'Chờ thanh toán', 
                    badgeCount: pendingCount,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OrderHistoryScreen(initialIndex: 1))),
                  ),
                  _TaskIcon(
                    icon: Icons.inventory_2_outlined, 
                    label: 'Đang xử lý', 
                    // badgeCount: pendingCount, // Duplicate badge? Maybe leave empty 
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OrderHistoryScreen(initialIndex: 1))),
                  ),
                  _TaskIcon(
                    icon: Icons.local_shipping_outlined, 
                    label: 'Đang giao', 
                    badgeCount: shippingCount, 
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OrderHistoryScreen(initialIndex: 2))),
                  ),
                  _TaskIcon(
                    icon: Icons.rate_review_outlined, 
                    label: 'Đánh giá', 
                    badgeCount: reviewCount,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OrderHistoryScreen(initialIndex: 3))),
                  ),
                  _TaskIcon(
                    icon: Icons.replay_outlined, 
                    label: 'Đổi trả', 
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OrderHistoryScreen(initialIndex: 4))),
                  ),
                ],
              )
            ],
          ),
        );
      },
    );
  }
}

class _TaskIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  final int badgeCount;
  final VoidCallback onTap;

  const _TaskIcon({required this.icon, required this.label, this.badgeCount = 0, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(icon, size: 26, color: Colors.black87),
              if (badgeCount > 0)
                Positioned(
                  top: -6,
                  right: -6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: Colors.black, shape: BoxShape.circle),
                    child: Text('$badgeCount', style: const TextStyle(color: Colors.white, fontSize: 10)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.black87)),
        ],
      ),
    );
  }
}

class _ServicesSection extends StatelessWidget {
  const _ServicesSection();

  @override
  Widget build(BuildContext context) {
    // Using a simple Row for typical 4 items like the screenshot
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          const _ServiceItem(icon: Icons.headset_mic_outlined, label: 'CSKH'),
          _ServiceItem(
            icon: Icons.calendar_today_outlined, 
            label: 'Điểm danh',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoyaltyScreen())),
          ),
          _ServiceItem(
            icon: Icons.post_add_outlined, 
            label: 'Bài đăng',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyPostsScreen())),
          ),
          const _ServiceItem(icon: Icons.shield_outlined, label: 'Chính sách'),
        ],
      ),
    );
  }
}

class _ServiceItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _ServiceItem({required this.icon, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
     return InkWell(
       onTap: onTap,
       borderRadius: BorderRadius.circular(8),
       child: Container(
         width: 70, 
         padding: const EdgeInsets.symmetric(vertical: 4),
         child: Column(
          children: [
            Icon(icon, size: 26, color: Colors.black87),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontSize: 11)),
          ],
         ),
       ),
    );
  }
}

class _EngagementSection extends StatelessWidget {
  const _EngagementSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: IntrinsicHeight(
        child: Row(
          children: [
             Expanded(child: _EngagementItem(label: 'Đang theo dõi', subLabel: '0 shop', icon: Icons.storefront_outlined)),
             const VerticalDivider(),
             Expanded(
               child: Consumer<HistoryProvider>(
                 builder: (_, history, __) => _EngagementItem(
                   label: 'Lịch sử xem', 
                   subLabel: '${history.viewedProductIds.length} sản phẩm', 
                   icon: Icons.history_outlined,
                   onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryScreen())),
                 ),
               ),
             ),
             const VerticalDivider(),
             Expanded(
               child: Consumer<FavoriteProvider>(
                 builder: (_, fav, __) => _EngagementItem(
                   label: 'Yêu thích', 
                   subLabel: '${fav.favoriteIds.length} sản phẩm', 
                   icon: Icons.favorite_border,
                   onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FavoriteListScreen())),
                 ),
               ),
             ),
          ],
        ),
      ),
    );
  }
}

class _EngagementItem extends StatelessWidget {
  final String label;
  final String subLabel;
  final IconData icon;
  final VoidCallback? onTap;

  const _EngagementItem({required this.label, required this.subLabel, required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: Colors.black87),
              const SizedBox(width: 4),
              Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 4),
          Text(subLabel, style: const TextStyle(color: Colors.grey, fontSize: 11)),
        ],
      ),
    );
  }
}

class _RecommendationGrid extends StatelessWidget {
  const _RecommendationGrid();

  @override
  Widget build(BuildContext context) {
    // Reuse ProductService logic 
    return StreamBuilder<List<Product>>(
      stream: ProductService.instance.getProductsStream(status: ProductStatus.active),
      builder: (context, snapshot) {
         if (snapshot.hasError) return SliverToBoxAdapter(child: Text('Lỗi: ${snapshot.error}'));
         if (!snapshot.hasData) return const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator()));
         
         final products = snapshot.data!;
         if (products.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());

         return SliverPadding(
           padding: const EdgeInsets.symmetric(horizontal: 16),
           sliver: SliverGrid(
             gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
               crossAxisCount: 2,
               mainAxisSpacing: 10,
               crossAxisSpacing: 10,
               childAspectRatio: 0.65, // Adjust for product card ratio
             ),
             delegate: SliverChildBuilderDelegate(
               (context, index) {
                 final product = products[index];
                 return GestureDetector(
                   onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailScreen(product: product))),
                   child: Container(
                     decoration: BoxDecoration(
                       color: Colors.white,
                       borderRadius: BorderRadius.circular(4),
                       boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 4)],
                     ),
                     child: Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                         Expanded(
                           child: ClipRRect(
                             borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                             child: Image.network(
                               product.images.isNotEmpty ? product.images.first : '',
                               width: double.infinity,
                               fit: BoxFit.cover,
                               errorBuilder: (_,__,___) => Container(color: Colors.grey[200]),
                             ),
                           ),
                         ),
                         Padding(
                           padding: const EdgeInsets.all(8.0),
                           child: Column(
                             crossAxisAlignment: CrossAxisAlignment.start,
                             children: [
                               Text(product.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13)),
                               const SizedBox(height: 4),
                               Text('đ${product.price}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                             ],
                           ),
                         )
                       ],
                     ),
                   ),
                 );
               },
               childCount: products.length,
             ),
           ),
         );
      },
    );
  }
}
