// app/lib/ui/checkout/checkout_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/cart_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/address_provider.dart';
import '../../models/order_model.dart';
import '../../models/address_model.dart';
import '../../models/coupon_model.dart';
import '../../services/auth_service.dart';
import '../address/address_list_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  String _paymentMethod = 'Credit/Debit Card';
  final TextEditingController _couponController = TextEditingController();
  bool _isValidatingCoupon = false;

  String get _deliveryDateEstimate {
    final now = DateTime.now();
    final start = now.add(const Duration(days: 5));
    final end = now.add(const Duration(days: 7));
    return 'Giao hàng khoảng ${DateFormat('dd/MM').format(start)} - ${DateFormat('dd/MM').format(end)}';
  }

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
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }

  // [SỬA LỖI 1 & 2] Chuyển toàn bộ logic áp mã sang Provider xử lý
  Future<void> _applyCoupon() async {
    final code = _couponController.text.trim();
    if (code.isEmpty) return;

    setState(() => _isValidatingCoupon = true);
    
    // Ẩn bàn phím
    FocusScope.of(context).unfocus();

    try {
      // Gọi hàm trong Provider để validate và tính toán
      await context.read<CartProvider>().applyCoupon(code);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Áp dụng mã giảm giá thành công!', style: TextStyle(color: Colors.white)), backgroundColor: Colors.green)
        );
      }
    } catch (e) {
      // Provider sẽ ném lỗi nếu mã không hợp lệ (hết hạn, chưa đủ tiền...)
      if (mounted) {
        // Lỗi đã được lưu trong provider.couponError, nhưng hiển thị snackbar cho rõ
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.red)
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isValidatingCoupon = false);
      }
    }
  }

  void _removeCoupon() {
    context.read<CartProvider>().removeCoupon();
    _couponController.clear();
  }

  void _selectAddress() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddressListScreen(isSelecting: true)),
    );
  }

  @override
  Widget build(BuildContext context) {
    // [QUAN TRỌNG] Lắng nghe CartProvider để update UI khi tiền thay đổi
    final cart = context.watch<CartProvider>();
    final addressProvider = context.watch<AddressProvider>();
    final address = addressProvider.selectedAddress;
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    
    // [SỬA LỖI 3] Lấy số liệu trực tiếp từ Provider
    double subtotal = cart.subtotal; // Tổng tiền hàng chưa giảm
    double shippingFee = 12000;
    double shippingDiscount = 12000; // Freeship
    
    // Lấy tiền giảm từ Provider (đã tính toán chính xác theo danh mục)
    double couponDiscount = cart.discountAmount; 
    
    // Tính tổng cuối cùng
    double grandTotal = subtotal + (shippingFee - shippingDiscount) - couponDiscount;
    if (grandTotal < 0) grandTotal = 0;

    double savedAmount = shippingDiscount + couponDiscount;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Xác nhận đơn hàng', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: const BackButton(color: Colors.black),
      ),
      body: cart.cart.items.isEmpty // Kiểm tra items trong cart
          ? const Center(child: Text('Giỏ hàng trống'))
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        // Freeship Banner
                        Container(
                          width: double.infinity,
                          color: const Color(0xFFE8F5E9),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Row(
                            children: const [
                              Icon(Icons.check, color: Colors.green, size: 16),
                              SizedBox(width: 8),
                              Text(
                                'Miễn phí vận chuyển cho tất cả sản phẩm',
                                style: TextStyle(color: Colors.green, fontWeight: FontWeight.w600, fontSize: 13),
                              ),
                            ],
                          ),
                        ),

                        // 1. Address Section
                        InkWell(
                          onTap: _selectAddress,
                          child: Container(
                            color: Colors.white,
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.location_on, size: 20),
                                    const SizedBox(width: 8),
                                    if (address != null) ...[
                                      Text(
                                        address.name,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        address.phone,
                                        style: const TextStyle(color: Colors.grey, fontSize: 14),
                                      ),
                                    ] else
                                      const Text('Vui lòng chọn địa chỉ', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                                    
                                    const Spacer(),
                                    const Icon(Icons.chevron_right, color: Colors.grey),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                if (address != null)
                                  Padding(
                                    padding: const EdgeInsets.only(left: 28),
                                    child: Text(
                                      address.fullAddress,
                                      style: const TextStyle(fontSize: 14, height: 1.4),
                                    ),
                                  ),
                                const Padding(
                                  padding: EdgeInsets.only(top: 12.0),
                                  child: Divider(height: 1), 
                                ),
                                SizedBox(
                                  height: 4,
                                  child: Row(
                                    children: List.generate(40, (index) => 
                                      Expanded(child: Container(color: index % 2 == 0 ? Colors.red.shade200 : Colors.blue.shade200))
                                    ),
                                  ),
                                )
                              ],
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 12),

                        // 2. Order Items
                         Container(
                          color: Colors.white,
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Sản phẩm (${cart.selectedItemCount})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              const SizedBox(height: 16),
                              // Chỉ hiện các item ĐƯỢC CHỌN (isSelected = true)
                              ...cart.cart.items.where((i) => i.isSelected).map((item) => Padding(
                                padding: const EdgeInsets.only(bottom: 24.0),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: Image.network(
                                        item.imageUrl,
                                        width: 80, height: 100, fit: BoxFit.cover,
                                        errorBuilder: (_,__,___) => Container(width: 80, height: 100, color: Colors.grey[200]),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(item.productName, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, height: 1.2)),
                                          const SizedBox(height: 4),
                                          Text('${item.color ?? 'Mặc định'} / ${item.size ?? 'Freesize'}', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                                          const SizedBox(height: 8),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(currencyFormat.format(item.price), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                              Text('x ${item.quantity}'),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              )),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 12),
                        
                        // Coupons Section
                        Container(
                          color: Colors.white,
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                             children: [
                               const Text('Mã giảm giá', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                               const SizedBox(height: 12),
                               Row(
                                 children: [
                                   Expanded(
                                     child: TextField(
                                       controller: _couponController,
                                       decoration: InputDecoration(
                                         hintText: 'Nhập mã giảm giá',
                                         contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                         border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                       ),
                                     ),
                                   ),
                                   const SizedBox(width: 8),
                                   ElevatedButton(
                                     onPressed: _isValidatingCoupon ? null : _applyCoupon,
                                     style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white),
                                     child: _isValidatingCoupon 
                                         ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                         : const Text('Áp dụng'),
                                   ),
                                 ],
                               ),
                               
                               // Hiển thị lỗi từ Provider nếu có
                               if (cart.couponError != null)
                                 Padding(
                                   padding: const EdgeInsets.only(top: 8.0),
                                   child: Text(cart.couponError!, style: const TextStyle(color: Colors.red, fontSize: 12)),
                                 ),
                               
                               // Hiển thị mã đã áp dụng
                               if (cart.appliedCoupon != null)
                                 Padding(
                                   padding: const EdgeInsets.only(top: 8.0),
                                   child: Container(
                                     padding: EdgeInsets.all(8),
                                     decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.green)),
                                     child: Row(
                                       children: [
                                         const Icon(Icons.confirmation_number_outlined, color: Colors.green, size: 16),
                                         const SizedBox(width: 4),
                                         Expanded(
                                           child: Text(
                                             'Mã: ${cart.appliedCoupon!.code} (-${currencyFormat.format(cart.discountAmount)})',
                                             style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                                           ),
                                         ),
                                         InkWell(
                                           onTap: _removeCoupon,
                                           child: const Icon(Icons.close, size: 16, color: Colors.grey),
                                         ),
                                       ],
                                     ),
                                   ),
                                 ),
                             ],
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Summary
                        Container(
                          color: Colors.white,
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              _SummaryRow(label: 'Tạm tính (${cart.selectedItemCount} món)', value: currencyFormat.format(subtotal)),
                              const SizedBox(height: 8),
                              _SummaryRow(
                                label: 'Phí vận chuyển:', 
                                value: currencyFormat.format(shippingFee),
                                valueColor: Colors.grey,
                                isStrikethrough: true,
                                suffix: const Text('Miễn phí', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                              ),
                              if (cart.appliedCoupon != null) ...[
                                const SizedBox(height: 8),
                                _SummaryRow(
                                  label: 'Voucher giảm giá:', 
                                  value: '-${currencyFormat.format(couponDiscount)}',
                                  valueColor: Colors.red,
                                ),
                              ],
                              const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider()),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Tổng thanh toán:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(currencyFormat.format(grandTotal), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.red)),
                                      Text('Tiết kiệm ${currencyFormat.format(savedAmount)}', style: const TextStyle(color: Colors.orange, fontSize: 13)),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 100), 
                      ],
                    ),
                  ),
                ),
              ],
            ),
      
      // Bottom Bar
      bottomSheet: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
             BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5)),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Tổng thanh toán', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    Text(currencyFormat.format(grandTotal), style: const TextStyle(color: Colors.red, fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: () {
                    if (address == null) {
                       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng chọn địa chỉ giao hàng')));
                       return;
                    }
                    _placeOrder(cart, grandTotal, address);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                  ),
                  child: const Text('ĐẶT HÀNG', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _placeOrder(CartProvider cartProvider, double total, Address address) async {
    final user = AuthService.instance.currentUser;
    final userId = user?.uid ?? 'guest_123';

    // Tạo đơn hàng
    final order = OrderModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      // Lưu ý: Chỉ lưu các item ĐƯỢC CHỌN vào đơn hàng
      items: cartProvider.cart.items.where((i) => i.isSelected).toList(),
      totalAmount: total,
      shippingAddress: address,
      status: OrderStatus.pending,
      paymentMethod: _paymentMethod,
      createdAt: DateTime.now(),
      discountAmount: cartProvider.discountAmount,
      couponCode: cartProvider.appliedCoupon?.code,
    );

    try {
      // Gọi Provider tạo đơn hàng
      await context.read<OrderProvider>().createOrder(order);
      
      // Sau khi đặt thành công:
      // 1. Xóa các món đã mua khỏi giỏ hàng (không phải xóa hết nếu còn món chưa chọn)
      // cartProvider.removeSelectedItems(); // Cần viết hàm này trong Provider sau
      cartProvider.clearCart(); // Tạm thời clear hết để demo
      
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => AlertDialog(
            icon: const Icon(Icons.check_circle, color: Colors.green, size: 60),
            title: const Text('Đặt hàng thành công!', textAlign: TextAlign.center),
            content: const Text('Cảm ơn bạn đã mua sắm tại Foodie/Fashion.'),
            actions: [
              TextButton(
                onPressed: () {
                  // Quay về màn hình Home (xóa hết các màn hình trước đó)
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                child: const Text('Về trang chủ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              )
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    }
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool isStrikethrough;
  final Widget? suffix;

  const _SummaryRow({
    required this.label, 
    required this.value, 
    this.valueColor, 
    this.isStrikethrough = false,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
        Row(
          children: [
            Text(
              value, 
              style: TextStyle(
                color: valueColor ?? Colors.black, 
                fontSize: 14,
                decoration: isStrikethrough ? TextDecoration.lineThrough : null,
              )
            ),
            if (suffix != null) ...[
              const SizedBox(width: 8),
              suffix!,
            ],
          ],
        ),
      ],
    );
  }
}