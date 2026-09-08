import 'package:flutter/material.dart';

import '../utils/breakpoints.dart';
import '../services/api_service.dart';
import 'sidebar_nav.dart';
import 'profile_header.dart';

/// Master layout shell used by every post-login screen.
///
/// On wide screens (≥ kDesktopBreakpoint):
///   [SidebarNav] | [AppBar + body]
///
/// On narrow screens (< kDesktopBreakpoint):
///   [AppBar + body] / [BottomNavigationBar]
///
/// Usage:
///   return AppShell(
///     title: 'Dashboard',
///     selectedIndex: 0,
///     role: 'Auditor',
///     userName: 'Shri Ramesh Kumar',
///     userId: 'AUD-2024-01',
///     body: YourContent(),
///   );
class AppShell extends StatefulWidget {
  final String title;
  final Widget body;
  final int selectedIndex;

  /// Optional: floating action button
  final Widget? floatingActionButton;

  const AppShell({
    super.key,
    required this.title,
    required this.body,
    required this.selectedIndex,
    this.floatingActionButton,
  });

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  bool _sidebarExpanded = true;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= kDesktopBreakpoint;

        if (isDesktop) {
          return _buildDesktopLayout(context);
        } else {
          return _buildMobileLayout(context);
        }
      },
    );
  }

  // ── Desktop Layout ──────────────────────────────────────────────────────

  Widget _buildDesktopLayout(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Row(
        children: [
          // Sidebar
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeInOut,
            width: _sidebarExpanded ? kSidebarExpandedWidth : kSidebarCollapsedWidth,
            child: SidebarNav(
              selectedIndex: widget.selectedIndex,
              role: ApiService.currentUser?.role ?? 'Auditor',
              expanded: _sidebarExpanded,
              onToggle: () => setState(() => _sidebarExpanded = !_sidebarExpanded),
            ),
          ),
          // Main content area
          Expanded(
            child: Column(
              children: [
                _buildDesktopAppBar(context),
                Expanded(child: widget.body),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: widget.floatingActionButton,
    );
  }

  Widget _buildDesktopAppBar(BuildContext context) {
    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          // Sidebar toggle
          IconButton(
            icon: Icon(
              _sidebarExpanded ? Icons.menu_open : Icons.menu,
              color: const Color(0xFF0B1F3A),
            ),
            onPressed: () => setState(() => _sidebarExpanded = !_sidebarExpanded),
            tooltip: _sidebarExpanded ? 'Collapse sidebar' : 'Expand sidebar',
          ),
          const SizedBox(width: 16),

          // Page title
          Text(
            widget.title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0B1F3A),
            ),
          ),

          const Spacer(),

          // Notification bell
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.notifications_outlined, color: Color(0xFF0B1F3A), size: 26),
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFFD32F2F),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
            onPressed: () => Navigator.of(context).pushNamed('/notifications'),
            tooltip: 'Notifications',
          ),

          const SizedBox(width: 8),

          // Profile chip
          ProfileHeaderChip(
            userName: ApiService.currentUser?.name ?? 'Shri Ramesh Kumar',
            role: ApiService.currentUser?.role ?? 'Auditor',
            userId: ApiService.currentUser?.id ?? 'USR-001',
          ),
        ],
      ),
    );
  }

  // ── Mobile Layout ───────────────────────────────────────────────────────

  Widget _buildMobileLayout(BuildContext context) {
    final role = ApiService.currentUser?.role ?? 'Auditor';
    final navItems = _navItemsForRole(role);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B1F3A),
        foregroundColor: Colors.white,
        title: Text(widget.title),
        actions: [
          // Notification
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => Navigator.of(context).pushNamed('/notifications'),
          ),
          // Profile chip (compact for mobile)
          ProfileHeaderChip(
            userName: ApiService.currentUser?.name ?? 'Shri Ramesh Kumar',
            role: role,
            userId: ApiService.currentUser?.id ?? 'USR-001',
            compact: true,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: widget.body,
      floatingActionButton: widget.floatingActionButton,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: widget.selectedIndex,
        selectedItemColor: const Color(0xFF2F6FED),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: (index) => _onNavTap(context, index),
        items: navItems,
      ),
    );
  }

  List<BottomNavigationBarItem> _navItemsForRole(String role) {
    if (role == 'Data Manager') {
      return const [
        BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), label: 'Dashboard'),
        BottomNavigationBarItem(icon: Icon(Icons.upload_file_outlined), label: 'Upload'),
        BottomNavigationBarItem(icon: Icon(Icons.fact_check_outlined), label: 'Data Quality'),
        BottomNavigationBarItem(icon: Icon(Icons.folder_outlined), label: 'Projects'),
        BottomNavigationBarItem(icon: Icon(Icons.bar_chart_outlined), label: 'Reports'),
      ];
    }
    return const [
      BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), label: 'Dashboard'),
      BottomNavigationBarItem(icon: Icon(Icons.folder_outlined), label: 'Projects'),
      BottomNavigationBarItem(icon: Icon(Icons.search_outlined), label: 'Investigation'),
      BottomNavigationBarItem(icon: Icon(Icons.history_outlined), label: 'History'),
      BottomNavigationBarItem(icon: Icon(Icons.assessment_outlined), label: 'Report'),
    ];
  }

  void _onNavTap(BuildContext context, int index) {
    if (index == widget.selectedIndex) return;
    
    final role = ApiService.currentUser?.role ?? 'Auditor';

    if (role == 'Data Manager') {
      switch (index) {
        case 0:
          Navigator.of(context).pushNamedAndRemoveUntil('/data-manager-dashboard', (r) => false);
          break;
        case 1:
          Navigator.of(context).pushNamedAndRemoveUntil('/upload-project', (r) => false);
          break;
        case 2:
          Navigator.of(context).pushNamedAndRemoveUntil('/data-quality', (r) => false);
          break;
        case 3:
          Navigator.of(context).pushNamedAndRemoveUntil('/dm-projects', (r) => false);
          break;
        case 4:
          Navigator.of(context).pushNamedAndRemoveUntil('/dm-reports', (r) => false);
          break;
      }
    } else {
      // Auditor
      switch (index) {
        case 0:
          Navigator.of(context).pushNamedAndRemoveUntil('/auditor-dashboard', (r) => false);
          break;
        case 1:
          Navigator.of(context).pushNamedAndRemoveUntil('/risk-projects', (r) => false);
          break;
        case 2:
          Navigator.of(context).pushNamedAndRemoveUntil('/auditor-investigations', (r) => false);
          break;
        case 3:
          Navigator.of(context).pushNamedAndRemoveUntil('/audit-history', (r) => false);
          break;
        case 4:
          Navigator.of(context).pushNamedAndRemoveUntil('/audit-report', (r) => false);
          break;
      }
    }
  }
}
