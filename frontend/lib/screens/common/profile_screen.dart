import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../widgets/profile_header.dart';
import '../../services/api_service.dart';

/// Profile Screen — shared between Auditor and Data Manager roles.
/// Displays all user fields from the DB users table.
/// Fields are fetched from ApiService.currentUser.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = ApiService.currentUser;
    final name = user?.name ?? 'Shri Ramesh Kumar';
    final username = user?.username ?? 'ramesh.kumar';
    final email = user?.email ?? 'ramesh.kumar@mplads.gov.in';
    final role = user?.role ?? 'Auditor';
    final department = user?.department ?? 'Ministry of Statistics & Programme Implementation';
    final userId = user?.id ?? 'USR-001';
    
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final createdAtStr = user != null 
        ? '${user.createdAt.day.toString().padLeft(2, '0')} ${months[user.createdAt.month - 1]} ${user.createdAt.year}'
        : '01 Jan 2024';

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        backgroundColor: const Color(0xFF0B1F3A),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: buildProfileAppBarActions(context),
      ),
      backgroundColor: const Color(0xFFF5F7FA),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Avatar Card ────────────────────────────────────────
                Card(
                  elevation: 0,
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: Colors.grey.shade200),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Row(
                      children: [
                        Stack(
                          children: [
                            CircleAvatar(
                              radius: 44,
                              backgroundColor: const Color(0xFF0B1F3A),
                              child: Text(
                                name.isNotEmpty ? name[0].toUpperCase() : 'U',
                                style: const TextStyle(fontSize: 36, color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: () async {
                                  try {
                                    final files = await FilePicker.pickFiles(
                                      type: FileType.image,
                                    );
                                    if (files.isNotEmpty) {
                                      final fileName = files.first.name;
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Selected profile picture: $fileName')),
                                        );
                                      }
                                      // TODO: Upload file to backend and update ApiService.currentUser
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Failed to pick image: $e')),
                                      );
                                    }
                                  }
                                },
                                child: Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2F6FED),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2),
                                  ),
                                  child: const Icon(Icons.camera_alt, size: 14, color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Color(0xFF0B1F3A))),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2F6FED).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(role, style: const TextStyle(color: Color(0xFF2F6FED), fontWeight: FontWeight.w600, fontSize: 12)),
                              ),
                              const SizedBox(height: 6),
                              Text('ID: $userId', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // ── Account Details Card ───────────────────────────────
                _buildSectionCard(
                  title: 'Account Details',
                  icon: Icons.person_outline,
                  fields: [
                    _ProfileField(label: 'Full Name', value: name, icon: Icons.person_outline),
                    _ProfileField(label: 'Username', value: '@$username', icon: Icons.alternate_email),
                    _ProfileField(label: 'Email', value: email, icon: Icons.email_outlined),
                    _ProfileField(label: 'Role', value: role, icon: Icons.badge_outlined),
                    _ProfileField(label: 'Department', value: department, icon: Icons.business_outlined),
                  ],
                ),
                const SizedBox(height: 16),

                // ── System Info Card ───────────────────────────────────
                _buildSectionCard(
                  title: 'System Information',
                  icon: Icons.info_outline,
                  fields: [
                    _ProfileField(label: 'User ID', value: userId, icon: Icons.tag),
                    _ProfileField(label: 'Member Since', value: createdAtStr, icon: Icons.calendar_today_outlined),
                    _ProfileField(label: 'Account Status', value: 'Active', icon: Icons.check_circle_outline, valueColor: const Color(0xFF43A047)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({required String title, required IconData icon, required List<_ProfileField> fields}) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: const Color(0xFF2F6FED)),
                const SizedBox(width: 8),
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0B1F3A))),
              ],
            ),
            const Divider(height: 24),
            ...fields.map((f) => _buildFieldRow(f)),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldRow(_ProfileField field) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(field.icon, size: 16, color: Colors.grey.shade500),
          const SizedBox(width: 10),
          SizedBox(
            width: 140,
            child: Text(field.label, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          ),
          Expanded(
            child: Text(
              field.value,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: field.valueColor ?? const Color(0xFF0B1F3A),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileField {
  final String label;
  final String value;
  final IconData icon;
  final Color? valueColor;

  const _ProfileField({required this.label, required this.value, required this.icon, this.valueColor});
}
