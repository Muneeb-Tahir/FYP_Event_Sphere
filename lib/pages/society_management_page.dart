// lib/pages/society_management_page.dart
// Admin Society Management - Create/Edit/Delete societies, Assign Presidents

import 'package:flutter/material.dart';
import '../services/society_service.dart';
import '../services/user_service.dart';
import '../constants/app_theme.dart';
import 'society_detail_page.dart';

class SocietyManagementPage extends StatefulWidget {
  const SocietyManagementPage({super.key});

  @override
  State<SocietyManagementPage> createState() => _SocietyManagementPageState();
}

class _SocietyManagementPageState extends State<SocietyManagementPage> {
  List<Society> _societies = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSocieties();
  }

  Future<void> _loadSocieties() async {
    setState(() => _loading = true);
    try {
      final societies = await SocietyService.getAllSocieties();
      setState(() { _societies = societies; _loading = false; });
    } catch (e) {
      setState(() => _loading = false);
      _showError('Failed to load societies: $e');
    }
  }

  void _showError(String msg) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  void _showSuccess(String msg) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.green));
  }

  Future<void> _createSociety() async {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    String? selectedCategory;

    final categories = [
      'COMSATS Skill Development Society (CSDS)',
      'COMSATS Health Awareness & Blood Donor Society (CHA&BDS)',
      'COMSATS Literary Society (CLS)',
      'COMSATS Dramatic Society (CDS)',
      'COMSATS Music Club (CMC)',
      'COMSATS Adventure and Rovering Club (CARC)',
      'COMSATS Fine Arts\' Society (CFAS)',
      'COMSATS E-Sports Society',
      'Sports',
      'Tech',
      'Cultural',
      'Community Service',
    ];

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1E1B2E),
          title: const Text('Create Society', style: TextStyle(color: Colors.white)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Society Name',
                    labelStyle: const TextStyle(color: Color(0xFFB8A9C9)),
                    filled: true,
                    fillColor: const Color(0xFF2D2645),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF9D4EDD), width: 2)),
                  ),
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  dropdownColor: const Color(0xFF2D2645),
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: 'Category',
                    labelStyle: const TextStyle(color: Color(0xFFB8A9C9)),
                    filled: true,
                    fillColor: const Color(0xFF2D2645),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF9D4EDD), width: 2)),
                  ),
                  style: const TextStyle(color: Colors.white),
                  hint: const Text('Select Category', style: TextStyle(color: Color(0xFFB8A9C9))),
                  items: categories.map((cat) => DropdownMenuItem(
                    value: cat,
                    child: Text(cat, style: const TextStyle(color: Colors.white), overflow: TextOverflow.ellipsis),
                  )).toList(),
                  onChanged: (value) => setDialogState(() => selectedCategory = value),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descController,
                  decoration: InputDecoration(
                    labelText: 'Description (Optional)',
                    labelStyle: const TextStyle(color: Color(0xFFB8A9C9)),
                    filled: true,
                    fillColor: const Color(0xFF2D2645),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF9D4EDD), width: 2)),
                  ),
                  style: const TextStyle(color: Colors.white),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel', style: TextStyle(color: Color(0xFFB8A9C9)))),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.isEmpty || selectedCategory == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please fill in name and select a category'), backgroundColor: Colors.orange),
                  );
                  return;
                }
                Navigator.pop(context, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: EdgeInsets.zero,
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)]),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('Create', style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );

    if (result == true && nameController.text.isNotEmpty && selectedCategory != null) {
      try {
        await SocietyService.createSociety(
          name: nameController.text,
          description: descController.text.isEmpty ? null : descController.text,
          category: selectedCategory,
        );
        _showSuccess('Society created successfully!');
        _loadSocieties();
      } catch (e) {
        _showError('Failed to create society: $e');
      }
    }
  }

  Future<void> _assignPresident(Society society) async {

    // Get list of presidents
    final presidents = await UserService.getUsersByRole('president');

    final selected = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1B2E),
        title: Text('Assign President to ${society.name}', style: const TextStyle(color: Colors.white)),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: presidents.isEmpty
              ? const Center(child: Text('No presidents found', style: TextStyle(color: Color(0xFFB8A9C9))))
              : ListView.builder(
                  itemCount: presidents.length,
                  itemBuilder: (context, idx) {
                    final user = presidents[idx];
                    final isSelected = user.id == society.presidentId;
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.orange.withOpacity(0.2),
                        child: Text(user.name[0].toUpperCase(), style: const TextStyle(color: Colors.orange)),
                      ),
                      title: Text(user.name, style: TextStyle(color: Colors.white, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                      subtitle: Text(user.email, style: const TextStyle(color: Color(0xFFB8A9C9), fontSize: 12)),
                      trailing: isSelected ? const Icon(Icons.check_circle, color: Colors.green) : null,
                      onTap: () => Navigator.pop(context, user.id),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: Color(0xFFB8A9C9)))),
        ],
      ),
    );

    if (selected != null) {
      try {
        await SocietyService.assignPresident(society.id, selected);
        _showSuccess('President assigned successfully!');
        _loadSocieties();
      } catch (e) {
        _showError('Failed to assign president: $e');
      }
    }
  }

  Future<void> _deleteSociety(Society society) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1B2E),
        title: const Text('Delete Society', style: TextStyle(color: Colors.red)),
        content: Text('Are you sure you want to delete "${society.name}"?\nThis will remove all members.', style: const TextStyle(color: Colors.white)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel', style: TextStyle(color: Color(0xFFB8A9C9)))),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await SocietyService.deleteSociety(society.id);
        _showSuccess('Society deleted');
        _loadSocieties();
      } catch (e) {
        _showError('Failed to delete: $e');
      }
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
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios, color: Colors.white), onPressed: () => Navigator.pop(context)),
        title: const Text('Society Management', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)]),
          borderRadius: BorderRadius.circular(16),
        ),
        child: FloatingActionButton.extended(
          onPressed: _createSociety,
          backgroundColor: Colors.transparent,
          elevation: 0,
          highlightElevation: 0,
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text('New Society', style: TextStyle(color: Colors.white)),
        ),
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: isDark ? DarkColors.primary : AppTheme.primaryColor))
          : _societies.isEmpty
              ? const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.groups_outlined, size: 64, color: Color(0xFFB8A9C9)),
                  SizedBox(height: 16),
                  Text('No societies yet', style: TextStyle(color: Color(0xFFB8A9C9))),
                ]))
              : RefreshIndicator(
                  onRefresh: _loadSocieties,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _societies.length,
                    itemBuilder: (context, idx) => _buildSocietyCard(_societies[idx], isDark),
                  ),
                ),
    );
  }

  Widget _buildSocietyCard(Society society, bool isDark) {
    final colors = [AppTheme.primaryColor, AppTheme.accentColor, Colors.orange, Colors.teal];
    final color = colors[society.name.hashCode.abs() % colors.length];


    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1B2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF3D3557).withOpacity(0.5)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [color, color.withOpacity(0.7)]),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                  child: Center(child: Text(society.name[0], style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold))),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(society.name, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      Text('${society.memberCount} members', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Actions
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SocietyDetailPage(societyId: society.id))),
                    icon: const Icon(Icons.people, size: 18, color: Color(0xFF9D4EDD)),
                    label: const Text('Members', style: TextStyle(color: Color(0xFF9D4EDD))),
                    style: OutlinedButton.styleFrom(side: const BorderSide(color: Color(0xFF9D4EDD))),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _assignPresident(society),
                    icon: const Icon(Icons.person_add, size: 18, color: Color(0xFF9D4EDD)),
                    label: const Text('President', style: TextStyle(color: Color(0xFF9D4EDD))),
                    style: OutlinedButton.styleFrom(side: const BorderSide(color: Color(0xFF9D4EDD))),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => _deleteSociety(society),
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
