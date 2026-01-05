// app/lib/ui/checkout/checkout_screen.dart
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
import '../../services/ui_service.dart';
import '../address/address_list_screen.dart';
import '../../services/user_service.dart'; // [NEW]
import '../../services/loyalty_service.dart'; // [NEW]
import '../../models/user_model.dart'; // [NEW]
import '../../services/coupon_service.dart';
import '../components/gift_received_dialog.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  String _paymentMethod = 'Credit/Debit Card';
  final TextEditingController _couponController = TextEditingController();
  bool _isValidatingCoupon = false;
  
  // Point Redemption
  bool _isUsingPoints = false;
  int _userPoints = 0;
  int _redeemablePoints = 0;
  double _discountFromPoints = 0;

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
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        context.read<AddressProvider>().fetchAddresses(userId);
        
        // Fetch User Points
        final user = await UserService.instance.getCurrentUserProfile();
        if (user != null) {
           setState(() => _userPoints = user.points);
        }
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
    double shippingFee = cart.shippingFee;
    double shippingDiscount = cart.shippingDiscountAmount; // [MỚI] Lấy từ Provider
    double couponDiscount = cart.discountAmount;
    
    // Points Logic
    _redeemablePoints = LoyaltyService.instance.getMaxRedeemablePoints(subtotal, _userPoints);
    final potentialPointsDiscount = LoyaltyService.instance.getPointValue(_redeemablePoints);
    _discountFromPoints = _isUsingPoints ? potentialPointsDiscount : 0.0;
    
    // Tính tổng cuối cùng (đã gồm ship và mã giảm giá từ Cart) - trừ thêm điểm tích lũy
    double grandTotal = cart.finalTotalAmount - _discountFromPoints;
    if (grandTotal < 0) grandTotal = 0;

    double savedAmount = shippingDiscount + couponDiscount + _discountFromPoints;

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
                                             'Mã: ${cart.appliedCoupon!.code} ${cart.discountAmount > 0 ? "(-${currencyFormat.format(cart.discountAmount)})" : "(FreeShip)"}',
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

                        // Point Redemption Section
                        if (_userPoints > 0)
                          Container(
                            color: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: Column(
                              children: [
                                SwitchListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Row(
                                    children: [
                                      const Icon(Icons.stars, color: Colors.amber),
                                      const SizedBox(width: 8),
                                      Text('Dùng $_redeemablePoints điểm', style: const TextStyle(fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                  subtitle: Text(
                                    'Giảm ${NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(LoyaltyService.instance.getPointValue(_redeemablePoints))}',
                                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                                  ),
                                  value: _isUsingPoints,
                                  activeColor: Colors.amber,
                                  onChanged: (value) {
                                    setState(() => _isUsingPoints = value);
                                  },
                                ),
                                if (_isUsingPoints)
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(color: Colors.amber.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.info_outline, size: 16, color: Colors.amber),
                                        const SizedBox(width: 8),
                                        Expanded(child: Text('Đã dùng $_redeemablePoints điểm để giảm giá.', style: TextStyle(fontSize: 12, color: Colors.amber[800]))),
                                      ],
                                    ),
                                  )
                              ],
                            ),
                          ),

                        const SizedBox(height: 12),

                        // [NEW] Shipping Method Section
                         Container(
                          color: Colors.white,
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Phương thức vận chuyển', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.green.shade200),
                                  borderRadius: BorderRadius.circular(8),
                                  color: Colors.green.shade50,
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.local_shipping_outlined, color: Colors.green),
                                    const SizedBox(width: 12),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('Giao hàng tiêu chuẩn', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                        const SizedBox(height: 4),
                                        Text(_deliveryDateEstimate, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                      ],
                                    ),
                                    const Spacer(),
                                    const Text('Miễn phí', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 12),

                        // [NEW] Payment Method Section
                         Container(
                          color: Colors.white,
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Phương thức thanh toán', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                              const SizedBox(height: 4),
                              
                              // Cash
                              RadioListTile<String>(
                                value: 'Cash On Delivery',
                                groupValue: _paymentMethod,
                                onChanged: (value) => setState(() => _paymentMethod = value!),
                                title: const Text('Thanh toán khi nhận hàng (COD)'),
                                contentPadding: EdgeInsets.zero,
                                activeColor: Colors.black,
                              ),
                              const Divider(height: 1),
                              
                              // MoMo
                              RadioListTile<String>(
                                value: 'MoMo',
                                groupValue: _paymentMethod,
                                onChanged: (value) => setState(() => _paymentMethod = value!),
                                title: Row(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: Image.network(
                                        'https://upload.wikimedia.org/wikipedia/vi/f/fe/MoMo_Logo.png',
                                        width: 24, height: 24,
                                        errorBuilder: (_,__,___) => const Icon(Icons.account_balance_wallet, color: Colors.pink),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    const Text('Ví MoMo'),
                                  ],
                                ),
                                contentPadding: EdgeInsets.zero,
                                activeColor: Colors.pink,
                              ),
                               const Divider(height: 1),

                              // Credit Card (Demo)
                              RadioListTile<String>(
                                value: 'Credit/Debit Card',
                                groupValue: _paymentMethod,
                                onChanged: (value) => setState(() => _paymentMethod = value!),
                                title: const Text('Thẻ Tín dụng/Ghi nợ'),
                                contentPadding: EdgeInsets.zero,
                                activeColor: Colors.black,
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
                              ),
                              // [CẬP NHẬT] Hiển thị dòng giảm giá ship riêng biệt
                              if (shippingDiscount > 0)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text("Ưu đãi phí vận chuyển:", style: TextStyle(color: Colors.teal, fontSize: 14)),
                                      Text("-${currencyFormat.format(shippingDiscount)}", 
                                           style: const TextStyle(color: Colors.teal, fontWeight: FontWeight.bold, fontSize: 14)),
                                    ],
                                  ),
                                ),

                              if (couponDiscount > 0) ...[
                                const SizedBox(height: 8),
                                _SummaryRow(
                                  label: 'Voucher giảm giá:', 
                                  value: '-${currencyFormat.format(couponDiscount)}',
                                  valueColor: Colors.red,
                                ),
                              ],
                              if (_isUsingPoints && _discountFromPoints > 0) ...[
                                const SizedBox(height: 8),
                                _SummaryRow(
                                  label: 'Dùng điểm ($_redeemablePoints):', 
                                  value: '-${currencyFormat.format(_discountFromPoints)}',
                                  valueColor: Colors.amber[800],
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
    
    // [UPDATED] Tự động hoàn tất đơn hàng thay vì hiện dialog
    if (mounted) {
       _confirmOrderPlacement();
    }
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
    
    // Use read instead of watch in callbacks
    final cart = context.read<CartProvider>();
    final cartItems = cart.cart.items;
    final subtotal = cart.totalAmount;
    final shippingFee = 0.0; // Free shipping
    final couponDiscount = cart.discountAmount;
    
    // Calculate redeemable points
    _redeemablePoints = LoyaltyService.instance.getMaxRedeemablePoints(subtotal, _userPoints);
    final potentialPointsDiscount = LoyaltyService.instance.getPointValue(_redeemablePoints);
    
    // Update discount based on toggle
    _discountFromPoints = _isUsingPoints ? potentialPointsDiscount : 0.0;

    final grandTotal = subtotal + shippingFee - couponDiscount - _discountFromPoints;
    final savedAmount = couponDiscount + _discountFromPoints;
    
    final user = AuthService.instance.currentUser;
    final userId = user?.uid ?? 'guest_123';

    // Tạo đơn hàng
    final order = OrderModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      items: cartProvider.cart.items.where((i) => i.isSelected).toList(),
      totalAmount: grandTotal, 
      shippingAddress: address,
      status: OrderStatus.pending,
      paymentMethod: _paymentMethod,
      createdAt: DateTime.now(),
      discountAmount: cartProvider.discountAmount + _discountFromPoints,
      couponCode: cartProvider.appliedCoupon?.code,
      pointsUsed: _isUsingPoints ? _redeemablePoints : 0,
      discountFromPoints: _discountFromPoints,
    );

    try {
      // [MỚI] Xử lý Flash Sale: Ghi nhận người dùng nếu dùng mã Flash Sale
      if (cartProvider.appliedCoupon != null) {
        await UIService.instance.processFlashSaleUsage(
          userId,
          address.name, // Dùng tên người nhận hàng
          cartProvider.appliedCoupon!.code,
        );
      }

      // Gọi Provider tạo đơn hàng
      await context.read<OrderProvider>().createOrder(order);
      
      // Sau khi đặt thành công:
      // 1. Xóa các món đã mua khỏi giỏ hàng (không phải xóa hết nếu còn món chưa chọn)
      // cartProvider.removeSelectedItems(); // Cần viết hàm này trong Provider sau
      cartProvider.clearCart(); // Tạm thời clear hết để demo
      
      // [MỚI] Xử lý Logic Tặng Quà (Gift Coupons)
      try {
        final homeConfig = await UIService.instance.getHomeConfig();
        final flashSale = homeConfig.flashSale;
        
        if (flashSale.giftCouponIds.isNotEmpty) {
          // Thêm coupon vào ví user
          await UserService.instance.addCouponsToUserWallet(userId, flashSale.giftCouponIds);
          
          // Lấy thông tin coupon để hiển thị popup
          final giftCoupons = await CouponService.instance.getCouponsByIds(flashSale.giftCouponIds);
          
          if (mounted && giftCoupons.isNotEmpty) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (_) => GiftReceivedDialog(coupons: giftCoupons),
            );
            return; // Kết thúc hàm tại đây, không hiện dialog success mặc định bên dưới
          }
        }
      } catch (e) {
        debugPrint("Lỗi xử lý quà tặng: $e");
        // Nếu lỗi phần quà tặng, vẫn hiện thông báo thành công bình thường
      }

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
        // Show actual error message (e.g., "Sản phẩm X không đủ hàng")
        String message = e.toString().replaceAll('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ));
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