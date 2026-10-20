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
<html lang="fa" dir="rtl">
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
      <div class="status-dot"></div>
      <span class="brand-title">BUBBLE CALC // نبض بازار</span>
    </div>
    <div class="tehran-clock-pill" id="tehranClock">۰۰:۰۰:۰۰</div>
  </div>

  <!-- Content Body -->
  <div class="content-body">

    <!-- Tab 1: بازار و حباب سنج -->
    <div class="tab-view active" id="tabMarket">
      <div style="display: flex; justify-content: space-between; align-items: center;">
        <span style="font-size: 13px; font-weight: 700;">تابلو نرخ و حباب بازار تهران</span>
        <span style="font-size: 11px; color: var(--gold-accent); font-family: monospace;" id="shamsiHeaderDate">۲۸ مهر ۱۴۰۵</span>
      </div>

      <!-- Category Filter Chips -->
      <div class="chip-row">
        <div class="chip active" onclick="setCategoryFilter('all', this)">همه دارایی ها</div>
        <div class="chip" onclick="setCategoryFilter('coins', this)">مسکوکات طلا</div>
        <div class="chip" onclick="setCategoryFilter('gold', this)">طلای خام و اونس</div>
      </div>

      <!-- Quick Search -->
      <input type="text" class="input-field" id="marketSearchInput" placeholder="جستجوی سکه، امامی، بهار آزادی، ۱۸ عیار..." oninput="filterAssets()">

      <!-- Asset Cards Container -->
      <div id="assetsListContainer" style="display: flex; flex-direction: column; gap: 8px;">
        <!-- Dynamically rendered -->
      </div>
    </div>

    <!-- Tab 2: طلافروشی و فاکتور قانونی -->
    <div class="tab-view" id="tabJewelry">
      <div class="card">
        <div class="card-header">
          <span style="font-size: 13px; font-weight: 700; color: var(--gold-accent);">محاسبه گر فاکتور طلا (ماده ۲۶ ارزش افزوده)</span>
          <span class="pill pill-emerald">معافیت اصل طلا</span>
        </div>

        <!-- Carat Selection -->
        <div class="form-group">
          <label class="form-label">عیار طلا:</label>
          <div class="chip-row">
            <div class="chip active" onclick="setCarat(750, this)">۱۸ عیار (۷۵۰)</div>
            <div class="chip" onclick="setCarat(1000, this)">۲۴ عیار (شمش)</div>
            <div class="chip" onclick="setCarat(875, this)">۲۱ عیار (۸۷۵)</div>
            <div class="chip" onclick="setCarat(740, this)">۷۴۰ (متفرقه)</div>
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
              <span>📅</span>
            </div>
          </div>
        </div>

        <!-- Breakdown Receipt -->
        <div class="receipt-table">
          <div class="receipt-row"><span>ارزش طلای خام:</span><span id="resRawGold">-</span></div>
          <div class="receipt-row"><span>اجرت ساخت:</span><span id="resLabor">-</span></div>
          <div class="receipt-row"><span>سود فروشنده (۷٪ مصوب):</span><span id="resProfit">-</span></div>
          <div class="receipt-row"><span>مالیات بر ارزش افزوده (۹٪ اجرت+سود):</span><span id="resVat" style="color: var(--signal-amber);">-</span></div>
          <div class="receipt-row highlight"><span>مبلغ کل نهایی:</span><span id="resTotal" style="color: var(--gold-bright);">-</span></div>
        </div>

        <!-- Price in Persian Words -->
        <div style="font-size: 11px; color: var(--gold-accent); text-align: center; font-weight: 600;" id="resWords">-</div>

        <!-- Share / Copy Action -->
        <button class="btn" onclick="copyReceipt()">📋 کپی صورتحساب رسمی</button>
      </div>
    </div>

    <!-- Tab 3: تحلیل هوشمند و استراتژی خرید -->
    <div class="tab-view" id="tabAdvisor">
      <div class="card">
        <div class="card-header">
          <span style="font-size: 13px; font-weight: 700; color: var(--gold-accent);">مدیریت ریسک خرید پله ای (DCA)</span>
          <span class="pill pill-blue">توصیه هوشمند</span>
        </div>
        <div style="font-size: 11px; color: var(--text-secondary); line-height: 1.5;">
          با توجه به حباب بالای مسکوکات تمام بهار و امامی، توصیه هوشمند سامانه خرید طلای ۱۸ عیار بدون اجرت و ورود در ۴ پله با فاصله زمانی منظم است.
        </div>
        <div class="form-group">
          <label class="form-label">سرمایه پیشنهادی (تومان):</label>
          <input type="number" id="dcaCapital" class="input-field" value="100000000" step="1000000" oninput="renderDca()">
        </div>
        <div class="receipt-table">
          <div class="receipt-row"><span>طلای ۱۸ عیار آبشده (کم ریسک):</span><span id="dcaGold" style="color: var(--signal-emerald);">-</span></div>
          <div class="receipt-row"><span>سکه تمام / نیم (ریسک متوسط):</span><span id="dcaCoin" style="color: var(--signal-amber);">-</span></div>
          <div class="receipt-row"><span>وجه نقد احتیاطی ریالی:</span><span id="dcaCash" style="color: var(--signal-blue);">-</span></div>
        </div>
      </div>

      <div class="card">
        <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 8px;">
          <span style="font-size: 12px; font-weight: 700;">برنامه زمانبندی خرید پله ای:</span>
          <span class="pill pill-emerald" id="dcaProgressBadge">پیشرفت: ۰٪</span>
        </div>
        <div id="dcaStepsContainer">
          <!-- Rendered in JS -->
        </div>
      </div>
    </div>

    <!-- Tab 4: تنظیمات -->
    <div class="tab-view" id="tabSettings">
      <div class="card">
        <div style="font-size: 13px; font-weight: 700; margin-bottom: 8px;">مبدل تاریخ شمسی به میلادی</div>
        <div style="display: flex; gap: 8px; margin-bottom: 8px;">
          <input type="text" id="shamsiInputDate" class="input-field" value="1405/07/28" placeholder="1405/07/28">
          <button class="btn" style="width: 80px;" onclick="convertShamsi()">تبدیل</button>
        </div>
        <div style="font-size: 12px; color: var(--text-secondary);" id="gregorianResult">معادل میلادی: 2026-10-20</div>
      </div>

      <div class="card">
        <div style="font-size: 13px; font-weight: 700; margin-bottom: 8px;">وضعیت سرور و سلامت سیستم</div>
        <div class="receipt-row"><span>آدرس سرور API:</span><span>http://127.0.0.1:8080</span></div>
        <div class="receipt-row"><span>وضعیت سلامت:</span><span class="pill pill-emerald">سالم و آنلاین</span></div>
        <div class="receipt-row"><span>پروتکل:</span><span>OpenAPI 3.1 & In-Memory Cache</span></div>
      </div>

      <div class="card" style="border: 1px solid var(--border-color);">
        <div style="font-size: 12px; font-weight: 700; margin-bottom: 6px;">مستندات قانونی مالیات طلا (ماده ۲۶):</div>
        <div style="font-size: 11px; color: var(--text-muted); line-height: 1.6;">
          بر اساس قانون دائمی مالیات بر ارزش افزوده مصوب ۱۴۰۰، اصل طلا، جواهر و پلاتین از پرداخت مالیات معاف است. مالیات صرفا با نرخ ۹ درصد به اجرت ساخت و سود فروشنده تعلق می گیرد.
        </div>
      </div>
    </div>

  </div>

  <!-- Bottom Navigation -->
  <div class="bottom-nav">
    <div class="nav-item active" onclick="switchTab('tabMarket', this)">
      <div class="nav-icon">📈</div>
      <div class="nav-label">بازار و حباب</div>
    </div>
    <div class="nav-item" onclick="switchTab('tabJewelry', this)">
      <div class="nav-icon">⚖️</div>
      <div class="nav-label">طلافروشی</div>
    </div>
    <div class="nav-item" onclick="switchTab('tabAdvisor', this)">
      <div class="nav-icon">🧠</div>
      <div class="nav-label">تحلیل هوشمند</div>
    </div>
    <div class="nav-item" onclick="switchTab('tabSettings', this)">
      <div class="nav-icon">⚙️</div>
      <div class="nav-label">تنظیمات</div>
    </div>
  </div>

  <!-- Shamsi Date Picker Modal -->
  <div class="modal-overlay" id="shamsiPickerModal">
    <div class="modal-sheet">
      <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 12px;">
        <span style="font-size: 14px; font-weight: 700; color: var(--gold-accent);">انتخاب تاریخ شمسی فاکتور</span>
        <button class="pill pill-amber" onclick="closeShamsiPicker()">تایید</button>
      </div>
      <div class="calendar-grid">
        <div class="cal-cell header">ش</div>
        <div class="cal-cell header">ی</div>
        <div class="cal-cell header">د</div>
        <div class="cal-cell header">س</div>
        <div class="cal-cell header">چ</div>
        <div class="cal-cell header">پ</div>
        <div class="cal-cell header" style="color: var(--signal-coral);">ج</div>
        <!-- Days 1 to 30 -->
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
