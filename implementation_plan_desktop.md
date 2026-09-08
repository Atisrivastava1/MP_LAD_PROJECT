# MPLADS Sentinel — PC Desktop Interface Roadmap

## Goal
Build a fully responsive Flutter Web layout that:
- Uses the **same codebase** as the mobile app
- Shows a **collapsible left sidebar** on wide screens (≥900px)
- Shows the **bottom nav bar** on narrow screens (<900px) — keeping the existing mobile experience
- Has an **account/profile section in the top header** on every screen
- Matches the **navy #0B1F3A + light body** colour scheme from the mobile designs

---

## Phase 0 — Foundation (Responsive Shell)

### 0A. Breakpoint constants
File: `lib/utils/breakpoints.dart` [NEW]
- `kDesktopWidth = 900.0` — sidebar visible above this
- `kSidebarExpandedWidth = 240.0`
- `kSidebarCollapsedWidth = 68.0`

### 0B. `AppShell` widget — the master layout wrapper
File: `lib/widgets/app_shell.dart` [NEW]

This replaces `Scaffold` for all post-login screens. It wraps content with:
- **Left sidebar** (desktop) OR **bottom nav bar** (mobile)
- **Top AppBar** with:
  - Hamburger to toggle sidebar collapse/expand
  - Page title
  - Notification bell
  - **Profile avatar chip** → opens a `ProfileDrawer` overlay

### 0C. `SidebarNav` widget
File: `lib/widgets/sidebar_nav.dart` [NEW]

Collapsible sidebar with:
| Icon | Label | Route |
|------|-------|-------|
| 🏠 | Dashboard | role-specific |
| 📁 | Projects | risk_project_list / project_records |
| 🔍 | Investigation | investigation_form |
| 📊 | Reports | audit_report / reports_export |
| ⚙️ | Settings | (placeholder) |

Collapsed = icon only (68px wide). Expanded = icon + label (240px wide). Hover expands.

### 0D. `ProfileHeaderChip` + `ProfileDrawer`
File: `lib/widgets/profile_header.dart` [NEW]

Top-right of every screen's AppBar:
```
[ 👤 ] [ Shri Ramesh Kumar ▾ ]
         Auditor · AUD-2024-01
```
Tapping opens a slide-out drawer (right side) with:
- Circular avatar placeholder (grey, person icon)
- Full name
- Role badge (colour-coded)
- Employee/Officer ID placeholder
- **Logout button** (red)
- **View Profile** button

---

## Phase 1 — Login Screen (Desktop)

File: `lib/screens/login.dart` [MODIFY]

**Mobile** (current): Full-screen dark navy header + white card below.
**Desktop layout**:
- **Left half** (50%): Navy panel with Ashoka emblem, MPLADS title, tagline, "Secure · Transparent · Accountable"
- **Right half** (50%): White login card centred — username, password, role selector, LOGIN button

Uses `LayoutBuilder` to switch between layouts at `kDesktopWidth`.

---

## Phase 2 — Auditor Screens (10 screens)

All screens use `AppShell`. Each gets a page title in the AppBar.

### 2.1 Auditor Dashboard
File: `lib/screens/auditor_dashboard.dart` [MODIFY]

**Desktop layout** (3-column grid):
- **Top row**: 4 stat cards (Total, Critical, High, Under Review) in a `Row`
- **Middle row**:
  - Left 60%: `Risk Overview` donut chart + legend
  - Right 40%: `Recent Alerts` scrollable list
- **Bottom row**: Quick action buttons

### 2.2 Risk Project List
File: `lib/screens/risk_project_list.dart` [MODIFY]

**Desktop layout**:
- Left panel (35%): Search bar + filter chips (Critical/High/Medium/Low) + project list cards
- Right panel (65%): **Project detail preview pane** (shows selected project details inline — no navigation needed)

### 2.3 Project Details
File: `lib/screens/project_details.dart` [MODIFY]

**Desktop layout** (2-column):
- Left: Project metadata table (Constituency, Scheme, Agency, Cost, Dates, Status, Location)
- Right: Risk score gauge + Quick Actions (Why Flagged, Start Investigation, View Duplicates)

### 2.4 Risk Analysis (Why Flagged?)
File: `lib/screens/risk_analysis.dart` [MODIFY]

**Desktop layout** (2-column):
- Left: ML risk header card (score, level, progress bar)
- Right: Anomaly cards in a scrollable column

### 2.5 Investigation Form
File: `lib/screens/investigation_form.dart` [MODIFY]

**Desktop layout**: Centred 720px wide form card (not full-width).

### 2.6 Evidence Upload
File: `lib/screens/evidence_upload.dart` [MODIFY]

**Desktop layout** (2-column):
- Left: Photo grid upload
- Right: Document upload + GPS location

### 2.7 Review / Decision
File: `lib/screens/review_decision.dart` [MODIFY]

**Desktop layout**: Centred 720px wide card.

### 2.8 Audit History
File: `lib/screens/audit_history.dart` [MODIFY]

**Desktop layout**: Timeline list with wider cards showing more metadata.

### 2.9 Audit Report
File: `lib/screens/audit_report.dart` [MODIFY]

**Desktop layout** (2-column):
- Left: Summary + risk + anomalies
- Right: Audit trail + Export button

---

## Phase 3 — Data Manager Screens (10 screens)

All screens use `AppShell`. Sidebar shows Data Manager nav items.

### 3.1 Data Manager Dashboard
File: `lib/screens/data_manager_dashboard.dart` [MODIFY]

**Desktop layout**:
- Top: 3 stat cards (Uploaded, Pending, Processed)
- Middle-left: Data Overview donut chart (Completed/Ongoing/Pending)
- Middle-right: Risk distribution (High/Medium/Low)
- Bottom: Quick upload + history buttons

### 3.2 Upload Project Data
File: `lib/screens/upload_project.dart` [MODIFY]

**Desktop layout**:
- Left: Drag-and-drop upload zone (large) + Guidelines list
- Right: Manual entry form (tabs)

### 3.3 Validation & Preview
File: `lib/screens/project_data_validation.dart` [MODIFY]

**Desktop layout**: Full-width data table (5 columns) instead of cards.

### 3.4 Import Progress
File: `lib/screens/upload_history.dart` [MODIFY]

**Desktop layout**: Step tracker (horizontal stepper) + file history table.

### 3.5 Data Quality (new screen needed)
File: `lib/screens/data_quality.dart` [NEW]

Gauge + quality checks table.

### 3.6 Project Records List
File: `lib/screens/risk_project_list.dart` (reused with Data Manager mode)

**Desktop layout**: Full data table with sortable columns.

### 3.7–3.10 Project Details / AI Analysis / Reports
Similar 2-column desktop layouts.

---

## Shared Widgets to Create

| Widget | File | Purpose |
|--------|------|---------|
| `AppShell` | `lib/widgets/app_shell.dart` | Master responsive layout |
| `SidebarNav` | `lib/widgets/sidebar_nav.dart` | Collapsible left nav |
| `ProfileHeaderChip` | `lib/widgets/profile_header.dart` | Top-right user info |
| `ProfileDrawerPanel` | same file | Slide-out profile panel |
| `StatCard` | `lib/widgets/stat_card.dart` | Reusable stat card |
| `RiskBadge` | `lib/widgets/risk_badge.dart` | Critical/High/Medium/Low chip |
| `SectionHeader` | `lib/widgets/section_header.dart` | Section title + divider |
| `ResponsiveGrid` | `lib/widgets/responsive_grid.dart` | 1-col mobile / N-col desktop |

---

## Implementation Order

```
Phase 0  →  AppShell + SidebarNav + ProfileHeader  (foundation)
Phase 1  →  Login screen (split-panel desktop)
Phase 2  →  Auditor Dashboard (most important demo screen)
Phase 2  →  Risk Project List (master-detail panel)
Phase 2  →  Project Details + Risk Analysis
Phase 2  →  Investigation + Evidence + Review + History + Report
Phase 3  →  Data Manager Dashboard
Phase 3  →  Upload + Validation + Data Quality + Records + Reports
```

---

## Key Design Rules (from mobile reference)
1. Navy `#0B1F3A` sidebar + top bar — matches mobile header colour
2. Risk colours: Critical `#D32F2F`, High `#F57C00`, Medium `#F9A825`, Low `#388E3C`
3. Card border-radius: 12px
4. Font: Roboto (already set in theme)
5. Body background: `#F5F7FA`
6. Profile chip in top-right of AppBar on **every** screen (no exceptions)

---

> **Estimated files**: ~20 new/modified files  
> **Approach**: `LayoutBuilder` checks width at each screen. No separate codebase — one Flutter app, one set of widgets.
