import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../models/review_model.dart';
import '../../services/review_service.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';

class WriteReviewScreen extends StatefulWidget {
  final String productId;
  final String orderId;
  final String productName;
  final String productImage;
  final String variantColor;
  final String variantSize;

  const WriteReviewScreen({
    super.key,
    required this.productId,
    required this.orderId,
    required this.productName,
    required this.productImage,
    required this.variantColor,
    required this.variantSize,
  });

  @override
  State<WriteReviewScreen> createState() => _WriteReviewScreenState();
}

class _WriteReviewScreenState extends State<WriteReviewScreen> {
  // Form State
  double _rating = 5.0;
  FitRating _fitRating = FitRating.trueToSize;
  final TextEditingController _commentController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  bool _isSubmitting = false;

  // Mock Image Picker State
  final List<String> _localImages = []; // In a real app, this would be File or XFile

  @override
  void dispose() {
    _commentController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  void _submitReview() async {
    final user = AuthService.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng đăng nhập để đánh giá')));
      return;
    }

    if (_commentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng nhập nội dung đánh giá')));
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Create Review Object
      final review = Review(
        id: const Uuid().v4(),
        productId: widget.productId,
        userId: user.uid,
        userName: user.displayName ?? 'Khách hàng', // Should fetch real name if needed
        userAvatar: user.photoURL,
        rating: _rating,
        comment: _commentController.text.trim(),
        color: widget.variantColor,
        size: widget.variantSize,
        fitRating: _fitRating,
        userHeight: double.tryParse(_heightController.text),
        userWeight: double.tryParse(_weightController.text),
        images: _localImages, // In real app, upload these first and get URLs
        createdAt: DateTime.now(),
      );

      // Submit
      await ReviewService().addReview(review);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Đánh giá thành công!'),
          backgroundColor: Colors.green,
        ));
        Navigator.pop(context, true); // Return true to refresh previous screen
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Lỗi: $e'),
          backgroundColor: Colors.red,
        ));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _pickImage() {
    // Mock image picking
    // In real app: create a helper or use image_picker
    setState(() {
      _localImages.add('https://picsum.photos/200?random=${DateTime.now().millisecondsSinceEpoch}');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đánh giá sản phẩm', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Info
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    image: DecorationImage(image: NetworkImage(widget.productImage), fit: BoxFit.cover),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.productName, style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('Màu: ${widget.variantColor} / Size: ${widget.variantSize}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 32),

            // Rating
            const Text('Chất lượng sản phẩm', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return IconButton(
                  icon: Icon(
                    index < _rating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 32,
                  ),
                  onPressed: () => setState(() => _rating = index + 1.0),
                );
              }),
            ),
            const SizedBox(height: 8),
            Center(child: Text(_getRatingText(_rating), style: TextStyle(color: Colors.amber[700], fontWeight: FontWeight.bold))),
            
            const Divider(height: 32),

            // Fit Feedback
            const Text('Độ vừa vặn', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildFitOption(FitRating.small, 'Chật'),
                const SizedBox(width: 8),
                _buildFitOption(FitRating.trueToSize, 'Vừa vặn'),
                const SizedBox(width: 8),
                _buildFitOption(FitRating.large, 'Rộng'),
              ],
            ),

            const Divider(height: 32),

            // Media
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.camera_alt_outlined),
                label: const Text('Thêm hình ảnh'),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  side: BorderSide(color: AppColors.border),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
            if (_localImages.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _localImages.map((url) => Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(url, width: 80, height: 80, fit: BoxFit.cover),
                      ),
                      Positioned(
                        right: 0,
                        top: 0,
                        child: GestureDetector(
                          onTap: () => setState(() => _localImages.remove(url)),
                          child: Container(
                            color: Colors.black54,
                            child: const Icon(Icons.close, color: Colors.white, size: 16),
                          ),
                        ),
                      ),
                    ],
                  )).toList(),
                ),
              ),

            const Divider(height: 32),

            // Comment
            const Text('Chi tiết đánh giá', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            TextField(
              controller: _commentController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Hãy chia sẻ nhận xét của bạn về sản phẩm...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                filled: true,
                fillColor: Colors.grey[50],
              ),
            ),

            const SizedBox(height: 24),

            // Body Stats (Collapsible or just fields)
            ExpansionTile(
              title: const Text('Số đo của bạn (Tùy chọn)', style: TextStyle(fontSize: 14)),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _heightController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Chiều cao (cm)',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: _weightController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Cân nặng (kg)',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
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
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, -2))],
        ),
        child: SafeArea(
          child: ElevatedButton(
            onPressed: _isSubmitting ? null : _submitReview,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.charcoal,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: _isSubmitting
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('GỬI ĐÁNH GIÁ'),
          ),
        ),
      ),
    );
  }

  Widget _buildFitOption(FitRating value, String label) {
    bool isSelected = _fitRating == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _fitRating = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.black : Colors.white,
            border: Border.all(color: isSelected ? Colors.black : Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.black,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  String _getRatingText(double rating) {
    if (rating >= 5) return 'Tuyệt vời';
    if (rating >= 4) return 'Hài lòng';
    if (rating >= 3) return 'Bình thường';
    if (rating >= 2) return 'Không hài lòng';
    return 'Tệ';
  }
}
