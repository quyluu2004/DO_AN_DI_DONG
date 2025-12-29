import 'dart:io';
import 'dart:io' if (dart.library.html) 'dart:html' as html;
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/cloudinary_service.dart';

/// Component upload và preview nhiều ảnh
/// 
/// Hỗ trợ:
/// - Upload nhiều ảnh
/// - Preview ảnh
/// - Chọn ảnh đại diện
/// - Xóa ảnh
/// - Sắp xếp lại thứ tự ảnh
class ImageUploader extends StatefulWidget {
  const ImageUploader({
    super.key,
    this.initialImages = const [],
    this.maxImages = 10,
    this.onImagesChanged,
  });

  final List<String> initialImages; // Danh sách URL ảnh ban đầu
  final int maxImages; // Số lượng ảnh tối đa
  final ValueChanged<List<String>>? onImagesChanged; // Callback khi danh sách ảnh thay đổi

  @override
  State<ImageUploader> createState() => _ImageUploaderState();
}

class _ImageUploaderState extends State<ImageUploader> {
  final ImagePicker _picker = ImagePicker();
  final CloudinaryService _cloudinaryService = CloudinaryService.instance;
  
  List<String> _imageUrls = [];
  List<XFile> _localImages = []; // Ảnh chưa upload (dùng XFile để hỗ trợ web)
  Map<String, Uint8List> _localImageBytes = {}; // Cache bytes cho web
  bool _uploading = false;
  int? _primaryImageIndex;

  @override
  void initState() {
    super.initState();
    _imageUrls = List.from(widget.initialImages);
    _primaryImageIndex = _imageUrls.isNotEmpty ? 0 : null;
  }

  /// Thêm ảnh từ gallery hoặc camera
  Future<void> _pickImages() async {
    if (_imageUrls.length + _localImages.length >= widget.maxImages) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Chỉ được tải tối đa ${widget.maxImages} ảnh'),
        ),
      );
      return;
    }

    try {
      final List<XFile> images = await _picker.pickMultiImage();
      
      if (images.isEmpty) return;

      setState(() {
        for (var image in images) {
          if (_imageUrls.length + _localImages.length < widget.maxImages) {
            _localImages.add(image);
          }
        }
      });

      // Đọc bytes cho web (cache để hiển thị)
      if (kIsWeb) {
        for (var image in images) {
          final bytes = await image.readAsBytes();
          _localImageBytes[image.path] = bytes;
        }
        setState(() {}); // Trigger rebuild để hiển thị ảnh
      }

      // Tự động upload ảnh
      await _uploadLocalImages();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi chọn ảnh: $e')),
      );
    }
  }

  /// Upload các ảnh local lên Cloudinary
  Future<void> _uploadLocalImages() async {
    if (_localImages.isEmpty) return;

    setState(() {
      _uploading = true;
    });

    try {
      final List<String> uploadedUrls = [];
      
      for (var imageFile in _localImages) {
        // Đọc bytes từ XFile (hỗ trợ cả web và mobile)
        final bytes = await imageFile.readAsBytes();
        final url = await _cloudinaryService.uploadImage(
          bytes: bytes,
          folder: 'products',
        );
        uploadedUrls.add(url);
      }

      setState(() {
        _imageUrls.addAll(uploadedUrls);
        _localImages.clear();
        _localImageBytes.clear();
        if (_primaryImageIndex == null && _imageUrls.isNotEmpty) {
          _primaryImageIndex = 0;
        }
        _uploading = false;
      });

      widget.onImagesChanged?.call(_imageUrls);
    } catch (e) {
      setState(() {
        _uploading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi upload ảnh: $e')),
        );
      }
    }
  }

  /// Xóa ảnh
  void _removeImage(int index) {
    setState(() {
      _imageUrls.removeAt(index);
      
      // Cập nhật primary image index
      if (_primaryImageIndex != null) {
        if (_primaryImageIndex == index) {
          _primaryImageIndex = _imageUrls.isNotEmpty ? 0 : null;
        } else if (_primaryImageIndex! > index) {
          _primaryImageIndex = _primaryImageIndex! - 1;
        }
      }
    });
    
    widget.onImagesChanged?.call(_imageUrls);
  }

  /// Đặt ảnh làm ảnh đại diện
  void _setPrimaryImage(int index) {
    setState(() {
      _primaryImageIndex = index;
    });
  }

  /// Di chuyển ảnh lên trên
  void _moveImageUp(int index) {
    if (index == 0) return;
    
    setState(() {
      final image = _imageUrls.removeAt(index);
      _imageUrls.insert(index - 1, image);
      
      // Cập nhật primary image index
      if (_primaryImageIndex == index) {
        _primaryImageIndex = index - 1;
      } else if (_primaryImageIndex == index - 1) {
        _primaryImageIndex = index;
      }
    });
    
    widget.onImagesChanged?.call(_imageUrls);
  }

  /// Di chuyển ảnh xuống dưới
  void _moveImageDown(int index) {
    if (index == _imageUrls.length - 1) return;
    
    setState(() {
      final image = _imageUrls.removeAt(index);
      _imageUrls.insert(index + 1, image);
      
      // Cập nhật primary image index
      if (_primaryImageIndex == index) {
        _primaryImageIndex = index + 1;
      } else if (_primaryImageIndex == index + 1) {
        _primaryImageIndex = index;
      }
    });
    
    widget.onImagesChanged?.call(_imageUrls);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        const Text(
          'Hình ảnh sản phẩm',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF0F1115),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Tối đa ${widget.maxImages} ảnh. Ảnh đầu tiên sẽ là ảnh đại diện.',
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF6C7077),
          ),
        ),
        const SizedBox(height: 12),
        
        // Grid ảnh
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            // Hiển thị các ảnh đã upload
            ...List.generate(_imageUrls.length, (index) {
              return _ImageItem(
                imageUrl: _imageUrls[index],
                isPrimary: _primaryImageIndex == index,
                onRemove: () => _removeImage(index),
                onSetPrimary: () => _setPrimaryImage(index),
                onMoveUp: index > 0 ? () => _moveImageUp(index) : null,
                onMoveDown: index < _imageUrls.length - 1
                    ? () => _moveImageDown(index)
                    : null,
              );
            }),
            
            // Hiển thị các ảnh đang upload
            ...List.generate(_localImages.length, (index) {
              final xFile = _localImages[index];
              final bytes = kIsWeb ? _localImageBytes[xFile.path] : null;
              File? file;
              if (!kIsWeb) {
                try {
                  file = File(xFile.path);
                } catch (e) {
                  // Ignore if File is not available
                }
              }
              return _ImageItem(
                imageFile: file,
                imageBytes: bytes,
                isUploading: true,
              );
            }),
            
            // Nút thêm ảnh
            if (_imageUrls.length + _localImages.length < widget.maxImages)
              _AddImageButton(
                onTap: _pickImages,
                disabled: _uploading,
              ),
          ],
        ),
        
        // Loading indicator khi đang upload
        if (_uploading)
          const Padding(
            padding: EdgeInsets.only(top: 12),
            child: Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 8),
                Text(
                  'Đang upload ảnh...',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6C7077),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _ImageItem extends StatelessWidget {
  const _ImageItem({
    this.imageUrl,
    this.imageFile,
    this.imageBytes,
    this.isPrimary = false,
    this.isUploading = false,
    this.onRemove,
    this.onSetPrimary,
    this.onMoveUp,
    this.onMoveDown,
  });

  final String? imageUrl;
  final File? imageFile;
  final Uint8List? imageBytes; // Cho web
  final bool isPrimary;
  final bool isUploading;
  final VoidCallback? onRemove;
  final VoidCallback? onSetPrimary;
  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isPrimary ? Colors.blue : Colors.grey[300]!,
              width: isPrimary ? 2 : 1,
            ),
            color: Colors.grey[100],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: isUploading
                ? const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : imageBytes != null
                    ? Image.memory(
                        imageBytes!,
                        fit: BoxFit.cover,
                      )
                    : imageFile != null
                        ? Image.file(
                            imageFile!,
                            fit: BoxFit.cover,
                          )
                        : imageUrl != null
                            ? Image.network(
                                imageUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(Icons.error_outline),
                              )
                            : const Icon(Icons.image_outlined),
          ),
        ),
        
        // Badge ảnh đại diện
        if (isPrimary)
          Positioned(
            top: 4,
            left: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'Đại diện',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        
        // Nút xóa
        if (!isUploading && onRemove != null)
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 14,
                ),
              ),
            ),
          ),
        
        // Menu hành động
        if (!isUploading)
          Positioned(
            bottom: 4,
            left: 4,
            right: 4,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (onMoveUp != null)
                  _ActionButton(
                    icon: Icons.arrow_upward,
                    onTap: onMoveUp!,
                  ),
                if (onMoveDown != null)
                  _ActionButton(
                    icon: Icons.arrow_downward,
                    onTap: onMoveDown!,
                  ),
                if (!isPrimary && onSetPrimary != null)
                  _ActionButton(
                    icon: Icons.star_outline,
                    onTap: onSetPrimary!,
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.6),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(icon, color: Colors.white, size: 14),
      ),
    );
  }
}

class _AddImageButton extends StatelessWidget {
  const _AddImageButton({
    required this.onTap,
    this.disabled = false,
  });

  final VoidCallback onTap;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.grey[300]!,
            style: BorderStyle.solid,
          ),
          color: Colors.grey[50],
        ),
        child: disabled
            ? const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_photo_alternate_outlined, size: 32),
                  SizedBox(height: 4),
                  Text(
                    'Thêm ảnh',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6C7077),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

