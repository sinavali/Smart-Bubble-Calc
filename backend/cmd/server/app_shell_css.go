package main

// appShellCSS contains the Swiss minimalist design stylesheet with Dark & Light modes.
// Invariant: ZERO half-space characters (\u200c) allowed.
// Culture: fa-IR, Tehran timezone & Iranian financial market regulations.
const appShellCSS = `
@import url('https://cdn.jsdelivr.net/gh/rastikerdar/vazirmatn@v33.003/Vazirmatn-font-face.css');

:root {
  --bg-app: #060709;
  --bg-carbon: #0D0F12;
  --surface-slate: #15181F;
  --card-dark: #1C202A;
  --card-light: #222735;
  --border-color: #272D3B;
  --border-subtle: #1F2430;
  --gold-accent: #D4AF37;
  --gold-bright: #F59E0B;
  --gold-glow: rgba(212, 175, 55, 0.2);
  --signal-emerald: #10B981;
  --signal-amber: #F59E0B;
  --signal-coral: #EF4444;
  --signal-blue: #38BDF8;
  --text-primary: #F1F5F9;
  --text-secondary: #94A3B8;
  --text-muted: #64748B;
  --shadow-frame: 0 25px 60px rgba(0,0,0,0.85), 0 0 0 1px rgba(212,175,55,0.18);
  --shadow-card: 0 4px 12px rgba(0,0,0,0.3);
  --nav-active-bg: rgba(212,175,55,0.12);
}

[data-theme="light"] {
  --bg-app: #E2E8F0;
  --bg-carbon: #F8FAFC;
  --surface-slate: #FFFFFF;
  --card-dark: #F1F5F9;
  --card-light: #FFFFFF;
  --border-color: #CBD5E1;
  --border-subtle: #E2E8F0;
  --gold-accent: #B45309;
  --gold-bright: #D97706;
  --gold-glow: rgba(180, 83, 9, 0.15);
  --signal-emerald: #059669;
  --signal-amber: #D97706;
  --signal-coral: #DC2626;
  --signal-blue: #0284C7;
  --text-primary: #0F172A;
  --text-secondary: #475569;
  --text-muted: #64748B;
  --shadow-frame: 0 20px 45px rgba(15,23,42,0.15), 0 0 0 1px rgba(180,83,9,0.2);
  --shadow-card: 0 2px 8px rgba(15,23,42,0.06);
  --nav-active-bg: rgba(180,83,9,0.1);
}

* {
  box-sizing: border-box;
  margin: 0;
  padding: 0;
  font-family: 'IRANSansX', 'IRANSans', 'Vazirmatn', -apple-system, BlinkMacSystemFont, 'Segoe UI', Tahoma, sans-serif;
  -webkit-tap-highlight-color: transparent;
  transition: background-color 0.25s ease, border-color 0.25s ease, color 0.25s ease;
}

body {
  background-color: var(--bg-app);
  color: var(--text-primary);
  display: flex;
  justify-content: center;
  align-items: center;
  min-height: 100vh;
  padding: 12px;
  direction: rtl;
}

/* Mobile Frame Simulation */
.mobile-wrapper {
  width: 100%;
  max-width: 440px;
  height: 920px;
  max-height: 97vh;
  background-color: var(--bg-carbon);
  border: 1px solid var(--border-color);
  border-radius: 32px;
  display: flex;
  flex-direction: column;
  overflow: hidden;
  box-shadow: var(--shadow-frame);
  position: relative;
}

/* Top App Header */
.app-header {
  background-color: var(--surface-slate);
  border-bottom: 1px solid var(--border-color);
  padding: 12px 18px;
  display: flex;
  justify-content: space-between;
  align-items: center;
  z-index: 20;
}

.brand-badge {
  display: flex;
  align-items: center;
  gap: 10px;
}

.pulse-wrapper {
  position: relative;
  width: 10px;
  height: 10px;
}

.pulse-dot {
  width: 10px;
  height: 10px;
  border-radius: 50%;
  background-color: var(--signal-emerald);
}

.pulse-ring {
  position: absolute;
  top: -3px;
  left: -3px;
  width: 16px;
  height: 16px;
  border-radius: 50%;
  border: 2px solid var(--signal-emerald);
  animation: pulseAnimation 2s infinite ease-out;
}

@keyframes pulseAnimation {
  0% { transform: scale(0.6); opacity: 1; }
  100% { transform: scale(1.6); opacity: 0; }
}

.brand-title {
  font-size: 13px;
  font-weight: 800;
  letter-spacing: 0.3px;
  color: var(--text-primary);
}

.header-actions {
  display: flex;
  align-items: center;
  gap: 8px;
}

.tehran-clock-pill {
  background-color: var(--card-dark);
  border: 1px solid var(--border-color);
  padding: 4px 10px;
  border-radius: 6px;
  font-size: 11px;
  font-weight: 700;
  color: var(--gold-accent);
  font-variant-numeric: tabular-nums;
  letter-spacing: 0.5px;
}

.theme-toggle-btn {
  background: var(--card-dark);
  border: 1px solid var(--border-color);
  color: var(--text-primary);
  width: 32px;
  height: 32px;
  border-radius: 8px;
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  outline: none;
}

.theme-toggle-btn:hover {
  border-color: var(--gold-accent);
  transform: rotate(15deg);
}

/* Content Area */
.content-body {
  flex: 1;
  overflow-y: auto;
  padding: 16px;
  display: flex;
  flex-direction: column;
  gap: 14px;
}

/* Tab Views with Animations */
.tab-view {
  display: none;
  flex-direction: column;
  gap: 14px;
  animation: tabFadeIn 0.28s cubic-bezier(0.16, 1, 0.3, 1);
}

.tab-view.active {
  display: flex;
}

@keyframes tabFadeIn {
  from { opacity: 0; transform: translateY(6px); }
  to { opacity: 1; transform: translateY(0); }
}

/* Cards & Panels */
.card {
  background-color: var(--surface-slate);
  border: 1px solid var(--border-color);
  border-radius: 12px;
  padding: 14px 16px;
  display: flex;
  flex-direction: column;
  gap: 10px;
  box-shadow: var(--shadow-card);
}

.card:hover {
  border-color: var(--border-subtle);
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

/* Metric Pill Badges */
.pill {
  display: inline-flex;
  align-items: center;
  gap: 5px;
  padding: 3px 8px;
  border-radius: 6px;
  font-size: 11px;
  font-weight: 700;
  font-variant-numeric: tabular-nums;
}

.pill-emerald { background: rgba(16,185,129,0.12); color: var(--signal-emerald); border: 1px solid rgba(16,185,129,0.3); }
.pill-amber   { background: rgba(245,158,11,0.12); color: var(--signal-amber); border: 1px solid rgba(245,158,11,0.3); }
.pill-coral   { background: rgba(239,68,68,0.12); color: var(--signal-coral); border: 1px solid rgba(239,68,68,0.3); }
.pill-blue    { background: rgba(56,189,248,0.12); color: var(--signal-blue); border: 1px solid rgba(56,189,248,0.3); }

/* Form Controls */
.form-group {
  display: flex;
  flex-direction: column;
  gap: 6px;
}

.form-label {
  font-size: 11px;
  color: var(--text-secondary);
  font-weight: 700;
}

.input-field {
  background-color: var(--card-dark);
  border: 1px solid var(--border-color);
  border-radius: 8px;
  padding: 9px 12px;
  color: var(--text-primary);
  font-size: 13px;
  outline: none;
  font-variant-numeric: tabular-nums;
}

.input-field:focus {
  border-color: var(--gold-accent);
  box-shadow: 0 0 0 2px var(--gold-glow);
}

/* Search Bar with SVG Icon */
.search-wrapper {
  position: relative;
  display: flex;
  align-items: center;
}

.search-icon {
  position: absolute;
  right: 12px;
  color: var(--text-muted);
  pointer-events: none;
}

.search-input {
  width: 100%;
  padding-right: 36px;
  padding-left: 12px;
}

/* Chip Filter Row */
.chip-row {
  display: flex;
  gap: 6px;
  overflow-x: auto;
  padding-bottom: 2px;
}

.chip {
  flex: 1;
  background-color: var(--card-dark);
  border: 1px solid var(--border-color);
  border-radius: 8px;
  padding: 7px 10px;
  font-size: 11px;
  font-weight: 700;
  text-align: center;
  cursor: pointer;
  color: var(--text-secondary);
  white-space: nowrap;
  user-select: none;
}

.chip:hover {
  border-color: var(--gold-accent);
  color: var(--text-primary);
}

.chip.active {
  background-color: var(--nav-active-bg);
  border-color: var(--gold-accent);
  color: var(--gold-bright);
}

/* Receipt & Breakdown Table */
.receipt-table {
  display: flex;
  flex-direction: column;
  gap: 8px;
  background-color: var(--card-dark);
  padding: 12px 14px;
  border-radius: 8px;
  border: 1px solid var(--border-color);
  font-size: 12px;
}

.receipt-row {
  display: flex;
  justify-content: space-between;
  align-items: center;
  color: var(--text-secondary);
  font-variant-numeric: tabular-nums;
}

.receipt-row.highlight {
  color: var(--gold-bright);
  font-weight: 800;
  font-size: 13px;
  border-top: 1px dashed var(--border-color);
  padding-top: 8px;
  margin-top: 4px;
}

/* Bottom Tab Bar */
.bottom-nav {
  background-color: var(--surface-slate);
  border-top: 1px solid var(--border-color);
  display: flex;
  justify-content: space-around;
  padding: 8px 0;
  z-index: 20;
}

.nav-item {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 4px;
  cursor: pointer;
  color: var(--text-muted);
  font-size: 10px;
  font-weight: 700;
  flex: 1;
  position: relative;
}

.nav-item:hover {
  color: var(--text-primary);
}

.nav-item.active {
  color: var(--gold-accent);
}

.nav-icon {
  display: flex;
  align-items: center;
  justify-content: center;
  width: 24px;
  height: 24px;
}

/* Interactive SVG Buttons */
.btn {
  background-color: var(--gold-accent);
  color: #0D0F12;
  border: none;
  border-radius: 8px;
  padding: 10px 14px;
  font-weight: 800;
  font-size: 12px;
  cursor: pointer;
  display: flex;
  justify-content: center;
  align-items: center;
  gap: 8px;
  box-shadow: 0 2px 6px rgba(0,0,0,0.15);
}

[data-theme="light"] .btn {
  color: #FFFFFF;
}

.btn:active {
  transform: scale(0.98);
}

.btn-secondary {
  background-color: var(--card-dark);
  color: var(--text-primary);
  border: 1px solid var(--border-color);
}

.btn-secondary:hover {
  border-color: var(--gold-accent);
}

/* Date Picker Modal */
.modal-overlay {
  display: none;
  position: absolute;
  top: 0; left: 0; right: 0; bottom: 0;
  background: rgba(0,0,0,0.7);
  backdrop-filter: blur(4px);
  z-index: 100;
  align-items: flex-end;
}

.modal-sheet {
  background: var(--surface-slate);
  border-top: 2px solid var(--gold-accent);
  border-radius: 20px 20px 0 0;
  width: 100%;
  padding: 18px 20px;
  box-shadow: 0 -10px 35px rgba(0,0,0,0.6);
  animation: sheetSlideUp 0.28s cubic-bezier(0.16, 1, 0.3, 1);
}

@keyframes sheetSlideUp {
  from { transform: translateY(100%); }
  to { transform: translateY(0); }
}

/* Calendar Grid */
.calendar-grid {
  display: grid;
  grid-template-columns: repeat(7, 1fr);
  gap: 5px;
  text-align: center;
  font-size: 12px;
  margin-top: 10px;
}

.cal-cell {
  padding: 8px 2px;
  border-radius: 6px;
  cursor: pointer;
  font-variant-numeric: tabular-nums;
  font-weight: 600;
}

.cal-cell.header {
  font-weight: 800;
  color: var(--text-muted);
}

.cal-cell:not(.header):hover {
  background: var(--card-light);
}

.cal-cell.active {
  background: var(--gold-accent);
  color: #0D0F12;
  font-weight: 800;
}

[data-theme="light"] .cal-cell.active {
  color: #FFFFFF;
}

/* English Distinct Text */
.en-distinct {
  font-family: monospace, Consolas, sans-serif;
  direction: ltr;
  display: inline-block;
  font-weight: 700;
  letter-spacing: 0.5px;
}

/* Expandable Law Cards */
.law-card {
  border: 1px solid var(--border-color);
  border-radius: 10px;
  background: var(--surface-slate);
  overflow: hidden;
  transition: border-color 0.2s ease;
}

.law-header {
  padding: 12px 14px;
  display: flex;
  justify-content: space-between;
  align-items: center;
  cursor: pointer;
  user-select: none;
}

.law-header:hover {
  background-color: var(--card-dark);
}

.law-chevron {
  transition: transform 0.25s ease;
  color: var(--text-muted);
}

.law-card.expanded .law-chevron {
  transform: rotate(180deg);
}

.law-content {
  display: none;
  padding: 14px;
  border-top: 1px solid var(--border-color);
  background-color: var(--card-dark);
  font-size: 12px;
  line-height: 1.7;
}

.law-card.expanded .law-content {
  display: flex;
  flex-direction: column;
  gap: 10px;
}
`
