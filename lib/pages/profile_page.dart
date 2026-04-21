import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:async';
import '../services/auth_service.dart';
import '../services/user_stats_service.dart';
import '../services/settings_service.dart';
import '../services/bookmark_service.dart';
import '../services/avatar_service.dart';
import '../providers/auth_provider.dart';
import '../constants/app_theme.dart';
import '../widgets/animated_button.dart';
// Import refactored widgets
import 'profile/profile_widgets.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> with TickerProviderStateMixin {
  late TextEditingController nameController;
  late TextEditingController emailController;
  late TextEditingController bioController;
  late TextEditingController phoneController;
  bool isEditing = false;
  bool loading = false;
  Map<String, int>? _stats;
  bool _loadingStats = true;
  int _bookmarkCount = 0;
  StreamSubscription<List<String>>? _bookmarkSubscription;
  final _formKey = GlobalKey<FormState>();
  String? _nameError;
  String? _emailError;
  String? _phoneError;
  String? _selectedAvatarId;

  late AnimationController _entryController;
  late List<Animation<double>> _itemAnimations;

  @override
  void initState() {
    super.initState();
    // Initialize controllers with empty values - data will be populated in didChangeDependencies
    nameController = TextEditingController();
    emailController = TextEditingController();
    bioController = TextEditingController();
    phoneController = TextEditingController();
    _selectedAvatarId = null;


    _entryController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _itemAnimations = List.generate(6, (index) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _entryController,
          curve: Interval(
            index * 0.1,
            0.6 + index * 0.08,
            curve: Curves.easeOutCubic,
          ),
        ),
      );
    });

    _entryController.forward();
    _loadStats();
    _subscribeToBookmarks();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Update controllers when user data is available from Riverpod
    final user = ref.read(currentUserProvider);
    if (user != null && nameController.text.isEmpty) {
      nameController.text = user.name;
      emailController.text = user.email;
      bioController.text = user.bio ?? '';
      phoneController.text = user.phone ?? '';
      _selectedAvatarId = user.profileImageUrl;
    }
  }

  void _subscribeToBookmarks() {
    final user = ref.read(currentUserProvider);
    if (user != null) {
      _bookmarkSubscription = BookmarkService.getBookmarksStream(user.id).listen((ids) {
        if (mounted) {
          setState(() => _bookmarkCount = ids.length);
        }
      });
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    bioController.dispose();
    phoneController.dispose();
    _entryController.dispose();
    _bookmarkSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadStats() async {
    final user = ref.read(currentUserProvider);
    if (user != null) {
      final stats = await UserStatsService.getQuickStats(user.id);
      if (mounted) {
        setState(() {
          _stats = stats;
          _loadingStats = false;
        });
      }
    }
  }

  void _saveProfile() async {
    // Validate form first
    if (!_validateForm()) {
      return;
    }

    final user = ref.read(currentUserProvider);
    if (user == null) return;

    setState(() => loading = true);
    try {
      await AuthService.updateProfile(user.id, {
        'name': nameController.text.trim(),
        'email': emailController.text.trim(),
        'bio': bioController.text.trim(),
        'phone': phoneController.text.trim(),
        'profileImageUrl': _selectedAvatarId,
      });
      setState(() => isEditing = false);
      _showSnackBar('Profile updated successfully', AppColors.success);
    } catch (e) {
      _showSnackBar('Error: ${e.toString()}', AppColors.danger);
    }
    setState(() => loading = false);
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
      } else if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(nameController.text.trim())) {
        _nameError = 'Name can only contain letters';
        isValid = false;
      } else {
        _nameError = null;
      }

      // Validate Email
      if (emailController.text.trim().isEmpty) {
        _emailError = 'Email is required';
        isValid = false;
      } else if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(emailController.text.trim())) {
        _emailError = 'Please enter a valid email address';
        isValid = false;
      } else {
        _emailError = null;
      }

      // Validate Phone
      if (phoneController.text.trim().isEmpty) {
        _phoneError = 'Phone number is required';
        isValid = false;
      } else if (!RegExp(r'^[0-9+\-\s]+$').hasMatch(phoneController.text.trim())) {
        _phoneError = 'Phone can only contain numbers';
        isValid = false;
      } else if (phoneController.text.replaceAll(RegExp(r'[^0-9]'), '').length < 10) {
        _phoneError = 'Phone must be at least 10 digits';
        isValid = false;
      } else {
        _phoneError = null;
      }
    });

    return isValid;
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              color == AppColors.success
                  ? Icons.check_circle_rounded
                  : Icons.error_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(message),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // Build profile avatar widget
  Widget _buildProfileAvatar() {
    final user = ref.read(currentUserProvider);

    // Check if profileImageUrl is an actual URL (uploaded image)
    if (_selectedAvatarId != null && _selectedAvatarId!.startsWith('http')) {
      return Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFF9D4EDD), width: 3),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF9D4EDD).withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipOval(
          child: CachedNetworkImage(
            imageUrl: _selectedAvatarId!,
            width: 100,
            height: 100,
            fit: BoxFit.cover,
            placeholder: (context, url) => const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF9D4EDD),
                strokeWidth: 2,
              ),
            ),
            errorWidget: (context, url, error) => _buildDefaultAvatarFallback(user),
          ),
        ),
      );
    }

    // Legacy: Check if it's an avatar ID
    final avatar = AvatarService.getAvatarById(_selectedAvatarId);
    if (avatar != null) {
      return Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: avatar.gradient,
          boxShadow: [
            BoxShadow(
              color: avatar.gradientColors.first.withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Icon(
          avatar.icon,
          color: Colors.white,
          size: 50,
        ),
      );
    }

    // Default fallback - letter avatar
    return _buildDefaultAvatarFallback(user);
  }

  Widget _buildDefaultAvatarFallback(user) {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [const Color(0xFF8B5CF6).withOpacity(0.3), const Color(0xFFEC4899).withOpacity(0.3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: const Color(0xFF3D3557), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Center(
        child: Text(
          (user?.name ?? 'U')[0].toUpperCase(),
          style: const TextStyle(
            fontSize: 42,
            fontWeight: FontWeight.bold,
            color: Color(0xFF9D4EDD),
          ),
        ),
      ),
    );
  }

  // Show avatar picker dialog
  void _showAvatarPicker() async {
    // Navigate to edit profile page which now has image picker
    final result = await Navigator.pushNamed(context, '/edit-profile');

    if (result == true) {
      // Refresh profile data
      final user = ref.read(currentUserProvider);
      if (user != null) {
        setState(() {
          _selectedAvatarId = user.profileImageUrl;
          nameController.text = user.name ?? '';
          emailController.text = user.email ?? '';
          bioController.text = user.bio ?? '';
          phoneController.text = user.phone ?? '';
        });
        _loadStats();
      }
    }
  }

  void _logout() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
            ),
            onPressed: () async {
              await AuthService.signOut();
              Navigator.pushReplacementNamed(context, '/login');
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  String _formatJoinDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                   'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);

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
          'Settings',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Profile Card
            _buildAnimatedItem(0, _buildUserProfileCard(user)),
            const SizedBox(height: 24),

            // Stats Row
            _buildAnimatedItem(1, _buildStatsRow()),
            const SizedBox(height: 24),

            // Societies Section
            if (user != null && user.societyIds.isNotEmpty) ...[
              _buildAnimatedItem(2, _buildSocietiesSection(user.societyIds)),
              const SizedBox(height: 24),
            ],

            // Account Section
            _buildAnimatedItem(3, _buildSettingsGroup('Account', [
              _SettingsItem(Icons.person_outline, 'Edit Profile', () => _openEditProfile()),
              _SettingsItem(Icons.lock_outline, 'Change Password', () => Navigator.pushNamed(context, '/account-settings')),
              _SettingsItem(Icons.shield_outlined, 'Privacy', () => Navigator.pushNamed(context, '/privacy-settings')),
            ])),
            const SizedBox(height: 16),

            // Preferences Section
            _buildAnimatedItem(4, _buildSettingsGroup('Preferences', [
              _SettingsItem(Icons.notifications_outlined, 'Notifications', () => Navigator.pushNamed(context, '/notification-settings')),
              _SettingsItem(Icons.color_lens_outlined, 'Theme', () => Navigator.pushNamed(context, '/account-settings')),
            ])),
            const SizedBox(height: 16),

            // Account & Support Section
            _buildAnimatedItem(5, _buildSettingsGroup('Account & Support', [
              _SettingsItem(Icons.help_outline, 'Help & Support', () => Navigator.pushNamed(context, '/faq')),
              _SettingsItem(Icons.info_outline, 'About App', () => _showAboutDialog()),
            ])),
            const SizedBox(height: 24),

            // Logout Button
            SizedBox(
              width: double.infinity,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: TextButton.icon(
                  onPressed: _logout,
                  icon: const Icon(Icons.logout, color: Colors.red),
                  label: const Text('Logout', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
                  style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // User Profile Card - Display only
  Widget _buildUserProfileCard(user) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1B2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF3D3557).withOpacity(0.5)),
      ),
      child: Row(
        children: [
          // Avatar
          GestureDetector(
            onTap: _showAvatarPicker,
            child: _buildProfileAvatar(),
          ),
          const SizedBox(width: 16),
          // User info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user?.name ?? 'User',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user?.email ?? '',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFFB8A9C9),
                  ),
                ),
              ],
            ),
          ),
          // Edit button
          IconButton(
            onPressed: _openEditProfile,
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF9D4EDD).withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.edit_outlined, color: Color(0xFF9D4EDD), size: 20),
            ),
          ),
        ],
      ),
    );
  }

  // Settings Group with section title
  Widget _buildSettingsGroup(String title, List<_SettingsItem> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFFB8A9C9),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1E1B2E),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF3D3557).withOpacity(0.5)),
          ),
          child: Column(
            children: items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              return Column(
                children: [
                  ListTile(
                    leading: Icon(item.icon, color: const Color(0xFFB8A9C9)),
                    title: Text(item.label, style: const TextStyle(color: Colors.white)),
                    trailing: const Icon(Icons.chevron_right, color: Color(0xFFB8A9C9)),
                    onTap: item.onTap,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  ),
                  if (index < items.length - 1)
                    const Divider(height: 1, color: Color(0xFF3D3557), indent: 56),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  void _openEditProfile() {
    Navigator.pushNamed(context, '/edit-profile');
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1B2E),
        title: const Text('About Event Sphere', style: TextStyle(color: Colors.white)),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Version 1.0.0', style: TextStyle(color: Color(0xFFB8A9C9))),
            SizedBox(height: 8),
            Text('Event Sphere is your campus event management companion.', style: TextStyle(color: Color(0xFFB8A9C9))),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: Color(0xFF9D4EDD))),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedItem(int index, Widget child) {
    if (index >= _itemAnimations.length) return child;

    return AnimatedBuilder(
      animation: _itemAnimations[index],
      builder: (context, _) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - _itemAnimations[index].value)),
          child: Opacity(
            opacity: _itemAnimations[index].value,
            child: child,
          ),
        );
      },
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        _buildStatCard(
          'Events',
          _loadingStats ? '-' : '${_stats?['events'] ?? 0}',
          Icons.event_rounded,
          AppColors.primary,
          onTap: () => Navigator.pushNamed(context, '/registered-events'),
        ),
        const SizedBox(width: 12),
        _buildStatCard(
          'Bookmarks',
          '$_bookmarkCount',
          Icons.bookmark_rounded,
          AppColors.accent,
          onTap: () => Navigator.pushNamed(context, '/bookmarks'),
        ),
        const SizedBox(width: 12),
        _buildStatCard(
          'Attended',
          _loadingStats ? '-' : '${_stats?['attended'] ?? 0}',
          Icons.check_circle_rounded,
          AppColors.success,
          onTap: () => Navigator.pushNamed(context, '/attended-events'),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color, {VoidCallback? onTap}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1B2E),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF3D3557).withOpacity(0.5)),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(isDark ? 0.2 : 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(height: 12),
              _loadingStats && label != 'Bookmarks'
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      value,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      label,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFFB8A9C9),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Icon(Icons.arrow_forward_ios, size: 10, color: Color(0xFFB8A9C9)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileCard(user) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1B2E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF3D3557).withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Profile Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              if (!isEditing)
                GestureDetector(
                  onTap: () => setState(() => isEditing = true),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF9D4EDD).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.edit_rounded,
                      size: 18,
                      color: Color(0xFF9D4EDD),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          _buildFormField('Full Name', nameController, Icons.person_outline_rounded, errorText: _nameError),
          const SizedBox(height: 16),
          _buildFormField('Email', emailController, Icons.email_outlined, errorText: _emailError),
          const SizedBox(height: 16),
          _buildFormField('Phone', phoneController, Icons.phone_outlined, errorText: _phoneError),
          const SizedBox(height: 16),
          _buildFormField('Bio', bioController, Icons.info_outline, maxLines: 2),
          const SizedBox(height: 16),
          // Role (read-only)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF2D2645),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)]),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.badge_outlined, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Role', style: TextStyle(fontSize: 12, color: Color(0xFFB8A9C9))),
                    const SizedBox(height: 2),
                    Text(
                      user?.role.toString().split('.').last.toUpperCase() ?? 'USER',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Action buttons when editing
          if (isEditing) ...[
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF3D3557)),
                    ),
                    child: TextButton(
                      onPressed: () => setState(() => isEditing = false),
                      child: const Text('Cancel', style: TextStyle(color: Color(0xFFB8A9C9))),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)]),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ElevatedButton.icon(
                      onPressed: loading ? null : _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: loading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.check_rounded, color: Colors.white),
                      label: const Text('Save Changes', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFormField(
    String label,
    TextEditingController controller,
    IconData icon, {
    int maxLines = 1,
    String? errorText,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasError = errorText != null && errorText.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: hasError
                ? AppColors.danger
                : const Color(0xFFB8A9C9),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          enabled: isEditing,
          maxLines: maxLines,
          style: const TextStyle(fontSize: 15, color: Colors.white),
          decoration: InputDecoration(
            prefixIcon: Icon(
              icon,
              color: hasError
                  ? AppColors.danger
                  : (isEditing ? const Color(0xFF9D4EDD) : const Color(0xFFB8A9C9)),
              size: 20,
            ),
            filled: true,
            fillColor: hasError
                ? AppColors.danger.withOpacity(0.05)
                : (isEditing ? const Color(0xFF1E1B2E) : const Color(0xFF2D2645)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: hasError
                  ? AppColors.danger
                  : (isEditing ? const Color(0xFF9D4EDD) : const Color(0xFF3D3557))),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: hasError ? AppColors.danger : const Color(0xFF9D4EDD),
                width: 1.5,
              ),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF3D3557)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: hasError ? AppColors.danger : const Color(0xFF9D4EDD),
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            errorText: hasError ? errorText : null,
            errorStyle: const TextStyle(
              color: AppColors.danger,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSocietiesSection(List<String> societyIds) {
    // Mock society names - in production, fetch from a service
    final societyNames = {
      'soc1': 'Tech Society',
      'soc2': 'Sports Club',
      'soc3': 'Cultural Society',
    };

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1B2E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF3D3557).withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'My Societies',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: societyIds.map((id) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [const Color(0xFF8B5CF6).withOpacity(0.2), const Color(0xFFEC4899).withOpacity(0.2)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF8B5CF6).withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.groups, size: 16, color: Color(0xFF9D4EDD)),
                    const SizedBox(width: 6),
                    Text(
                      societyNames[id] ?? id,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1B2E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF3D3557).withOpacity(0.5)),
      ),
      child: Column(
        children: [
          _buildSettingsTile(
            'Account Settings',
            'Theme, password, delete account',
            Icons.settings_outlined,
            () => Navigator.pushNamed(context, '/account-settings'),
          ),
          const Divider(height: 1, color: Color(0xFF3D3557)),
          _buildSettingsTile(
            'Notifications',
            'Manage your notification preferences',
            Icons.notifications_outlined,
            () => Navigator.pushNamed(context, '/notification-settings'),
          ),
          const Divider(height: 1, color: Color(0xFF3D3557)),
          _buildSettingsTile(
            'Privacy',
            'Control your privacy settings',
            Icons.lock_outline_rounded,
            () => Navigator.pushNamed(context, '/privacy-settings'),
          ),
          const Divider(height: 1, color: Color(0xFF3D3557)),
          _buildSettingsTile(
            'Help & Support',
            'Get help or contact us',
            Icons.help_outline_rounded,
            () => Navigator.pushNamed(context, '/faq'),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
    // Now using refactored ProfileSettingsTile widget
    return ProfileSettingsTile(
      title: title,
      subtitle: subtitle,
      icon: icon,
      onTap: onTap,
      showDivider: false,
    );
  }
}

// Helper class for settings items
class _SettingsItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  _SettingsItem(this.icon, this.label, this.onTap);
}
