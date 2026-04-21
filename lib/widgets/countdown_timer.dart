// lib/widgets/countdown_timer.dart
// Adjustable Event Timer Widget - Admin/President can set and control

import 'dart:async';
import 'package:flutter/material.dart';
import '../constants/app_theme.dart';
import '../services/event_timer_service.dart';
import '../services/supabase_service.dart';
import '../models/user.dart';

class CountdownTimer extends StatefulWidget {
  final DateTime eventDate;
  final String eventId;
  final UserRole? userRole;
  final bool compact;
  final VoidCallback? onPostpone;

  const CountdownTimer({
    super.key,
    required this.eventDate,
    required this.eventId,
    this.userRole,
    this.compact = false,
    this.onPostpone,
  });

  @override
  State<CountdownTimer> createState() => _CountdownTimerState();
}

class _CountdownTimerState extends State<CountdownTimer> {
  Timer? _timer;
  EventTimerState? _timerState;
  bool _loading = true;
  int _displaySeconds = 0;
  dynamic _realtimeSubscription;

  bool get _canControl =>
      widget.userRole == UserRole.president ||
      widget.userRole == UserRole.admin ||
      widget.userRole == UserRole.superAdmin;

  @override
  void initState() {
    super.initState();
    _loadTimerState();
    _startLocalTimer();
    _setupRealtimeSubscription();
  }

  void _setupRealtimeSubscription() {
    _realtimeSubscription = SupabaseService.client
        .from('event_timers')
        .stream(primaryKey: ['event_id'])
        .eq('event_id', widget.eventId)
        .listen((data) {
          if (data.isNotEmpty && mounted) {
            setState(() {
              _timerState = EventTimerState.fromMap(data.first);
            });
            _updateDisplay();
          }
        });
  }

  void _startLocalTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateDisplay());
  }

  Future<void> _loadTimerState() async {
    var state = await EventTimerService.getTimerState(widget.eventId);
    if (state == null) {
      await EventTimerService.initializeTimer(widget.eventId, widget.eventDate);
      state = await EventTimerService.getTimerState(widget.eventId);
    }
    if (mounted) {
      setState(() {
        _timerState = state;
        _loading = false;
      });
      _updateDisplay();
    }
  }

  void _updateDisplay() {
    if (!mounted || _timerState == null) return;
    setState(() {
      _displaySeconds = _timerState!.remainingSeconds;
    });
  }

  Future<void> _toggleTimer() async {
    if (_timerState == null) return;

    if (_timerState!.isRunning) {
      await EventTimerService.pauseTimer(widget.eventId);
    } else {
      await EventTimerService.startTimer(widget.eventId);
    }
    await _loadTimerState();
  }

  Future<void> _resetTimer() async {
    await EventTimerService.resetTimer(widget.eventId);
    await _loadTimerState();
  }

  Future<void> _showSetTimeDialog() async {
    final result = await showDialog<int>(
      context: context,
      builder: (ctx) => _SetTimeDialog(
        currentSeconds: _timerState?.totalDurationSeconds ?? 0,
      ),
    );

    if (result != null && mounted) {
      await EventTimerService.setTimerDuration(widget.eventId, result);
      await _loadTimerState();
    }
  }

  Future<void> _showAddTimeDialog() async {
    final result = await showDialog<int>(
      context: context,
      builder: (ctx) => _AddTimeDialog(),
    );

    if (result != null && result > 0 && mounted) {
      await EventTimerService.addTime(widget.eventId, result);
      await _loadTimerState();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _realtimeSubscription?.cancel();
    super.dispose();
  }

  String _formatTime(int totalSeconds) {
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_loading) {
      return const Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)));
    }

    final isRunning = _timerState?.isRunning ?? false;
    final isNotSet = _timerState?.isNotSet ?? true;
    final isComplete = _timerState?.isComplete ?? false;

    // Compact mode
    if (widget.compact) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isRunning ? Colors.green.withOpacity(0.2) : AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(isRunning ? Icons.play_arrow : Icons.timer_outlined, size: 16, color: isRunning ? Colors.green : AppColors.primary),
            const SizedBox(width: 6),
            Text(
              isNotSet ? 'Not Set' : _formatTime(_displaySeconds),
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isRunning ? Colors.green : AppColors.primary),
            ),
          ],
        ),
      );
    }

    // Full mode
    Color bgColor = isDark ? DarkColors.primary : AppColors.primary;
    if (isComplete) {
      bgColor = Colors.green;
    } else if (!isRunning && !isNotSet) bgColor = Colors.orange;
    else if (isNotSet) bgColor = Colors.grey;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [bgColor, bgColor.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: bgColor.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          // Status label
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isComplete) ...[
                const Icon(Icons.check_circle, color: Colors.white, size: 18),
                const SizedBox(width: 6),
                const Text('TIME\'S UP!', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
              ] else if (isNotSet) ...[
                const Icon(Icons.timer_off, color: Colors.white70, size: 18),
                const SizedBox(width: 6),
                const Text('TIMER NOT SET', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
              ] else if (isRunning) ...[
                const Icon(Icons.play_circle, color: Colors.white, size: 18),
                const SizedBox(width: 6),
                const Text('RUNNING', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
              ] else ...[
                const Icon(Icons.pause_circle, color: Colors.white, size: 18),
                const SizedBox(width: 6),
                const Text('PAUSED', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ],
          ),

          const SizedBox(height: 16),

          // Timer display
          Text(
            isNotSet ? '00:00:00' : _formatTime(_displaySeconds),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 48,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
              letterSpacing: 4,
            ),
          ),

          // Control buttons (only for admin/president)
          if (_canControl) ...[
            const SizedBox(height: 20),

            // Main controls row
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isNotSet) ...[
                  // Set Time button
                  _buildControlButton(
                    icon: Icons.timer,
                    label: 'Set Time',
                    onPressed: _showSetTimeDialog,
                    color: Colors.white,
                  ),
                ] else ...[
                  // Play/Pause
                  _buildControlButton(
                    icon: isRunning ? Icons.pause : Icons.play_arrow,
                    label: isRunning ? 'Pause' : 'Start',
                    onPressed: _toggleTimer,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 12),
                  // Reset
                  _buildControlButton(
                    icon: Icons.refresh,
                    label: 'Reset',
                    onPressed: _resetTimer,
                    color: Colors.white,
                  ),
                ],
              ],
            ),

            if (!isNotSet) ...[
              const SizedBox(height: 12),
              // Secondary controls
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildControlButton(
                    icon: Icons.edit,
                    label: 'Edit',
                    onPressed: _showSetTimeDialog,
                    color: Colors.white70,
                    small: true,
                  ),
                  const SizedBox(width: 12),
                  _buildControlButton(
                    icon: Icons.add,
                    label: 'Add Time',
                    onPressed: _showAddTimeDialog,
                    color: Colors.white70,
                    small: true,
                  ),
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required Color color,
    bool small = false,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: small ? 10 : 16, vertical: small ? 6 : 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: small ? 14 : 18),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(color: color, fontSize: small ? 11 : 13, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

// Set Time Dialog
class _SetTimeDialog extends StatefulWidget {
  final int currentSeconds;
  const _SetTimeDialog({required this.currentSeconds});

  @override
  State<_SetTimeDialog> createState() => _SetTimeDialogState();
}

class _SetTimeDialogState extends State<_SetTimeDialog> {
  late int _hours;
  late int _minutes;
  late int _seconds;

  @override
  void initState() {
    super.initState();
    _hours = widget.currentSeconds ~/ 3600;
    _minutes = (widget.currentSeconds % 3600) ~/ 60;
    _seconds = widget.currentSeconds % 60;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.timer, color: AppColors.primary),
          SizedBox(width: 8),
          Text('Set Timer'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Set the countdown duration:', style: TextStyle(fontSize: 14)),
          const SizedBox(height: 20),

          // Time pickers
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildNumberPicker('Hours', _hours, 0, 99, (v) => setState(() => _hours = v)),
              const Text(' : ', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              _buildNumberPicker('Mins', _minutes, 0, 59, (v) => setState(() => _minutes = v)),
              const Text(' : ', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              _buildNumberPicker('Secs', _seconds, 0, 59, (v) => setState(() => _seconds = v)),
            ],
          ),

          const SizedBox(height: 20),

          // Quick presets
          const Text('Quick presets:', style: TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildPresetChip('5 min', 5 * 60),
              _buildPresetChip('10 min', 10 * 60),
              _buildPresetChip('15 min', 15 * 60),
              _buildPresetChip('30 min', 30 * 60),
              _buildPresetChip('1 hour', 60 * 60),
              _buildPresetChip('2 hours', 2 * 60 * 60),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final total = (_hours * 3600) + (_minutes * 60) + _seconds;
            Navigator.pop(context, total);
          },
          child: const Text('Set'),
        ),
      ],
    );
  }

  Widget _buildNumberPicker(String label, int value, int min, int max, ValueChanged<int> onChanged) {
    final controller = FixedExtentScrollController(initialItem: value - min);
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        const SizedBox(height: 4),
        Container(
          width: 70,
          height: 120,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: ListWheelScrollView.useDelegate(
            controller: controller,
            itemExtent: 40,
            perspective: 0.005,
            diameterRatio: 1.5,
            physics: const FixedExtentScrollPhysics(),
            onSelectedItemChanged: (index) => onChanged(min + index),
            childDelegate: ListWheelChildBuilderDelegate(
              childCount: max - min + 1,
              builder: (context, index) {
                final itemValue = min + index;
                final isSelected = itemValue == value;
                return Center(
                  child: Text(
                    itemValue.toString().padLeft(2, '0'),
                    style: TextStyle(
                      fontSize: isSelected ? 24 : 18,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? AppColors.primary : Colors.grey,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPresetChip(String label, int seconds) {
    final isSelected = (_hours * 3600 + _minutes * 60 + _seconds) == seconds;
    return ChoiceChip(
      label: Text(label, style: const TextStyle(fontSize: 11)),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _hours = seconds ~/ 3600;
            _minutes = (seconds % 3600) ~/ 60;
            _seconds = seconds % 60;
          });
        }
      },
      selectedColor: AppColors.primary.withOpacity(0.3),
    );
  }
}

// Add Time Dialog
class _AddTimeDialog extends StatefulWidget {
  @override
  State<_AddTimeDialog> createState() => _AddTimeDialogState();
}

class _AddTimeDialogState extends State<_AddTimeDialog> {
  int _minutes = 5;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.add_circle, color: Colors.green),
          SizedBox(width: 8),
          Text('Add Time'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Add extra time to the countdown:'),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildChip('1 min', 1),
              _buildChip('5 min', 5),
              _buildChip('10 min', 10),
              _buildChip('15 min', 15),
              _buildChip('30 min', 30),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, _minutes * 60),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          child: Text('Add $_minutes min'),
        ),
      ],
    );
  }

  Widget _buildChip(String label, int mins) {
    return ChoiceChip(
      label: Text(label),
      selected: _minutes == mins,
      onSelected: (s) => setState(() => _minutes = mins),
      selectedColor: Colors.green.withOpacity(0.3),
    );
  }
}
