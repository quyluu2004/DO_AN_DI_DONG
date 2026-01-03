import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/coupon_model.dart';
import '../../services/coupon_service.dart';
import '../../services/ui_service.dart'; // Import UIService

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
  final _maxShippingDiscountController = TextEditingController(); // Dùng cho FreeShip

  // Biến cho Flash Sale
  bool isFlashSale = false;
  DateTime? _selectedDate;
  final TextEditingController _hourController = TextEditingController(text: "0");
  final TextEditingController _minuteController = TextEditingController(text: "0");
  final TextEditingController _secondController = TextEditingController(text: "0");

  CouponType _couponType = CouponType.orderDiscount; // Mặc định là giảm giá đơn
  String _discountType = 'fixed'; // 'fixed' hoặc 'percent'
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(Duration(days: 7));
  
  // Danh sách các category (Bạn nên lấy từ Firebase Category Collection)
  final List<String> _availableCategories = ['Áo', 'Quần', 'Giày', 'Phụ kiện'];
  List<String> _selectedCategories = [];

  Future<void> _saveCoupon() async {
    if (!_formKey.currentState!.validate()) return;

    // Nếu là FreeShip thì value có thể là 0 hoặc max shipping
    double discountValue = 0;
    if (_couponType == CouponType.orderDiscount) {
    // 1. Xử lý số liệu an toàn (Hỗ trợ nhập dấu phẩy thay vì dấu chấm)
      discountValue = double.tryParse(_valueController.text.replaceAll(',', '.')) ?? 0;
      if (discountValue == 0) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng nhập giá trị giảm')));
        return;
      }
    }

    double? maxDiscount;
    if (_maxDiscountController.text.isNotEmpty) {
      maxDiscount = double.tryParse(_maxDiscountController.text.replaceAll(',', '.'));
      if (maxDiscount == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Giảm tối đa không hợp lệ')));
        return;
      }
    }

    double maxShippingDiscount = 0;
    if (_couponType == CouponType.freeShip && _maxShippingDiscountController.text.isNotEmpty) {
      maxShippingDiscount = double.tryParse(_maxShippingDiscountController.text.replaceAll(',', '.')) ?? 0;
    }

    double minOrder = 0;
    if (_minOrderController.text.isNotEmpty) {
      minOrder = double.tryParse(_minOrderController.text.replaceAll(',', '.')) ?? 0;
    }

    DateTime? flashSaleEndTime;
    DateTime finalEndDate = _endDate; // Mặc định là 7 ngày nếu không phải Flash Sale

    if (isFlashSale) {
      if (_selectedDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vui lòng chọn ngày kết thúc Flash Sale'))
        );
        return;
      }
      
      int h = int.tryParse(_hourController.text) ?? 0;
      int m = int.tryParse(_minuteController.text) ?? 0;
      int s = int.tryParse(_secondController.text) ?? 0;

      flashSaleEndTime = DateTime(_selectedDate!.year, _selectedDate!.month, _selectedDate!.day, h, m, s);
      
      // 2. Kiểm tra thời gian phải ở tương lai
      if (flashSaleEndTime.isBefore(DateTime.now())) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lỗi: Thời gian kết thúc Flash Sale phải lớn hơn hiện tại!'))
        );
        return;
      }
      // 3. Đồng bộ ngày hết hạn coupon khớp với Flash Sale
      finalEndDate = flashSaleEndTime;
    }

    try {
      final newCoupon = CouponModel(
        id: '', // Firestore tự sinh ID
        code: _codeController.text,
        title: _titleController.text,
        type: _couponType,
        discountType: _discountType,
        discountValue: discountValue,
        maxDiscount: maxDiscount,
        maxShippingDiscount: maxShippingDiscount,
        minOrderValue: minOrder,
        targetCategories: _selectedCategories,
        isActive: true,
        startDate: _startDate,
        endDate: finalEndDate, // Sử dụng ngày đã đồng bộ
        isFlashSale: isFlashSale,
        endTime: flashSaleEndTime,
      );

      await CouponService.instance.addCoupon(newCoupon);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã tạo mã thành công!')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi hệ thống: $e')));
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
              
              // [CẬP NHẬT] Dùng Dropdown thay cho Radio theo yêu cầu
              DropdownButtonFormField<CouponType>(
                value: _couponType,
                decoration: const InputDecoration(
                  labelText: "Loại Voucher",
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: CouponType.orderDiscount, child: Text("Giảm giá đơn hàng")),
                  DropdownMenuItem(value: CouponType.freeShip, child: Text("Miễn phí vận chuyển (FreeShip)")),
                ],
                onChanged: (val) => setState(() => _couponType = val!),
              ),
              const SizedBox(height: 10),

              if (_couponType == CouponType.orderDiscount) ...[
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
              ] else ...[
                // UI cho Free Ship
                TextFormField(
                  controller: _maxShippingDiscountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Giảm tiền Ship tối đa (VD: 30000)',
                    helperText: 'Nhập 0 nếu miễn phí 100% không giới hạn',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],

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

              // --- KHỐI CODE FLASH SALE (BẮT ĐẦU) ---
              Container(
                margin: const EdgeInsets.only(top: 20, bottom: 20),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Cấu hình Flash Sale",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const Divider(),
                    
                    // 1. Nút Bật/Tắt
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text("Kích hoạt đếm ngược"),
                      subtitle: const Text("Hiển thị popup đếm ngược trên app"),
                      value: isFlashSale, // Đảm bảo biến này đã khai báo ở trên
                      activeColor: Colors.orange,
                      onChanged: (bool value) async {
                        setState(() {
                          isFlashSale = value;
                          // Reset ngày giờ nếu tắt đi bật lại để tránh lỗi
                          if (!value) {
                            _selectedDate = null;
                            _hourController.text = "0";
                            _minuteController.text = "0";
                            _secondController.text = "0";
                          } 
                        });

                        // TỰ ĐỘNG LẤY DỮ LIỆU TỪ FLASH SALE CONFIG KHI BẬT
                        if (value) {
                          final homeConfig = await UIService.instance.getHomeConfig();
                          final flashSaleConfig = homeConfig.flashSale;
                          
                          if (flashSaleConfig.endTime != null) {
                            setState(() {
                              _selectedDate = flashSaleConfig.endTime;
                              _hourController.text = flashSaleConfig.endTime!.hour.toString();
                              _minuteController.text = flashSaleConfig.endTime!.minute.toString();
                              _secondController.text = flashSaleConfig.endTime!.second.toString();
                              
                              // Tự động điền Code và Discount nếu có
                              if (flashSaleConfig.code != null) _codeController.text = flashSaleConfig.code!;
                              if (flashSaleConfig.discountValue != null) _valueController.text = flashSaleConfig.discountValue.toString();
                            });
                            
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                                content: Text('Đã tự động lấy cấu hình từ Flash Sale Manager!'),
                                backgroundColor: Colors.green,
                              ));
                            }
                          }
                        }
                      },
                    ),

                    // 2. Phần chọn ngày giờ (Hiện ra khi Switch bật ON)
                    if (isFlashSale) ...[ // Dùng cú pháp ...[] để đảm bảo an toàn trong List
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(top: 10),
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50, // Màu nền xanh nhạt cho dễ nhìn
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 1. CHỌN NGÀY KẾT THÚC
                            const Text("1. Ngày kết thúc:", 
                                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                            const SizedBox(height: 8),
                            InkWell(
                              onTap: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: DateTime.now(),
                                  firstDate: DateTime.now(),
                                  lastDate: DateTime(2030),
                                );
                                if (date != null) {
                                  setState(() => _selectedDate = date);
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border.all(color: Colors.grey.shade400),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _selectedDate == null 
                                        ? "Chọn ngày..." 
                                        : "Ngày ${_selectedDate!.day} / ${_selectedDate!.month} / ${_selectedDate!.year}",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: _selectedDate == null ? Colors.grey : Colors.black87
                                      ),
                                    ),
                                    const Icon(Icons.calendar_today, color: Colors.blue),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 20),

                            // 2. CHỌN GIỜ : PHÚT : GIÂY
                            const Text("2. Thời gian cụ thể (Đếm ngược đến):", 
                                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                // Ô nhập Giờ
                                _buildTimeInput(_hourController, "Giờ (0-23)"),
                                const Text(" : ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                                // Ô nhập Phút
                                _buildTimeInput(_minuteController, "Phút (0-59)"),
                                const Text(" : ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                                // Ô nhập Giây
                                _buildTimeInput(_secondController, "Giây (0-59)"),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // --- KHỐI CODE FLASH SALE (KẾT THÚC) ---

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

  Widget _buildTimeInput(TextEditingController controller, String label) {
    return Expanded(
      child: Column(
        children: [
          TextFormField(
            controller: controller,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(5)),
              filled: true,
              fillColor: Colors.white,
            ),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        ],
      ),
    );
  }
}