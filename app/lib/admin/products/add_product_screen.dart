
import 'dart:typed_data';
import 'package:flutter/foundation.dart'; // For kIsWeb (optional here since we use bytes)
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../models/product_model.dart';
import '../../services/product_service.dart';
import '../../services/cloudinary_service.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();

  // State
  String? _selectedCategory;
  XFile? _pickedFile; // Changed from File
  Uint8List? _originalImageBytes; // Added to store bytes for display & upload
  Uint8List? _removedBgImageBytes;
  bool _isProcessingImage = false;
  bool _isSaving = false;

  final List<String> _categories = ['Shirt', 'T-Shirt', 'Pants', 'Jeans', 'Shoes', 'Dress', 'Hoodie'];

  // 1. Pick Image
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      
      setState(() {
        _pickedFile = pickedFile;
        _originalImageBytes = bytes;
        _removedBgImageBytes = null; // Reset previous result
      });
      
      // Auto trigger remove bg
      _removeBackground();
    }
  }

  // 2. Remove Background API
  Future<void> _removeBackground() async {
    if (_pickedFile == null || _originalImageBytes == null) return;

    setState(() => _isProcessingImage = true);

    try {
      final uri = Uri.parse('https://api.remove.bg/v1.0/removebg');
      final request = http.MultipartRequest('POST', uri);
      
      final apiKey = dotenv.env['REMOVE_BG_API_KEY'] ?? '';
      
      if (apiKey.isEmpty) {
        throw Exception('Chưa tìm thấy API Key. Hãy khởi động lại ứng dụng (Restart) để tải file .env.');
      }

      request.headers['X-Api-Key'] = apiKey;
      request.headers['X-Api-Key'] = apiKey;
      
      // Use fromBytes for Web compatibility
      request.files.add(http.MultipartFile.fromBytes(
        'image_file', 
        _originalImageBytes!,
        filename: 'original.png'
      ));
      request.fields['size'] = 'auto';

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        setState(() {
          _removedBgImageBytes = response.bodyBytes;
        });
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('RemoveBG Error: ${response.statusCode} - ${response.body}')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Exception: $e')));
    } finally {
      setState(() => _isProcessingImage = false);
    }
  }

  // 3. Save Product
  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;
    if (_originalImageBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng chọn ảnh sản phẩm')));
      return;
    }

    setState(() => _isSaving = true);

    try {
      // A. Upload Original Image
      final originalUrl = await CloudinaryService.instance.uploadImage(
        bytes: _originalImageBytes!,
        folder: 'products',
      );

      // B. Upload Try-On Image (Processed or Fallback to Original)
      String tryOnUrl = originalUrl;
      if (_removedBgImageBytes != null) {
         tryOnUrl = await CloudinaryService.instance.uploadImage(
          bytes: _removedBgImageBytes!,
          folder: 'products/transparent',
        );
      }

      // C. Create Product Model
      final newProduct = Product(
        id: '', // Will be set by Firestore
        shopId: 'admin', // Default
        name: _nameController.text,
        price: int.parse(_priceController.text),
        stock: 100, // Default stock
        category: _selectedCategory,
        description: _descriptionController.text,
        images: [originalUrl], // List of images
        tryOnImageUrl: tryOnUrl,
        status: ProductStatus.active,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // D. Save to Firestore
      await ProductService.instance.addProduct(newProduct);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Thêm sản phẩm thành công!')));
        Navigator.pop(context);
      }

    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi lưu: $e')));
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Thêm Sản Phẩm Mới')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- Image Section ---
              Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        const Text('Ảnh Gốc'),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: _pickImage,
                          child: Container(
                            height: 150,
                            color: Colors.grey[200],
                            alignment: Alignment.center,
                            child: _originalImageBytes != null
                                ? Image.memory(_originalImageBytes!, fit: BoxFit.cover)
                                : const Icon(Icons.add_a_photo),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      children: [
                        const Text('Đã Tách Nền'),
                        const SizedBox(height: 8),
                        Container(
                          height: 150,
                          color: _removedBgImageBytes != null ? Colors.white : Colors.grey[100], // Checkered bg ideal
                          alignment: Alignment.center,
                          child: _isProcessingImage
                              ? const CircularProgressIndicator()
                              : _removedBgImageBytes != null
                                  ? Image.memory(_removedBgImageBytes!, fit: BoxFit.contain)
                                  : const Text('Chưa có', style: TextStyle(color: Colors.grey)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // --- Info Section ---
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Tên sản phẩm', border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? 'Nhập tên' : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _priceController,
                      decoration: const InputDecoration(labelText: 'Giá (VND)', border: OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                      validator: (v) => v!.isEmpty ? 'Nhập giá' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      decoration: const InputDecoration(labelText: 'Danh mục', border: OutlineInputBorder()),
                      items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                      onChanged: (v) => setState(() => _selectedCategory = v),
                      validator: (v) => v == null ? 'Chọn danh mục' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Mô tả', border: OutlineInputBorder()),
                maxLines: 3,
              ),
              const SizedBox(height: 24),

              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveProduct,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white),
                  child: _isSaving 
                    ? const CircularProgressIndicator(color: Colors.white) 
                    : const Text('LƯU SẢN PHẨM', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
