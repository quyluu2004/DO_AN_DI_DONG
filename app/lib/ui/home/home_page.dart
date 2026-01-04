import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'package:app/l10n/arb/app_localizations.dart'; // [NEW]

import '../../models/ui_config_model.dart';
import '../../services/ui_service.dart';

import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../profile/profile_screen.dart';
import '../../models/product_model.dart';
import '../../services/product_service.dart';
import '../product/product_detail_screen.dart';
import '../../providers/cart_provider.dart';
import '../../providers/favorite_provider.dart';
import '../search/search_screen.dart';
import '../cart/cart_screen.dart';
import '../try_on/virtual_try_on_screen.dart'; // [UPDATED]
import '../social_feed/social_feed_screen.dart'; // [NEW]
import '../product/favorite_list_screen.dart';
import '../../models/coupon_model.dart'; // [NEW]
import '../../services/coupon_service.dart'; // [NEW]
import '../components/flash_sale_widget.dart'; // [NEW]

class FashionHomePage extends StatefulWidget {
  const FashionHomePage({super.key});

  @override
  State<FashionHomePage> createState() => _FashionHomePageState();
}


class _FashionHomePageState extends State<FashionHomePage> {
  int _currentIndex = 0;
  List<Widget> _pages = [];

  @override
  void initState() {
    super.initState();
    _pages = [
      const _HomeTab(),
      const SocialFeedScreen(), // [UPDATED]
      const VirtualTryOnScreen(), // [UPDATED] Using the new Class
      const CartScreen(),
      const ProfileScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(
            index: _currentIndex,
            children: _pages,
          ),
          // Flash Sale Widget Overlay
          StreamBuilder<List<CouponModel>>(
            stream: CouponService.instance.getFlashSaleCoupons(),
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.isEmpty) return const SizedBox.shrink();
              final coupon = snapshot.data!.first;
              if (coupon.endTime == null) return const SizedBox.shrink();
              return FlashSaleWidget(
                endTime: coupon.endTime!,
                code: coupon.code,
                discountValue: coupon.discountValue,
                discountType: coupon.discountType,
              );
            },
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10),
        unselectedLabelStyle: const TextStyle(fontSize: 10),
        items: [
          BottomNavigationBarItem(icon: const Icon(Icons.home_filled), label: l10n.home), // localized
          BottomNavigationBarItem(icon: const Icon(Icons.style_outlined), label: l10n.style), // localized
          BottomNavigationBarItem(icon: const Icon(Icons.checkroom), label: l10n.tryOn), // localized
          BottomNavigationBarItem(
            icon: Consumer<CartProvider>(
              builder: (context, cart, child) {
                return Badge(
                  isLabelVisible: cart.itemCount > 0,
                  label: Text('${cart.itemCount}'),
                  child: const Icon(Icons.shopping_cart_outlined),
                );
              },
            ),
            label: l10n.cart, // localized
          ),
          BottomNavigationBarItem(icon: const Icon(Icons.person_outline), label: l10n.profile), // localized
        ],
      ),
    );
  }
}

class _HomeTab extends StatefulWidget {
  const _HomeTab();

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  String _selectedCategory = 'Xem tất cả';

  void _onCategorySelected(String category) {
    setState(() {
      _selectedCategory = category;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          // 1. Custom Header (Search Bar)
          const _HomeHeader(),
          
          Expanded(
            child: CustomScrollView(
              slivers: [
                // 2. Category Tabs (Text Tabs)
                SliverToBoxAdapter(
                  child: _CategoryTabs(
                    selectedCategory: _selectedCategory,
                    onCategorySelected: _onCategorySelected,
                  ),
                ),

                // 3. Banner Slider (Updated)
                const SliverToBoxAdapter(child: _BannerSlider()),
                
                // 4. Category Icons Grid (New)
                const SliverToBoxAdapter(child: _CategoryIconsGrid()),

                // 5. Free Shipping Strip
                const SliverToBoxAdapter(child: _FreeShippingStrip()),

                // 6. Flash Sale / Super Deals
                const SliverToBoxAdapter(child: _FlashSaleSection()),

                // 7. Navigation Chips
                const SliverToBoxAdapter(child: _NavigationChips()),
                

                // 8. Promo Banner
                const SliverToBoxAdapter(child: _PromoBanner()),
                
                // 9. Recommendation Grid
                _ProductGrid(category: _selectedCategory),
                
                const SliverToBoxAdapter(child: SizedBox(height: 20)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ... _HomeHeader, _DynamicCategoryTabs unchanged ...

class _BannerSlider extends StatefulWidget {
  const _BannerSlider();

  @override
  State<_BannerSlider> createState() => _BannerSliderState();
}

class _BannerSliderState extends State<_BannerSlider> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<HomeConfig>(
      stream: UIService.instance.getHomeConfigStream(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final banners = snapshot.data!.banners;

        if (banners.isEmpty) return const SizedBox.shrink();

        return Column(
          children: [
            SizedBox(
              height: 200,
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemCount: banners.length,
                itemBuilder: (context, index) {
                  final banner = banners[index];
                  return GestureDetector(
                    onTap: () {
                      // Handle parsing actionType and actionValue (web, category, product)
                    },
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        banner.imageUrl.isNotEmpty
                            ? Image.network(banner.imageUrl, fit: BoxFit.cover)
                            : Container(color: Colors.grey[300]),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.black.withOpacity(0.4), Colors.transparent],
                              begin: Alignment.bottomLeft,
                              end: Alignment.center,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                banners.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == index ? 20 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: _currentPage == index ? Colors.black : Colors.grey[300],
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _CategoryIconsGrid extends StatelessWidget {
  const _CategoryIconsGrid();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<String>>(
      future: ProductService.instance.getUniqueCategories(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) return const SizedBox.shrink();
        final categories = snapshot.data!;

        return Container(
          height: 200, // Adjusted height for 2 rows
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: GridView.builder(
            scrollDirection: Axis.horizontal,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.0,
            ),
            itemCount: categories.length,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemBuilder: (context, index) {
              return _CategoryIconItem(category: categories[index]);
            },
          ),
        );
      },
    );
  }
}

class _CategoryIconItem extends StatelessWidget {
  final String category;
  const _CategoryIconItem({required this.category});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Product?>(
      future: ProductService.instance.getFirstProductByCategory(category),
      builder: (context, snapshot) {
        final imageUrl = snapshot.data?.primaryImageUrl;

        return Column(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey[100],
                  border: Border.all(color: Colors.grey[200]!),
                  image: imageUrl != null 
                    ? DecorationImage(image: NetworkImage(imageUrl), fit: BoxFit.cover)
                    : null,
                ),
                child: imageUrl == null ? const Icon(Icons.category, color: Colors.grey) : null,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              category, 
              style: const TextStyle(fontSize: 11), 
              textAlign: TextAlign.center, 
              maxLines: 1, 
              overflow: TextOverflow.ellipsis
            ),
          ],
        );
      },
    );
  }
}

// Remove old FeaturedBanner if present in file to avoid conflicts or duplication

class _HomeHeader extends StatelessWidget {
  const _HomeHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: Colors.white,
      child: Row(
        children: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.mail_outline, color: Colors.black87)),
          IconButton(onPressed: () {}, icon: const Icon(Icons.calendar_today_outlined, color: Colors.black87)),
          Expanded(
            child: GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SearchScreen())),
              child: Container(
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Row(
                  children: [
                    Text(AppLocalizations.of(context)!.searchPlaceholder, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(color: Colors.orange[50], borderRadius: BorderRadius.circular(4)),
                      child: Text(AppLocalizations.of(context)!.recently, style: const TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                    const Spacer(),
                    const Icon(Icons.camera_alt_outlined, color: Colors.grey, size: 20),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(color: Colors.black, shape: BoxShape.circle),
                      child: const Icon(Icons.search, color: Colors.white, size: 14),
                    ),
                  ],
                ),
              ),
            ),
          ),
          IconButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FavoriteListScreen())),
            icon: const Icon(Icons.favorite_border, color: Colors.black87),
          ),
        ],
      ),
    );
  }
}

class _CategoryTabs extends StatelessWidget {
  final String selectedCategory;
  final ValueChanged<String> onCategorySelected;

  const _CategoryTabs({
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    // Categories as per user request
    final categories = ['Xem tất cả', 'Nam', 'Nữ', 'Kid', 'Phụ kiện'];
    
    return Container(
      height: 40,
      color: Colors.white,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = category == selectedCategory;
          return GestureDetector(
            onTap: () => onCategorySelected(category),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 12),
              alignment: Alignment.center,
              decoration: isSelected ? const BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.black, width: 2))
              ) : null,
              child: Text(
                category,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? Colors.black : Colors.black54,
                  fontSize: 14,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _FreeShippingStrip extends StatelessWidget {
  const _FreeShippingStrip();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<HomeConfig>(
      stream: UIService.instance.getHomeConfigStream(),
      builder: (context, snapshot) {
        final config = snapshot.data?.announcement ?? AnnouncementConfig();
        
        return Container(
          width: double.infinity,
          color: Color(int.parse(config.backgroundColor.replaceFirst('#', '0xff'))),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: [
                if (config.icon != null) ...[
                   Icon(Icons.local_shipping, color: Color(int.parse(config.textColor.replaceFirst('#', '0xff'))), size: 16), // Use icon font or default
                   const SizedBox(width: 4),
                ],
                Text(
                  config.content, 
                  style: TextStyle(
                    color: Color(int.parse(config.textColor.replaceFirst('#', '0xff'))), 
                    fontWeight: FontWeight.bold
                  )
                ),
              ]),
              if (config.clickable)
                const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
            ],
          ),
        );
      }
    );
  }
}

class _FlashSaleSection extends StatelessWidget {
  const _FlashSaleSection();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<HomeConfig>(
      stream: UIService.instance.getHomeConfigStream(),
      builder: (context, snapshot) {
        final config = snapshot.data?.flashSale ?? FlashSaleConfig();
        
        // If 'auto', fetch from ProductService logic
        if (config.type == 'auto') {
           return StreamBuilder<List<Product>>(
            stream: ProductService.instance.getFlashSaleProducts(limit: 5),
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.isEmpty) return const SizedBox.shrink();
              return _buildContent(context, config.title, config.endTime, snapshot.data!);
            }
           );
        } else {
           // 'manual' - Fetch specific products (Coming soon, for now showing randoms or empty)
           // For MVP, just reusing auto logic if manual list is empty
           if (config.productIds.isEmpty) return const SizedBox.shrink();
           return const SizedBox.shrink(); // TODO: Implement fetchByIds
        }
      },
    );
  }

  Widget _buildContent(BuildContext context, String title, DateTime? endTime, List<Product> products) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const Spacer(),
              if (endTime != null) 
                 // Simple countdown placeholder
                 Container(
                   padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                   color: Colors.black,
                   child: const Text('Ending Soon', style: TextStyle(color: Colors.white, fontSize: 10)),
                 ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
        SizedBox(
          height: 160,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            scrollDirection: Axis.horizontal,
            itemCount: products.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final product = products[index];
              return _FlashSaleItem(product: product);
            },
          ),
        ),
      ],
    );
  }
}

class _FlashSaleItem extends StatelessWidget {
  final Product product;
  const _FlashSaleItem({required this.product});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailScreen(product: product))),
      child: SizedBox(
        width: 100,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Container(
                  height: 100,
                  width: 100,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(4),
                    image: product.primaryImageUrl != null ? DecorationImage(image: NetworkImage(product.primaryImageUrl!), fit: BoxFit.cover) : null,
                  ),
                ),
                Positioned(
                  top: 0,
                  left: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    color: Colors.yellow,
                    child: const Text('-10%', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                )
              ],
            ),
            const SizedBox(height: 6),
            Text('đ${product.price}', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            LinearProgressIndicator(value: 0.8, backgroundColor: Colors.grey[200], color: Colors.orange, minHeight: 4),
          ],
        ),
      ),
    );
  }
}


class _NavigationChips extends StatelessWidget {
  const _NavigationChips();

  @override
  Widget build(BuildContext context) {
    final items = [
      {'icon': Icons.favorite, 'label': AppLocalizations.of(context)!.forYou, 'active': true},
      {'icon': Icons.new_releases, 'label': AppLocalizations.of(context)!.newArrivals, 'active': false},
      {'icon': Icons.local_offer, 'label': AppLocalizations.of(context)!.deals, 'active': false},
      {'icon': Icons.star, 'label': AppLocalizations.of(context)!.bestSellers, 'active': false},
    ];

    return Container(
      color: Colors.grey[50],
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: items.map((item) => _NavChip(
          icon: item['icon'] as IconData, 
          label: item['label'] as String,
          isActive: item['active'] as bool,
        )).toList(),
      ),
    );
  }
}

class _NavChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;

  const _NavChip({required this.icon, required this.label, this.isActive = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isActive ? Colors.black87 : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: isActive ? [] : [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 4)],
      ),
      child: Row(
        children: [
          if (!isActive) Icon(icon, size: 16, color: Colors.black54),
          if (!isActive) const SizedBox(width: 4),
          Text(
            label, 
            style: TextStyle(
              color: isActive ? Colors.white : Colors.black87,
              fontWeight: FontWeight.bold,
              fontSize: 13
            )
          ),
        ],
      ),
    );
  }
}

class _FeaturedBanner extends StatelessWidget {
  const _FeaturedBanner();

  @override
  Widget build(BuildContext context) {
    // Dynamic Banner from Product Images would be ideal, 
    // but for now let's just use a placeholder to match the layout
    return StreamBuilder<List<Product>>(
      stream: ProductService.instance.getProductsStream(sortBy: 'createdAt', limit: 3), // Get 3 newest
      builder: (context, snapshot) {
         if (!snapshot.hasData || snapshot.data!.isEmpty) return const SizedBox.shrink();
         
         final product = snapshot.data!.first; // Just highlight the newest one for now
         
         return Container(
           margin: const EdgeInsets.all(12),
           height: 200,
           child: Stack(
             children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: product.primaryImageUrl != null 
                    ? Image.network(product.primaryImageUrl!, width: double.infinity, height: 200, fit: BoxFit.cover)
                    : Container(color: Colors.black),
                ),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    gradient: LinearGradient(
                      colors: [Colors.black.withOpacity(0.6), Colors.transparent],
                      begin: Alignment.bottomLeft,
                      end: Alignment.topRight
                    )
                  ),
                ),
                Positioned(
                  bottom: 16,
                  left: 16,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                       const Text('New Arrival', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 24)),
                       const SizedBox(height: 8),
                       ElevatedButton(
                         onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailScreen(product: product))),
                         style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black),
                         child: const Text('SHOP NOW'),
                       )
                    ],
                  ),
                )
             ],
           ),
         );
      },
    );
  }
}

class _ProductGrid extends StatelessWidget {
  final String category;
  const _ProductGrid({required this.category});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Product>>(
      stream: ProductService.instance.getProductsStream(
        status: ProductStatus.active,
        category: category,
      ),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
           return SliverToBoxAdapter(
             child: Padding(
               padding: const EdgeInsets.all(20),
               child: Center(
                 child: SelectableText(
                   'Lỗi Firestore (Cần tạo Index): ${snapshot.error}', 
                   style: const TextStyle(color: Colors.red),
                   textAlign: TextAlign.center,
                 ),
               ),
             ),
           );
        }
        if (!snapshot.hasData) {
           return const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.data!.isEmpty) {
           return const SliverToBoxAdapter(child: Center(child: Text('Không có sản phẩm nào')));
        }
        final products = snapshot.data!;

        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 0.60,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final product = products[index];
                return _ProductCard(product: product);
              },
              childCount: products.length,
            ),
          ),
        );
      },
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Product product;
  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
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
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                    child: product.primaryImageUrl != null 
                      ? Image.network(product.primaryImageUrl!, width: double.infinity, fit: BoxFit.cover)
                      : Container(color: Colors.grey[200]),
                  ),
                  Positioned(
                    bottom: 8,
                    left: 8,
                    child: Consumer<FavoriteProvider>(
                      builder: (context, favoriteProvider, child) {
                        final isFavorite = favoriteProvider.isFavorite(product.id);
                        return GestureDetector(
                          onTap: () {
                             favoriteProvider.toggleFavorite(product.id);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isFavorite ? Icons.favorite : Icons.favorite_border,
                              size: 18,
                              color: isFavorite ? Colors.red : Colors.grey,
                            ),
                          ),
                        );
                      }
                    ),
                  )
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text('đ${product.price}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.red)),
                      const SizedBox(width: 6),
                      const Text('-35%', style: TextStyle(color: Colors.grey, fontSize: 11)),
                    ],
                  ),
                  const SizedBox(height: 4),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PromoBanner extends StatelessWidget {
  const _PromoBanner();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<HomeConfig>(
      stream: UIService.instance.getHomeConfigStream(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final config = snapshot.data!.promoBanner;
        
        if (config.imageUrl.isEmpty) return const SizedBox.shrink();

        return GestureDetector(
          onTap: () {
            // Handle navigation based on config.destination
          },
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            height: 150,
            width: double.infinity,
            child: Image.network(
              config.imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          ),
        );
      },
    );
  }
}
