import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/coupon_model.dart';
import '../../services/coupon_service.dart';

class AddCouponScreen extends StatefulWidget {
  @override
  _AddCouponScreenState createState() => _AddCouponScreenState();
}

class _AddCouponScreenState extends State<AddCouponScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _titleController = TextEditingController();
  final _valueController = TextEditingController();
  final _minOrderController = TextEditingController();
  final _maxDiscountController = TextEditingController(); // Dùng cho %

  String _discountType = 'fixed'; // 'fixed' hoặc 'percent'
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(Duration(days: 7));
  
  // Danh sách các category (Bạn nên lấy từ Firebase Category Collection)
  final List<String> _availableCategories = ['Áo', 'Quần', 'Giày', 'Phụ kiện'];
  List<String> _selectedCategories = [];

  Future<void> _saveCoupon() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final newCoupon = CouponModel(
        id: '', // Firestore tự sinh ID
        code: _codeController.text,
        title: _titleController.text,
        discountType: _discountType,
        discountValue: double.parse(_valueController.text),
        maxDiscount: _maxDiscountController.text.isNotEmpty 
            ? double.parse(_maxDiscountController.text) : null,
        minOrderValue: _minOrderController.text.isNotEmpty 
            ? double.parse(_minOrderController.text) : 0,
        targetCategories: _selectedCategories,
        isActive: true,
        startDate: _startDate,
        endDate: _endDate,
      );

      await CouponService.instance.addCoupon(newCoupon);

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Đã tạo mã thành công!')));
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Tạo khuyến mãi mới")),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _codeController,
                decoration: InputDecoration(labelText: 'Mã Coupon (VD: SALE50)', border: OutlineInputBorder()),
                textCapitalization: TextCapitalization.characters,
                validator: (v) => v!.isEmpty ? 'Nhập mã' : null,
              ),
              SizedBox(height: 10),
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(labelText: 'Tên chương trình', border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? 'Nhập tên' : null,
              ),
              SizedBox(height: 20),
              
              Text("Loại giảm giá:", style: TextStyle(fontWeight: FontWeight.bold)),
              Row(
                children: [
                  Expanded(
                    child: RadioListTile(
                      title: Text("Số tiền (VNĐ)"),
                      value: 'fixed',
                      groupValue: _discountType,
                      onChanged: (v) => setState(() => _discountType = v.toString()),
                    ),
                  ),
                  Expanded(
                    child: RadioListTile(
                      title: Text("Phần trăm (%)"),
                      value: 'percent',
                      groupValue: _discountType,
                      onChanged: (v) => setState(() => _discountType = v.toString()),
                    ),
                  ),
                ],
              ),
              
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _valueController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: _discountType == 'percent' ? 'Số % giảm' : 'Số tiền giảm',
                        suffixText: _discountType == 'percent' ? '%' : 'đ'
                      ),
                      validator: (v) => v!.isEmpty ? 'Nhập giá trị' : null,
                    ),
                  ),
                  SizedBox(width: 10),
                  if (_discountType == 'percent')
                  Expanded(
                    child: TextFormField(
                      controller: _maxDiscountController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(labelText: 'Giảm tối đa (đ)'),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10),
              TextFormField(
                controller: _minOrderController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'Giá trị đơn tối thiểu (đ)'),
              ),

              SizedBox(height: 20),
              Text("Áp dụng cho danh mục:", style: TextStyle(fontWeight: FontWeight.bold)),
              Wrap(
                spacing: 8,
                children: _availableCategories.map((cat) {
                  final isSelected = _selectedCategories.contains(cat);
                  return FilterChip(
                    label: Text(cat),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedCategories.add(cat);
                        } else {
                          _selectedCategories.remove(cat);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              if (_selectedCategories.isEmpty)
                Text("Không chọn danh mục nào = Áp dụng cho TOÀN BỘ sản phẩm", 
                     style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),

              SizedBox(height: 20),
              // Nút lưu
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveCoupon,
                  child: Padding(padding: EdgeInsets.all(15), child: Text("TẠO MÃ")),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}