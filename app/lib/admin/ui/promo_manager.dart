import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/ui_config_model.dart';
import '../../services/ui_service.dart';
import '../../services/cloudinary_service.dart';

class PromoManager extends StatefulWidget {
  final PromoBannerConfig initialConfig;

  const PromoManager({super.key, required this.initialConfig});

  @override
  State<PromoManager> createState() => _PromoManagerState();
}

class _PromoManagerState extends State<PromoManager> {
  late PromoBannerConfig _config;
  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _config = PromoBannerConfig.fromMap(widget.initialConfig.toMap());
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image == null) return;

      setState(() => _isLoading = true);
      
      final bytes = await image.readAsBytes();
      final url = await CloudinaryService.instance.uploadImage(
        bytes: bytes,
        folder: 'promos',
      );

      setState(() {
        _config.imageUrl = url;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi upload: $e')));
    }
  }

  Future<void> _save() async {
    setState(() => _isLoading = true);
    await UIService.instance.updatePromoBanner(_config);
    setState(() => _isLoading = false);
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã lưu Promo Banner!')));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Promo Banner (Single)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _save,
              icon: const Icon(Icons.save),
              label: const Text('Lưu thay đổi'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    height: 150,
                    width: double.infinity,
                    color: Colors.grey[200],
                    alignment: Alignment.center,
                    child: _config.imageUrl.isNotEmpty
                        ? Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.network(_config.imageUrl, fit: BoxFit.cover, width: double.infinity),
                               Center(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20)),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.edit, color: Colors.white),
                                      SizedBox(width: 8),
                                      Text('Thay ảnh', style: TextStyle(color: Colors.white)),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          )
                        : const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_photo_alternate, size: 50, color: Colors.grey),
                              Text('Bấm để tải ảnh lên', style: TextStyle(color: Colors.grey)),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 12),
                // TextField(
                //   decoration: const InputDecoration(labelText: 'URL Ảnh Banner'),
                //   controller: TextEditingController(text: _config.imageUrl)..selection = TextSelection.collapsed(offset: _config.imageUrl.length),
                //   onChanged: (v) => _config.imageUrl = v,
                //   readOnly: true,
                // ),
                // const SizedBox(height: 12),
                TextField(
                  decoration: const InputDecoration(labelText: 'Tiêu đề (Optional)'),
                  controller: TextEditingController(text: _config.title)..selection = TextSelection.collapsed(offset: (_config.title ?? '').length),
                  onChanged: (v) => _config.title = v,
                ),
                const SizedBox(height: 12),
                TextField(
                  decoration: const InputDecoration(labelText: 'Mô tả ngắn (Subtitle)'),
                  controller: TextEditingController(text: _config.subtitle)..selection = TextSelection.collapsed(offset: (_config.subtitle ?? '').length),
                  onChanged: (v) => _config.subtitle = v,
                ),
                const SizedBox(height: 12),
                TextField(
                  decoration: const InputDecoration(labelText: 'Đích đến (Link/Collection)'),
                  controller: TextEditingController(text: _config.destination)..selection = TextSelection.collapsed(offset: (_config.destination ?? '').length),
                  onChanged: (v) => _config.destination = v,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
