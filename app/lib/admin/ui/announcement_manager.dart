import 'package:flutter/material.dart';
import '../../models/ui_config_model.dart';
import '../../services/ui_service.dart';

class AnnouncementManager extends StatefulWidget {
  final AnnouncementConfig initialConfig;

  const AnnouncementManager({super.key, required this.initialConfig});

  @override
  State<AnnouncementManager> createState() => _AnnouncementManagerState();
}

class _AnnouncementManagerState extends State<AnnouncementManager> {
  late AnnouncementConfig _config;
  bool _isLoading = false;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _config = AnnouncementConfig.fromMap(widget.initialConfig.toMap());
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();
    
    setState(() => _isLoading = true);
    await UIService.instance.updateAnnouncement(_config);
    setState(() => _isLoading = false);
    
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã lưu Announcement!')));
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Announcement Bar', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                  TextFormField(
                    initialValue: _config.content,
                    decoration: const InputDecoration(labelText: 'Nội dung thông báo'),
                    onSaved: (v) => _config.content = v ?? '',
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          initialValue: _config.textColor,
                          decoration: const InputDecoration(labelText: 'Màu chữ (Hex)'),
                          onSaved: (v) => _config.textColor = v ?? '',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          initialValue: _config.backgroundColor,
                          decoration: const InputDecoration(labelText: 'Màu nền (Hex)'),
                          onSaved: (v) => _config.backgroundColor = v ?? '',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    title: const Text('Cho phép bấm vào xem chi tiết?'),
                    value: _config.clickable,
                    onChanged: (v) => setState(() => _config.clickable = v),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
