/// Breakpoint constants for responsive layout switching.
///
/// Usage:
///   LayoutBuilder(builder: (context, constraints) {
///     if (constraints.maxWidth >= kDesktopBreakpoint) { ... }
///   })
library;

/// Screens wider than this show the sidebar + desktop layout.
const double kDesktopBreakpoint = 900.0;

/// Fully expanded sidebar width.
const double kSidebarExpandedWidth = 240.0;

/// Collapsed sidebar width (icons only).
const double kSidebarCollapsedWidth = 68.0;
