// lib/pages/edit_event_page.dart
// Edit Event Page - Allows presidents/admins to edit existing events

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../models/event.dart';
import '../services/event_service.dart';
import '../services/storage_service.dart';
import '../providers/auth_provider.dart';
import '../constants/app_theme.dart';

class EditEventPage extends ConsumerStatefulWidget {
  final Event event;
  const EditEventPage({super.key, required this.event});

  @override
  ConsumerState<EditEventPage> createState() => _EditEventPageState();
}

class _EditEventPageState extends ConsumerState<EditEventPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController titleController;
  late TextEditingController descriptionController;
  late TextEditingController venueController;

  late DateTime selectedDate;
  late TimeOfDay selectedTime;
  late String selectedCategory;
  bool loading = false;
  bool imageChanged = false;

  XFile? _selectedImage;
  Uint8List? _imageBytes;
  String? _existingImageUrl;

  final categories = ['Tech', 'Sports', 'Cultural', 'Academic', 'Music'];

  @override
  void initState() {
    super.initState();
    // Pre-fill with existing event data
    titleController = TextEditingController(text: widget.event.title);
    descriptionController = TextEditingController(text: widget.event.description);
    venueController = TextEditingController(text: widget.event.venue);
    selectedDate = widget.event.date;
    selectedTime = TimeOfDay(hour: widget.event.date.hour, minute: widget.event.date.minute);
    selectedCategory = widget.event.category;
    _existingImageUrl = widget.event.imageUrl;
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    venueController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final image = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 80, maxWidth: 1200, maxHeight: 800);
      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _selectedImage = image;
          _imageBytes = bytes;
          imageChanged = true;
        });
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.dangerColor));
    }
  }

  void _removeImage() => setState(() {
    _selectedImage = null;
    _imageBytes = null;
    _existingImageUrl = null;
    imageChanged = true;
  });

  void _updateEvent() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { loading = true; });

    try {
      final user = ref.read(currentUserProvider);
      if (user == null) throw Exception('User not authenticated');

      final eventDateTime = DateTime(selectedDate.year, selectedDate.month, selectedDate.day, selectedTime.hour, selectedTime.minute);

      String? imageUrl = _existingImageUrl;

      // Upload new image if changed
      if (imageChanged && _selectedImage != null && _imageBytes != null) {
        imageUrl = await StorageService.uploadEventImageBytes(_imageBytes!, widget.event.id, _selectedImage!.name.split('.').last);
      } else if (imageChanged && _imageBytes == null) {
        // Image was removed
        imageUrl = null;
      }

      await EventService.updateEvent(widget.event.id, {
        'title': titleController.text.trim(),
        'description': descriptionController.text.trim(),
        'venue': venueController.text.trim(),
        'date': eventDateTime,
        'category': selectedCategory,
        'image_url': imageUrl,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Row(children: [Icon(Icons.check_circle, color: Colors.white), SizedBox(width: 8), Text('Event updated!')]),
          backgroundColor: Colors.green,
        ));
        Navigator.pop(context, true); // Return true to indicate update
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.dangerColor));
    }
    if (mounted) setState(() { loading = false; });
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(context: context, initialDate: selectedDate, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)));
    if (picked != null) setState(() => selectedDate = picked);
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(context: context, initialTime: selectedTime);
    if (picked != null) setState(() => selectedTime = picked);
  }

  String _formatDate(DateTime d) => '${['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'][d.month-1]} ${d.day}, ${d.year}';
  String _formatTime(TimeOfDay t) => '${t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod}:${t.minute.toString().padLeft(2,'0')} ${t.period == DayPeriod.am ? 'AM' : 'PM'}';

  Color _catColor(String c) {
    switch (c.toLowerCase()) {
      case 'tech': return AppColors.categoryTech;
      case 'sports': return AppColors.categorySports;
      case 'cultural': return AppColors.categoryCultural;
      case 'academic': return AppColors.categoryAcademic;
      case 'music': return AppColors.categoryMusic;
      default: return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0B14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1B2E),
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(context)),
        title: const Text('Edit Event', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          if (!loading)
            TextButton(
              onPressed: _updateEvent,
              child: const Text('Save', style: TextStyle(color: Color(0xFF9D4EDD), fontWeight: FontWeight.bold, fontSize: 16)),
            ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF9D4EDD)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image Picker
                    _imagePicker(isDark),
                    const SizedBox(height: 24),

                    // Title
                    _buildLabel('Event Title', isDark),
                    const SizedBox(height: 8),
                    _buildTextField(titleController, 'Enter event title', Icons.event, isDark, validator: (v) => v!.isEmpty ? 'Title required' : null),
                    const SizedBox(height: 20),

                    // Description
                    _buildLabel('Description', isDark),
                    const SizedBox(height: 8),
                    _buildTextField(descriptionController, 'Describe your event...', Icons.description, isDark, maxLines: 4, validator: (v) => v!.isEmpty ? 'Description required' : null),
                    const SizedBox(height: 20),

                    // Venue
                    _buildLabel('Venue', isDark),
                    const SizedBox(height: 8),
                    _buildTextField(venueController, 'Event location', Icons.location_on, isDark, validator: (v) => v!.isEmpty ? 'Venue required' : null),
                    const SizedBox(height: 20),

                    // Date & Time
                    Row(
                      children: [
                        Expanded(child: _buildDateTimeCard('Date', _formatDate(selectedDate), Icons.calendar_today, _selectDate, isDark)),
                        const SizedBox(width: 12),
                        Expanded(child: _buildDateTimeCard('Time', _formatTime(selectedTime), Icons.access_time, _selectTime, isDark)),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Category
                    _buildLabel('Category', isDark),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: categories.map((cat) => _buildCategoryChip(cat, isDark)).toList(),
                    ),
                    const SizedBox(height: 32),

                    // Update Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)]),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: ElevatedButton(
                          onPressed: _updateEvent,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: const Text('Update Event', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _imagePicker(bool isDark) {
    final hasImage = _imageBytes != null || _existingImageUrl != null;

    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFF1E1B2E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: hasImage ? const Color(0xFF9D4EDD) : const Color(0xFF3D3557), width: hasImage ? 3 : 2),
        ),
        child: hasImage
            ? ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Stack(fit: StackFit.expand, children: [
                  Container(
                    color: const Color(0xFF1E1B2E),
                    child: _imageBytes != null
                        ? Image.memory(_imageBytes!, fit: BoxFit.contain)
                        : Image.network(_existingImageUrl!, fit: BoxFit.contain, errorBuilder: (_, __, ___) => _buildPlaceholder(isDark)),
                  ),
                  Positioned(top: 8, right: 8, child: GestureDetector(onTap: _removeImage, child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.red.shade600, shape: BoxShape.circle), child: const Icon(Icons.close, color: Colors.white, size: 18)))),
                  Positioned(bottom: 8, left: 8, child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20)), child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.edit, color: Colors.greenAccent, size: 16), SizedBox(width: 4), Text('Tap to change', style: TextStyle(color: Colors.white, fontSize: 12))]))),
                ]),
              )
            : _buildPlaceholder(isDark),
      ),
    );
  }

  Widget _buildPlaceholder(bool isDark) {
    return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: const Color(0xFF9D4EDD).withOpacity(0.1), shape: BoxShape.circle), child: const Icon(Icons.add_photo_alternate_outlined, size: 40, color: Color(0xFF9D4EDD))),
      const SizedBox(height: 16),
      const Text('Add Event Poster', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
      const SizedBox(height: 4),
      const Text('Tap to select an image', style: TextStyle(color: Color(0xFFB8A9C9), fontSize: 13)),
    ]);
  }

  Widget _buildLabel(String text, bool isDark) {
    return Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFFB8A9C9)));
  }

  Widget _buildTextField(TextEditingController controller, String hint, IconData icon, bool isDark, {int maxLines = 1, String? Function(String?)? validator}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFFB8A9C9)),
        prefixIcon: Icon(icon, color: const Color(0xFFB8A9C9)),
        filled: true,
        fillColor: const Color(0xFF1E1B2E),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF3D3557))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF3D3557))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF9D4EDD), width: 2)),
      ),
    );
  }

  Widget _buildDateTimeCard(String label, String value, IconData icon, VoidCallback onTap, bool isDark) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1B2E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF3D3557)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFFB8A9C9))),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(icon, size: 20, color: const Color(0xFF9D4EDD)),
                const SizedBox(width: 8),
                Expanded(child: Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String category, bool isDark) {
    final isSelected = selectedCategory == category;
    final color = _catColor(category);

    return GestureDetector(
      onTap: () => setState(() => selectedCategory = category),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? color : const Color(0xFF1E1B2E),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? color : const Color(0xFF3D3557), width: isSelected ? 2 : 1),
        ),
        child: Text(category, style: TextStyle(color: isSelected ? Colors.white : Colors.white, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      ),
    );
  }
}
