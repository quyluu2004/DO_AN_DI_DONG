
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../models/product_model.dart';
import '../../services/product_service.dart';
import '../../services/cloudinary_service.dart';
import '../../theme/app_theme.dart';
import '../../ui/components/image_uploader.dart';

class AdminProductEditScreen extends StatefulWidget {
  final Product? product;
  const AdminProductEditScreen({super.key, this.product});

  @override
  State<AdminProductEditScreen> createState() => _AdminProductEditScreenState();
}

class _AdminProductEditScreenState extends State<AdminProductEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _productService = ProductService.instance;
  final _cloudinaryService = CloudinaryService.instance;

  // Controllers
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();
  final _colorsInputController = TextEditingController();
  final _sizesInputController = TextEditingController();
  
  String? _selectedCategory;
  String? _selectedSubCategory; // [NEW]
  List<String> _images = [];
  List<ProductVariant> _variants = [];
  bool _isLoading = false;

  // Try-On State
  Uint8List? _tryOnOriginalBytes;
  Uint8List? _tryOnProcessedBytes;
  String? _existingTryOnUrl;
  bool _isProcessingTryOn = false;

  final List<String> _categories = ['Women', 'Men', 'Kids', 'Shoes', 'Bags', 'Accessories'];

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      final p = widget.product!;
      _nameController.text = p.name;
      _descriptionController.text = p.description ?? '';
      _priceController.text = p.price.toString();
      _stockController.text = p.stock.toString();
      _selectedCategory = p.category;
      _selectedSubCategory = p.subCategory; // [NEW]
      _images = List.from(p.images);
      _variants = List.from(p.variants);
      _existingTryOnUrl = p.tryOnImageUrl;
    }
  }

  // --- Variants Logic ---
  void _generateVariants() {
    final colorsStr = _colorsInputController.text.trim();
    final sizesStr = _sizesInputController.text.trim();
    
    if (colorsStr.isEmpty && sizesStr.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng nhập Màu hoặc Size')));
      return;
    }

    final colors = colorsStr.isEmpty ? [null] : colorsStr.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    final sizes = sizesStr.isEmpty ? [null] : sizesStr.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

    List<ProductVariant> newVariants = [];
    int basePrice = int.tryParse(_priceController.text) ?? 0;
    
    for (var color in colors) {
      for (var size in sizes) {
        newVariants.add(ProductVariant(
          id: '${color ?? 'x'}_${size ?? 'x'}'.toLowerCase(),
          color: color,
          size: size,
          price: basePrice,
          stock: 10, // Default stock
          sku: 'SKU-${DateTime.now().millisecondsSinceEpoch}',
        ));
      }
    }

    setState(() {
      _variants = [..._variants, ...newVariants];
    });
  }

  // --- Try-On Logic (Remove BG) ---
  Future<void> _pickTryOnImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      
      setState(() {
        _tryOnOriginalBytes = bytes;
        _tryOnProcessedBytes = null; // Reset result
        _existingTryOnUrl = null; // Clear existing if new picked
      });
      
      // Auto trigger remove bg
      _removeBackground(bytes);
    }
  }

  Future<void> _removeBackground(Uint8List originalBytes) async {
    setState(() => _isProcessingTryOn = true);

    try {
      final uri = Uri.parse('https://api.remove.bg/v1.0/removebg');
      final request = http.MultipartRequest('POST', uri);
      
      final apiKey = dotenv.env['REMOVE_BG_API_KEY'] ?? '';
      if (apiKey.isEmpty) {
        throw Exception('Chưa tìm thấy API Key. Hãy khởi động lại ứng dụng.');
      }

      request.headers['X-Api-Key'] = apiKey;
      
      request.files.add(http.MultipartFile.fromBytes(
        'image_file', 
        originalBytes,
        filename: 'original.png'
      ));
      request.fields['size'] = 'auto';

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        setState(() {
          _tryOnProcessedBytes = response.bodyBytes;
        });
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('RemoveBG Error: ${response.statusCode}')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('RemoveBG Failed: $e')));
    } finally {
      setState(() => _isProcessingTryOn = false);
    }
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;
    if (_images.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng thêm ít nhất 1 ảnh sản phẩm')));
      return;
    }
    // [NEW] Validate subCategory if Try-On image is present
    if ((_tryOnProcessedBytes != null || _existingTryOnUrl != null) && _selectedSubCategory == null) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng chọn "Loại (Try-On)" để dùng tính năng thử đồ')));
       return;
    }

    setState(() => _isLoading = true);
    
    try {
      // 1. Upload Try-On Image if needed
      String? tryOnUrl = _existingTryOnUrl;
      
      if (_tryOnProcessedBytes != null) {
        // Upload processed
        tryOnUrl = await _cloudinaryService.uploadImage(
          bytes: _tryOnProcessedBytes!,
          folder: 'products/transparent',
        );
      } else if (_tryOnOriginalBytes != null && tryOnUrl == null) {
        // Fallback to original if processing failed or skipped
        tryOnUrl = await _cloudinaryService.uploadImage(
          bytes: _tryOnOriginalBytes!,
          folder: 'products/tryon_fallback',
        );
      }

      // 2. Prepare Data
      final productData = Product(
        id: widget.product?.id ?? '', 
        shopId: 'official_store', // Fixed for D2C
        name: _nameController.text,
        description: _descriptionController.text,
        price: int.tryParse(_priceController.text) ?? 0,
        stock: int.tryParse(_stockController.text) ?? 0,
        category: _selectedCategory,
        subCategory: _selectedSubCategory, // [NEW]
        images: _images,
        variants: _variants,
        tryOnImageUrl: tryOnUrl,
        status: ProductStatus.active, 
        createdAt: widget.product?.createdAt ?? DateTime.now(), 
        updatedAt: DateTime.now(),
      );

      // 3. Save to Firestore
      if (widget.product == null) {
        await _productService.addProduct(productData);
      } else {
        await _productService.updateProduct(productData.id, productData.toMap());
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lưu sản phẩm thành công')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.product == null ? 'Thêm sản phẩm mới' : 'Chỉnh sửa sản phẩm'),
        // ... theme styles
        actions: [
          TextButton.icon(
            onPressed: _isLoading ? null : _saveProduct,
            icon: _isLoading 
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.check),
            label: const Text('LƯU'),
            // ... button styles
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Column: General Info & Images
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionHeader(title: 'Thông tin chung'),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Tên sản phẩm', border: OutlineInputBorder()),
                      validator: (val) => val == null || val.isEmpty ? 'Bắt buộc nhập' : null,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              DropdownButtonFormField<String>(
                                value: _selectedCategory,
                                decoration: const InputDecoration(labelText: 'Danh mục (Giới tính)', border: OutlineInputBorder()),
                                items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                                onChanged: (val) => setState(() => _selectedCategory = val),
                                validator: (val) => val == null ? 'Bắt buộc chọn' : null,
                              ),
                              const SizedBox(height: 16),
                               DropdownButtonFormField<String>(
                                value: _selectedSubCategory,
                                decoration: const InputDecoration(labelText: 'Loại (Try-On)', border: OutlineInputBorder()), // [NEW]
                                items: const [
                                  DropdownMenuItem(value: 'Top', child: Text('Áo (Top)')),
                                  DropdownMenuItem(value: 'Bottom', child: Text('Quần / Váy (Bottom)')),
                                  DropdownMenuItem(value: 'Outerwear', child: Text('Áo Khoác (Outerwear)')),
                                  DropdownMenuItem(value: 'Shoes', child: Text('Giày (Shoes)')),
                                  DropdownMenuItem(value: 'Accessories', child: Text('Phụ kiện')),
                                ],
                                onChanged: (val) => setState(() => _selectedSubCategory = val),
                                // Optional validator, or required for Try-On items
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _priceController,
                            decoration: const InputDecoration(labelText: 'Giá bán cơ bản (VNĐ)', border: OutlineInputBorder(), suffixText: 'đ'),
                            keyboardType: TextInputType.number,
                            validator: (val) => val == null || val.isEmpty ? 'Bắt buộc nhập' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 5,
                      decoration: const InputDecoration(labelText: 'Mô tả chi tiết', border: OutlineInputBorder()),
                    ),
                    
                    const SizedBox(height: 32),
                    _SectionHeader(title: 'Hình ảnh Gallery'),
                    const SizedBox(height: 8),
                    ImageUploader(
                      initialImages: _images,
                      onImagesChanged: (newImages) => setState(() => _images = newImages),
                    ),

                    const SizedBox(height: 32),
                    _SectionHeader(title: 'Ảnh Thử Đồ (Virtual Try-On)'),
                    const SizedBox(height: 8),
                    _buildTryOnSection(),
                  ],
                ),
              ),

              const SizedBox(width: 32),

              // Right Column: Variants
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                     _SectionHeader(title: 'Biến thể (Size/Màu)'),
                     const SizedBox(height: 16),
                     // ... Variant UI reused
                     _buildVariantGenerator(),
                     const SizedBox(height: 24),
                     _buildVariantList(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTryOnSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50], 
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    const Text('1. Chọn ảnh gốc (Nền trơn)', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _pickTryOnImage,
                      child: Container(
                        height: 150,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: _tryOnOriginalBytes != null
                          ? Image.memory(_tryOnOriginalBytes!, fit: BoxFit.contain)
                          : const Icon(Icons.add_a_photo, color: Colors.grey),
                      ),
                    ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Icon(Icons.arrow_forward, color: Colors.grey),
              ),
              Expanded(
                child: Column(
                  children: [
                    const Text('2. Kết quả tách nền', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Container(
                      height: 150,
                       decoration: BoxDecoration(
                          color: _tryOnProcessedBytes != null ? Colors.white : Colors.grey[100],
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                           // Checkerboard pattern could go here
                        ),
                      alignment: Alignment.center,
                      child: _isProcessingTryOn 
                        ? const CircularProgressIndicator()
                        : _tryOnProcessedBytes != null
                            ? Image.memory(_tryOnProcessedBytes!, fit: BoxFit.contain)
                            : _existingTryOnUrl != null
                                ? Image.network(_existingTryOnUrl!, fit: BoxFit.contain)
                                : const Text('Chưa có dữ liệu', style: TextStyle(color: Colors.grey)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_tryOnProcessedBytes == null && _existingTryOnUrl == null)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text('Hệ thống sẽ tự động tách nền khi bạn chọn ảnh gốc.', style: TextStyle(fontSize: 12, color: Colors.grey)),
            ),
        ],
      ),
    );
  }

  Widget _buildVariantGenerator() {
      // Reuse the UI code from before...
      return Container(
       padding: const EdgeInsets.all(16),
       decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(8)),
       child: Column(
         crossAxisAlignment: CrossAxisAlignment.start,
         children: [
           const Text('Tạo nhanh biến thể', style: TextStyle(fontWeight: FontWeight.bold)),
           const SizedBox(height: 12),
           Row(
             children: [
               Expanded(
                 child: TextField(
                   decoration: const InputDecoration(
                     labelText: 'Màu sắc (phân cách bằng dấu phẩy)',
                     hintText: 'Vd: Đen, Trắng, Đỏ',
                     border: OutlineInputBorder(),
                     isDense: true,
                   ),
                   controller: _colorsInputController,
                 ),
               ),
               const SizedBox(width: 12),
               Expanded(
                 child: TextField(
                   decoration: const InputDecoration(
                     labelText: 'Kích thước (phân cách bằng dấu phẩy)',
                     hintText: 'Vd: S, M, L, XL',
                     border: OutlineInputBorder(),
                     isDense: true,
                   ),
                   controller: _sizesInputController,
                 ),
               ),
               const SizedBox(width: 12),
               ElevatedButton(
                 onPressed: _generateVariants,
                 style: ElevatedButton.styleFrom(
                   backgroundColor: AppColors.charcoal,
                   foregroundColor: Colors.white,
                   padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                 ),
                 child: const Text('Tạo Matrix'),
               ),
             ],
           ),
         ],
       ),
     );
  }

  Widget _buildVariantList() {
      if(_variants.isEmpty) return const Center(child: Padding(padding: EdgeInsets.all(20), child: Text('Chưa có biến thể nào.')));
      
      return Container(
        decoration: BoxDecoration(border: Border.all(color: Colors.grey[300]!), borderRadius: BorderRadius.circular(8)),
        child: Column(
          children: [
             Container(
              padding: const EdgeInsets.all(12),
              color: Colors.grey[100],
              child: const Row(
                children: [
                  Expanded(flex: 2, child: Text('Thuộc tính', style: TextStyle(fontWeight: FontWeight.bold))),
                  Expanded(flex: 2, child: Text('Giá bán', style: TextStyle(fontWeight: FontWeight.bold))),
                  Expanded(flex: 2, child: Text('Tồn kho', style: TextStyle(fontWeight: FontWeight.bold))),
                  SizedBox(width: 48, child: Text('Xóa', style: TextStyle(fontWeight: FontWeight.bold))),
                ],
              ),
            ),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _variants.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final variant = _variants[index];
                return Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Row(
                          children: [
                            if (variant.color != null) Chip(label: Text(variant.color!), backgroundColor: Colors.grey[200], labelStyle: const TextStyle(fontSize: 12)),
                            const SizedBox(width: 8),
                            if (variant.size != null) Chip(label: Text(variant.size!), backgroundColor: Colors.grey[200], labelStyle: const TextStyle(fontSize: 12)),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          initialValue: variant.price.toString(),
                          decoration: const InputDecoration(isDense: true, border: OutlineInputBorder(), suffixText: 'đ'),
                          keyboardType: TextInputType.number,
                          onChanged: (val) {
                            _variants[index] = variant.copyWith(price: int.tryParse(val) ?? 0);
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          initialValue: variant.stock.toString(),
                          decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()),
                          keyboardType: TextInputType.number,
                          onChanged: (val) {
                            _variants[index] = variant.copyWith(stock: int.tryParse(val) ?? 0);
                          },
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: () => setState(() => _variants.removeAt(index)),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
         Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.charcoal)),
         const Divider(),
      ],
    );
  }
}
