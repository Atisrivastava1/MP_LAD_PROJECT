import 'package:flutter/material.dart';
import '../../widgets/app_shell.dart';
import '../../models/investigation.dart';
import '../../services/api_service.dart';
import 'review_decision.dart';

/// Investigation List Screen — shows all submitted investigations for the Auditor.
/// Each row links to the Review & Decision screen.
class InvestigationListScreen extends StatefulWidget {
  const InvestigationListScreen({super.key});

  @override
  State<InvestigationListScreen> createState() => _InvestigationListScreenState();
}

class _InvestigationListScreenState extends State<InvestigationListScreen> {
  late Future<List<Investigation>> _investigationsFuture;

  @override
  void initState() {
    super.initState();
    _investigationsFuture = ApiService.fetchAllInvestigations();
  }

  void _openDecisionScreen(BuildContext context, Investigation inv) {
    final isDesktop = MediaQuery.of(context).size.width >= 900;
    if (isDesktop) {
      showDialog(
        context: context,
        builder: (context) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800, maxHeight: 800),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: ReviewDecisionScreen(investigationId: inv.id),
            ),
          ),
        ),
      );
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ReviewDecisionScreen(investigationId: inv.id),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Investigations',
      selectedIndex: 2,
      body: FutureBuilder<List<Investigation>>(
        future: _investigationsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final investigations = snapshot.data ?? [];
          return _buildBody(context, investigations);
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, List<Investigation> investigations) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('All Investigations', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: Color(0xFF0B1F3A))),
                  Text('${investigations.length} investigations found', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // List
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            itemCount: investigations.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final inv = investigations[index];
              return _InvestigationCard(
                inv: inv,
                onTap: () => _openDecisionScreen(context, inv),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _InvestigationCard extends StatelessWidget {
  final Investigation inv;
  final VoidCallback onTap;

  const _InvestigationCard({required this.inv, required this.onTap});

  Color _statusColor(String status) {
    switch (status) {
      case 'Submitted': return const Color(0xFF2F6FED);
      case 'Under Review': return const Color(0xFFFF8F00);
      case 'In Progress': return const Color(0xFF00ACC1);
      case 'Closed': return const Color(0xFF43A047);
      default: return Colors.grey;
    }
  }
  
  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return '${date.day.toString().padLeft(2, '0')} ${_monthString(date.month)} ${date.year}';
  }

  String _monthString(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(inv.status);
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: const Color(0xFF0B1F3A).withValues(alpha: 0.08),
                child: const Icon(Icons.search_outlined, color: Color(0xFF0B1F3A), size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(inv.id, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0B1F3A))),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(inv.status, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 11)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text('Work ID: ${inv.projectId}', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                    const SizedBox(height: 2),
                    Text('Assigned to: ${inv.auditorName} · ${_formatDate(inv.submittedAt)}', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
