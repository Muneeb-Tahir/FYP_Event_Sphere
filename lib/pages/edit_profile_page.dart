// lib/pages/edit_profile_page.dart
// Edit Profile Page - Form for editing user profile with Image Upload

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../services/logging_service.dart';
import '../providers/auth_provider.dart';
import '../constants/app_theme.dart';
import '../utils/sanitizer.dart';

class EditProfilePage extends ConsumerStatefulWidget {
  const EditProfilePage({super.key});

  @override
  ConsumerState<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends ConsumerState<EditProfilePage> {
  late TextEditingController nameController;
  late TextEditingController emailController;
  late TextEditingController bioController;
  late TextEditingController phoneController;
  bool loading = false;
  bool _uploadingImage = false;
  double _uploadProgress = 0.0;

  // Profile image - either URL string or local bytes for preview
  String? _profileImageUrl;
  XFile? _selectedImageFile;
  Uint8List? _selectedImageBytes;

  String? _nameError;
  String? _emailError;
  String? _phoneError;

  @override
  void initState() {
    super.initState();
    final user = ref.read(currentUserProvider);
    nameController = TextEditingController(text: user?.name ?? '');
    emailController = TextEditingController(text: user?.email ?? '');
    bioController = TextEditingController(text: user?.bio ?? '');
    phoneController = TextEditingController(text: user?.phone ?? '');
    _profileImageUrl = user?.profileImageUrl;
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    bioController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  bool _validateForm() {
    bool isValid = true;
    setState(() {
      // Validate Full Name
      if (nameController.text.trim().isEmpty) {
        _nameError = 'Full name is required';
        isValid = false;
      } else if (nameController.text.trim().length < 2) {
        _nameError = 'Name must be at least 2 characters';
        isValid = false;
      } else {
        _nameError = null;
      }

      // Validate Email (basic check)
      if (emailController.text.trim().isEmpty) {
        _emailError = 'Email is required';
        isValid = false;
      } else if (!emailController.text.contains('@')) {
        _emailError = 'Invalid email format';
        isValid = false;
      } else {
        _emailError = null;
      }

      // Validate Phone (optional)
      if (phoneController.text.trim().isNotEmpty && phoneController.text.trim().length < 10) {
        _phoneError = 'Phone must be at least 10 digits';
        isValid = false;
      } else {
        _phoneError = null;
      }
    });
    return isValid;
  }

  void _saveProfile() async {
    if (!_validateForm()) return;

    final user = ref.read(currentUserProvider);
    if (user == null) return;

    setState(() => loading = true);

    try {
      String? finalImageUrl = _profileImageUrl;

      // Upload new image if selected
      if (_selectedImageFile != null) {
        setState(() {
          _uploadingImage = true;
          _uploadProgress = 0.3;
        });

        final uploadedUrl = await StorageService.uploadProfileImage(_selectedImageFile!, user.id);

        setState(() => _uploadProgress = 0.8);

        if (uploadedUrl != null) {
          finalImageUrl = uploadedUrl;
        } else {
          throw Exception('Failed to upload image');
        }

        setState(() {
          _uploadingImage = false;
          _uploadProgress = 1.0;
        });
      }

      // Sanitize user inputs before saving
      final sanitizedName = Sanitizer.sanitizePlainText(nameController.text.trim());
      final sanitizedBio = Sanitizer.sanitize(bioController.text.trim());
      final sanitizedPhone = Sanitizer.sanitizePhone(phoneController.text.trim());

      await AuthService.updateProfile(user.id, {
        'name': sanitizedName,
        'email': emailController.text.trim(),
        'bio': sanitizedBio,
        'phone': sanitizedPhone,
        'profileImageUrl': finalImageUrl,
      });

      // Refresh Riverpod auth state so all pages get the updated user data immediately
      await ref.read(authProvider.notifier).refreshUser();

      // Evict old cached image so the new profile image displays without relaunch
      if (_profileImageUrl != null && _profileImageUrl != finalImageUrl) {
        try {
          await CachedNetworkImage.evictFromCache(_profileImageUrl!);
        } catch (_) {
          // Eviction is best-effort
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully'), backgroundColor: Colors.green),
        );
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      LoggingService.error('Edit profile save failed', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    }
    if (mounted) {
      setState(() {
        loading = false;
        _uploadingImage = false;
      });
    }
  }

  void _showImageSourcePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1B2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Change Profile Picture', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 8),
            const Text('Choose an option', style: TextStyle(color: Color(0xFFB8A9C9), fontSize: 14)),
            const SizedBox(height: 24),

            // Gallery option
            _buildPickerOption(
              icon: Icons.photo_library_rounded,
              label: 'Choose from Gallery',
              description: 'Select an existing photo',
              gradientColors: [const Color(0xFF8B5CF6), const Color(0xFFEC4899)],
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            const SizedBox(height: 12),

            // Camera option
            _buildPickerOption(
              icon: Icons.camera_alt_rounded,
              label: 'Take a Photo',
              description: 'Use your camera',
              gradientColors: [const Color(0xFF06B6D4), const Color(0xFF3B82F6)],
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),

            // Remove photo option (if image exists)
            if (_profileImageUrl != null || _selectedImageBytes != null) ...[
              const SizedBox(height: 12),
              _buildPickerOption(
                icon: Icons.delete_rounded,
                label: 'Remove Photo',
                description: 'Use default avatar',
                gradientColors: [const Color(0xFFEF4444), const Color(0xFFF97316)],
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _profileImageUrl = null;
                    _selectedImageFile = null;
                    _selectedImageBytes = null;
                  });
                },
              ),
            ],
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildPickerOption({
    required IconData icon,
    required String label,
    required String description,
    required List<Color> gradientColors,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF2A2640),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF3D3557)),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: gradientColors),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(description, style: const TextStyle(color: Color(0xFFB8A9C9), fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFFB8A9C9)),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final image = await StorageService.pickImage(source: source, imageQuality: 85);
      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _selectedImageFile = image;
          _selectedImageBytes = bytes;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Image selected! Save to upload.'), backgroundColor: Color(0xFF9D4EDD)),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _buildProfileImage() {
    // Show preview of selected image
    if (_selectedImageBytes != null) {
      return Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFF9D4EDD), width: 3),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF9D4EDD).withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipOval(
          child: Image.memory(
            _selectedImageBytes!,
            width: 120,
            height: 120,
            fit: BoxFit.cover,
          ),
        ),
      );
    }

    // Show existing profile image from URL
    if (_profileImageUrl != null && _profileImageUrl!.isNotEmpty && _profileImageUrl!.startsWith('http')) {
      return Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFF3D3557), width: 3),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipOval(
          child: CachedNetworkImage(
            imageUrl: _profileImageUrl!,
            width: 120,
            height: 120,
            fit: BoxFit.cover,
            placeholder: (context, url) => const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF9D4EDD),
                strokeWidth: 2,
              ),
            ),
            errorWidget: (context, url, error) => _buildDefaultAvatar(),
          ),
        ),
      );
    }

    // Show default avatar
    return _buildDefaultAvatar();
  }

  Widget _buildDefaultAvatar() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [const Color(0xFF8B5CF6).withOpacity(0.3), const Color(0xFFEC4899).withOpacity(0.3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: const Color(0xFF3D3557), width: 3),
      ),
      child: const Icon(Icons.person, size: 60, color: Color(0xFF9D4EDD)),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    int maxLines = 1,
    String? errorText,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFFB8A9C9))),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          style: const TextStyle(color: Colors.white, fontSize: 16),
          cursorColor: const Color(0xFF9D4EDD),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: const Color(0xFF9D4EDD), size: 20),
            filled: true,
            fillColor: const Color(0xFF1E1B2E),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: errorText != null ? Colors.red : const Color(0xFF3D3557),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: errorText != null ? Colors.red : const Color(0xFF3D3557),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF9D4EDD), width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            hintText: 'Enter $label',
            hintStyle: const TextStyle(color: Color(0xFF6B6180), fontSize: 15),
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 4),
          Text(errorText, style: const TextStyle(color: Colors.red, fontSize: 12)),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0B14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0B14),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text(
          'Edit Profile',
          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600),
        ),
        actions: [
          TextButton(
            onPressed: loading ? null : _saveProfile,
            child: loading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF9D4EDD)))
                : const Text('Save', style: TextStyle(color: Color(0xFF9D4EDD), fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Profile Image with Upload indicator
            GestureDetector(
              onTap: _showImageSourcePicker,
              child: Stack(
                children: [
                  _buildProfileImage(),

                  // Upload progress overlay
                  if (_uploadingImage)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black.withOpacity(0.6),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(
                              value: _uploadProgress,
                              color: const Color(0xFF9D4EDD),
                              strokeWidth: 3,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${(_uploadProgress * 100).toInt()}%',
                              style: const TextStyle(color: Colors.white, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Camera button
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)]),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF0D0B14), width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF9D4EDD).withOpacity(0.4),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.camera_alt, size: 18, color: Colors.white),
                    ),
                  ),

                  // New badge if image selected
                  if (_selectedImageBytes != null)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF22C55E),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text('NEW', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _selectedImageBytes != null ? 'Tap to change • Save to upload' : 'Tap to change photo',
              style: const TextStyle(color: Color(0xFFB8A9C9), fontSize: 12),
            ),
            const SizedBox(height: 32),

            // Form fields
            _buildTextField(label: 'Full Name', controller: nameController, icon: Icons.person_outline, errorText: _nameError),
            const SizedBox(height: 20),
            _buildTextField(label: 'Email', controller: emailController, icon: Icons.email_outlined, keyboardType: TextInputType.emailAddress, errorText: _emailError),
            const SizedBox(height: 20),
            _buildTextField(label: 'Phone', controller: phoneController, icon: Icons.phone_outlined, keyboardType: TextInputType.phone, errorText: _phoneError),
            const SizedBox(height: 20),
            _buildTextField(label: 'Bio', controller: bioController, icon: Icons.info_outline, maxLines: 3),
            const SizedBox(height: 40),

            // Save button (also at bottom)
            Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)]),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF9D4EDD).withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: loading ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: loading
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                          SizedBox(width: 12),
                          Text('Saving...', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                        ],
                      )
                    : const Text('Save Changes', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
