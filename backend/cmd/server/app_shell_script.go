package main

// appShellJS contains the interactive client-side logic for the Swiss mobile simulator.
// Invariant: ZERO half-space characters (\u200c) allowed.
// Culture: fa-IR, Tehran timezone & Iranian financial market regulations.
const appShellJS = `
let marketData = null;
let lawsData = null;
let currentCarat = 750;
let activeCategory = 'all';
let searchQuery = '';
let lawsCategory = 'all';
let lawsQuery = '';

const persianMonths = [
  'فروردین', 'اردیبهشت', 'خرداد',
  'تیر', 'مرداد', 'شهریور',
  'مهر', 'آبان', 'آذر',
  'دی', 'بهمن', 'اسفند'
];

const zodiacSigns = [
  'برج حمل (قوچ)', 'برج ثور (گاو)', 'برج جوزا (دوپیکر)',
  'برج سرطان (خرچنگ)', 'برج اسد (شیر)', 'برج سنبله (دوشیزه)',
  'برج میزان (ترازو)', 'برج عقرب (کژدم)', 'برج قوس (کماندار)',
  'برج جدی (بزغاله)', 'برج دلو (آبکش)', 'برج حوت (ماهی)'
];

const weekDaysFa = ['یکشنبه', 'دوشنبه', 'سه شنبه', 'چهارشنبه', 'پنجشنبه', 'جمعه', 'شنبه'];

function formatToman(num) {
  return Math.round(num).toLocaleString('fa-IR') + ' تومان';
}

function toPersianDigits(n) {
  if (n === null || n === undefined) return '';
  const p = ['۰','۱','۲','۳','۴','۵','۶','۷','۸','۹'];
  return n.toString().replace(/[0-9]/g, function(w){ return p[+w]; });
}

function pad2(n) {
  return n < 10 ? '0' + n : '' + n;
}

function numberToPersianWords(num) {
  if (!num || num === 0) return 'صفر تومان';
  const ones = ['', 'یک', 'دو', 'سه', 'چهار', 'پنج', 'شش', 'هفت', 'هشت', 'نه', 'ده', 'یازده', 'دوازده', 'سیزده', 'چهارده', 'پانزده', 'شانزده', 'هفده', 'هجده', 'نوزده'];
  const tens = ['', '', 'بیست', 'سی', 'چهل', 'پنجاه', 'شصت', 'هفتاد', 'هشتاد', 'نود'];
  const hundreds = ['', 'یکصد', 'دویست', 'سیصد', 'چهارصد', 'پانصد', 'ششصد', 'هفتصد', 'هشتصد', 'نهصد'];
  const scales = ['', 'هزار', 'میلیون', 'میلیارد'];

  let n = Math.abs(Math.round(num));
  let groups = [];
  let scaleIdx = 0;

  while (n > 0) {
    let rem = n % 1000;
    if (rem > 0) {
      let h = Math.floor(rem / 100);
      let r = rem % 100;
      let parts = [];
      if (h > 0) parts.push(hundreds[h]);
      if (r > 0) {
        if (r < 20) parts.push(ones[r]);
        else {
          let t = Math.floor(r / 10);
          let o = r % 10;
          parts.push(tens[t]);
          if (o > 0) parts.push(ones[o]);
        }
      }
      let groupStr = parts.join(' و ');
      if (scaleIdx > 0) groupStr += ' ' + scales[scaleIdx];
      groups.unshift(groupStr);
    }
    n = Math.floor(n / 1000);
    scaleIdx++;
  }
  return groups.join(' و ') + ' تومان';
}

// Theme Management (Dark & Light)
function initTheme() {
  const saved = localStorage.getItem('sb_theme') || 'dark';
  setTheme(saved);
}

function toggleTheme() {
  const cur = document.documentElement.getAttribute('data-theme') || 'dark';
  const next = cur === 'dark' ? 'light' : 'dark';
  setTheme(next);
}

function setTheme(theme) {
  document.documentElement.setAttribute('data-theme', theme);
  localStorage.setItem('sb_theme', theme);
  const sun = document.getElementById('sunIcon');
  const moon = document.getElementById('moonIcon');
  if (theme === 'light') {
    if (sun) sun.style.display = 'block';
    if (moon) moon.style.display = 'none';
  } else {
    if (sun) sun.style.display = 'none';
    if (moon) moon.style.display = 'block';
  }
}

// Clock in Tehran Time
function updateClock() {
  const now = new Date();
  const h = String(now.getHours()).padStart(2, '0');
  const m = String(now.getMinutes()).padStart(2, '0');
  const s = String(now.getSeconds()).padStart(2, '0');
  const el = document.getElementById('tehranClock');
  if (el) el.innerText = toPersianDigits(h + ':' + m + ':' + s);
}
setInterval(updateClock, 1000);
updateClock();

// Tab Switcher
function switchTab(tabId, el) {
  document.querySelectorAll('.tab-view').forEach(t => t.classList.remove('active'));
  document.querySelectorAll('.nav-item').forEach(n => n.classList.remove('active'));
  const target = document.getElementById(tabId);
  if (target) target.classList.add('active');
  if (el) el.classList.add('active');
}

// Market Quotes & Bubbles
async function fetchMarket() {
  try {
    const res = await fetch('/api/v1/market');
    if (res.ok) {
      marketData = await res.json();
      const hDate = document.getElementById('shamsiHeaderDate');
      if (hDate) hDate.innerText = marketData.shamsi_date || '۲۸ مهر ۱۴۰۵';
      renderAssets();
    }
  } catch (e) {
    console.error('Market fetch error:', e);
  }
}

function renderAssets() {
  if (!marketData || !marketData.assets) return;
  const container = document.getElementById('assetsListContainer');
  if (!container) return;
  container.innerHTML = '';

  let list = marketData.assets;
  if (activeCategory === 'coins') {
    list = list.filter(a => a.id.startsWith('coin_'));
  } else if (activeCategory === 'gold') {
    list = list.filter(a => !a.id.startsWith('coin_'));
  }

  if (searchQuery) {
    const q = searchQuery.toLowerCase();
    list = list.filter(a => a.name_fa.includes(q) || a.id.includes(q));
  }

  list.forEach(a => {
    let pillClass = 'pill-blue';
    if (a.risk_level === 'high' || a.risk_level === 'critical') pillClass = 'pill-coral';
    else if (a.risk_level === 'medium') pillClass = 'pill-amber';
    else if (a.risk_level === 'low') pillClass = 'pill-emerald';

    const card = document.createElement('div');
    card.className = 'card';
    let bubbleHtml = '';
    if (a.bubble > 0) {
      bubbleHtml = '<div style="text-align: left;">' +
        '<div style="font-size: 11px; color: var(--text-muted);">حباب: ' + formatToman(a.bubble) + '</div>' +
        '<div style="font-size: 13px; font-weight: 800; color: var(--gold-accent); font-variant-numeric: tabular-nums;">' + toPersianDigits(a.bubble_pct.toFixed(2)) + '٪</div>' +
      '</div>';
    }

    let priceDisplay = '';
    if (a.id === 'gold_ounce') {
      priceDisplay = '<span class="en-distinct">$' + a.price.toLocaleString('en-US') + '</span>';
    } else {
      priceDisplay = formatToman(a.price);
    }

    card.innerHTML =
      '<div class="card-header">' +
        '<span style="font-weight: 800; font-size: 14px;">' + a.name_fa + '</span>' +
        '<span class="pill ' + pillClass + '">' + a.risk_label_fa + '</span>' +
      '</div>' +
      '<div style="display: flex; justify-content: space-between; align-items: flex-end;">' +
        '<div>' +
          '<div style="font-size: 11px; color: var(--text-muted);">قیمت بازار</div>' +
          '<div style="font-size: 15px; font-weight: 800;">' + priceDisplay + '</div>' +
        '</div>' +
        bubbleHtml +
      '</div>';
    container.appendChild(card);
  });
}

function setCategoryFilter(cat, el) {
  activeCategory = cat;
  document.querySelectorAll('#tabMarket .chip').forEach(c => c.classList.remove('active'));
  el.classList.add('active');
  renderAssets();
}

function filterAssets() {
  searchQuery = document.getElementById('marketSearchInput').value.trim();
  renderAssets();
}

// Legal Jewelry Calculator (Article 26)
function setCarat(carat, el) {
  currentCarat = carat;
  document.querySelectorAll('#tabJewelry .chip').forEach(c => c.classList.remove('active'));
  el.classList.add('active');
  sync18kPrice();
}

function sync18kPrice() {
  if (marketData && marketData.assets) {
    const gold = marketData.assets.find(a => a.id === 'gold_18k');
    if (gold && gold.price > 0) {
      const adjusted = Math.round(gold.price * (currentCarat / 750));
      document.getElementById('gramPrice').value = adjusted;
      calculateJewelry();
    }
  }
}

function calculateJewelry() {
  const weight = parseFloat(document.getElementById('goldWeight').value) || 0;
  const price = parseFloat(document.getElementById('gramPrice').value) || 0;
  const laborPct = parseFloat(document.getElementById('laborPct').value) || 0;

  if (weight <= 0 || price <= 0) return;

  const rawGold = weight * price;
  const labor = rawGold * (laborPct / 100);
  const profit = (rawGold + labor) * 0.07;
  const vat = (labor + profit) * 0.09; // Strictly on Labor + Profit (Article 26)
  const total = rawGold + labor + profit + vat;

  document.getElementById('resRawGold').innerText = formatToman(rawGold);
  document.getElementById('resLabor').innerText = formatToman(labor);
  document.getElementById('resProfit').innerText = formatToman(profit);
  document.getElementById('resVat').innerText = formatToman(vat);
  document.getElementById('resTotal').innerText = formatToman(total);
  document.getElementById('resWords').innerText = 'مبلغ به حروف: ' + numberToPersianWords(total);
}

function copyReceipt() {
  const total = document.getElementById('resTotal').innerText;
  const words = document.getElementById('resWords').innerText;
  const text = 'صورتحساب رسمی طلا و جواهر:\nمبلغ کل فاکتور: ' + total + '\n' + words + '\nمحاسبه شده مطابق ماده ۲۶ قانون مالیات بر ارزش افزوده';
  navigator.clipboard.writeText(text);
  alert('صورتحساب رسمی در حافظه کپی شد.');
}

// Shamsi Invoice Date Picker
function openShamsiPicker() {
  document.getElementById('shamsiPickerModal').style.display = 'flex';
}

function closeShamsiPicker() {
  document.getElementById('shamsiPickerModal').style.display = 'none';
}

function selectDay(d) {
  const pDigit = toPersianDigits(d);
  document.querySelectorAll('.cal-cell:not(.header)').forEach(c => {
    if (c.innerText.trim() === pDigit) {
      c.classList.add('active');
    } else {
      c.classList.remove('active');
    }
  });
  document.getElementById('selectedInvoiceDateDisplay').innerText = pDigit + ' مهر ۱۴۰۵';
  closeShamsiPicker();
}

// Official Laws & Regulations (Daily Cached from Backend)
async function fetchLaws() {
  try {
    const res = await fetch('/api/v1/laws');
    if (res.ok) {
      lawsData = await res.json();
      const badge = document.getElementById('lawsCountBadge');
      if (badge && lawsData.total_count) {
        badge.innerText = toPersianDigits(lawsData.total_count) + ' قانون معتبر';
      }
      renderLaws();
    }
  } catch (e) {
    console.error('Laws fetch error:', e);
  }
}

function renderLaws() {
  if (!lawsData || !lawsData.articles) return;
  const container = document.getElementById('lawsContainer');
  if (!container) return;
  container.innerHTML = '';

  let list = lawsData.articles;
  if (lawsCategory !== 'all') {
    list = list.filter(l => l.category === lawsCategory);
  }

  if (lawsQuery) {
    const q = lawsQuery.toLowerCase();
    list = list.filter(l => l.title.includes(q) || l.summary.includes(q) || l.reference.includes(q));
  }

  list.forEach((law, idx) => {
    const card = document.createElement('div');
    card.className = 'law-card';
    card.id = 'lawCard_' + idx;

    let pillType = 'pill-blue';
    if (law.category === 'tax') pillType = 'pill-emerald';
    else if (law.category === 'guild') pillType = 'pill-amber';
    else if (law.category === 'aml') pillType = 'pill-coral';

    card.innerHTML =
      '<div class="law-header" onclick="toggleLaw(' + idx + ')">' +
        '<div>' +
          '<div style="font-weight: 800; font-size: 13px; margin-bottom: 4px;">' + law.title + '</div>' +
          '<div style="display: flex; gap: 6px; align-items: center;">' +
            '<span class="pill ' + pillType + '">' + law.category_fa + '</span>' +
            '<span style="font-size: 11px; color: var(--text-muted);">' + law.reference + '</span>' +
          '</div>' +
        '</div>' +
        '<div class="law-chevron">' +
          '<svg viewBox="0 0 24 24" width="16" height="16" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round">' +
            '<polyline points="6 9 12 15 18 9"></polyline>' +
          '</svg>' +
        '</div>' +
      '</div>' +
      '<div class="law-content">' +
        '<div style="color: var(--text-secondary);"><strong style="color: var(--text-primary);">مرجع قانونی:</strong> ' + law.source + ' (' + law.enacted_date + ')</div>' +
        '<div style="background: var(--surface-slate); padding: 10px; border-radius: 6px; border: 1px solid var(--border-color);">' +
          '<strong style="color: var(--gold-accent);">متن مصوب قانون:</strong><br>' + law.fullText +
        '</div>' +
        '<div><strong style="color: var(--signal-emerald);">تکلیف مودی / خریدار:</strong> ' + law.mandate_fa + '</div>' +
        '<div><strong style="color: var(--signal-coral);">ضمانت اجرا و جریمه تخلف:</strong> ' + law.penalty_fa + '</div>' +
      '</div>';
    container.appendChild(card);
  });
}

function toggleLaw(idx) {
  const card = document.getElementById('lawCard_' + idx);
  if (card) card.classList.toggle('expanded');
}

function setLawsCategory(cat, el) {
  lawsCategory = cat;
  document.querySelectorAll('#tabLaws .chip').forEach(c => c.classList.remove('active'));
  el.classList.add('active');
  renderLaws();
}

function filterLaws() {
  lawsQuery = document.getElementById('lawsSearchInput').value.trim();
  renderLaws();
}

// Shamsi & Gregorian DateTime Converter
function initDatetimePicker() {
  const ySel = document.getElementById('dtYear');
  const mSel = document.getElementById('dtMonth');
  const dSel = document.getElementById('dtDay');
  const hSel = document.getElementById('dtHour');
  const minSel = document.getElementById('dtMinute');

  if (!ySel || !mSel || !dSel) return;

  // Years 1395 to 1410
  ySel.innerHTML = '';
  for (let y = 1410; y >= 1395; y--) {
    const opt = document.createElement('option');
    opt.value = y;
    opt.innerText = toPersianDigits(y);
    if (y === 1405) opt.selected = true;
    ySel.appendChild(opt);
  }

  // Months
  mSel.innerHTML = '';
  persianMonths.forEach((mName, idx) => {
    const opt = document.createElement('option');
    opt.value = idx + 1;
    opt.innerText = toPersianDigits(idx + 1) + '. ' + mName;
    if (idx === 6) opt.selected = true; // Mehr
    mSel.appendChild(opt);
  });

  // Days 1 to 31
  dSel.innerHTML = '';
  for (let d = 1; d <= 31; d++) {
    const opt = document.createElement('option');
    opt.value = d;
    opt.innerText = toPersianDigits(d);
    if (d === 28) opt.selected = true;
    dSel.appendChild(opt);
  }

  // Hours 00 to 23
  hSel.innerHTML = '';
  for (let h = 0; h < 24; h++) {
    const opt = document.createElement('option');
    opt.value = h;
    opt.innerText = toPersianDigits(pad2(h));
    if (h === 21) opt.selected = true;
    hSel.appendChild(opt);
  }

  // Minutes 00 to 59
  minSel.innerHTML = '';
  for (let m = 0; m < 60; m++) {
    const opt = document.createElement('option');
    opt.value = m;
    opt.innerText = toPersianDigits(pad2(m));
    if (m === 30) opt.selected = true;
    minSel.appendChild(opt);
  }

  runDatetimeConvert();
}

function setPresetDate(preset) {
  const now = new Date();
  if (preset === 'now') {
    document.getElementById('dtYear').value = 1405;
    document.getElementById('dtMonth').value = 7;
    document.getElementById('dtDay').value = 28;
    document.getElementById('dtHour').value = now.getHours();
    document.getElementById('dtMinute').value = now.getMinutes();
  } else if (preset === 'start_of_day') {
    document.getElementById('dtYear').value = 1405;
    document.getElementById('dtMonth').value = 7;
    document.getElementById('dtDay').value = 28;
    document.getElementById('dtHour').value = 0;
    document.getElementById('dtMinute').value = 0;
  } else if (preset === 'yesterday') {
    document.getElementById('dtYear').value = 1405;
    document.getElementById('dtMonth').value = 7;
    document.getElementById('dtDay').value = 27;
  }
  runDatetimeConvert();
}

// Algorithmic Jalali to Gregorian Conversion
function jalaliToGregorian(jy, jm, jd) {
  let gy = (jy <= 979) ? 621 : 1600;
  jy -= (jy <= 979) ? 0 : 979;
  let days = (365 * jy) + (Math.floor(jy / 33) * 8) + Math.floor(((jy % 33) + 3) / 4) + 78 + jd + ((jm < 7) ? (jm - 1) * 31 : ((jm - 7) * 30) + 186);
  gy += 400 * Math.floor(days / 146097);
  days %= 146097;
  if (days > 36524) {
    gy += 100 * Math.floor(--days / 36524);
    days %= 36524;
    if (days >= 365) days++;
  }
  gy += 4 * Math.floor(days / 1461);
  days %= 1461;
  if (days > 365) {
    gy += Math.floor((days - 1) / 365);
    days = (days - 1) % 365;
  }
  let gd = days + 1;
  const salA = [0, 31, ((gy % 4 === 0 && gy % 100 !== 0) || (gy % 400 === 0)) ? 29 : 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
  let gm;
  for (gm = 0; gm < 13; gm++) {
    const v = salA[gm];
    if (gd <= v) break;
    gd -= v;
  }
  return { gy: gy, gm: gm, gd: gd };
}

function runDatetimeConvert() {
  const y = parseInt(document.getElementById('dtYear').value, 10);
  const m = parseInt(document.getElementById('dtMonth').value, 10);
  const d = parseInt(document.getElementById('dtDay').value, 10);
  const h = parseInt(document.getElementById('dtHour').value, 10);
  const min = parseInt(document.getElementById('dtMinute').value, 10);

  const g = jalaliToGregorian(y, m, d);
  // Tehran is UTC+3:30 (standard)
  const dtUTC = new Date(Date.UTC(g.gy, g.gm - 1, g.gd, h - 3, min - 30));

  const pYear = toPersianDigits(y);
  const pMonth = persianMonths[m - 1];
  const pDay = toPersianDigits(d);
  const pHour = toPersianDigits(pad2(h));
  const pMin = toPersianDigits(pad2(min));

  const dayOfWeek = weekDaysFa[dtUTC.getUTCDay()];
  const zodiac = zodiacSigns[m - 1];

  document.getElementById('dtFullShamsi').innerText = pDay + ' ' + pMonth + ' ' + pYear + ' - ساعت ' + pHour + ':' + pMin;
  document.getElementById('dtWeekdayZodiac').innerText = dayOfWeek + ' | ' + zodiac;

  const gStr = g.gy + '-' + pad2(g.gm) + '-' + pad2(g.gd) + ' ' + pad2(h) + ':' + pad2(min) + ':00 (+03:30)';
  document.getElementById('dtGregorian').innerText = gStr;
  document.getElementById('dtIsoString').innerText = dtUTC.toISOString();
  document.getElementById('dtUnixTimestamp').innerText = Math.floor(dtUTC.getTime() / 1000);
}

function copyDatetimeResult() {
  const shamsi = document.getElementById('dtFullShamsi').innerText;
  const greg = document.getElementById('dtGregorian').innerText;
  const unix = document.getElementById('dtUnixTimestamp').innerText;
  const text = 'تبدیل تاریخ:\nتاریخ شمسی: ' + shamsi + '\nمعادل میلادی: ' + greg + '\nتایم استمپ: ' + unix;
  navigator.clipboard.writeText(text);
  alert('اطلاعات تبدیل تاریخ در حافظه کپی شد.');
}

// Initial Bootstrapping
initTheme();
initDatetimePicker();
fetchMarket();
setInterval(fetchMarket, 10000);
fetchLaws();
calculateJewelry();
`
