import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'dashboard/admin_dashboard.dart';
import 'products/admin_products_screen.dart';
import 'orders/admin_orders_screen.dart';
import 'marketing/admin_coupon_screen.dart';
import 'ui/admin_interface_screen.dart';
import 'customers/admin_customers_screen.dart';



class AdminLayout extends StatefulWidget {
  const AdminLayout({super.key});

  @override
  State<AdminLayout> createState() => _AdminLayoutState();
}

class _AdminLayoutState extends State<AdminLayout> {
  int _selectedIndex = 0;
  bool _isCollapsed = false;

  final List<Widget> _screens = [
    const AdminDashboard(),
    const AdminProductsScreen(),
    const AdminOrdersScreen(),
    const AdminCustomersScreen(),
    const AdminCouponScreen(),
    const AdminInterfaceScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Row(
        children: [
          // Sidebar
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: _isCollapsed ? 70 : 250,
            color: AppColors.charcoal,
            child: Column(
              children: [
                // Logo Area
                Container(
                  height: 64,
                  alignment: Alignment.center,
                  child: _isCollapsed
                      ? const Icon(Icons.token, color: Colors.white)
                      : const Text(
                          'FASHION ADMIN',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                ),
                const Divider(color: Colors.white24, height: 1),
                
                // Menu Items
                const SizedBox(height: 16),
                _SidebarItem(
                  icon: Icons.dashboard_outlined,
                  label: 'Dashboard',
                  isSelected: _selectedIndex == 0,
                  isCollapsed: _isCollapsed,
                  onTap: () => setState(() => _selectedIndex = 0),
                ),
                _SidebarItem(
                  icon: Icons.shopping_bag_outlined,
                  label: 'Sản phẩm',
                  isSelected: _selectedIndex == 1,
                  isCollapsed: _isCollapsed,
                  onTap: () => setState(() => _selectedIndex = 1),
                ),
                _SidebarItem(
                  icon: Icons.local_shipping_outlined,
                  label: 'Đơn hàng',
                  isSelected: _selectedIndex == 2,
                  isCollapsed: _isCollapsed,
                  onTap: () => setState(() => _selectedIndex = 2),
                ),
                _SidebarItem(
                  icon: Icons.people_outline,
                  label: 'Khách hàng',
                  isSelected: _selectedIndex == 3,
                  isCollapsed: _isCollapsed,
                  onTap: () => setState(() => _selectedIndex = 3),
                ),
                _SidebarItem(
                  icon: Icons.campaign_outlined,
                  label: 'Marketing',
                  isSelected: _selectedIndex == 4,
                  isCollapsed: _isCollapsed,
                  onTap: () => setState(() => _selectedIndex = 4),
                ),
                 _SidebarItem(
                  icon: Icons.settings_outlined,
                  label: 'Cấu hình',
                  isSelected: _selectedIndex == 5,
                  isCollapsed: _isCollapsed,
                  onTap: () => setState(() => _selectedIndex = 5),
                ),
                
                const Spacer(),
                const Divider(color: Colors.white24),
                IconButton(
                  onPressed: () => setState(() => _isCollapsed = !_isCollapsed),
                  icon: Icon(
                    _isCollapsed ? Icons.chevron_right : Icons.chevron_left,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),

          // Main Content
          Expanded(
            child: Column(
              children: [
                // Header
                Container(
                  height: 64,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
                  ),
                  child: Row(
                    children: [
                      Text(
                        _getPageTitle(_selectedIndex),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.charcoal,
                        ),
                      ),
                      const Spacer(),
                      const CircleAvatar(
                        backgroundColor: AppColors.border,
                        child: Icon(Icons.person, color: AppColors.charcoal),
                      ),
                    ],
                  ),
                ),
                
                // Content Body
                Expanded(
                  child: _screens[_selectedIndex],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getPageTitle(int index) {
    switch (index) {
      case 0: return 'Dashboard';
      case 1: return 'Quản lý Sản phẩm';
      case 2: return 'Đơn hàng';
      case 3: return 'Khách hàng';
      case 4: return 'Marketing & Banner';
      case 5: return 'Cấu hình';
      default: return 'Admin Portal';
    }
  }
}

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.isCollapsed = false,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isCollapsed;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 50,
        margin: const EdgeInsets.symmetric(vertical: 2),
        decoration: BoxDecoration(
          border: isSelected
              ? const Border(left: BorderSide(color: Colors.white, width: 4))
              : null,
          color: isSelected ? Colors.white.withOpacity(0.1) : Colors.transparent,
        ),
        child: Row(
          children: [
            const SizedBox(width: 20),
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.white70,
              size: 22,
            ),
            if (!isCollapsed) ...[
              const SizedBox(width: 14),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white70,
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
