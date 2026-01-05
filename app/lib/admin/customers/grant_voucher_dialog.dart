import 'package:flutter/material.dart';
import '../../models/coupon_model.dart';
import '../../services/coupon_service.dart';
import 'package:intl/intl.dart';

class GrantVoucherDialog extends StatefulWidget {
  final String userId;
  final String userName;

  const GrantVoucherDialog({super.key, required this.userId, required this.userName});

  @override
  State<GrantVoucherDialog> createState() => _GrantVoucherDialogState();
}

class _GrantVoucherDialogState extends State<GrantVoucherDialog> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _titleController = TextEditingController();
  final _discountController = TextEditingController();
  final _minOrderController = TextEditingController(text: '0');

  String _discountType = 'percent'; // 'percent' or 'fixed'
  DateTime _expiryDate = DateTime.now().add(const Duration(days: 7));
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Auto-generate a random code
    _codeController.text = 'GIFT${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
    _titleController.text = 'Voucher tặng riêng cho bạn';
  }

  @override
  void dispose() {
    _codeController.dispose();
    _titleController.dispose();
    _discountController.dispose();
    _minOrderController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final coupon = CouponModel(
        id: '', // Firestore auto-id
        code: _codeController.text.trim().toUpperCase(),
        title: _titleController.text.trim(),
        type: CouponType.orderDiscount,
        discountType: _discountType,
        discountValue: double.parse(_discountController.text.trim()),
        minOrderValue: double.parse(_minOrderController.text.trim()),
        targetCategories: [],
        isActive: true,
        startDate: DateTime.now(),
        endDate: _expiryDate,
        allowedUserIds: [widget.userId], // PRIVATE TO THIS USER
      );

      await CouponService.instance.addCoupon(coupon);

      if (mounted) {
        Navigator.pop(context, true); // Success
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã tặng voucher thành công!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Tặng Voucher cho ${widget.userName}'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _codeController,
                decoration: const InputDecoration(labelText: 'Mã Voucher', hintText: 'VD: GIFT2026'),
                textCapitalization: TextCapitalization.characters,
                validator: (v) => v!.isEmpty ? 'Nhập mã voucher' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Tên hiển thị'),
                validator: (v) => v!.isEmpty ? 'Nhập tên hiển thị' : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _discountType,
                      decoration: const InputDecoration(labelText: 'Loại giảm giá'),
                      items: const [
                        DropdownMenuItem(value: 'percent', child: Text('Phần trăm (%)')),
                        DropdownMenuItem(value: 'fixed', child: Text('Số tiền (VNĐ)')),
                      ],
                      onChanged: (v) => setState(() => _discountType = v!),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _discountController,
                      decoration: const InputDecoration(labelText: 'Giá trị'),
                      keyboardType: TextInputType.number,
                      validator: (v) => v!.isEmpty ? 'Nhập giá trị' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _minOrderController,
                decoration: const InputDecoration(labelText: 'Đơn tối thiểu (VNĐ)'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                   const Text('Hết hạn: '),
                   TextButton(
                     onPressed: () async {
                       final date = await showDatePicker(
                         context: context, 
                         initialDate: _expiryDate, 
                         firstDate: DateTime.now(), 
                         lastDate: DateTime(2030)
                       );
                       if (date != null) setState(() => _expiryDate = date);
                     },
                     child: Text(DateFormat('dd/MM/yyyy').format(_expiryDate)),
                   )
                ],
              )
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
        ElevatedButton(
          onPressed: _isLoading ? null : _submit, 
          child: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Gửi Tặng'),
        ),
      ],
    );
  }
}
