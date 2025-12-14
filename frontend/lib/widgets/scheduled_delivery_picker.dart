import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// 🕐 Scheduled Delivery Time Picker
/// Allows users to schedule delivery for a specific time (Chowdeck/Glovo parity)
class ScheduledDeliveryPicker extends StatefulWidget {
  final Function(DateTime? scheduledTime, Map<String, dynamic>? slotInfo)
  onTimeSelected;
  final DateTime? initialTime;

  const ScheduledDeliveryPicker({
    super.key,
    required this.onTimeSelected,
    this.initialTime,
  });

  @override
  State<ScheduledDeliveryPicker> createState() =>
      _ScheduledDeliveryPickerState();
}

class _ScheduledDeliveryPickerState extends State<ScheduledDeliveryPicker> {
  bool _isScheduled = false;
  DateTime? _selectedDate;
  String? _selectedTimeSlot;

  // Available time slots (30-min intervals from 8 AM to 10 PM)
  final List<String> _timeSlots = [];

  @override
  void initState() {
    super.initState();
    _generateTimeSlots();
    if (widget.initialTime != null) {
      _isScheduled = true;
      _selectedDate = widget.initialTime;
      _selectedTimeSlot = _getTimeSlotFromDateTime(widget.initialTime!);
    }
  }

  void _generateTimeSlots() {
    _timeSlots.clear();
    for (int hour = 8; hour <= 22; hour++) {
      for (int minute = 0; minute < 60; minute += 30) {
        if (hour == 22 && minute > 0) break;
        final time = TimeOfDay(hour: hour, minute: minute);
        _timeSlots.add(_formatTimeSlot(time));
      }
    }
  }

  String _formatTimeSlot(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  String _getTimeSlotFromDateTime(DateTime dateTime) {
    return _formatTimeSlot(TimeOfDay.fromDateTime(dateTime));
  }

  DateTime? _getDateTimeFromSlot() {
    if (_selectedDate == null || _selectedTimeSlot == null) return null;

    // Parse time slot
    final parts = _selectedTimeSlot!.split(' ');
    final timeParts = parts[0].split(':');
    int hour = int.parse(timeParts[0]);
    final minute = int.parse(timeParts[1]);
    final isPM = parts[1] == 'PM';

    if (isPM && hour != 12) hour += 12;
    if (!isPM && hour == 12) hour = 0;

    return DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      hour,
      minute,
    );
  }

  List<String> _getAvailableTimeSlots() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (_selectedDate == null) return _timeSlots;

    final selectedDay = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
    );

    // If not today, all slots are available
    if (!selectedDay.isAtSameMomentAs(today)) return _timeSlots;

    // For today, only show future slots (with 1 hour buffer)
    final minTime = now.add(const Duration(hours: 1));

    return _timeSlots.where((slot) {
      final parts = slot.split(' ');
      final timeParts = parts[0].split(':');
      int hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);
      final isPM = parts[1] == 'PM';

      if (isPM && hour != 12) hour += 12;
      if (!isPM && hour == 12) hour = 0;

      final slotTime = DateTime(now.year, now.month, now.day, hour, minute);
      return slotTime.isAfter(minTime);
    }).toList();
  }

  void _notifyParent() {
    if (!_isScheduled) {
      widget.onTimeSelected(null, null);
      return;
    }

    final scheduledTime = _getDateTimeFromSlot();
    if (scheduledTime != null) {
      final dateStr = DateFormat('yyyy-MM-dd').format(scheduledTime);
      final displayText = _getDisplayText(scheduledTime);

      widget.onTimeSelected(scheduledTime, {
        'date': dateStr,
        'timeSlot': _selectedTimeSlot,
        'displayText': displayText,
      });
    }
  }

  String _getDisplayText(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final selectedDay = DateTime(dateTime.year, dateTime.month, dateTime.day);

    String dayText;
    if (selectedDay.isAtSameMomentAs(today)) {
      dayText = 'Today';
    } else if (selectedDay.isAtSameMomentAs(tomorrow)) {
      dayText = 'Tomorrow';
    } else {
      dayText = DateFormat('EEE, MMM d').format(dateTime);
    }

    return '$dayText at $_selectedTimeSlot';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with toggle
            Row(
              children: [
                Icon(Icons.schedule, color: Theme.of(context).primaryColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Delivery Time',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _isScheduled
                            ? 'Schedule for later'
                            : 'As soon as possible',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _isScheduled,
                  onChanged: (value) {
                    setState(() {
                      _isScheduled = value;
                      if (!value) {
                        _selectedDate = null;
                        _selectedTimeSlot = null;
                      }
                    });
                    _notifyParent();
                  },
                  activeTrackColor: Theme.of(context).primaryColor,
                ),
              ],
            ),

            // Scheduling options
            if (_isScheduled) ...[
              const Divider(height: 24),

              // ASAP option
              _DeliveryOption(
                icon: Icons.bolt,
                label: 'As soon as possible',
                isSelected: !_isScheduled,
                onTap: () {
                  setState(() {
                    _isScheduled = false;
                    _selectedDate = null;
                    _selectedTimeSlot = null;
                  });
                  _notifyParent();
                },
              ),

              const SizedBox(height: 8),

              // Date selector
              const Text(
                'Select Date',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),

              SizedBox(
                height: 80,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: 7, // Show next 7 days
                  itemBuilder: (context, index) {
                    final date = DateTime.now().add(Duration(days: index));
                    final isSelected =
                        _selectedDate != null &&
                        _selectedDate!.day == date.day &&
                        _selectedDate!.month == date.month;

                    return _DateCard(
                      date: date,
                      isSelected: isSelected,
                      onTap: () {
                        setState(() {
                          _selectedDate = date;
                          // Reset time slot if not available for new date
                          final availableSlots = _getAvailableTimeSlots();
                          if (_selectedTimeSlot != null &&
                              !availableSlots.contains(_selectedTimeSlot)) {
                            _selectedTimeSlot = availableSlots.isNotEmpty
                                ? availableSlots.first
                                : null;
                          }
                        });
                        _notifyParent();
                      },
                    );
                  },
                ),
              ),

              // Time slot selector
              if (_selectedDate != null) ...[
                const SizedBox(height: 16),
                const Text(
                  'Select Time',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),

                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _getAvailableTimeSlots().map((slot) {
                    final isSelected = _selectedTimeSlot == slot;
                    return ChoiceChip(
                      label: Text(slot),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _selectedTimeSlot = slot;
                          });
                          _notifyParent();
                        }
                      },
                      selectedColor: Theme.of(
                        context,
                      ).primaryColor.withValues(alpha: 0.2),
                      labelStyle: TextStyle(
                        color: isSelected
                            ? Theme.of(context).primaryColor
                            : Colors.grey[700],
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    );
                  }).toList(),
                ),
              ],

              // Summary
              if (_selectedDate != null && _selectedTimeSlot != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: Theme.of(context).primaryColor,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Scheduled: ${_getDisplayText(_getDateTimeFromSlot()!)}',
                          style: TextStyle(
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _DeliveryOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _DeliveryOption({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).primaryColor.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).primaryColor
                : Colors.grey[300]!,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? Theme.of(context).primaryColor
                  : Colors.grey[600],
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected
                      ? Theme.of(context).primaryColor
                      : Colors.grey[700],
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: Theme.of(context).primaryColor),
          ],
        ),
      ),
    );
  }
}

class _DateCard extends StatelessWidget {
  final DateTime date;
  final bool isSelected;
  final VoidCallback onTap;

  const _DateCard({
    required this.date,
    required this.isSelected,
    required this.onTap,
  });

  String _getDayName() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final dateDay = DateTime(date.year, date.month, date.day);

    if (dateDay.isAtSameMomentAs(today)) return 'Today';
    if (dateDay.isAtSameMomentAs(tomorrow)) return 'Tomorrow';
    return DateFormat('EEE').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 70,
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).primaryColor : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).primaryColor
                : Colors.grey[300]!,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _getDayName(),
              style: TextStyle(
                fontSize: 11,
                color: isSelected ? Colors.white : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              date.day.toString(),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : Colors.black87,
              ),
            ),
            Text(
              DateFormat('MMM').format(date),
              style: TextStyle(
                fontSize: 11,
                color: isSelected ? Colors.white70 : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
