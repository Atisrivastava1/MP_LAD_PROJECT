import 'package:flutter/material.dart';

import '../routes/app_routes.dart';
import '../services/api_service.dart';

/// Profile chip displayed in the top AppBar of every screen.
///
/// Shows the user's avatar placeholder + name.
/// Tapping opens a [_ProfileDrawerPanel] from the right side of the screen.
///
/// [compact] = true → shows avatar only (for mobile AppBar).
/// [compact] = false → shows avatar + name + role (for desktop AppBar).
class ProfileHeaderChip extends StatelessWidget {
  final String userName;
  final String role;
  final String userId;
  final bool compact;
  final bool isDark;

  const ProfileHeaderChip({
    super.key,
    required this.userName,
    required this.role,
    required this.userId,
    this.compact = false,
    this.isDark = false,
  });

  Color get _roleColor {
    switch (role) {
      case 'Auditor':
        return const Color(0xFF2F6FED);
      case 'Data Manager':
        return const Color(0xFF00897B);
      default:
        return const Color(0xFF6D4C41);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _openProfileDrawer(context),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 6 : 12,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: compact ? 0.1 : 0.0),
            border: compact
                ? null
                : Border.all(color: Colors.grey.shade200),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Avatar placeholder
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: _roleColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: _roleColor.withValues(alpha: 0.4), width: 1.5),
                ),
                child: Icon(Icons.person, color: _roleColor, size: 20),
              ),
              if (!compact) ...[
                const SizedBox(width: 10),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : const Color(0xFF0B1F3A),
                      ),
                    ),
                    Text(
                      role,
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.white70 : _roleColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 6),
                Icon(Icons.keyboard_arrow_down, size: 16, color: isDark ? Colors.white54 : Colors.grey),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _openProfileDrawer(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'ProfileDrawer',
      barrierColor: Colors.black26,
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (context, anim1, anim2) => Align(
        alignment: Alignment.topRight,
        child: _ProfileDrawerPanel(
          userName: userName,
          role: role,
          userId: userId,
          roleColor: _roleColor,
        ),
      ),
      transitionBuilder: (context, anim1, anim2, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1.0, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: anim1, curve: Curves.easeOut)),
          child: child,
        );
      },
    );
  }
}

/// Helper method to add the profile chip to any AppBar actions
List<Widget> buildProfileAppBarActions(BuildContext context) {
  final isDesktop = MediaQuery.of(context).size.width >= 900;
  final user = ApiService.currentUser;
  
  return [
    ProfileHeaderChip(
      userName: user?.name ?? 'Shri Ramesh Kumar',
      role: user?.role ?? 'Auditor',
      userId: user?.id ?? 'USR-001',
      compact: !isDesktop,
      isDark: true, // Used when AppBar is dark blue
    ),
    const SizedBox(width: 8),
  ];
}

// ── Profile Drawer Panel ───────────────────────────────────────────────────

class _ProfileDrawerPanel extends StatelessWidget {
  final String userName;
  final String role;
  final String userId;
  final Color roleColor;

  const _ProfileDrawerPanel({
    required this.userName,
    required this.role,
    required this.userId,
    required this.roleColor,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: 300,
        height: double.infinity,
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 20,
              offset: Offset(-4, 0),
            ),
          ],
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                color: const Color(0xFF0B1F3A),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // Avatar placeholder
                        Container(
                          width: 58,
                          height: 58,
                          decoration: BoxDecoration(
                            color: roleColor.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                            border: Border.all(color: roleColor, width: 2),
                          ),
                          child: Icon(Icons.person, color: roleColor, size: 32),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                userName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: roleColor.withValues(alpha: 0.25),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: roleColor.withValues(alpha: 0.5)),
                                ),
                                child: Text(
                                  role,
                                  style: TextStyle(
                                    color: roleColor,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Close
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white54, size: 20),
                          onPressed: () => Navigator.of(context).pop(),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // Profile details
              Expanded(
                child: CustomScrollView(
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.all(20),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          // Menu items
                          _DrawerMenuItem(
                            icon: Icons.person_outline,
                            label: 'View Profile',
                            onTap: () {
                              Navigator.of(context).pop();
                              Navigator.of(context).pushNamed('/profile');
                            },
                          ),
                          _DrawerMenuItem(
                            icon: Icons.settings_outlined,
                            label: 'Account Settings',
                            onTap: () {
                              Navigator.of(context).pop();
                              // TODO: Settings screen
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Settings — coming soon')),
                              );
                            },
                          ),
                          _DrawerMenuItem(
                            icon: Icons.help_outline,
                            label: 'Help & Support',
                            onTap: () {
                              Navigator.of(context).pop();
                            },
                          ),
                        ]),
                      ),
                    ),
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            const Divider(),
                            const SizedBox(height: 8),

                            // Logout
                            _DrawerMenuItem(
                              icon: Icons.logout,
                              label: 'Logout',
                              color: const Color(0xFFD32F2F),
                              onTap: () {
                                Navigator.of(context).pop(); // close drawer
                                Navigator.of(context).pushNamedAndRemoveUntil(
                                  AppRoutes.login,
                                  (_) => false,
                                );
                              },
                            ),

                            const SizedBox(height: 24),
                            Center(
                              child: Text(
                                'Secure · Transparent · Accountable',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey.shade400,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Helper widgets ────────────────────────────────────────────────────────



class _DrawerMenuItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _DrawerMenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  State<_DrawerMenuItem> createState() => _DrawerMenuItemState();
}

class _DrawerMenuItemState extends State<_DrawerMenuItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? const Color(0xFF0B1F3A);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          margin: const EdgeInsets.symmetric(vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: _hovered ? color.withValues(alpha: 0.06) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(widget.icon, size: 20, color: color),
              const SizedBox(width: 14),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 14,
                  color: color,
                  fontWeight: widget.color != null ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
              const Spacer(),
              if (widget.color == null)
                Icon(Icons.chevron_right, size: 16, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }
}
