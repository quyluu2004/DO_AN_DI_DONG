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

  // Khai báo các Controller
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _discountController = TextEditingController();
  final TextEditingController _limitController = TextEditingController(); // <--- Controller cho số lượng
  final TextEditingController _durationController = TextEditingController();
  bool _useDuration = false;

  @override
  void initState() {
    super.initState();
    _config = FlashSaleConfig.fromMap(widget.initialConfig.toMap());

    // Load dữ liệu cũ lên giao diện
    if (_config.endTime != null) {
      _dateController.text = DateFormat('yyyy-MM-dd HH:mm').format(_config.endTime!);
    }
    _codeController.text = _config.code ?? '';
    _discountController.text = _config.discountValue?.toString() ?? '';
    _limitController.text = _config.limit.toString(); // <--- Load số lượng cũ
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
    // 1. Xử lý nhập phút nhanh
    if (_useDuration && _durationController.text.isNotEmpty) {
      int minutes = int.tryParse(_durationController.text) ?? 0;
      if (minutes > 0) {
        _config.endTime = DateTime.now().add(Duration(minutes: minutes));
        _dateController.text = DateFormat('yyyy-MM-dd HH:mm').format(_config.endTime!);
      }
    }

    // 2. Validate thời gian
    if (_config.endTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng chọn thời gian kết thúc!')));
      return;
    }
    if (_config.endTime!.isBefore(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lỗi: Thời gian phải ở tương lai!')));
      return;
    }

    // 3. Cập nhật Model từ Controller
    _config.code = _codeController.text;
    _config.discountValue = double.tryParse(_discountController.text) ?? 0;
    _config.limit = int.tryParse(_limitController.text) ?? 0; // <--- Lưu số lượng

    setState(() => _isLoading = true);
    await UIService.instance.updateFlashSale(_config);
    setState(() => _isLoading = false);

    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã lưu cấu hình Flash Sale!')));
  }

  // Hàm hiển thị danh sách người dùng
  void _showUserList() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Danh sách đã dùng (${_config.usedUserIds.length}/${_config.limit})"),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: _config.usageHistory.isEmpty
              ? const Center(child: Text("Chưa có ai sử dụng mã này"))
              : ListView.separated(
                  itemCount: _config.usageHistory.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (ctx, index) {
                    final item = _config.usageHistory[index];
                    final date = DateTime.fromMillisecondsSinceEpoch(item['time']);
                    return ListTile(
                      leading: CircleAvatar(child: Text("${index + 1}")),
                      title: Text(item['name'] ?? "Không có tên", style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text("ID: ${item['uid']}\nThời gian: ${DateFormat('HH:mm dd/MM').format(date)}"),
                      isThreeLine: true,
                    );
                  },
                ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Đóng"))
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Tính toán thống kê
    int used = _config.usedUserIds.length;
    int limit = int.tryParse(_limitController.text) ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Flash Sale Block', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _save,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white),
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
                  decoration: const InputDecoration(labelText: 'Tiêu đề (VD: Flash Sale)'),
                  controller: TextEditingController(text: _config.title)..selection = TextSelection.collapsed(offset: _config.title.length),
                  onChanged: (v) => _config.title = v,
                ),
                const SizedBox(height: 12),

                // Chọn ngày giờ
                TextField(
                  controller: _dateController,
                  readOnly: true,
                  decoration: const InputDecoration(labelText: 'Thời gian kết thúc', suffixIcon: Icon(Icons.calendar_today)),
                  onTap: _pickDateTime,
                ),

                // Checkbox nhập phút nhanh
                CheckboxListTile(
                  title: const Text("Cài đặt nhanh theo thời lượng (phút)"),
                  value: _useDuration,
                  onChanged: (val) => setState(() => _useDuration = val ?? false),
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                ),
                if (_useDuration)
                  TextField(
                    controller: _durationController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Nhập số phút (VD: 30)', border: OutlineInputBorder()),
                  ),

                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 12),

                // --- HÀNG NHẬP LIỆU QUAN TRỌNG ---
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Ô Mã Code
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: _codeController,
                        decoration: const InputDecoration(
                          labelText: 'Mã Code',
                          border: OutlineInputBorder(),
                          hintText: 'VD: FLASH50'
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    
                    // Ô Giảm giá
                    Expanded(
                      flex: 1,
                      child: TextField(
                        controller: _discountController,
                        decoration: const InputDecoration(
                          labelText: 'Giảm (%)',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 10),
                    
                    // --- Ô NHẬP SỐ LƯỢNG (MỚI) ---
                    Expanded(
                      flex: 1,
                      child: TextField(
                        controller: _limitController,
                        decoration: const InputDecoration(
                          labelText: 'Số lượng',
                          border: OutlineInputBorder(),
                          hintText: '0 = Vô hạn'
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (v) => setState((){}), // Để cập nhật text thống kê bên dưới
                      ),
                    ),
                  ],
                ),
                
                // Hiển thị thống kê & Danh sách
                if (limit > 0)
                  Container(
                    margin: const EdgeInsets.only(top: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.people, color: Colors.blue.shade700),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Tiến độ: $used / $limit", style: const TextStyle(fontWeight: FontWeight.bold)),
                            const Text("người đã sử dụng mã", style: TextStyle(fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: _showUserList,
                          icon: const Icon(Icons.list),
                          label: const Text("Xem chi tiết"),
                        )
                      ],
                    ),
                  ),

                const SizedBox(height: 12),
                const Text(
                  "Lưu ý: Sau khi bấm Lưu, hãy xuống mục 'Cấu hình Flash Sale' bên dưới để kích hoạt đếm ngược.",
                  style: TextStyle(color: Colors.grey, fontSize: 12, fontStyle: FontStyle.italic)
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}