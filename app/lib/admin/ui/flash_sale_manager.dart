import 'package:flutter/material.dart';
import '../../models/ui_config_model.dart';
import '../../services/ui_service.dart';
import 'package:intl/intl.dart';

class FlashSaleManager extends StatefulWidget {
  final FlashSaleConfig initialConfig;

  const FlashSaleManager({super.key, required this.initialConfig});

  @override
  State<FlashSaleManager> createState() => _FlashSaleManagerState();
}

class _FlashSaleManagerState extends State<FlashSaleManager> {
  late FlashSaleConfig _config;
  bool _isLoading = false;
  final TextEditingController _dateController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _config = FlashSaleConfig.fromMap(widget.initialConfig.toMap());
    if (_config.endTime != null) {
      _dateController.text = DateFormat('yyyy-MM-dd HH:mm').format(_config.endTime!);
    }
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _config.endTime ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );
    if (date == null) return;

    if (!mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_config.endTime ?? DateTime.now()),
    );
    if (time == null) return;

    final dateTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    setState(() {
      _config.endTime = dateTime;
      _dateController.text = DateFormat('yyyy-MM-dd HH:mm').format(dateTime);
    });
  }

  Future<void> _save() async {
    setState(() => _isLoading = true);
    await UIService.instance.updateFlashSale(_config);
    setState(() => _isLoading = false);
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã lưu Flash Sale!')));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Flash Sale Block', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                TextField(
                  decoration: const InputDecoration(labelText: 'Tiêu đề (VD: Flash Sale, Giờ vàng)'),
                  controller: TextEditingController(text: _config.title)..selection = TextSelection.collapsed(offset: _config.title.length),
                  onChanged: (v) => _config.title = v,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _dateController,
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: 'Thời gian kết thúc',
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  onTap: _pickDateTime,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _config.type,
                  decoration: const InputDecoration(labelText: 'Nguồn sản phẩm'),
                  items: const [
                    DropdownMenuItem(value: 'auto', child: Text('Tự động (Top giảm giá)')),
                    DropdownMenuItem(value: 'manual', child: Text('Thủ công (Chọn ID)')),
                  ],
                  onChanged: (v) => setState(() => _config.type = v ?? 'auto'),
                ),
                if (_config.type == 'manual') ...[
                   const SizedBox(height: 12),
                   const Text('Chức năng chọn sản phẩm thủ công đang được phát triển...', style: TextStyle(color: Colors.grey)),
                   // TODO: Add Product Selector widget here
                ]
              ],
            ),
          ),
        ),
      ],
    );
  }
}
