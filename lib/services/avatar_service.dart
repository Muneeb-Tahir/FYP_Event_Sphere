// lib/services/avatar_service.dart
// Custom Avatar Service - 10 predefined avatars (5 male, 5 female)

import 'package:flutter/material.dart';

class AvatarService {
  // Avatar definitions with gradient colors and icons
  static const List<AvatarData> maleAvatars = [
    AvatarData(
      id: 'male_1',
      name: 'Alex',
      icon: Icons.face,
      gradientColors: [Color(0xFF667eea), Color(0xFF764ba2)],
      gender: 'male',
    ),
    AvatarData(
      id: 'male_2',
      name: 'Max',
      icon: Icons.sentiment_very_satisfied,
      gradientColors: [Color(0xFF11998e), Color(0xFF38ef7d)],
      gender: 'male',
    ),
    AvatarData(
      id: 'male_3',
      name: 'Leo',
      icon: Icons.mood,
      gradientColors: [Color(0xFFf093fb), Color(0xFFf5576c)],
      gender: 'male',
    ),
    AvatarData(
      id: 'male_4',
      name: 'Sam',
      icon: Icons.emoji_emotions,
      gradientColors: [Color(0xFF4facfe), Color(0xFF00f2fe)],
      gender: 'male',
    ),
    AvatarData(
      id: 'male_5',
      name: 'Jake',
      icon: Icons.tag_faces,
      gradientColors: [Color(0xFFfa709a), Color(0xFFfee140)],
      gender: 'male',
    ),
  ];

  static const List<AvatarData> femaleAvatars = [
    AvatarData(
      id: 'female_1',
      name: 'Emma',
      icon: Icons.face_3,
      gradientColors: [Color(0xFFa18cd1), Color(0xFFfbc2eb)],
      gender: 'female',
    ),
    AvatarData(
      id: 'female_2',
      name: 'Sophia',
      icon: Icons.face_4,
      gradientColors: [Color(0xFFff9a9e), Color(0xFFfad0c4)],
      gender: 'female',
    ),
    AvatarData(
      id: 'female_3',
      name: 'Mia',
      icon: Icons.face_5,
      gradientColors: [Color(0xFFffecd2), Color(0xFFfcb69f)],
      gender: 'female',
    ),
    AvatarData(
      id: 'female_4',
      name: 'Lily',
      icon: Icons.face_6,
      gradientColors: [Color(0xFF89f7fe), Color(0xFF66a6ff)],
      gender: 'female',
    ),
    AvatarData(
      id: 'female_5',
      name: 'Zoe',
      icon: Icons.sentiment_satisfied_alt,
      gradientColors: [Color(0xFFfddb92), Color(0xFFd1fdff)],
      gender: 'female',
    ),
  ];

  static List<AvatarData> get allAvatars => [...maleAvatars, ...femaleAvatars];

  static AvatarData? getAvatarById(String? id) {
    if (id == null) return null;
    try {
      return allAvatars.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }

  static AvatarData getDefaultAvatar() => maleAvatars.first;
}

class AvatarData {
  final String id;
  final String name;
  final IconData icon;
  final List<Color> gradientColors;
  final String gender;

  const AvatarData({
    required this.id,
    required this.name,
    required this.icon,
    required this.gradientColors,
    required this.gender,
  });

  LinearGradient get gradient => LinearGradient(
    colors: gradientColors,
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

// Widget to display avatar
class AvatarWidget extends StatelessWidget {
  final AvatarData avatar;
  final double size;
  final bool isSelected;
  final VoidCallback? onTap;

  const AvatarWidget({
    super.key,
    required this.avatar,
    this.size = 60,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: avatar.gradient,
          border: isSelected
              ? Border.all(color: Colors.white, width: 3)
              : null,
          boxShadow: [
            BoxShadow(
              color: avatar.gradientColors.first.withOpacity(0.4),
              blurRadius: isSelected ? 12 : 6,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(
          avatar.icon,
          color: Colors.white,
          size: size * 0.5,
        ),
      ),
    );
  }
}

// Avatar selection dialog
class AvatarPickerDialog extends StatefulWidget {
  final String? currentAvatarId;

  const AvatarPickerDialog({super.key, this.currentAvatarId});

  @override
  State<AvatarPickerDialog> createState() => _AvatarPickerDialogState();
}

class _AvatarPickerDialogState extends State<AvatarPickerDialog> {
  String? selectedAvatarId;
  String selectedGender = 'male';

  @override
  void initState() {
    super.initState();
    selectedAvatarId = widget.currentAvatarId;
    if (selectedAvatarId != null && selectedAvatarId!.startsWith('female')) {
      selectedGender = 'female';
    }
  }

  @override
  Widget build(BuildContext context) {
    final avatars = selectedGender == 'male'
        ? AvatarService.maleAvatars
        : AvatarService.femaleAvatars;

    return AlertDialog(
      title: const Text('Choose Your Avatar'),
      content: SizedBox(
        width: 300,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Gender toggle
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => selectedGender = 'male'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: selectedGender == 'male'
                            ? const Color(0xFF667eea)
                            : Colors.grey[200],
                        borderRadius: const BorderRadius.horizontal(left: Radius.circular(25)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.male,
                            color: selectedGender == 'male' ? Colors.white : Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Male',
                            style: TextStyle(
                              color: selectedGender == 'male' ? Colors.white : Colors.grey[600],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => selectedGender = 'female'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: selectedGender == 'female'
                            ? const Color(0xFFa18cd1)
                            : Colors.grey[200],
                        borderRadius: const BorderRadius.horizontal(right: Radius.circular(25)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.female,
                            color: selectedGender == 'female' ? Colors.white : Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Female',
                            style: TextStyle(
                              color: selectedGender == 'female' ? Colors.white : Colors.grey[600],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Avatar grid
            Wrap(
              spacing: 16,
              runSpacing: 16,
              alignment: WrapAlignment.center,
              children: avatars.map((avatar) => Column(
                children: [
                  AvatarWidget(
                    avatar: avatar,
                    size: 70,
                    isSelected: selectedAvatarId == avatar.id,
                    onTap: () => setState(() => selectedAvatarId = avatar.id),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    avatar.name,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: selectedAvatarId == avatar.id
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: selectedAvatarId == avatar.id
                          ? avatar.gradientColors.first
                          : Colors.grey[600],
                    ),
                  ),
                ],
              )).toList(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: selectedAvatarId != null
              ? () => Navigator.pop(context, selectedAvatarId)
              : null,
          child: const Text('Select'),
        ),
      ],
    );
  }
}
