package main

// appShellCSS contains the Swiss minimalist design stylesheet for the mobile simulator.
// Invariant: ZERO half-space characters (\u200c) allowed.
// Culture: fa-IR, Tehran timezone & Iranian financial market regulations.
const appShellCSS = `
:root {
  --bg-carbon: #0D0F12;
  --surface-slate: #161920;
  --card-dark: #1C202A;
  --card-light: #222733;
  --border-color: #2A303F;
  --gold-accent: #D4AF37;
  --gold-bright: #FFD700;
  --signal-emerald: #00E676;
  --signal-amber: #FFB300;
  --signal-coral: #FF5252;
  --signal-blue: #40C4FF;
  --text-primary: #ECEFF4;
  --text-secondary: #9099A8;
  --text-muted: #5F687A;
}

* {
  box-sizing: border-box;
  margin: 0;
  padding: 0;
  font-family: system-ui, -apple-system, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif;
  -webkit-tap-highlight-color: transparent;
}

body {
  background-color: #060709;
  color: var(--text-primary);
  display: flex;
  justify-content: center;
  align-items: center;
  min-height: 100vh;
  padding: 10px;
}

/* Mobile Frame Simulation */
.mobile-wrapper {
  width: 100%;
  max-width: 440px;
  height: 900px;
  max-height: 96vh;
  background-color: var(--bg-carbon);
  border: 1px solid var(--border-color);
  border-radius: 28px;
  display: flex;
  flex-direction: column;
  overflow: hidden;
  box-shadow: 0 20px 50px rgba(0,0,0,0.8), 0 0 0 1px rgba(212,175,55,0.15);
  position: relative;
}

/* Top Terminal Bar */
.app-header {
  background-color: var(--surface-slate);
  border-bottom: 1px solid var(--border-color);
  padding: 12px 16px;
  display: flex;
  justify-content: space-between;
  align-items: center;
  z-index: 10;
}

.brand-badge {
  display: flex;
  align-items: center;
  gap: 8px;
}

.status-dot {
  width: 8px;
  height: 8px;
  border-radius: 50%;
  background-color: var(--signal-emerald);
  box-shadow: 0 0 8px var(--signal-emerald);
}

.brand-title {
  font-size: 13px;
  font-weight: 700;
  letter-spacing: 0.5px;
  color: var(--text-primary);
  font-family: monospace;
}

.tehran-clock-pill {
  background-color: var(--card-dark);
  border: 1px solid var(--border-color);
  padding: 4px 10px;
  border-radius: 4px;
  font-size: 11px;
  font-weight: 700;
  color: var(--gold-accent);
  font-family: monospace;
}

/* Content Area */
.content-body {
  flex: 1;
  overflow-y: auto;
  padding: 16px;
  display: flex;
  flex-direction: column;
  gap: 16px;
}

/* Tab View Switcher */
.tab-view {
  display: none;
  flex-direction: column;
  gap: 14px;
}

.tab-view.active {
  display: flex;
}

/* Cards & Panels */
.card {
  background-color: var(--surface-slate);
  border: 1px solid var(--border-color);
  border-radius: 8px;
  padding: 14px;
  display: flex;
  flex-direction: column;
  gap: 10px;
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
  padding: 2px 8px;
  border-radius: 4px;
  font-size: 11px;
  font-weight: 700;
  font-family: monospace;
}

.pill-emerald { background: rgba(0,230,118,0.12); color: var(--signal-emerald); border: 1px solid rgba(0,230,118,0.3); }
.pill-amber   { background: rgba(255,179,0,0.12); color: var(--signal-amber); border: 1px solid rgba(255,179,0,0.3); }
.pill-coral   { background: rgba(255,82,82,0.12); color: var(--signal-coral); border: 1px solid rgba(255,82,82,0.3); }
.pill-blue    { background: rgba(64,196,255,0.12); color: var(--signal-blue); border: 1px solid rgba(64,196,255,0.3); }

/* Form Controls */
.form-group {
  display: flex;
  flex-direction: column;
  gap: 6px;
}

.form-label {
  font-size: 11px;
  color: var(--text-secondary);
  font-weight: 600;
}

.input-field {
  background-color: var(--bg-carbon);
  border: 1px solid var(--border-color);
  border-radius: 4px;
  padding: 8px 12px;
  color: var(--text-primary);
  font-size: 13px;
  font-family: monospace;
  outline: none;
}

.input-field:focus {
  border-color: var(--gold-accent);
}

/* Carat Chip Selector */
.chip-row {
  display: flex;
  gap: 6px;
}

.chip {
  flex: 1;
  background-color: var(--card-dark);
  border: 1px solid var(--border-color);
  border-radius: 4px;
  padding: 6px;
  font-size: 11px;
  font-weight: 700;
  text-align: center;
  cursor: pointer;
  color: var(--text-secondary);
}

.chip.active {
  background-color: rgba(212,175,55,0.15);
  border-color: var(--gold-accent);
  color: var(--gold-bright);
}

/* Legal Breakdown Table */
.receipt-table {
  display: flex;
  flex-direction: column;
  gap: 6px;
  background-color: var(--card-dark);
  padding: 10px;
  border-radius: 6px;
  border: 1px solid var(--border-color);
  font-size: 12px;
}

.receipt-row {
  display: flex;
  justify-content: space-between;
  color: var(--text-secondary);
}

.receipt-row.highlight {
  color: var(--gold-bright);
  font-weight: 700;
  font-size: 13px;
  border-top: 1px dashed var(--border-color);
  padding-top: 6px;
  margin-top: 2px;
}

/* Bottom Tab Bar */
.bottom-nav {
  background-color: var(--surface-slate);
  border-top: 1px solid var(--border-color);
  display: flex;
  justify-content: space-around;
  padding: 8px 0;
  z-index: 10;
}

.nav-item {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 4px;
  cursor: pointer;
  color: var(--text-muted);
  font-size: 10px;
  font-weight: 600;
  flex: 1;
}

.nav-item.active {
  color: var(--gold-accent);
}

.nav-icon {
  font-size: 18px;
}

/* Buttons */
.btn {
  background-color: var(--gold-accent);
  color: #0D0F12;
  border: none;
  border-radius: 4px;
  padding: 10px;
  font-weight: 700;
  font-size: 12px;
  cursor: pointer;
  display: flex;
  justify-content: center;
  align-items: center;
  gap: 6px;
}

.btn:active {
  opacity: 0.85;
}

/* Shamsi Date Modal Sheet */
.modal-overlay {
  display: none;
  position: absolute;
  top: 0; left: 0; right: 0; bottom: 0;
  background: rgba(0,0,0,0.7);
  z-index: 100;
  align-items: flex-end;
}

.modal-sheet {
  background: var(--surface-slate);
  border-top: 1px solid var(--gold-accent);
  border-radius: 16px 16px 0 0;
  width: 100%;
  padding: 16px;
  box-shadow: 0 -10px 30px rgba(0,0,0,0.8);
}

.calendar-grid {
  display: grid;
  grid-template-columns: repeat(7, 1fr);
  gap: 4px;
  text-align: center;
  font-size: 11px;
}

.cal-cell {
  padding: 8px 2px;
  border-radius: 4px;
  cursor: pointer;
}

.cal-cell.header {
  font-weight: 700;
  color: var(--text-muted);
}

.cal-cell:not(.header):hover {
  background: var(--card-light);
}

.cal-cell.active {
  background: var(--gold-accent);
  color: #0D0F12;
  font-weight: 700;
}
`
