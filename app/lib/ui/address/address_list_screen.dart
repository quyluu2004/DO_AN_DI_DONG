import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/address_provider.dart';
import '../../services/auth_service.dart';
import 'add_edit_address_screen.dart';

class AddressListScreen extends StatefulWidget {
  final bool isSelecting;
  const AddressListScreen({super.key, this.isSelecting = false});

  @override
  State<AddressListScreen> createState() => _AddressListScreenState();
}

class _AddressListScreenState extends State<AddressListScreen> {
  @override
  void initState() {
    super.initState();
    final userId = AuthService.instance.currentUser?.uid;
    if (userId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<AddressProvider>().fetchAddresses(userId);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Địa chỉ của tôi', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
      ),
      body: Consumer<AddressProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.addresses.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.location_off_outlined, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('Bạn chưa lưu địa chỉ nào'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => _navigateToAddEdit(context),
                    child: const Text('Thêm địa chỉ mới'),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: provider.addresses.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final address = provider.addresses[index];
              final isSelected = provider.selectedAddress?.id == address.id;

              return InkWell(
                onTap: widget.isSelecting 
                  ? () {
                      provider.selectAddress(address.id);
                      Navigator.pop(context);
                    } 
                  : null,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected && widget.isSelecting ? Colors.black : Colors.grey[300]!,
                      width: isSelected && widget.isSelecting ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${address.name}  |  ${address.phone}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                          ),
                          if (address.isDefault)
                            Container(
                              margin: const EdgeInsets.only(left: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text('Mặc định', style: TextStyle(fontSize: 10)),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        address.fullAddress,
                        style: const TextStyle(color: Colors.grey, height: 1.3),
                      ),
                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton.icon(
                            onPressed: () => _navigateToAddEdit(context, address: address),
                            icon: const Icon(Icons.edit, size: 16, color: Colors.grey),
                            label: const Text('Sửa', style: TextStyle(color: Colors.grey)),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(16),
        color: Colors.white,
        child: SafeArea(
          child: ElevatedButton(
            onPressed: () => _navigateToAddEdit(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 50),
            ),
             child: const Text('+ Thêm địa chỉ gửi hàng'),
          ),
        ),
      ),
    );
  }

  void _navigateToAddEdit(BuildContext context, {dynamic address}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddEditAddressScreen(address: address),
      ),
    );
  }
}
