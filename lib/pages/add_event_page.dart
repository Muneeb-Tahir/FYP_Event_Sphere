// lib/pages/add_event_page.dart
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../models/event.dart';
import '../models/user.dart';
import '../services/event_service.dart';
import '../services/storage_service.dart';
import '../services/society_service.dart';
import '../providers/auth_provider.dart';
import '../constants/app_theme.dart';
import '../utils/sanitizer.dart';

class AddEventPage extends ConsumerStatefulWidget {
  final String? preSeletedSocietyId;
  final String? preSeletedSocietyName;

  const AddEventPage({super.key, this.preSeletedSocietyId, this.preSeletedSocietyName});

  @override
  ConsumerState<AddEventPage> createState() => _AddEventPageState();
}

class _AddEventPageState extends ConsumerState<AddEventPage> {
  final _formKey = GlobalKey<FormState>();
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final venueController = TextEditingController();
  final capacityController = TextEditingController();

  DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay selectedTime = const TimeOfDay(hour: 10, minute: 0);
  String selectedCategory = 'Tech';
  bool loading = false;
  bool unlimitedCapacity = true;
  bool _isFeatured = false; // Admin-only: mark event as featured

  XFile? _selectedImage;
  Uint8List? _imageBytes;

  // Society selection
  List<Society> _availableSocieties = [];
  String? _selectedSocietyId;
  bool _loadingSocieties = true;
  bool _canSelectAnySociety = false; // Only true for admin/super_admin

  final categories = [
    'Tech',
    'Sports',
    'Cultural',
    'Academic',
    'Music',
    'Literary & Debating',
    'Drama & Performing Arts',
    'Art & Design',
    'Community Service',
    'Entrepreneurship',
    'Science & Innovation',
    'Gaming & Esports',
    'Environmental',
  ];

  @override
  void initState() {
    super.initState();
    _loadSocietiesBasedOnRole();
  }

  Future<void> _loadSocietiesBasedOnRole() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    setState(() => _loadingSocieties = true);

    try {
      // Super Admin or Admin can create events for ANY society
      if (user.role == UserRole.superAdmin || user.role == UserRole.admin) {
        _canSelectAnySociety = true;
        final societies = await SocietyService.getAllSocieties();
        setState(() {
          _availableSocieties = societies;
          // If preselected, use that; otherwise use first society
          _selectedSocietyId = widget.preSeletedSocietyId ?? (societies.isNotEmpty ? societies.first.id : null);
          _loadingSocieties = false;
        });
      }
      // President can ONLY create for their own society
      else if (user.role == UserRole.president || user.role == UserRole.vicePresident) {
        _canSelectAnySociety = false;
        // Get societies they are president of
        final presidentSocieties = await SocietyService.getSocietiesByPresident(user.id);
        setState(() {
          _availableSocieties = presidentSocieties;
          // Lock to preselected or their first society
          _selectedSocietyId = widget.preSeletedSocietyId ?? (presidentSocieties.isNotEmpty ? presidentSocieties.first.id : null);
          _loadingSocieties = false;
        });
      }
      // Students shouldn't be here, but handle gracefully
      else {
        setState(() => _loadingSocieties = false);
      }
    } catch (e) {
      setState(() => _loadingSocieties = false);
    }
  }

  // Generate UUID without external package
  String _generateUuid() {
    final random = Random();
    const hexDigits = '0123456789abcdef';
    final uuid = StringBuffer();
    for (int i = 0; i < 32; i++) {
      if (i == 8 || i == 12 || i == 16 || i == 20) uuid.write('-');
      uuid.write(hexDigits[random.nextInt(16)]);
    }
    return uuid.toString();
  }

  Future<void> _pickImage() async {
    try {
      final image = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 80, maxWidth: 1200, maxHeight: 800);
      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() { _selectedImage = image; _imageBytes = bytes; });
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.dangerColor));
    }
  }

  void _removeImage() => setState(() { _selectedImage = null; _imageBytes = null; });

  void _addEvent() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { loading = true; });

    try {
      final user = ref.read(currentUserProvider);
      if (user == null) throw Exception('User not authenticated');

      final eventDateTime = DateTime(selectedDate.year, selectedDate.month, selectedDate.day, selectedTime.hour, selectedTime.minute);
      final eventId = _generateUuid();

      String? imageUrl;
      if (_selectedImage != null && _imageBytes != null) {
        imageUrl = await StorageService.uploadEventImageBytes(_imageBytes!, eventId, _selectedImage!.name.split('.').last);
      }

      // Sanitize user inputs to prevent XSS/injection
      final sanitizedTitle = Sanitizer.sanitizePlainText(titleController.text.trim());
      final sanitizedDesc = Sanitizer.sanitize(descriptionController.text.trim());
      final sanitizedVenue = Sanitizer.sanitizePlainText(venueController.text.trim());

      await EventService.createEvent(Event(
        id: eventId,
        title: sanitizedTitle,
        description: sanitizedDesc,
        venue: sanitizedVenue,
        date: eventDateTime,
        societyId: _selectedSocietyId ?? 'general',
        createdBy: user.id,
        approvalStatus: 'pending',
        category: selectedCategory,
        imageUrl: imageUrl,
        maxAttendees: unlimitedCapacity ? null : int.tryParse(capacityController.text),
        isFeatured: _isFeatured,
      ));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Row(children: [Icon(Icons.check_circle, color: Colors.white), SizedBox(width: 8), Text('Event submitted for approval!')]), backgroundColor: Colors.green));
        Navigator.pop(context, true);
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
      case 'literary & debating': return const Color(0xFF8B5CF6);
      case 'drama & performing arts': return const Color(0xFFEC4899);
      case 'art & design': return const Color(0xFFF43F5E);
      case 'community service': return const Color(0xFF22C55E);
      case 'entrepreneurship': return const Color(0xFFF59E0B);
      case 'science & innovation': return const Color(0xFF0EA5E9);
      case 'gaming & esports': return const Color(0xFF6366F1);
      case 'environmental': return const Color(0xFF10B981);
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
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white), onPressed: () => Navigator.pop(context)),
        title: const Text('Create Event', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _label('Event Poster', Icons.image, isDark),
              const SizedBox(height: 8),
              _imagePicker(isDark),
              const SizedBox(height: 24),

              // Society Selector
              _label('Society', Icons.groups, isDark),
              const SizedBox(height: 8),
              _buildSocietySelector(isDark),
              const SizedBox(height: 20),

              _label('Event Title', Icons.event, isDark),
              const SizedBox(height: 8),
              TextFormField(
                controller: titleController,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDec('Enter event title', Icons.title, isDark),
                validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 20),

              _label('Category', Icons.category, isDark),
              const SizedBox(height: 8),
              _categorySelector(isDark),
              const SizedBox(height: 20),

              _label('Description', Icons.description, isDark),
              const SizedBox(height: 8),
              TextFormField(
                controller: descriptionController,
                style: const TextStyle(color: Colors.white),
                maxLines: 4,
                decoration: _inputDec('Enter description', Icons.notes, isDark),
                validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 20),

              _label('Date & Time', Icons.calendar_today, isDark),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(child: _dateTimeCard(_formatDate(selectedDate), Icons.calendar_month, _selectDate, isDark)),
                const SizedBox(width: 12),
                Expanded(child: _dateTimeCard(_formatTime(selectedTime), Icons.access_time, _selectTime, isDark)),
              ]),
              const SizedBox(height: 20),

              _label('Venue', Icons.location_on, isDark),
              const SizedBox(height: 8),
              TextFormField(
                controller: venueController,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDec('Enter venue', Icons.place, isDark),
                validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 20),

              // Capacity Section
              _label('Capacity', Icons.people, isDark),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1B2E),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF3D3557).withOpacity(0.5)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Unlimited Capacity', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                        Switch(
                          value: unlimitedCapacity,
                          onChanged: (v) => setState(() => unlimitedCapacity = v),
                          activeColor: const Color(0xFF9D4EDD),
                        ),
                      ],
                    ),
                    if (!unlimitedCapacity) ...[
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: capacityController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white),
                        decoration: _inputDec('Max attendees (e.g., 50)', Icons.group, isDark),
                        validator: (v) {
                          if (unlimitedCapacity) return null;
                          if (v == null || v.trim().isEmpty) return 'Enter capacity';
                          final num = int.tryParse(v);
                          if (num == null || num < 1) return 'Enter valid number';
                          return null;
                        },
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Featured toggle (admin only)
              if (_canSelectAnySociety) ...[
                _label('Featured', Icons.star, isDark),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1B2E),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _isFeatured ? const Color(0xFFF59E0B).withOpacity(0.5) : const Color(0xFF3D3557).withOpacity(0.5)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.star_rounded, color: _isFeatured ? const Color(0xFFF59E0B) : const Color(0xFFB8A9C9), size: 22),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Mark as Featured', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                              Text(
                                _isFeatured ? 'Will appear in the Featured carousel' : 'Show in regular event listing',
                                style: const TextStyle(color: Color(0xFFB8A9C9), fontSize: 11),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Switch(
                        value: _isFeatured,
                        onChanged: (v) => setState(() => _isFeatured = v),
                        activeColor: const Color(0xFFF59E0B),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)]),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ElevatedButton(
                    onPressed: loading ? null : _addEvent,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: loading
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.send_rounded, color: Colors.white), SizedBox(width: 8), Text('Submit Event', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white))]),
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
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFF1E1B2E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _imageBytes != null ? const Color(0xFF9D4EDD) : const Color(0xFF3D3557), width: _imageBytes != null ? 3 : 2),
        ),
        child: _imageBytes != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Stack(fit: StackFit.expand, children: [
                  Container(
                    color: const Color(0xFF1E1B2E),
                    child: Image.memory(_imageBytes!, fit: BoxFit.contain),
                  ),
                  Positioned(top: 8, right: 8, child: GestureDetector(onTap: _removeImage, child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.red.shade600, shape: BoxShape.circle), child: const Icon(Icons.close, color: Colors.white, size: 18)))),
                  Positioned(bottom: 8, left: 8, child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20)), child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.check_circle, color: Colors.greenAccent, size: 16), SizedBox(width: 4), Text('Tap to change', style: TextStyle(color: Colors.white, fontSize: 12))]))),
                ]),
              )
            : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: const Color(0xFF9D4EDD).withOpacity(0.1), shape: BoxShape.circle), child: const Icon(Icons.add_photo_alternate_outlined, size: 40, color: Color(0xFF9D4EDD))),
                const SizedBox(height: 16),
                const Text('Add Event Poster', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                const Text('Tap to select an image', style: TextStyle(color: Color(0xFFB8A9C9), fontSize: 13)),
              ]),
      ),
    );
  }

  Widget _categorySelector(bool isDark) {
    return Wrap(spacing: 10, runSpacing: 10, children: categories.map((cat) {
      final sel = cat == selectedCategory;
      final color = _catColor(cat);
      return GestureDetector(
        onTap: () => setState(() => selectedCategory = cat),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(gradient: sel ? LinearGradient(colors: [color, color.withOpacity(0.8)]) : null, color: sel ? null : const Color(0xFF1E1B2E), borderRadius: BorderRadius.circular(25), border: Border.all(color: sel ? Colors.transparent : const Color(0xFF3D3557))),
          child: Text(cat, style: TextStyle(color: sel ? Colors.white : Colors.white, fontWeight: sel ? FontWeight.bold : FontWeight.normal)),
        ),
      );
    }).toList());
  }

  Widget _label(String text, IconData icon, bool isDark) => Row(children: [Icon(icon, size: 18, color: const Color(0xFF9D4EDD)), const SizedBox(width: 8), Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white))]);

  InputDecoration _inputDec(String hint, IconData icon, bool isDark) => InputDecoration(hintText: hint, hintStyle: const TextStyle(color: Color(0xFFB8A9C9)), prefixIcon: Icon(icon, color: const Color(0xFFB8A9C9)), filled: true, fillColor: const Color(0xFF1E1B2E), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF9D4EDD), width: 2)));

  Widget _dateTimeCard(String text, IconData icon, VoidCallback onTap, bool isDark) => GestureDetector(onTap: onTap, child: Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: const Color(0xFF1E1B2E), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF3D3557))), child: Row(children: [Icon(icon, color: const Color(0xFF9D4EDD), size: 20), const SizedBox(width: 8), Expanded(child: Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.white)))])));

  Widget _buildSocietySelector(bool isDark) {
    if (_loadingSocieties) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1B2E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF3D3557)),
        ),
        child: const Row(
          children: [
            SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF9D4EDD))),
            SizedBox(width: 12),
            Text('Loading societies...', style: TextStyle(color: Color(0xFFB8A9C9))),
          ],
        ),
      );
    }

    if (_availableSocieties.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1B2E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.withOpacity(0.5)),
        ),
        child: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 20),
            SizedBox(width: 12),
            Expanded(child: Text('No societies available. You need to be assigned to a society.', style: TextStyle(color: Color(0xFFB8A9C9), fontSize: 13))),
          ],
        ),
      );
    }

    // Admins can select any society - show dropdown
    if (_canSelectAnySociety) {
      return DropdownButtonFormField<String>(
        value: _selectedSocietyId,
        dropdownColor: const Color(0xFF1E1B2E),
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.business, color: Color(0xFFB8A9C9)),
          filled: true,
          fillColor: const Color(0xFF1E1B2E),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF9D4EDD), width: 2)),
        ),
        items: _availableSocieties.map((society) => DropdownMenuItem(
          value: society.id,
          child: Text(society.name, style: const TextStyle(color: Colors.white)),
        )).toList(),
        onChanged: (value) => setState(() => _selectedSocietyId = value),
        validator: (v) => v == null ? 'Please select a society' : null,
      );
    }

    // Presidents see locked society (cannot change)
    final selectedSociety = _availableSocieties.firstWhere(
      (s) => s.id == _selectedSocietyId,
      orElse: () => _availableSocieties.first,
    );
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1B2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF9D4EDD).withOpacity(0.5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.lock_rounded, color: Color(0xFF9D4EDD), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(selectedSociety.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                const Text('You can only create events for your society', style: TextStyle(color: Color(0xFFB8A9C9), fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}