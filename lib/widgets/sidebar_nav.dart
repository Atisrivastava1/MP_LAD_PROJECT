import 'package:flutter/material.dart';


/// Collapsible left navigation sidebar used on desktop layouts.
///
/// When [expanded] is true → shows icon + label (240px wide).
/// When [expanded] is false → shows icon only (68px wide).
///
/// The sidebar items adapt based on [role]:
///   'Auditor'      → Dashboard, Projects, Investigation, History, Reports
///   'Data Manager' → Dashboard, Upload, Data Quality, Projects, Reports
class SidebarNav extends StatelessWidget {
  final int selectedIndex;
  final String role;
  final bool expanded;
  final VoidCallback onToggle;

  const SidebarNav({
    super.key,
    required this.selectedIndex,
    required this.role,
    required this.expanded,
    required this.onToggle,
  });

  static const Color _navBg = Color(0xFF0B1F3A);

  List<_SidebarItem> _itemsForRole() {
    if (role == 'Data Manager') {
      return [
        _SidebarItem(icon: Icons.dashboard_outlined, label: 'Dashboard', route: '/data-manager-dashboard'),
        _SidebarItem(icon: Icons.upload_file_outlined, label: 'Upload', route: '/upload-project'),
        _SidebarItem(icon: Icons.fact_check_outlined, label: 'Data Quality', route: '/data-quality'),
        _SidebarItem(icon: Icons.folder_open_outlined, label: 'Projects', route: '/dm-projects'),
        _SidebarItem(icon: Icons.bar_chart_outlined, label: 'Reports', route: '/dm-reports'),
      ];
    }
    // Auditor (default)
    return [
      _SidebarItem(icon: Icons.dashboard_outlined, label: 'Dashboard', route: '/auditor-dashboard'),
      _SidebarItem(icon: Icons.folder_open_outlined, label: 'Projects', route: '/risk-projects'),
      _SidebarItem(icon: Icons.search_outlined, label: 'Investigation', route: '/auditor-investigations'),
      _SidebarItem(icon: Icons.history_outlined, label: 'Audit History', route: '/audit-history'),
      _SidebarItem(icon: Icons.description_outlined, label: 'Reports', route: '/audit-report'),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final items = _itemsForRole();

    return Container(
      color: _navBg,
      child: Column(
        children: [
          // ── Logo / Header ──────────────────────────────────────────
          Container(
            height: 64,
            padding: EdgeInsets.symmetric(
              horizontal: expanded ? 16 : 0,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.15),
            ),
            child: Row(
              mainAxisAlignment:
                  expanded ? MainAxisAlignment.start : MainAxisAlignment.center,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2F6FED),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.shield_outlined, color: Colors.white, size: 22),
                ),
                if (expanded) ...[
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'MPLADS',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            letterSpacing: 0.5,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Sentinel',
                          style: TextStyle(color: Colors.white54, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 8),

          // ── Nav Items ──────────────────────────────────────────────
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                final isSelected = selectedIndex == index;
                return _NavTile(
                  item: item,
                  isSelected: isSelected,
                  expanded: expanded,
                  onTap: () {
                    if (!isSelected) {
                      Navigator.of(context).pushNamedAndRemoveUntil(
                        item.route,
                        (r) => false,
                      );
                    }
                  },
                );
              },
            ),
          ),

          // ── Divider + Version ──────────────────────────────────────
          if (expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: [
                  const Divider(color: Colors.white12),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        width: 6, height: 6,
                        decoration: const BoxDecoration(
                          color: Color(0xFF4CAF50),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'System Online · v1.0-prototype',
                        style: TextStyle(color: Colors.white38, fontSize: 10),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ── Internal widgets ──────────────────────────────────────────────────────

class _SidebarItem {
  final IconData icon;
  final String label;
  final String route;
  const _SidebarItem({required this.icon, required this.label, required this.route});
}

class _NavTile extends StatefulWidget {
  final _SidebarItem item;
  final bool isSelected;
  final bool expanded;
  final VoidCallback onTap;

  const _NavTile({
    required this.item,
    required this.isSelected,
    required this.expanded,
    required this.onTap,
  });

  @override
  State<_NavTile> createState() => _NavTileState();
}

class _NavTileState extends State<_NavTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final isActive = widget.isSelected;
    final bg = isActive
        ? const Color(0xFF2F6FED)
        : _hovered
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.transparent;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.symmetric(vertical: 2),
          padding: EdgeInsets.symmetric(
            horizontal: widget.expanded ? 14 : 0,
            vertical: 11,
          ),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment:
                widget.expanded ? MainAxisAlignment.start : MainAxisAlignment.center,
            children: [
              Icon(
                widget.item.icon,
                color: isActive ? Colors.white : Colors.white60,
                size: 22,
              ),
              if (widget.expanded) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.item.label,
                    style: TextStyle(
                      color: isActive ? Colors.white : Colors.white70,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isActive)
                  Container(
                    width: 6, height: 6,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
