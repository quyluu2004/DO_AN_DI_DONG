import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/address_provider.dart';
import '../../models/address_model.dart';
import '../../services/auth_service.dart';

class AddEditAddressScreen extends StatefulWidget {
  final Address? address;
  const AddEditAddressScreen({super.key, this.address});

  @override
  State<AddEditAddressScreen> createState() => _AddEditAddressScreenState();
}

class _AddEditAddressScreenState extends State<AddEditAddressScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _provinceController;
  late TextEditingController _districtController;
  late TextEditingController _wardController;
  late TextEditingController _streetController;
  bool _isDefault = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.address?.name ?? '');
    _phoneController = TextEditingController(text: widget.address?.phone ?? '');
    _provinceController = TextEditingController(text: widget.address?.province ?? '');
    _districtController = TextEditingController(text: widget.address?.district ?? '');
    _wardController = TextEditingController(text: widget.address?.ward ?? '');
    _streetController = TextEditingController(text: widget.address?.streetAddress ?? '');
    _isDefault = widget.address?.isDefault ?? false;
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _provinceController.dispose();
    _districtController.dispose();
    _wardController.dispose();
    _streetController.dispose();
    super.dispose();
  }

  Future<void> _saveAddress() async {
    if (!_formKey.currentState!.validate()) return;
    
    final userId = AuthService.instance.currentUser?.uid;
    if (userId == null) return;
    
    final newAddress = Address(
      id: widget.address?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      province: _provinceController.text.trim(),
      district: _districtController.text.trim(),
      ward: _wardController.text.trim(),
      streetAddress: _streetController.text.trim(),
      isDefault: _isDefault,
    );
    
    try {
      final provider = context.read<AddressProvider>();
      if (widget.address == null) {
        await provider.addAddress(userId, newAddress);
      } else {
        await provider.updateAddress(userId, newAddress);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    }
  }

  Future<void> _deleteAddress() async {
      final userId = AuthService.instance.currentUser?.uid;
      if (userId == null || widget.address == null) return;
      
      try {
        await context.read<AddressProvider>().deleteAddress(userId, widget.address!.id);
        if (mounted) Navigator.pop(context);
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.address != null;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Sửa địa chỉ' : 'Thêm địa chỉ mới', style: const TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
        actions: [
          if (isEditing)
             TextButton(
               onPressed: _deleteAddress,
               child: const Text('Xóa', style: TextStyle(color: Colors.red)),
             )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Liên hệ', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Họ và tên', border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? 'Vui lòng nhập tên' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Số điện thoại', border: OutlineInputBorder()),
                 keyboardType: TextInputType.phone,
                validator: (v) => v!.isEmpty ? 'Vui lòng nhập SĐT' : null,
              ),
              
              const SizedBox(height: 24),
              const Text('Địa chỉ', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              TextFormField(
                controller: _provinceController,
                decoration: const InputDecoration(labelText: 'Tỉnh/Thành phố', border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? 'Vui lòng nhập Tỉnh/Thành' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _districtController,
                decoration: const InputDecoration(labelText: 'Quận/Huyện', border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? 'Vui lòng nhập Quận/Huyện' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _wardController,
                decoration: const InputDecoration(labelText: 'Phường/Xã', border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? 'Vui lòng nhập Phường/Xã' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _streetController,
                decoration: const InputDecoration(labelText: 'Tên đường, toà nhà, số nhà.', border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? 'Vui lòng nhập địa chỉ cụ thể' : null,
              ),
              
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text('Đặt làm địa chỉ mặc định'),
                  const Spacer(),
                  Switch(
                    value: _isDefault, 
                    onChanged: (val) => setState(() => _isDefault = val),
                    activeColor: Colors.black,
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _saveAddress,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text('HOÀN THÀNH'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
