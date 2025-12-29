import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/ui_config_model.dart';
import '../../services/ui_service.dart';
import '../../services/cloudinary_service.dart';

class BannerManager extends StatefulWidget {
  final List<BannerItem> initialBanners;

  const BannerManager({super.key, required this.initialBanners});

  @override
  State<BannerManager> createState() => _BannerManagerState();
}

class _BannerManagerState extends State<BannerManager> {
  late List<BannerItem> _banners;
  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _banners = List.from(widget.initialBanners);
  }

  Future<void> _save() async {
    setState(() => _isLoading = true);
    await UIService.instance.updateBanners(_banners);
    setState(() => _isLoading = false);
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã lưu Banner!')));
  }

  void _addBanner() {
    setState(() {
      _banners.add(BannerItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        imageUrl: '',
        actionType: 'none',
      ));
    });
  }

  Future<void> _pickImage(BannerItem banner) async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image == null) return;

      setState(() => _isLoading = true);
      
      final bytes = await image.readAsBytes();
      final url = await CloudinaryService.instance.uploadImage(
        bytes: bytes,
        folder: 'banners',
      );

      setState(() {
        banner.imageUrl = url;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi upload: $e')));
    }
  }

  void _removeBanner(int index) {
    setState(() {
      _banners.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Main Banner / Carousel', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _save,
              icon: const Icon(Icons.save),
              label: const Text('Lưu thay đổi'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _banners.isEmpty
            ? Center(
                child: Column(
                  children: [
                    const Text('Chưa có banner nào'),
                    const SizedBox(height: 8),
                    OutlinedButton(onPressed: _addBanner, child: const Text('Thêm Banner Ngay')),
                  ],
                ),
              )
            : ReorderableListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _banners.length,
                onReorder: (oldIndex, newIndex) {
                  setState(() {
                    if (oldIndex < newIndex) newIndex -= 1;
                    final item = _banners.removeAt(oldIndex);
                    _banners.insert(newIndex, item);
                  });
                },
                itemBuilder: (context, index) {
                  final banner = _banners[index];
                  return Card(
                    key: ValueKey(banner.id),
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              GestureDetector(
                                onTap: () => _pickImage(banner),
                                child: Container(
                                  width: 120,
                                  height: 60,
                                  color: Colors.grey[200],
                                  alignment: Alignment.center,
                                  child: banner.imageUrl.isNotEmpty
                                      ? Stack(
                                          fit: StackFit.expand,
                                          children: [
                                            Image.network(banner.imageUrl, fit: BoxFit.cover),
                                            Positioned(
                                              bottom: 0,
                                              right: 0,
                                              child: Container(
                                                color: Colors.black54,
                                                padding: const EdgeInsets.all(2),
                                                child: const Icon(Icons.edit, color: Colors.white, size: 14),
                                              ),
                                            )
                                          ],
                                        )
                                      : const Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.add_photo_alternate, color: Colors.grey),
                                            Text('Upload', style: TextStyle(fontSize: 10, color: Colors.grey)),
                                          ],
                                        ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  children: [
                                    // Hidden URL field or Read-only
                                    // TextField(
                                    //   decoration: const InputDecoration(labelText: 'URL Ảnh Banner'),
                                    //   controller: TextEditingController(text: banner.imageUrl),
                                    //   readOnly: true,
                                    // ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: DropdownButtonFormField<String>(
                                            value: banner.actionType,
                                            decoration: const InputDecoration(labelText: 'Hành động'),
                                            items: const [
                                              DropdownMenuItem(value: 'none', child: Text('Không')),
                                              DropdownMenuItem(value: 'web', child: Text('Mở Web')),
                                              DropdownMenuItem(value: 'category', child: Text('Mở Danh mục')),
                                              DropdownMenuItem(value: 'product', child: Text('Mở Sản phẩm')),
                                            ],
                                            onChanged: (v) => setState(() => banner.actionType = v ?? 'none'),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: TextField(
                                            decoration: const InputDecoration(labelText: 'Giá trị (URL/ID)'),
                                            controller: TextEditingController(text: banner.actionValue)
                                                ..selection = TextSelection.collapsed(offset: banner.actionValue.length),
                                            onChanged: (v) => banner.actionValue = v,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                onPressed: () => _removeBanner(index),
                                icon: const Icon(Icons.delete, color: Colors.red),
                              ),
                              const Icon(Icons.drag_handle, color: Colors.grey),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
        if (_banners.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: OutlinedButton.icon(
              onPressed: _addBanner,
              icon: const Icon(Icons.add),
              label: const Text('Thêm Banner'),
            ),
          ),
      ],
    );
  }
}
