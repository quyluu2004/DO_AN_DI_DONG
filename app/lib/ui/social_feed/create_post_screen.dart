import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/product_model.dart';
import '../../services/product_service.dart';
import '../../services/feed_service.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  Uint8List? _imageBytes;
  final TextEditingController _descController = TextEditingController();
  final List<Product> _selectedProducts = [];
  bool _isUploading = false;

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _imageBytes = bytes;
      });
    }
  }

  void _openProductSelector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _ProductSelectorSheet(
        onSelect: (product) {
          if (!_selectedProducts.any((p) => p.id == product.id)) {
            setState(() {
              _selectedProducts.add(product);
            });
          }
          Navigator.pop(ctx);
        },
      ),
    );
  }

  Future<void> _submitPost() async {
    if (_imageBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng chọn ảnh!')));
      return;
    }
    if (_descController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng viết mô tả!')));
      return;
    }

    setState(() => _isUploading = true);

    try {
      await FeedService.instance.createPost(
        description: _descController.text,
        imageBytes: _imageBytes!,
        linkedProductIds: _selectedProducts.map((p) => p.id).toList(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đăng bài thành công!')));
        Navigator.pop(context); // Return to Feed
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tạo bài viết mới', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _isUploading ? null : _submitPost,
            child: _isUploading 
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('ĐĂNG', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Picker Area
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 300,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                  image: _imageBytes != null 
                    ? DecorationImage(image: MemoryImage(_imageBytes!), fit: BoxFit.cover)
                    : null,
                ),
                child: _imageBytes == null 
                  ? const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_a_photo, size: 40, color: Colors.grey),
                        SizedBox(height: 8),
                        Text('Chạm để chọn ảnh', style: TextStyle(color: Colors.grey))
                      ],
                    )
                  : null,
              ),
            ),
            const SizedBox(height: 16),
            
            // Description Input
            TextField(
              controller: _descController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Bạn đang nghĩ gì về bộ đồ này?',
                border: InputBorder.none,
              ),
            ),
            const Divider(),
            
            // Tagged Products List
            if (_selectedProducts.isNotEmpty) ...[
              const Text('Sản phẩm đã gắn thẻ:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _selectedProducts.map((p) => Chip(
                  label: Text(p.name),
                  avatar: p.images.isNotEmpty ? CircleAvatar(backgroundImage: NetworkImage(p.images.first)) : null,
                  onDeleted: () {
                    setState(() {
                      _selectedProducts.remove(p);
                    });
                  },
                )).toList(),
              ),
            ],

            // Add Product Button
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.style, color: Colors.black),
              title: const Text('Gắn thẻ sản phẩm'),
              trailing: const Icon(Icons.chevron_right),
              onTap: _openProductSelector,
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductSelectorSheet extends StatelessWidget {
  final Function(Product) onSelect;

  const _ProductSelectorSheet({required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 500,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Text('Chọn sản phẩm', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 12),
          Expanded(
            child: StreamBuilder<List<Product>>(
              stream: ProductService.instance.getProductsStream(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final products = snapshot.data!;
                
                return ListView.builder(
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];
                    return ListTile(
                      leading: Image.network(
                        product.primaryImageUrl ?? '', 
                        width: 50, height: 50, fit: BoxFit.cover,
                        errorBuilder: (_,__,___) => Container(width: 50, height: 50, color: Colors.grey),
                      ),
                      title: Text(product.name),
                      subtitle: Text('đ${product.price}'),
                      onTap: () => onSelect(product),
                    );
                  },
                );
              },
            ),
          )
        ],
      ),
    );
  }
}
