import 'package:flutter/material.dart';
import '../widgets/app_shell.dart';
import '../models/project.dart';
import '../services/api_service.dart';
import 'dm_project_details.dart';
import 'dm_ai_analysis.dart';

class DmProjectsScreen extends StatefulWidget {
  const DmProjectsScreen({super.key});

  @override
  State<DmProjectsScreen> createState() => _DmProjectsScreenState();
}

class _DmProjectsScreenState extends State<DmProjectsScreen> {
  bool _isLoading = true;
  List<Project> _projects = [];
  int? _selectedIndex;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final data = await ApiService.fetchProjects(searchQuery: _searchQuery);
      if (mounted) {
        setState(() {
          _projects = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Projects',
      selectedIndex: 3,
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    if (isDesktop) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Panel 1: Project list
          Expanded(
            flex: 1,
            child: _buildProjectList(context, isDesktop: true),
          ),
          Container(width: 1, color: Colors.grey.shade200),

          // Panel 2: Project Details
          Expanded(
            flex: 1,
            child: _selectedIndex == null || _projects.isEmpty
                ? const Center(child: Text('Select a project to view details', style: TextStyle(color: Colors.grey)))
                : DmProjectDetailsScreen(project: _projects[_selectedIndex!], isEmbedded: true),
          ),
          Container(width: 1, color: Colors.grey.shade200),

          // Panel 3: AI Analysis
          Expanded(
            flex: 1,
            child: _selectedIndex == null || _projects.isEmpty
                ? const Center(child: Text('AI Analysis Results will appear here', style: TextStyle(color: Colors.grey)))
                : DmAiAnalysisScreen(project: _projects[_selectedIndex!], isEmbedded: true),
          ),
        ],
      );
    }

    // Mobile: panel 1 only, push on tap
    return _buildProjectList(context, isDesktop: false);
  }

  Widget _buildProjectList(BuildContext context, {required bool isDesktop}) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search by ID, Name, Location...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            onChanged: (val) {
              setState(() => _searchQuery = val);
              _loadData();
            },
          ),
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: _projects.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final p = _projects[index];
                    final isSelected = _selectedIndex == index;
                    
                    Color statusColor = Colors.green;
                    if (p.status == 'Flagged' || p.status == 'Delayed') {
                      statusColor = Colors.red;
                    } else if (p.status == 'Ongoing') {
                      statusColor = Colors.blue;
                    }

                    return GestureDetector(
                      onTap: () {
                        if (isDesktop) {
                          setState(() => _selectedIndex = index);
                        } else {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => DmProjectDetailsScreen(project: p),
                            ),
                          );
                        }
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFF2F6FED).withValues(alpha: 0.05) : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? const Color(0xFF2F6FED) : Colors.grey.shade200,
                            width: isSelected ? 1.5 : 1,
                          ),
                          boxShadow: [
                            if (!isSelected)
                              BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4, offset: const Offset(0, 2))
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Work ID: ${p.id}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0B1F3A))),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: statusColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(p.status, style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(p.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black87)),
                            const SizedBox(height: 4),
                            Text('₹${p.estimatedCost}', style: const TextStyle(fontSize: 14, color: Colors.black54)),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.location_on, size: 14, color: Colors.grey),
                                const SizedBox(width: 4),
                                Expanded(child: Text(p.location, style: const TextStyle(fontSize: 13, color: Colors.grey))),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
