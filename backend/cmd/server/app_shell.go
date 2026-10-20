package main

import (
	"fmt"
	"net/http"
	"sync"
)

// handleAppShell serves the zero-overhead, instant-loading Swiss minimalist mobile simulator.
// Invariant: ZERO half-space characters (\u200c) allowed.
// Culture: fa-IR, Tehran timezone & Iranian financial market regulations.
var (
	appShellOnce sync.Once
	appShellHTML string
)

func (s *Server) handleAppShell(w http.ResponseWriter, r *http.Request) {
	if r.URL.Path != "/" {
		http.NotFound(w, r)
		return
	}

	appShellOnce.Do(func() {
		appShellHTML = fmt.Sprintf(appShellTemplate, appShellCSS, appShellJS)
	})

	w.Header().Set("Content-Type", "text/html; charset=utf-8")
	w.WriteHeader(http.StatusOK)
	_, _ = w.Write([]byte(appShellHTML))
}

const appShellTemplate = `<!DOCTYPE html>
<html lang="fa" dir="rtl" data-theme="dark">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>حباب سنج و نبض بازار // Smart Bubble Calc</title>
<style>%s</style>
</head>
<body>

<div class="mobile-wrapper">

  <!-- Header Bar -->
  <div class="app-header">
    <div class="brand-badge">
      <div class="pulse-wrapper">
        <div class="pulse-dot"></div>
        <div class="pulse-ring"></div>
      </div>
      <span class="brand-title">حباب سنج و نبض بازار</span>
    </div>
    <div class="header-actions">
      <div class="tehran-clock-pill" id="tehranClock">۰۰:۰۰:۰۰</div>
      <button class="theme-toggle-btn" id="themeToggleBtn" onclick="toggleTheme()" title="تغییر حالت شب و روز">
        <!-- Sun SVG -->
        <svg id="sunIcon" style="display: none;" viewBox="0 0 24 24" width="16" height="16" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
          <circle cx="12" cy="12" r="5"></circle>
          <line x1="12" y1="1" x2="12" y2="3"></line>
          <line x1="12" y1="21" x2="12" y2="23"></line>
          <line x1="4.22" y1="4.22" x2="5.64" y2="5.64"></line>
          <line x1="18.36" y1="18.36" x2="19.78" y2="19.78"></line>
          <line x1="1" y1="12" x2="3" y2="12"></line>
          <line x1="21" y1="12" x2="23" y2="12"></line>
          <line x1="4.22" y1="19.78" x2="5.64" y2="18.36"></line>
          <line x1="18.36" y1="5.64" x2="19.78" y2="4.22"></line>
        </svg>
        <!-- Moon SVG -->
        <svg id="moonIcon" viewBox="0 0 24 24" width="16" height="16" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
          <path d="M21 12.79A9 9 0 1 1 11.21 3 7 7 0 0 0 21 12.79z"></path>
        </svg>
      </button>
    </div>
  </div>

  <!-- Content Body -->
  <div class="content-body">

    <!-- Tab 1: بازار و حباب سنج -->
    <div class="tab-view active" id="tabMarket">
      <div style="display: flex; justify-content: space-between; align-items: center;">
        <span style="font-size: 13px; font-weight: 800;">تابلو نرخ و حباب طلا و سکه</span>
        <span style="font-size: 11px; color: var(--gold-accent); font-weight: 700;" id="shamsiHeaderDate">۲۸ مهر ۱۴۰۵</span>
      </div>

      <!-- Category Filter Chips -->
      <div class="chip-row">
        <div class="chip active" onclick="setCategoryFilter('all', this)">همه دارایی ها</div>
        <div class="chip" onclick="setCategoryFilter('coins', this)">مسکوکات طلا</div>
        <div class="chip" onclick="setCategoryFilter('gold', this)">طلای خام و اونس</div>
      </div>

      <!-- Quick Search with SVG icon -->
      <div class="search-wrapper">
        <svg class="search-icon" viewBox="0 0 24 24" width="16" height="16" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
          <circle cx="11" cy="11" r="8"></circle>
          <line x1="21" y1="21" x2="16.65" y2="16.65"></line>
        </svg>
        <input type="text" class="input-field search-input" id="marketSearchInput" placeholder="جستجوی سکه، امامی، بهار آزادی، ۱۸ عیار..." oninput="filterAssets()">
      </div>

      <!-- Asset Cards Container -->
      <div id="assetsListContainer" style="display: flex; flex-direction: column; gap: 8px;">
        <!-- Dynamically rendered -->
      </div>
    </div>

    <!-- Tab 2: طلافروشی و فاکتور قانونی -->
    <div class="tab-view" id="tabJewelry">
      <div class="card">
        <div class="card-header">
          <span style="font-size: 13px; font-weight: 800; color: var(--gold-accent);">محاسبه گر فاکتور قانونی طلا</span>
          <span class="pill pill-emerald">ماده ۲۶ ارزش افزوده</span>
        </div>

        <!-- Carat Selection -->
        <div class="form-group">
          <label class="form-label">عیار طلا:</label>
          <div class="chip-row">
            <div class="chip active" onclick="setCarat(750, this)">۱۸ عیار (<span class="en-distinct">750</span>)</div>
            <div class="chip" onclick="setCarat(1000, this)">۲۴ عیار (<span class="en-distinct">999.9</span>)</div>
            <div class="chip" onclick="setCarat(875, this)">۲۱ عیار (<span class="en-distinct">875</span>)</div>
            <div class="chip" onclick="setCarat(740, this)">۷۴۰ متفرقه (<span class="en-distinct">740</span>)</div>
          </div>
        </div>

        <!-- Weight and Price -->
        <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 10px;">
          <div class="form-group">
            <label class="form-label">وزن طلا (گرم):</label>
            <input type="number" id="goldWeight" class="input-field" value="4.250" step="0.001" oninput="calculateJewelry()">
          </div>
          <div class="form-group">
            <label class="form-label">قیمت هر گرم (تومان):</label>
            <input type="number" id="gramPrice" class="input-field" value="4450000" oninput="calculateJewelry()">
          </div>
        </div>

        <!-- Labor & Invoice Date -->
        <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 10px;">
          <div class="form-group">
            <label class="form-label">درصد اجرت ساخت:</label>
            <input type="number" id="laborPct" class="input-field" value="12" step="0.5" oninput="calculateJewelry()">
          </div>
          <div class="form-group">
            <label class="form-label">تاریخ فاکتور:</label>
            <div class="input-field" style="cursor: pointer; display: flex; justify-content: space-between; align-items: center;" onclick="openShamsiPicker()">
              <span id="selectedInvoiceDateDisplay">۲۸ مهر ۱۴۰۵</span>
              <svg viewBox="0 0 24 24" width="16" height="16" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                <rect x="3" y="4" width="18" height="18" rx="2" ry="2"></rect>
                <line x1="16" y1="2" x2="16" y2="6"></line>
                <line x1="8" y1="2" x2="8" y2="6"></line>
                <line x1="3" y1="10" x2="21" y2="10"></line>
              </svg>
            </div>
          </div>
        </div>

        <!-- Breakdown Receipt -->
        <div class="receipt-table">
          <div class="receipt-row"><span>ارزش طلای خام (معاف از مالیات):</span><span id="resRawGold">-</span></div>
          <div class="receipt-row"><span>اجرت ساخت:</span><span id="resLabor">-</span></div>
          <div class="receipt-row"><span>سود فروشنده (۷٪ مصوب صنفی):</span><span id="resProfit">-</span></div>
          <div class="receipt-row"><span>مالیات بر ارزش افزوده (۹٪ بر اجرت و سود):</span><span id="resVat" style="color: var(--signal-amber);">-</span></div>
          <div class="receipt-row highlight"><span>مبلغ کل فاکتور:</span><span id="resTotal" style="color: var(--gold-bright);">-</span></div>
        </div>

        <!-- Price in Persian Words -->
        <div style="font-size: 11px; color: var(--gold-accent); text-align: center; font-weight: 700; min-height: 18px;" id="resWords">-</div>

        <!-- Share / Copy Action with SVG -->
        <button class="btn" onclick="copyReceipt()">
          <svg viewBox="0 0 24 24" width="16" height="16" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
            <rect x="9" y="9" width="13" height="13" rx="2" ry="2"></rect>
            <path d="M5 15H4a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h9a2 2 0 0 1 2 2v1"></path>
          </svg>
          کپی صورتحساب رسمی
        </button>
      </div>
    </div>

    <!-- Tab 3: قوانین رسمی بازار طلا (Official Laws & Regulations) -->
    <div class="tab-view" id="tabLaws">
      <div style="display: flex; justify-content: space-between; align-items: center;">
        <span style="font-size: 13px; font-weight: 800;">قوانین و بخشنامه های رسمی بازار طلا</span>
        <span class="pill pill-emerald" id="lawsCountBadge">۶ قانون معتبر</span>
      </div>

      <!-- Quick Search in Laws with SVG -->
      <div class="search-wrapper">
        <svg class="search-icon" viewBox="0 0 24 24" width="16" height="16" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
          <circle cx="11" cy="11" r="8"></circle>
          <line x1="21" y1="21" x2="16.65" y2="16.65"></line>
        </svg>
        <input type="text" class="input-field search-input" id="lawsSearchInput" placeholder="جستجو در متن قوانین، شماره ماده، بخشنامه..." oninput="filterLaws()">
      </div>

      <!-- Laws Category Filter Chips -->
      <div class="chip-row">
        <div class="chip active" onclick="setLawsCategory('all', this)">همه</div>
        <div class="chip" onclick="setLawsCategory('tax', this)">مالیات و ارزش افزوده</div>
        <div class="chip" onclick="setLawsCategory('guild', this)">سود صنفی (۷٪)</div>
        <div class="chip" onclick="setLawsCategory('aml', this)">مبارزه با پولشویی</div>
        <div class="chip" onclick="setLawsCategory('trade', this)">سامانه جامع تجارت</div>
        <div class="chip" onclick="setLawsCategory('standard', this)">استاندارد و عیار</div>
      </div>

      <!-- Laws Cards Container -->
      <div id="lawsContainer" style="display: flex; flex-direction: column; gap: 8px;">
        <!-- Dynamically rendered -->
      </div>
    </div>

    <!-- Tab 4: مبدل تاریخ و زمان شمسی (Shamsi DateTime Converter) -->
    <div class="tab-view" id="tabDatetime">
      <div class="card">
        <div class="card-header">
          <span style="font-size: 13px; font-weight: 800; color: var(--gold-accent);">مبدل تاریخ و زمان خورشیدی و میلادی</span>
          <span class="pill pill-blue">زمان تهران (IRST/IRDT)</span>
        </div>

        <!-- Quick Presets -->
        <div style="display: flex; gap: 6px;">
          <button class="btn btn-secondary" style="flex: 1; padding: 6px; font-size: 11px;" onclick="setPresetDate('now')">هم اکنون</button>
          <button class="btn btn-secondary" style="flex: 1; padding: 6px; font-size: 11px;" onclick="setPresetDate('start_of_day')">ابتدای امروز</button>
          <button class="btn btn-secondary" style="flex: 1; padding: 6px; font-size: 11px;" onclick="setPresetDate('yesterday')">دیروز</button>
        </div>

        <!-- Interactive Shamsi DateTime Picker Selectors -->
        <div class="form-group">
          <label class="form-label">انتخاب تاریخ و ساعت شمسی:</label>
          <div style="display: grid; grid-template-columns: 2fr 3fr 2fr; gap: 6px; margin-bottom: 6px;">
            <select id="dtYear" class="input-field" onchange="runDatetimeConvert()"></select>
            <select id="dtMonth" class="input-field" onchange="runDatetimeConvert()"></select>
            <select id="dtDay" class="input-field" onchange="runDatetimeConvert()"></select>
          </div>
          <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 6px;">
            <div style="display: flex; align-items: center; gap: 6px;">
              <span style="font-size: 11px; color: var(--text-secondary);">ساعت:</span>
              <select id="dtHour" class="input-field" style="flex: 1;" onchange="runDatetimeConvert()"></select>
            </div>
            <div style="display: flex; align-items: center; gap: 6px;">
              <span style="font-size: 11px; color: var(--text-secondary);">دقیقه:</span>
              <select id="dtMinute" class="input-field" style="flex: 1;" onchange="runDatetimeConvert()"></select>
            </div>
          </div>
        </div>

        <!-- Output Breakdown Table -->
        <div class="receipt-table">
          <div class="receipt-row">
            <span>تاریخ کامل شمسی:</span>
            <span id="dtFullShamsi" style="color: var(--gold-bright); font-weight: 700;">-</span>
          </div>
          <div class="receipt-row">
            <span>روز هفته و برج فلکی:</span>
            <span id="dtWeekdayZodiac">-</span>
          </div>
          <div class="receipt-row">
            <span>معادل استاندارد میلادی (UTC):</span>
            <span id="dtGregorian" class="en-distinct">-</span>
          </div>
          <div class="receipt-row">
            <span>زمان استاندارد ایزو (<span class="en-distinct">ISO 8601</span>):</span>
            <span id="dtIsoString" class="en-distinct" style="font-size: 11px;">-</span>
          </div>
          <div class="receipt-row">
            <span>تایم استمپ یونیکس (<span class="en-distinct">Epoch Seconds</span>):</span>
            <span id="dtUnixTimestamp" class="en-distinct" style="color: var(--signal-blue);">-</span>
          </div>
        </div>

        <button class="btn" onclick="copyDatetimeResult()">
          <svg viewBox="0 0 24 24" width="16" height="16" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
            <rect x="9" y="9" width="13" height="13" rx="2" ry="2"></rect>
            <path d="M5 15H4a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h9a2 2 0 0 1 2 2v1"></path>
          </svg>
          کپی اطلاعات تبدیل تاریخ
        </button>
      </div>
    </div>

  </div>

  <!-- Bottom Navigation with High Quality SVG Icons -->
  <div class="bottom-nav">
    <div class="nav-item active" onclick="switchTab('tabMarket', this)">
      <div class="nav-icon">
        <svg viewBox="0 0 24 24" width="18" height="18" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
          <polyline points="22 7 13.5 15.5 8.5 10.5 2 17"></polyline>
          <polyline points="16 7 22 7 22 13"></polyline>
        </svg>
      </div>
      <div class="nav-label">بازار و حباب</div>
    </div>
    <div class="nav-item" onclick="switchTab('tabJewelry', this)">
      <div class="nav-icon">
        <svg viewBox="0 0 24 24" width="18" height="18" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
          <path d="m16 16 3-8 3 8c-.87.65-1.92 1-3 1s-2.13-.35-3-1Z"></path>
          <path d="m2 16 3-8 3 8c-.87.65-1.92 1-3 1s-2.13-.35-3-1Z"></path>
          <path d="M7 21h10"></path>
          <path d="M12 3v18"></path>
          <path d="M3 7h2c2 0 5-1 7-2 2 1 5 2 7 2h2"></path>
        </svg>
      </div>
      <div class="nav-label">طلافروشی</div>
    </div>
    <div class="nav-item" onclick="switchTab('tabLaws', this)">
      <div class="nav-icon">
        <svg viewBox="0 0 24 24" width="18" height="18" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
          <path d="M4 19.5v-15A2.5 2.5 0 0 1 6.5 2H20v20H6.5a2.5 2.5 0 0 1-2.5-2.5Z"></path>
          <path d="M6 6h10"></path>
          <path d="M6 10h10"></path>
          <path d="M6 14h6"></path>
        </svg>
      </div>
      <div class="nav-label">قوانین رسمی</div>
    </div>
    <div class="nav-item" onclick="switchTab('tabDatetime', this)">
      <div class="nav-icon">
        <svg viewBox="0 0 24 24" width="18" height="18" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
          <rect x="3" y="4" width="18" height="18" rx="2" ry="2"></rect>
          <line x1="16" y1="2" x2="16" y2="6"></line>
          <line x1="8" y1="2" x2="8" y2="6"></line>
          <line x1="3" y1="10" x2="21" y2="10"></line>
        </svg>
      </div>
      <div class="nav-label">تقویم و مبدل</div>
    </div>
  </div>

  <!-- Shamsi Date Picker Modal Sheet -->
  <div class="modal-overlay" id="shamsiPickerModal">
    <div class="modal-sheet">
      <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 12px;">
        <span style="font-size: 14px; font-weight: 800; color: var(--gold-accent);">انتخاب تاریخ فاکتور طلا</span>
        <button class="pill pill-amber" onclick="closeShamsiPicker()">
          <svg viewBox="0 0 24 24" width="14" height="14" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round">
            <polyline points="20 6 9 17 4 12"></polyline>
          </svg>
          تایید
        </button>
      </div>
      <div class="calendar-grid">
        <div class="cal-cell header">ش</div>
        <div class="cal-cell header">ی</div>
        <div class="cal-cell header">د</div>
        <div class="cal-cell header">س</div>
        <div class="cal-cell header">چ</div>
        <div class="cal-cell header">پ</div>
        <div class="cal-cell header" style="color: var(--signal-coral);">ج</div>
        <!-- Days 1 to 30 rendered with Persian digits -->
        <div class="cal-cell" onclick="selectDay(1)">۱</div>
        <div class="cal-cell" onclick="selectDay(2)">۲</div>
        <div class="cal-cell" onclick="selectDay(3)">۳</div>
        <div class="cal-cell" onclick="selectDay(4)">۴</div>
        <div class="cal-cell" onclick="selectDay(5)">۵</div>
        <div class="cal-cell" onclick="selectDay(6)">۶</div>
        <div class="cal-cell" onclick="selectDay(7)">۷</div>
        <div class="cal-cell" onclick="selectDay(8)">۸</div>
        <div class="cal-cell" onclick="selectDay(9)">۹</div>
        <div class="cal-cell" onclick="selectDay(10)">۱۰</div>
        <div class="cal-cell" onclick="selectDay(11)">۱۱</div>
        <div class="cal-cell" onclick="selectDay(12)">۱۲</div>
        <div class="cal-cell" onclick="selectDay(13)">۱۳</div>
        <div class="cal-cell" onclick="selectDay(14)">۱۴</div>
        <div class="cal-cell" onclick="selectDay(15)">۱۵</div>
        <div class="cal-cell" onclick="selectDay(16)">۱۶</div>
        <div class="cal-cell" onclick="selectDay(17)">۱۷</div>
        <div class="cal-cell" onclick="selectDay(18)">۱۸</div>
        <div class="cal-cell" onclick="selectDay(19)">۱۹</div>
        <div class="cal-cell" onclick="selectDay(20)">۲۰</div>
        <div class="cal-cell" onclick="selectDay(21)">۲۱</div>
        <div class="cal-cell" onclick="selectDay(22)">۲۲</div>
        <div class="cal-cell" onclick="selectDay(23)">۲۳</div>
        <div class="cal-cell" onclick="selectDay(24)">۲۴</div>
        <div class="cal-cell" onclick="selectDay(25)">۲۵</div>
        <div class="cal-cell" onclick="selectDay(26)">۲۶</div>
        <div class="cal-cell" onclick="selectDay(27)">۲۷</div>
        <div class="cal-cell active" onclick="selectDay(28)">۲۸</div>
        <div class="cal-cell" onclick="selectDay(29)">۲۹</div>
        <div class="cal-cell" onclick="selectDay(30)">۳۰</div>
      </div>
    </div>
  </div>

</div>

<script>%s</script>
</body>
</html>
`
