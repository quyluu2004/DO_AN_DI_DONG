import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/user_model.dart';
import '../../services/user_service.dart';
import '../../theme/app_theme.dart';

class AdminCustomersScreen extends StatefulWidget {
  const AdminCustomersScreen({super.key});

  @override
  State<AdminCustomersScreen> createState() => _AdminCustomersScreenState();
}

class _AdminCustomersScreenState extends State<AdminCustomersScreen> {
  final UserService _userService = UserService.instance;
  String _searchQuery = '';
  String? _filterRole;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Toolbar
          Row(
            children: [
              // Search Box
              SizedBox(
                width: 300,
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Tìm theo tên, email, sđt...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val),
                ),
              ),
              const SizedBox(width: 16),
              
              // Role Filter
              DropdownButton<String?>(
                value: _filterRole,
                hint: const Text('Tất cả vai trò'),
                underline: const SizedBox(),
                items: const [
                   DropdownMenuItem(value: null, child: Text('Tất cả vai trò')),
                   DropdownMenuItem(value: 'buyer', child: Text('Khách hàng')),
                   DropdownMenuItem(value: 'admin', child: Text('Admin')),
                   DropdownMenuItem(value: 'staff', child: Text('Nhân viên')),
                ],
                onChanged: (val) => setState(() => _filterRole = val),
              ),
              
              const Spacer(),
              
              // Stats or Actions (Optional)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Quản lý người dùng',
                      style: TextStyle(color: Colors.blue, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Users Table
          Expanded(
            child: StreamBuilder<List<UserModel>>(
              stream: _userService.getUsersStream(query: _searchQuery, role: _filterRole),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Lỗi tải dữ liệu: ${snapshot.error}'));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final users = snapshot.data ?? [];

                if (users.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.person_search_outlined, size: 64, color: Colors.black26),
                        SizedBox(height: 16),
                        Text('Không tìm thấy người dùng nào', style: TextStyle(color: Colors.black45)),
                      ],
                    ),
                  );
                }

                return Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: Colors.grey[200]!),
                  ),
                  child: ListView.separated(
                    itemCount: users.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final user = users[index];
                      return _buildUserItem(context, user);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserItem(BuildContext context, UserModel user) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: CircleAvatar(
        radius: 24,
        backgroundColor: Colors.grey[200],
        backgroundImage: user.avatarUrl.isNotEmpty ? NetworkImage(user.avatarUrl) : null,
        child: user.avatarUrl.isEmpty 
            ? Text(user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : '?', 
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))
            : null,
      ),
      title: Row(
        children: [
          Text(user.fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          _UserRoleBadge(role: user.role),
          if (user.isVerified) ...[
            const SizedBox(width: 8),
            const Icon(Icons.verified, color: Colors.blue, size: 16),
          ],
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.email_outlined, size: 14, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(user.email, style: TextStyle(color: Colors.grey[600])),
              const SizedBox(width: 16),
              if (user.phoneNumber.isNotEmpty) ...[
                Icon(Icons.phone_outlined, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(user.phoneNumber, style: TextStyle(color: Colors.grey[600])),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
               Icon(Icons.star_outline, size: 14, color: Colors.amber[700]),
               const SizedBox(width: 4),
               Text('${user.points} điểm • ${user.tier.toUpperCase()}', 
                style: TextStyle(color: Colors.amber[900], fontWeight: FontWeight.w500, fontSize: 12)),
            ],
          ),
        ],
      ),
      trailing: IconButton(
        icon: const Icon(Icons.more_vert),
        onPressed: () {
          // Show user details dialog or actions
          _showUserDetails(context, user);
        },
      ),
    );
  }

  void _showUserDetails(BuildContext context, UserModel user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Thông tin: ${user.fullName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _detailRow('Email:', user.email),
            _detailRow('SĐT:', user.phoneNumber.isEmpty ? 'Chưa cập nhật' : user.phoneNumber),
            _detailRow('Giới tính:', user.gender),
            _detailRow('Ngày sinh:', user.birthday != null ? DateFormat('dd/MM/yyyy').format(user.birthday!) : 'Chưa cập nhật'),
            _detailRow('Chi tiêu:', '${NumberFormat('#,###').format(user.totalSpent)} đ'),
            _detailRow('Ngày tham gia:', user.lastCheckInDate != null ? DateFormat('dd/MM/yyyy').format(user.lastCheckInDate!) : 'Unknown'), // Using checkIn as proxy if createdAt missing
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 100, child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black54))),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class _UserRoleBadge extends StatelessWidget {
  final String role;
  const _UserRoleBadge({required this.role});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;

    switch (role) {
      case 'admin':
        color = Colors.red;
        label = 'ADMIN';
        break;
      case 'staff':
        color = Colors.blue;
        label = 'NHÂN VIÊN';
        break;
      case 'buyer':
      default:
        color = Colors.green;
        label = 'KHÁCH HÀNG';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600),
      ),
    );
  }
}
