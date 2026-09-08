import 'package:flutter/material.dart';
import '../widgets/app_shell.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Static Placeholder Data
// Replace with ApiService calls once backend is ready.
// ─────────────────────────────────────────────────────────────────────────────
const List<_RiskProject> _mockProjects = [
  _RiskProject(
    workId: '175556',
    mpName: 'Shri Rajesh Gupta',
    state: 'Madhya Pradesh',
    district: 'Indore',
    description: 'Construction of community hall near village panchayat building, MP.',
    recommendedAmount: 2450000,
    completionDate: '15 Mar 2024',
    hasImages: true,
    riskScore: 91,
    anomalyFlag: true,
    isDuplicate: false,
    riskReasons: [
      'Critical statistical anomaly — Isolation Forest detected unusual cost pattern',
      'Completion delay of 240 days relative to project type baseline',
      'Description length too short (18 words vs. 35-word baseline)',
      'Amount ₹24.5L exceeds district median by 3.1 standard deviations',
    ],
    mlFeatures: {
      'description_length': '18',
      'completion_delay_missing': '1',
      'recommended_amount': '2450000',
      'has_images': '1',
      'mp_name_frequency': '0.67',
      'district_frequency': '0.42',
      'work_type_avg_amount': '1100000',
    },
    modelVersion: '1.0.0',
    rawAnomalyScore: 0.91,
    duplicateWorkIds: ['172001', '170889'],
    status: 'Flagged',
  ),
  _RiskProject(
    workId: '172001',
    mpName: 'Smt. Kavita Sharma',
    state: 'Uttar Pradesh',
    district: 'Lucknow',
    description: 'Laying of road from village Saraiyan to NH-27 junction.',
    recommendedAmount: 1850000,
    completionDate: '10 Jan 2024',
    hasImages: false,
    riskScore: 78,
    anomalyFlag: true,
    isDuplicate: true,
    riskReasons: [
      'Duplicate detected — similar project found in Work IDs 175556, 170889',
      'No images uploaded; reduces verification confidence',
      'Amount ₹18.5L is 2.4× above district road-type median',
    ],
    mlFeatures: {
      'description_length': '24',
      'completion_delay_missing': '0',
      'recommended_amount': '1850000',
      'has_images': '0',
      'mp_name_frequency': '0.55',
      'district_frequency': '0.39',
      'work_type_avg_amount': '770000',
    },
    modelVersion: '1.0.0',
    rawAnomalyScore: 0.78,
    duplicateWorkIds: ['175556', '170889'],
    status: 'Duplicate',
  ),
  _RiskProject(
    workId: '177320',
    mpName: 'Shri Mohan Das',
    state: 'Rajasthan',
    district: 'Jaipur',
    description: 'Installation of solar street lights in Gram Panchayat Kalyanpura.',
    recommendedAmount: 980000,
    completionDate: '',
    hasImages: true,
    riskScore: 84,
    anomalyFlag: true,
    isDuplicate: false,
    riskReasons: [
      'Completion date missing — cannot verify project closure',
      'Work description is generic; matches 12 other projects verbatim',
      'Amount ₹9.8L above expected range for solar installation in Jaipur',
    ],
    mlFeatures: {
      'description_length': '11',
      'completion_delay_missing': '1',
      'recommended_amount': '980000',
      'has_images': '1',
      'mp_name_frequency': '0.78',
      'district_frequency': '0.51',
      'work_type_avg_amount': '620000',
    },
    modelVersion: '1.0.0',
    rawAnomalyScore: 0.84,
    duplicateWorkIds: [],
    status: 'Flagged',
  ),
  _RiskProject(
    workId: '168934',
    mpName: 'Shri Anil Patel',
    state: 'Gujarat',
    district: 'Surat',
    description: 'Construction of approach road to primary health centre, Kadodara village.',
    recommendedAmount: 750000,
    completionDate: '22 Aug 2023',
    hasImages: true,
    riskScore: 18,
    anomalyFlag: false,
    isDuplicate: false,
    riskReasons: [],
    mlFeatures: {
      'description_length': '47',
      'completion_delay_missing': '0',
      'recommended_amount': '750000',
      'has_images': '1',
      'mp_name_frequency': '0.32',
      'district_frequency': '0.28',
      'work_type_avg_amount': '720000',
    },
    modelVersion: '1.0.0',
    rawAnomalyScore: 0.18,
    duplicateWorkIds: [],
    status: 'Clean',
  ),
  _RiskProject(
    workId: '163210',
    mpName: 'Smt. Sonia Verma',
    state: 'Bihar',
    district: 'Patna',
    description: 'Development of Anganwadi centre building — Phase 3, Muzaffarpur block.',
    recommendedAmount: 1200000,
    completionDate: '30 Jun 2023',
    hasImages: true,
    riskScore: 22,
    anomalyFlag: false,
    isDuplicate: false,
    riskReasons: [],
    mlFeatures: {
      'description_length': '38',
      'completion_delay_missing': '0',
      'recommended_amount': '1200000',
      'has_images': '1',
      'mp_name_frequency': '0.41',
      'district_frequency': '0.37',
      'work_type_avg_amount': '1150000',
    },
    modelVersion: '1.0.0',
    rawAnomalyScore: 0.22,
    duplicateWorkIds: [],
    status: 'Clean',
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
// Main Screen
// ─────────────────────────────────────────────────────────────────────────────

class RiskProjectListScreen extends StatefulWidget {
  const RiskProjectListScreen({super.key});

  @override
  State<RiskProjectListScreen> createState() => _RiskProjectListScreenState();
}

class _RiskProjectListScreenState extends State<RiskProjectListScreen> {
  int? _selectedIndex;
  String _riskFilter = 'All';
  String _searchQuery = '';
  // 0 = Why Flagged, 1 = New Investigation
  int _rightPanelTab = 0;

  List<_RiskProject> get _filtered {
    var list = _mockProjects.where((p) {
      final q = _searchQuery.toLowerCase();
      final matchSearch = q.isEmpty ||
          p.workId.contains(q) ||
          p.mpName.toLowerCase().contains(q) ||
          p.state.toLowerCase().contains(q) ||
          p.district.toLowerCase().contains(q);
      final matchFilter = _riskFilter == 'All' ||
          (_riskFilter == 'Flagged' && p.anomalyFlag) ||
          (_riskFilter == 'Duplicate' && p.isDuplicate) ||
          (_riskFilter == 'Clean' && !p.anomalyFlag);
      return matchSearch && matchFilter;
    }).toList();
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Projects',
      selectedIndex: 1,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth >= 900;
          return isDesktop ? _buildDesktopLayout() : _buildMobileLayout();
        },
      ),
    );
  }

  // ── Desktop: 3-Panel ──────────────────────────────────────────────────────
  Widget _buildDesktopLayout() {
    final selected = _selectedIndex != null ? _filtered.elementAtOrNull(_selectedIndex!) : null;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Panel 1 ── Project List
        Expanded(
          flex: 1,
          child: _buildPanel1(),
        ),
        Container(width: 1, color: Colors.grey.shade200),

        // Panel 2 ── Project Details
        Expanded(
          flex: 1,
          child: selected == null
              ? _emptyPanel('Select a project from the list')
              : _buildPanel2(selected),
        ),
        Container(width: 1, color: Colors.grey.shade200),

        // Panel 3 ── Why Flagged / Investigation / Duplicates
        Expanded(
          flex: 1,
          child: selected == null
              ? _emptyPanel('Analysis & Investigation panel')
              : _buildPanel3(selected),
        ),
      ],
    );
  }

  // ── Mobile: Push Navigation ───────────────────────────────────────────────
  Widget _buildMobileLayout() => _buildPanel1(mobile: true);

  // ── Panel 1: Project List ─────────────────────────────────────────────────
  Widget _buildPanel1({bool mobile = false}) {
    final projects = _filtered;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 14, 12, 8),
          child: TextField(
            onChanged: (v) => setState(() { _searchQuery = v; _selectedIndex = null; }),
            decoration: InputDecoration(
              hintText: 'Search Work ID, MP, State…',
              prefixIcon: const Icon(Icons.search, size: 20),
              filled: true,
              fillColor: Colors.grey.shade100,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            ),
          ),
        ),

        // Filter chips
        SizedBox(
          height: 38,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: ['All', 'Flagged', 'Duplicate', 'Clean'].map((f) {
              final sel = _riskFilter == f;
              final color = f == 'Flagged'
                  ? const Color(0xFFE53935)
                  : f == 'Duplicate'
                      ? const Color(0xFF8E24AA)
                      : f == 'Clean'
                          ? const Color(0xFF43A047)
                          : const Color(0xFF2F6FED);
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(f, style: TextStyle(fontSize: 12, color: sel ? color : Colors.black87, fontWeight: sel ? FontWeight.bold : FontWeight.normal)),
                  selected: sel,
                  selectedColor: color.withValues(alpha: 0.12),
                  backgroundColor: Colors.grey.shade100,
                  onSelected: (_) => setState(() { _riskFilter = f; _selectedIndex = null; }),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 6),

        // Count
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text('${projects.length} project${projects.length == 1 ? '' : 's'}',
              style: const TextStyle(color: Colors.grey, fontSize: 12)),
        ),
        const SizedBox(height: 4),

        // List
        Expanded(
          child: projects.isEmpty
              ? const Center(child: Text('No projects match the filter.', style: TextStyle(color: Colors.grey)))
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(10, 0, 10, 16),
                  itemCount: projects.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 6),
                  itemBuilder: (context, index) {
                    final p = projects[index];
                    final isSelected = !mobile && _selectedIndex == index;
                    return _ProjectListTile(
                      project: p,
                      isSelected: isSelected,
                      onTap: () {
                        if (mobile) {
                          Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => _MobileProjectDetail(project: p),
                          ));
                        } else {
                          setState(() {
                            _selectedIndex = index;
                            _rightPanelTab = 0; // reset to Why Flagged
                          });
                        }
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }

  // ── Panel 2: Project Details ──────────────────────────────────────────────
  Widget _buildPanel2(_RiskProject p) {
    final amountStr = '₹ ${(p.recommendedAmount / 100000).toStringAsFixed(2)} L';
    final statusColor = p.anomalyFlag
        ? (p.isDuplicate ? const Color(0xFF8E24AA) : const Color(0xFFE53935))
        : const Color(0xFF43A047);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Expanded(
                child: Text('Work ID: ${p.workId}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF0B1F3A))),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusColor.withValues(alpha: 0.4)),
                ),
                child: Text(p.status, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Risk score gauge
          _RiskScoreBar(score: p.riskScore),
          const SizedBox(height: 20),

          // Field table
          _fieldSection('Project Information', [
            _Field('Work ID', p.workId),
            _Field('MP Name', p.mpName),
            _Field('State', p.state),
            _Field('District', p.district),
            _Field('Description', p.description),
          ]),
          const SizedBox(height: 16),
          _fieldSection('Financial & Timeline', [
            _Field('Recommended Amount', amountStr),
            _Field('Completion Date', p.completionDate.isEmpty ? '— (missing)' : p.completionDate),
            _Field('Has Images', p.hasImages ? 'Yes ✓' : 'No ✗'),
          ]),
          const SizedBox(height: 16),

          // Action Buttons (appear on panel 2)
          if (p.anomalyFlag) ...[
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => setState(() { _rightPanelTab = 0; }),
                    icon: const Icon(Icons.info_outline, size: 16),
                    label: const Text('Why Flagged?'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE53935),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => setState(() { _rightPanelTab = 2; }),
                      icon: const Icon(Icons.copy_all_outlined, size: 16),
                      label: const Text('View Duplicates'),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF8E24AA)),
                        foregroundColor: const Color(0xFF8E24AA),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => setState(() { _rightPanelTab = 1; }),
                icon: const Icon(Icons.edit_note, size: 16),
                label: const Text('Start Investigation'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0B1F3A),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Panel 3: Why Flagged + ML Audit Trail / New Investigation / Duplicates ──
  Widget _buildPanel3(_RiskProject p) {
    return Column(
      children: [
        Expanded(
          child: _rightPanelTab == 0
              ? _buildWhyFlaggedPanel(p)
              : _rightPanelTab == 1
                  ? _buildInvestigationPanel(p)
                  : _buildDuplicatesPanel(p),
        ),
      ],
    );
  }

  // ── Why Flagged panel ─────────────────────────────────────────────────────
  Widget _buildWhyFlaggedPanel(_RiskProject p) {
    if (!p.anomalyFlag) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_outline, size: 48, color: Color(0xFF43A047)),
            SizedBox(height: 12),
            Text('No anomalies detected for this project.', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Risk summary card
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFE53935).withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE53935).withValues(alpha: 0.3)),
            ),
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Color(0xFFE53935), size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Anomaly Score: ${(p.rawAnomalyScore * 100).toStringAsFixed(0)}/100',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFFE53935))),
                      Text('ML Model v${p.modelVersion} · Isolation Forest',
                          style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Detected reasons
          const Text('Detected Anomalies', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0B1F3A))),
          const SizedBox(height: 10),
          ...p.riskReasons.asMap().entries.map((e) => _ReasonTile(number: e.key + 1, reason: e.value)),

          const SizedBox(height: 24),

          // ML Audit Trail
          _buildMLAuditTrail(p),
        ],
      ),
    );
  }

  Widget _buildMLAuditTrail(_RiskProject p) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.science_outlined, size: 16, color: Color(0xFF2F6FED)),
            const SizedBox(width: 6),
            const Text('AI Audit Trail', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0B1F3A))),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF2F6FED).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text('Model v${p.modelVersion}', style: const TextStyle(fontSize: 11, color: Color(0xFF2F6FED), fontWeight: FontWeight.w600)),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF5F7FA),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: p.mlFeatures.entries.map((e) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Text(_formatFeatureName(e.key),
                          style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(e.value,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Color(0xFF0B1F3A))),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 8),
        Text('Raw Anomaly Score: ${p.rawAnomalyScore.toStringAsFixed(3)} · Work ID: ${p.workId}',
            style: const TextStyle(color: Colors.grey, fontSize: 11)),
      ],
    );
  }

  String _formatFeatureName(String key) {
    return key.replaceAll('_', ' ').replaceFirstMapped(RegExp(r'^.'), (m) => m.group(0)!.toUpperCase());
  }

  // ── New Investigation Panel ───────────────────────────────────────────────
  Widget _buildInvestigationPanel(_RiskProject p) {
    return _InvestigationForm(project: p);
  }

  // ── Duplicates Panel ──────────────────────────────────────────────────────
  Widget _buildDuplicatesPanel(_RiskProject p) {
    if (p.duplicateWorkIds.isEmpty && !p.isDuplicate) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_outline, size: 48, color: Color(0xFF43A047)),
            SizedBox(height: 12),
            Text('No Duplicates Found', style: TextStyle(color: Colors.grey, fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.copy_all_outlined, color: Color(0xFF8E24AA)),
              const SizedBox(width: 10),
              Expanded(
                child: Text('Potential Duplicates for Work ID: ${p.workId}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0B1F3A))),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...p.duplicateWorkIds.map((id) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF8E24AA).withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF8E24AA).withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.content_copy, size: 16, color: Color(0xFF8E24AA)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Work ID: $id',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0B1F3A))),
                          const Text('Similar description, amount, and district detected',
                              style: TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () {},
                      child: const Text('View Project', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              )),
          if (p.duplicateWorkIds.isEmpty && p.isDuplicate)
            const Text('This project is marked as a duplicate, but specific IDs were not found.', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 20),
          const Text(
            'Duplicate detection uses cosine similarity on description embeddings + amount and district matching.',
            style: TextStyle(color: Colors.grey, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _emptyPanel(String text) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.table_rows_outlined, size: 48, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(text, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _fieldSection(String title, List<_Field> fields) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF2F6FED))),
        const SizedBox(height: 8),
        ...fields.map((f) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(width: 130, child: Text(f.label, style: const TextStyle(color: Colors.grey, fontSize: 12))),
                  Expanded(child: Text(f.value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Color(0xFF0B1F3A)))),
                ],
              ),
            )),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Investigation Form — embedded in Panel 3
// DB table: investigations
//   investigation_id, work_id, auditor_id, date_of_investigation,
//   physical_verification_done, findings, risk_indicator,
//   evidence_description, recommended_action, status
// ─────────────────────────────────────────────────────────────────────────────
class _InvestigationForm extends StatefulWidget {
  final _RiskProject project;
  const _InvestigationForm({required this.project});

  @override
  State<_InvestigationForm> createState() => _InvestigationFormState();
}

class _InvestigationFormState extends State<_InvestigationForm> {
  final _formKey = GlobalKey<FormState>();
  final _observationCtrl = TextEditingController();
  final _remarksCtrl = TextEditingController();
  String _workStatus = 'In Progress';
  bool _submitting = false;

  // Mock Evidence States
  bool _photoSelected = false;
  bool _docSelected = false;

  @override
  void dispose() {
    _observationCtrl.dispose();
    _remarksCtrl.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    await Future.delayed(const Duration(seconds: 1)); // Simulate API call
    // TODO: backend — POST /api/investigations with fields
    if (mounted) {
      setState(() {
        _submitting = false;
        _photoSelected = false;
        _docSelected = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Investigation submitted for Work ID ${widget.project.workId}'),
          backgroundColor: const Color(0xFF43A047),
        ),
      );
      _formKey.currentState!.reset();
      _observationCtrl.clear();
      _remarksCtrl.clear();
      _workStatus = 'In Progress';
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Context banner
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF0B1F3A).withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.edit_note, color: Color(0xFF0B1F3A), size: 18),
                  const SizedBox(width: 8),
                  Text('New Investigation — Work ID: ${widget.project.workId}',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF0B1F3A))),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Observation
            _formLabel('Observation *'),
            TextFormField(
              controller: _observationCtrl,
              maxLines: 4,
              decoration: _fDec('Enter your detailed observations here...'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Observation is required' : null,
            ),
            const SizedBox(height: 14),

            // Work Status
            _formLabel('Work Status'),
            DropdownButtonFormField<String>(
              initialValue: _workStatus,
              decoration: _fDec('Select current status of work'),
              items: ['Not Started', 'In Progress', 'Halted', 'Completed']
                  .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                  .toList(),
              onChanged: (v) => setState(() => _workStatus = v!),
            ),
            const SizedBox(height: 14),

            // Remarks
            _formLabel('Remarks (Optional)'),
            TextFormField(
              controller: _remarksCtrl,
              maxLines: 2,
              decoration: _fDec('Any additional remarks...'),
            ),
            const SizedBox(height: 24),

            // Evidence Section
            const Text('Evidence', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0B1F3A))),
            const SizedBox(height: 10),

            _buildEvidenceTile(
              title: 'Photo Evidence',
              icon: Icons.camera_alt_outlined,
              isSelected: _photoSelected,
              onTap: () async {
                // Simulate file picker
                await Future.delayed(const Duration(milliseconds: 500));
                setState(() => _photoSelected = !_photoSelected);
              },
            ),
            const SizedBox(height: 10),

            _buildEvidenceTile(
              title: 'Document Evidence',
              icon: Icons.description_outlined,
              isSelected: _docSelected,
              onTap: () async {
                // Simulate file picker
                await Future.delayed(const Duration(milliseconds: 500));
                setState(() => _docSelected = !_docSelected);
              },
            ),
            const SizedBox(height: 10),

            _buildEvidenceTile(
              title: 'Location / Tracking',
              icon: Icons.location_on_outlined,
              isSelected: true,
              subtitle: 'Coordinates attached automatically',
              onTap: () {},
            ),

            const SizedBox(height: 24),

            // Submit
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0B1F3A),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: _submitting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Submit Investigation', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEvidenceTile({
    required String title,
    required IconData icon,
    required bool isSelected,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF43A047).withValues(alpha: 0.05) : Colors.white,
          border: Border.all(
            color: isSelected ? const Color(0xFF43A047).withValues(alpha: 0.3) : Colors.grey.shade300,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? const Color(0xFF43A047) : Colors.grey.shade600, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.w600, color: isSelected ? const Color(0xFF43A047) : const Color(0xFF0B1F3A), fontSize: 13)),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  ],
                ],
              ),
            ),
            if (isSelected && subtitle == null)
              const Icon(Icons.check_circle, color: Color(0xFF43A047), size: 18)
            else if (subtitle == null)
              const Text('Select File', style: TextStyle(fontSize: 12, color: Color(0xFF2F6FED))),
          ],
        ),
      ),
    );
  }

  Widget _formLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Color(0xFF0B1F3A))),
      );



  InputDecoration _fDec(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade500),
        filled: true,
        fillColor: const Color(0xFFF5F7FA),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF2F6FED))),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Mobile Detail Screen (push from Panel 1 on mobile)
// ─────────────────────────────────────────────────────────────────────────────
class _MobileProjectDetail extends StatefulWidget {
  final _RiskProject project;
  const _MobileProjectDetail({required this.project});

  @override
  State<_MobileProjectDetail> createState() => _MobileProjectDetailState();
}

class _MobileProjectDetailState extends State<_MobileProjectDetail>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.project;
    return Scaffold(
      appBar: AppBar(
        title: Text('Work ID: ${p.workId}'),
        backgroundColor: const Color(0xFF0B1F3A),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: const Color(0xFF2F6FED),
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(text: 'Details & Why Flagged'),
            Tab(text: 'Investigation'),
          ],
        ),
      ),
      backgroundColor: const Color(0xFFF5F7FA),
      body: TabBarView(
        controller: _tabs,
        children: [
          // Tab 1: Details + Why Flagged
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _RiskScoreBar(score: p.riskScore),
                const SizedBox(height: 16),
                _mobileDetailRow('Work ID', p.workId),
                _mobileDetailRow('MP Name', p.mpName),
                _mobileDetailRow('State', p.state),
                _mobileDetailRow('District', p.district),
                _mobileDetailRow('Amount', '₹ ${(p.recommendedAmount / 100000).toStringAsFixed(2)} L'),
                _mobileDetailRow('Completion', p.completionDate.isEmpty ? '(missing)' : p.completionDate),
                _mobileDetailRow('Has Images', p.hasImages ? 'Yes ✓' : 'No ✗'),
                if (p.anomalyFlag) ...[
                  const SizedBox(height: 16),
                  const Text('Detected Anomalies', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 8),
                  ...p.riskReasons.asMap().entries.map((e) => _ReasonTile(number: e.key + 1, reason: e.value)),
                  if (p.duplicateWorkIds.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Center(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => _MobileDuplicatesScreen(project: p)),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2F6FED),
                          foregroundColor: Colors.white,
                          shape: const StadiumBorder(),
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                        ),
                        child: Text('Duplicates (${p.duplicateWorkIds.length})'),
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
          // Tab 2: Investigation Form
          _InvestigationForm(project: p),
        ],
      ),
    );
  }

  Widget _mobileDetailRow(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 110, child: Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13))),
            Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF0B1F3A)))),
          ],
        ),
      );

}

class _MobileDuplicatesScreen extends StatelessWidget {
  final _RiskProject project;
  const _MobileDuplicatesScreen({required this.project});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Duplicates'),
        backgroundColor: const Color(0xFF0B1F3A),
        foregroundColor: Colors.white,
      ),
      backgroundColor: const Color(0xFFF5F7FA),
      body: _buildDuplicatesPanel(project),
    );
  }

  Widget _buildDuplicatesPanel(_RiskProject p) {
    if (p.duplicateWorkIds.isEmpty && !p.isDuplicate) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_outline, size: 48, color: Color(0xFF43A047)),
            SizedBox(height: 12),
            Text('No Duplicates Found', style: TextStyle(color: Colors.grey, fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.copy_all_outlined, color: Color(0xFF8E24AA)),
              const SizedBox(width: 10),
              Expanded(
                child: Text('Potential Duplicates for Work ID: ${p.workId}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0B1F3A))),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...p.duplicateWorkIds.map((id) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF8E24AA).withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF8E24AA).withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.content_copy, size: 16, color: Color(0xFF8E24AA)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Work ID: $id',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0B1F3A))),
                          const Text('Similar description, amount, and district detected',
                              style: TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () {},
                      child: const Text('View Project', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              )),
          if (p.duplicateWorkIds.isEmpty && p.isDuplicate)
            const Text('This project is marked as a duplicate, but specific IDs were not found.', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Small Widgets
// ─────────────────────────────────────────────────────────────────────────────

class _RiskScoreBar extends StatelessWidget {
  final int score;
  const _RiskScoreBar({required this.score});

  Color get _color {
    if (score >= 90) return const Color(0xFFE53935);
    if (score >= 75) return const Color(0xFFF57C00);
    if (score >= 50) return const Color(0xFFF9A825);
    return const Color(0xFF43A047);
  }

  String get _label {
    if (score >= 90) return 'Critical';
    if (score >= 75) return 'High';
    if (score >= 50) return 'Medium';
    return 'Low';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Risk Score: ', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
            Text('$score / 100', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: _color)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(color: _color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
              child: Text(_label, style: TextStyle(color: _color, fontWeight: FontWeight.bold, fontSize: 12)),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: score / 100,
            minHeight: 8,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(_color),
          ),
        ),
      ],
    );
  }
}

class _ReasonTile extends StatelessWidget {
  final int number;
  final String reason;
  const _ReasonTile({required this.number, required this.reason});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: const Color(0xFFE53935).withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text('$number', style: const TextStyle(color: Color(0xFFE53935), fontSize: 11, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(reason, style: const TextStyle(fontSize: 13, color: Colors.black87))),
        ],
      ),
    );
  }
}



class _ProjectListTile extends StatelessWidget {
  final _RiskProject project;
  final bool isSelected;
  final VoidCallback onTap;
  const _ProjectListTile({required this.project, required this.isSelected, required this.onTap});

  Color get _statusColor {
    if (project.isDuplicate) return const Color(0xFF8E24AA);
    if (project.anomalyFlag) return const Color(0xFFE53935);
    return const Color(0xFF43A047);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF2F6FED).withValues(alpha: 0.07) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isSelected ? const Color(0xFF2F6FED) : Colors.grey.shade200,
          width: isSelected ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Work ID: ${project.workId}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0B1F3A))),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: _statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(project.status, style: TextStyle(color: _statusColor, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Text(project.mpName, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              Text('${project.state} · ${project.district}', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
              const SizedBox(height: 6),
              Row(
                children: [
                  Text('Risk Score: ', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                  Text('${project.riskScore}/100',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: _statusColor)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Data Models (placeholder, will be replaced by API model)
// ─────────────────────────────────────────────────────────────────────────────

class _RiskProject {
  final String workId;
  final String mpName;
  final String state;
  final String district;
  final String description;
  final double recommendedAmount;
  final String completionDate;
  final bool hasImages;
  final int riskScore;
  final bool anomalyFlag;
  final bool isDuplicate;
  final List<String> riskReasons;
  final Map<String, String> mlFeatures;
  final String modelVersion;
  final double rawAnomalyScore;
  final List<String> duplicateWorkIds;
  final String status;

  const _RiskProject({
    required this.workId,
    required this.mpName,
    required this.state,
    required this.district,
    required this.description,
    required this.recommendedAmount,
    required this.completionDate,
    required this.hasImages,
    required this.riskScore,
    required this.anomalyFlag,
    required this.isDuplicate,
    required this.riskReasons,
    required this.mlFeatures,
    required this.modelVersion,
    required this.rawAnomalyScore,
    required this.duplicateWorkIds,
    required this.status,
  });
}

class _Field {
  final String label;
  final String value;
  const _Field(this.label, this.value);
}
