import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/ui_config_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FlashSaleWidget extends StatefulWidget {
  final FlashSaleConfig config;

  FlashSaleWidget({
    super.key,
    FlashSaleConfig? config,
    // Hỗ trợ các tham số cũ để tránh lỗi ở home_page.dart
    DateTime? endTime,
    String? code,
    double? discountValue,
    String? discountType,
    bool isActive = true,
  }) : config = config ?? FlashSaleConfig(
          endTime: endTime,
          code: code,
          discountValue: discountValue,
          discountType: discountType ?? 'percent',
          isActive: isActive,
        );

  @override
  State<FlashSaleWidget> createState() => _FlashSaleWidgetState();
}

class _FlashSaleWidgetState extends State<FlashSaleWidget> {
  late Timer _timer;
  Duration _timeLeft = Duration.zero;
  bool _isVisible = false;
  bool _isSoldOut = false;
  bool _hasUsed = false;

  @override
  void initState() {
    super.initState();
    _checkVisibility();
    _startTimer();
    _checkUsageStatus();
  }

  void _checkVisibility() {
    final config = widget.config;
    final now = DateTime.now();

    // 1. Phải đang BẬT (isActive == true)
    // 2. Phải có thời gian kết thúc (endTime != null)
    // 3. Thời gian kết thúc phải ở tương lai (isAfter now)
    bool shouldShow = config.isActive &&
        config.endTime != null &&
        config.endTime!.isAfter(now);

    if (shouldShow) {
      if (mounted) {
        setState(() {
          _isVisible = true;
          _timeLeft = config.endTime!.difference(now);
        });
      }
    } else {
      if (mounted && _isVisible) setState(() => _isVisible = false);
    }
  }

  void _checkUsageStatus() {
    final config = widget.config;
    final currentUser = FirebaseAuth.instance.currentUser;

    // 1. Kiểm tra hết số lượng chưa
    if (config.limit > 0 && config.usedUserIds.length >= config.limit) {
      if (mounted) setState(() => _isSoldOut = true);
    }

    // 2. Kiểm tra User này dùng chưa
    if (currentUser != null && config.usedUserIds.contains(currentUser.uid)) {
      if (mounted) setState(() => _hasUsed = true);
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _checkVisibility();
    });
  }

  @override
  void dispose() {
    if (_timer.isActive) _timer.cancel();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String hours = twoDigits(d.inHours);
    String minutes = twoDigits(d.inMinutes.remainder(60));
    String seconds = twoDigits(d.inSeconds.remainder(60));
    return "$hours:$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    if (!_isVisible) return const SizedBox.shrink();
    
    // Tính toán phần trăm đã bán
    double progress = 0.0;
    int sold = widget.config.usedUserIds.length;
    int total = widget.config.limit;
    if (total > 0) {
      progress = sold / total;
      if (progress > 1.0) progress = 1.0;
    }

    return Positioned(
      bottom: 100,
      right: 16,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 120,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (_isSoldOut || _hasUsed) ? Colors.grey.shade700 : null,
              gradient: (_isSoldOut || _hasUsed) ? null : LinearGradient(
                colors: [Colors.red.shade800, Colors.orange.shade800],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                if (!_isSoldOut && !_hasUsed)
                  BoxShadow(color: Colors.red.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.flash_on, color: (_isSoldOut || _hasUsed) ? Colors.white54 : Colors.yellow, size: 14),
                    Text(
                      _hasUsed ? "ĐÃ DÙNG" : (_isSoldOut ? "HẾT MÃ" : "FLASH SALE"),
                      style: TextStyle(
                        color: (_isSoldOut || _hasUsed) ? Colors.white54 : Colors.yellow,
                        fontWeight: FontWeight.bold, fontSize: 11
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                
                // THANH TIẾN ĐỘ (Chỉ hiện khi chưa dùng & chưa hết & có limit)
                if (!_isSoldOut && !_hasUsed && total > 0) ...[
                   ClipRRect(
                     borderRadius: BorderRadius.circular(4),
                     child: LinearProgressIndicator(
                       value: progress,
                       backgroundColor: Colors.black26,
                       valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                       minHeight: 6,
                     ),
                   ),
                   const SizedBox(height: 4),
                   Text(
                     "Đã bán: $sold/$total",
                     style: const TextStyle(color: Colors.white, fontSize: 10),
                   ),
                   const SizedBox(height: 6),
                ],

                if (!_isSoldOut && !_hasUsed)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(4)),
                    child: Text(
                      _formatDuration(_timeLeft),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                
                const SizedBox(height: 6),
                
                if (_hasUsed)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 4),
                    child: Text("Bạn đã dùng mã này", style: TextStyle(color: Colors.white, fontSize: 10), textAlign: TextAlign.center),
                  ),

                if (widget.config.code != null)
                  Text(
                    "Code: ${widget.config.code}",
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500)
                  ),
                if (widget.config.discountValue != null)
                  Text(
                    widget.config.discountType == 'percent' ? '-${widget.config.discountValue!.toInt()}%' : '-${widget.config.discountValue!.toInt()}',
                    style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                  ),
              ],
            ),
          ),
          Positioned(
            top: -8,
            right: -8,
            child: GestureDetector(
              onTap: () => setState(() => _isVisible = false),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 2)],
                ),
                child: const Icon(Icons.close, size: 14, color: Colors.black),
              ),
            ),
          )
        ],
      ),
    );
  }
}
