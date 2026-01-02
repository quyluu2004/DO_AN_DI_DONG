import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/cart_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/address_provider.dart';
import '../../models/order_model.dart';
import '../../models/address_model.dart';
import '../../models/coupon_model.dart';
import '../../services/auth_service.dart';
import '../../services/coupon_service.dart';
import '../address/address_list_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  String _paymentMethod = 'Credit/Debit Card';
  bool _isShippingGuarantee = true;
  final TextEditingController _couponController = TextEditingController();
  CouponModel? _appliedCoupon;
  String? _couponError;
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

  Future<void> _applyCoupon(double currentSubtotal) async {
    final code = _couponController.text.trim();
    if (code.isEmpty) return;

    setState(() {
      _isValidatingCoupon = true;
      _couponError = null;
    });

    try {
      final coupon = await CouponService.instance.getCouponByCode(code);
      if (coupon == null) {
        setState(() => _couponError = 'Mã giảm giá không tồn tại hoặc đã hết hạn');
      } else if (currentSubtotal < coupon.minOrderValue) {
        final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
        setState(() => _couponError = 'Đơn hàng chưa đạt tối thiểu ${formatter.format(coupon.minOrderValue)}');
      } else {
        setState(() {
          _appliedCoupon = coupon;
          _couponError = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Áp dụng mã giảm giá thành công!')));
      }
    } catch (e) {
      setState(() => _couponError = 'Lỗi khi kiểm tra mã: $e');
    } finally {
      setState(() => _isValidatingCoupon = false);
    }
  }

  void _removeCoupon() {
    setState(() {
      _appliedCoupon = null;
      _couponController.clear();
      _couponError = null;
    });
  }

  void _selectAddress() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddressListScreen(isSelecting: true)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final addressProvider = context.watch<AddressProvider>();
    final address = addressProvider.selectedAddress;
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    
    // Calculations
    double subtotal = cart.totalAmount;
    double shippingFee = 12000;
    double shippingDiscount = 12000; // Freeship
    double shippingGuaranteeFee = 0;
    double couponDiscount = _appliedCoupon?.discountAmount ?? 0;
    
    double grandTotal = subtotal + (shippingFee - shippingDiscount) + shippingGuaranteeFee - couponDiscount;
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
        actions: [
          IconButton(
            icon: const Icon(Icons.support_agent_outlined, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
      body: cart.itemCount == 0
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
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Sản phẩm (${cart.itemCount})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                ],
                              ),
                              const SizedBox(height: 16),
                              ...cart.cart.items.map((item) => Padding(
                                padding: const EdgeInsets.only(bottom: 24.0),
                                child: Column(
                                  children: [
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Product Image
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(4),
                                          child: Image.network(
                                            item.imageUrl,
                                            width: 80,
                                            height: 100,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_,__,___) => Container(width: 80, height: 100, color: Colors.grey[200]),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        // Details
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                item.productName,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(fontSize: 14, height: 1.2),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                '${item.color ?? 'Nhiều màu'} / ${item.size ?? 'Freesize'}',
                                                style: const TextStyle(color: Colors.grey, fontSize: 13),
                                              ),
                                              const SizedBox(height: 8),
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Text(
                                                    currencyFormat.format(item.price),
                                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                                  ),
                                                  Text('x ${item.quantity}'),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              )),
                              
                              const Divider(height: 24),
                              
                              // Shipping Method
                              const Text('Phương thức vận chuyển', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                              const SizedBox(height: 12),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.check_circle, color: Colors.black, size: 24),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            const Text('Tiêu chuẩn', style: TextStyle(fontSize: 15)),
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                              color: const Color(0xFFE8F5E9),
                                              child: const Text('Freeship', style: TextStyle(fontSize: 10, color: Colors.green)),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        RichText(
                                          text: TextSpan(
                                            style: const TextStyle(color: Colors.black87, fontSize: 13), // Default font
                                            children: [
                                              const TextSpan(text: '0đ ', style: TextStyle(fontWeight: FontWeight.bold)),
                                              TextSpan(
                                                text: currencyFormat.format(shippingFee), // '12.000đ'
                                                style: const TextStyle(decoration: TextDecoration.lineThrough, color: Colors.grey),
                                              ),
                                              TextSpan(text: ' ($_deliveryDateEstimate)'),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 12),
                        
                        // Payment Method
                        Container(
                          color: Colors.white,
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Text('Phương thức thanh toán', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                  const Spacer(),
                                  const Icon(Icons.verified_user_outlined, size: 14, color: Colors.green),
                                  const SizedBox(width: 4),
                                  const Text('Bảo mật', style: TextStyle(color: Colors.green, fontSize: 12)),
                                ],
                              ),
                              const SizedBox(height: 16),
                              
                              // Credit/Debit Card
                              InkWell(
                                onTap: () => setState(() => _paymentMethod = 'Credit/Debit Card'),
                                child: Row(
                                  children: [
                                    Icon(
                                      _paymentMethod == 'Credit/Debit Card' ? Icons.check_circle : Icons.radio_button_unchecked, 
                                      color: _paymentMethod == 'Credit/Debit Card' ? Colors.black : Colors.grey
                                    ),
                                    const SizedBox(width: 12),
                                    const Icon(Icons.credit_card, size: 28),
                                    const SizedBox(width: 12),
                                    const Text('Thẻ Tín dụng/Ghi nợ', style: TextStyle(fontSize: 15)),
                                  ],
                                ),
                              ),
                              
                              const SizedBox(height: 16),
                              
                              // COD
                              InkWell(
                                onTap: () => setState(() => _paymentMethod = 'COD'),
                                child: Row(
                                  children: [
                                    Icon(
                                      _paymentMethod == 'COD' ? Icons.check_circle : Icons.radio_button_unchecked, 
                                      color: _paymentMethod == 'COD' ? Colors.black : Colors.grey
                                    ),
                                    const SizedBox(width: 12),
                                    const Icon(Icons.local_shipping_outlined, size: 28),
                                    const SizedBox(width: 12),
                                    const Text('Thanh toán khi nhận hàng (COD)', style: TextStyle(fontSize: 15)),
                                  ],
                                ),
                              ),
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
                                         suffixIcon: _isValidatingCoupon 
                                           ? const Padding(padding: EdgeInsets.all(10), child: CircularProgressIndicator(strokeWidth: 2))
                                           : null,
                                       ),
                                     ),
                                   ),
                                   const SizedBox(width: 8),
                                   ElevatedButton(
                                     onPressed: () => _applyCoupon(subtotal),
                                     style: ElevatedButton.styleFrom(
                                       backgroundColor: Colors.black,
                                       foregroundColor: Colors.white,
                                     ),
                                     child: const Text('Áp dụng'),
                                   ),
                                 ],
                               ),
                               if (_couponError != null)
                                 Padding(
                                   padding: const EdgeInsets.only(top: 8.0),
                                   child: Text(_couponError!, style: const TextStyle(color: Colors.red, fontSize: 12)),
                                 ),
                               if (_appliedCoupon != null)
                                 Padding(
                                   padding: const EdgeInsets.only(top: 8.0),
                                   child: Row(
                                     children: [
                                       const Icon(Icons.confirmation_number_outlined, color: Colors.green, size: 16),
                                       const SizedBox(width: 4),
                                       Text(
                                         'Đã dùng mã: ${_appliedCoupon!.code} (-${currencyFormat.format(_appliedCoupon!.discountAmount)})',
                                         style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                                       ),
                                       const Spacer(),
                                       InkWell(
                                         onTap: _removeCoupon,
                                         child: const Icon(Icons.close, size: 16, color: Colors.grey),
                                       ),
                                     ],
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
                              _SummaryRow(label: 'Tạm tính (${cart.itemCount} món)', value: currencyFormat.format(subtotal)),
                              const SizedBox(height: 8),
                              _SummaryRow(
                                label: 'Phí vận chuyển:', 
                                value: currencyFormat.format(shippingFee), // '12.000đ'
                                valueColor: Colors.grey,
                                isStrikethrough: true,
                                suffix: const Text('Miễn phí', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                              ),
                              if (_appliedCoupon != null) ...[
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

                        const SizedBox(height: 100), // Space for bottom bar
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
                    Row(
                      children: [
                        Text('Tổng: ', style: const TextStyle(fontSize: 12)),
                        Text(currencyFormat.format(grandTotal), style: const TextStyle(color: Colors.red, fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Text('Tiết kiệm ${currencyFormat.format(savedAmount)}', style: const TextStyle(color: Colors.orange, fontSize: 12)),
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
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
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

  Future<void> _handleMoMoPayment(double amount) async {
    // Số điện thoại nhận tiền (Hardcode cho demo)
    const receiverPhone = "0399999999"; 
    final note = "Thanh toan don hang FashionApp";
    
    // Tạo Deep Link MoMo
    // Format: momo://?action=transfer&to=[PHONE]&amount=[AMOUNT]&note=[NOTE]
    final Uri momoUrl = Uri.parse(
      "momo://?action=transfer&to=$receiverPhone&amount=${amount.toInt()}&note=$note"
    );

    try {
      if (await canLaunchUrl(momoUrl)) {
        await launchUrl(momoUrl, mode: LaunchMode.externalApplication);
      } else {
        // Fallback nếu không mở được app (ví dụ máy ảo không có MoMo)
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(content: Text('Không thể mở ứng dụng MoMo. Hãy đảm bảo bạn đã cài đặt MoMo.')),
           );
        }
      }
    } catch (e) {
      debugPrint('Error launching MoMo: $e');
    }
    
    // Sau khi mở App (hoặc fail), hiện dialog trác nhận thủ công
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Row(
           children: const [
             Icon(Icons.payment, color: Colors.pink),
             SizedBox(width: 8),
             Text('Xác nhận thanh toán'),
           ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Vui lòng hoàn tất chuyển tiền trên ứng dụng MoMo.'),
            const SizedBox(height: 12),
            Text('Số tiền: ${NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(amount)}', 
                 style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text('Người nhận: SHOP THOI TRANG (0399999999)'),
            const SizedBox(height: 16),
            const Text('Sau khi chuyển khoản thành công, vui lòng bấm nút bên dưới để hoàn tất đơn hàng.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx), // Huỷ
            child: const Text('Quay lại', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx); // Đóng dialog
              _confirmOrderPlacement(); // Gọi hàm tạo đơn hàng thực sự
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.pink),
            child: const Text('Đã thanh toán xong'),
          ),
        ],
      ),
    );
  }

  void _placeOrder(CartProvider cartProvider, double total, Address address) {
     if (_paymentMethod == 'MoMo') {
       _handleMoMoPayment(total);
     } else {
       _confirmOrderPlacement();
     }
  }

  // Tách logic tạo đơn hàng ra riêng để tái sử dụng
  void _confirmOrderPlacement() async {
    final cartProvider = context.read<CartProvider>();
    final addressProvider = context.read<AddressProvider>();
    final address = addressProvider.selectedAddress!;
    
    // Recalculate total just to be safe or pass it down. 
    // Simplify usage here since we passed data to _placeOrder previously but now splitting info.
    // Better to store 'grandTotal' in state or recalc. For now, let's recalculate quickly or check how to access.
    // Actually, accessing cart state again is safer.
    
    // ... Re-calculating grand total locally for Order Model ...
    double subtotal = cartProvider.totalAmount;
    double shippingFee = 12000;
    double shippingDiscount = 12000;
    double couponDiscount = _appliedCoupon?.discountAmount ?? 0;
    double total = subtotal + (shippingFee - shippingDiscount) - couponDiscount;
    if (total < 0) total = 0;

    final user = AuthService.instance.currentUser;
    final userId = user?.uid ?? 'guest_123';

    final order = OrderModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      items: cartProvider.cart.items,
      totalAmount: total,
      shippingAddress: address,
      status: OrderStatus.pending,
      paymentMethod: _paymentMethod,
      createdAt: DateTime.now(),
      discountAmount: _appliedCoupon?.discountAmount ?? 0,
      couponCode: _appliedCoupon?.code,
    );

    try {
      await context.read<OrderProvider>().createOrder(order);
      cartProvider.clearCart();
      
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => AlertDialog(
            title: const Icon(Icons.check_circle, color: Colors.green, size: 50),
            content: const Text('Đặt hàng thành công!', textAlign: TextAlign.center),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                child: const Text('Về trang chủ'),
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
