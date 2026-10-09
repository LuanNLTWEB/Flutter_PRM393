import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

/// Widget chọn lịch hẹn thợ đến nhà: khách chọn ngày và giờ tùy ý (kể cả giờ lẻ)
class ScheduleTimeSlotPicker extends StatefulWidget {
  /// Hẹn trước tối đa 14 ngày
  static const int maxDaysAhead = 14;

  final ValueChanged<DateTime?> onScheduleChanged;

  const ScheduleTimeSlotPicker({super.key, required this.onScheduleChanged});

  @override
  State<ScheduleTimeSlotPicker> createState() => _ScheduleTimeSlotPickerState();
}

class _ScheduleTimeSlotPickerState extends State<ScheduleTimeSlotPicker> {
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  void _emitSelection() {
    if (_selectedDate == null || _selectedTime == null) {
      widget.onScheduleChanged(null);
      return;
    }
    widget.onScheduleChanged(
      DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      ),
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final firstDate = DateTime(now.year, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? firstDate,
      firstDate: firstDate,
      lastDate: firstDate.add(const Duration(days: ScheduleTimeSlotPicker.maxDaysAhead)),
      helpText: 'CHỌN NGÀY THỢ ĐẾN NHÀ',
      cancelText: 'HỦY',
      confirmText: 'CHỌN',
    );
    if (picked == null) return;
    setState(() => _selectedDate = picked);
    // Nếu giờ đã chọn của hôm nay đã qua thì bỏ chọn
    if (_selectedTime != null && _isTimePast()) {
      setState(() => _selectedTime = null);
    }
    _emitSelection();
  }

  bool _isToday() {
    final now = DateTime.now();
    return _selectedDate != null &&
        _selectedDate!.year == now.year &&
        _selectedDate!.month == now.month &&
        _selectedDate!.day == now.day;
  }

  bool _isTimePast() {
    if (!_isToday() || _selectedTime == null) return false;
    final now = DateTime.now();
    final picked = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );
    return !picked.isAfter(now);
  }

  Future<void> _pickTime() async {
    if (_selectedDate == null) return;

    final now = DateTime.now();
    TimeOfDay initialTime = _selectedTime ?? const TimeOfDay(hour: 8, minute: 0);
    if (_isToday()) {
      // Làm tròn lên ít nhất 30 phút so với hiện tại làm giờ gợi ý
      final rounded = now.hour * 60 + now.minute + 30;
      if (rounded < 24 * 60) {
        initialTime = TimeOfDay(hour: rounded ~/ 60, minute: rounded % 60);
      }
    }

    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      helpText: 'CHỌN GIỜ THỢ ĐẾN NHÀ',
      cancelText: 'HỦY',
      confirmText: 'CHỌN',
    );
    if (picked == null) return;
    setState(() => _selectedTime = picked);
    _emitSelection();
  }

  String _formatDate(DateTime date) {
    const weekdays = ['Th 2', 'Th 3', 'Th 4', 'Th 5', 'Th 6', 'Th 7', 'CN'];
    final weekday = weekdays[date.weekday - 1];
    return '$weekday, ${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Chọn ngày
          InkWell(
            onTap: _pickDate,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              key: const Key('schedule_date_picker'),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.25)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_outlined, size: 20, color: AppTheme.primaryColor),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _selectedDate != null ? _formatDate(_selectedDate!) : 'Chọn ngày thợ đến nhà',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _selectedDate != null
                            ? AppTheme.textPrimaryColor
                            : Colors.grey.shade600,
                      ),
                    ),
                  ),
                  const Icon(Icons.arrow_drop_down, size: 24, color: AppTheme.primaryColor),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Chọn giờ
          Opacity(
            opacity: _selectedDate != null ? 1 : 0.5,
            child: InkWell(
              onTap: _selectedDate == null ? null : _pickTime,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                key: const Key('schedule_time_picker'),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: _selectedTime != null
                      ? AppTheme.primaryColor.withValues(alpha: 0.06)
                      : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _selectedTime != null
                        ? AppTheme.primaryColor.withValues(alpha: 0.25)
                        : Colors.grey.shade300,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.schedule_outlined,
                      size: 20,
                      color: _selectedDate != null
                          ? AppTheme.primaryColor
                          : Colors.grey.shade400,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _selectedTime != null
                            ? _formatTime(_selectedTime!)
                            : 'Chọn giờ thợ đến nhà',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _selectedTime != null
                              ? AppTheme.textPrimaryColor
                              : Colors.grey.shade600,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.arrow_drop_down,
                      size: 24,
                      color: _selectedDate != null ? AppTheme.primaryColor : Colors.grey.shade400,
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_selectedDate == null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Vui lòng chọn ngày trước khi chọn giờ',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
            ),
          if (_isTimePast())
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Giờ đã chọn đã qua, vui lòng chọn giờ khác',
                style: TextStyle(fontSize: 12, color: Colors.red.shade400),
              ),
            ),
        ],
      ),
    );
  }
}
