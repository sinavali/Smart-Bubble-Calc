package main

// appShellJS contains the interactive client-side logic for the Swiss mobile simulator.
// Invariant: ZERO half-space characters (\u200c) allowed.
// Culture: fa-IR, Tehran timezone & Iranian financial market regulations.
const appShellJS = `
let marketData = null;
let currentCarat = 750;
let activeCategory = 'all';
let searchQuery = '';
let completedSteps = new Set();

function formatToman(num) {
  return Math.round(num).toLocaleString('fa-IR') + ' تومان';
}

function toPersianDigits(n) {
  const p = ['۰','۱','۲','۳','۴','۵','۶','۷','۸','۹'];
  return n.toString().replace(/[0-9]/g, function(w){ return p[+w]; });
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

function updateClock() {
  const now = new Date();
  const h = String(now.getHours()).padStart(2, '0');
  const m = String(now.getMinutes()).padStart(2, '0');
  const s = String(now.getSeconds()).padStart(2, '0');
  document.getElementById('tehranClock').innerText = toPersianDigits(h + ':' + m + ':' + s);
}
setInterval(updateClock, 1000);
updateClock();

function switchTab(tabId, el) {
  document.querySelectorAll('.tab-view').forEach(t => t.classList.remove('active'));
  document.querySelectorAll('.nav-item').forEach(n => n.classList.remove('active'));
  document.getElementById(tabId).classList.add('active');
  el.classList.add('active');
}

async function fetchMarket() {
  try {
    const res = await fetch('/api/v1/market');
    if (res.ok) {
      marketData = await res.json();
      document.getElementById('shamsiHeaderDate').innerText = marketData.shamsi_date || '۲۸ مهر ۱۴۰۵';
      renderAssets();
    }
  } catch (e) {
    console.error('Market fetch error:', e);
  }
}

function renderAssets() {
  if (!marketData || !marketData.assets) return;
  const container = document.getElementById('assetsListContainer');
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
        '<div style="font-size: 13px; font-weight: 700; color: var(--gold-accent); font-family: monospace;">' + toPersianDigits(a.bubble_pct.toFixed(2)) + '%</div>' +
      '</div>';
    }
    const priceStr = (a.id === 'gold_ounce') ? ('$' + a.price) : formatToman(a.price);
    card.innerHTML =
      '<div class="card-header">' +
        '<span style="font-weight: 700; font-size: 14px;">' + a.name_fa + '</span>' +
        '<span class="pill ' + pillClass + '">' + a.risk_label_fa + '</span>' +
      '</div>' +
      '<div style="display: flex; justify-content: space-between; align-items: flex-end;">' +
        '<div>' +
          '<div style="font-size: 11px; color: var(--text-muted);">قیمت بازار</div>' +
          '<div style="font-size: 16px; font-weight: 700; font-family: monospace;">' + priceStr + '</div>' +
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
  const vat = (labor + profit) * 0.09;
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
  const text = 'صورتحساب طلا:\nمبلغ کل: ' + total + '\n' + document.getElementById('resWords').innerText;
  navigator.clipboard.writeText(text);
  alert('صورتحساب در حافظه کپی شد!');
}

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

function renderDca() {
  const cap = parseFloat(document.getElementById('dcaCapital').value) || 0;
  const g = cap * 0.55;
  const c = cap * 0.25;
  const k = cap * 0.20;

  document.getElementById('dcaGold').innerText = formatToman(g) + ' (۵۵٪)';
  document.getElementById('dcaCoin').innerText = formatToman(c) + ' (۲۵٪)';
  document.getElementById('dcaCash').innerText = formatToman(k) + ' (۲۰٪)';

  const steps = [
    { title: 'پله ۱ (امروز)', date: '۲۸ مهر ۱۴۰۵', action: 'خرید طلای ۱۸ عیار بدون حباب' },
    { title: 'پله ۲ (۲ هفته بعد)', date: '۱۲ آبان ۱۴۰۵', action: 'بررسی حباب سکه و ورود پله دوم' },
    { title: 'پله ۳ (۱ ماه بعد)', date: '۲۸ آبان ۱۴۰۵', action: 'تکمیل میانگین وزنی خرید' },
    { title: 'پله ۴ (۲ ماه بعد)', date: '۲۸ آذر ۱۴۰۵', action: 'تثبیت سبد سرمایه گذاری' }
  ];

  const cont = document.getElementById('dcaStepsContainer');
  cont.innerHTML = '';
  const stepAmt = cap / 4;

  steps.forEach((s, idx) => {
    const isChecked = completedSteps.has(idx);
    const div = document.createElement('div');
    div.style = 'padding: 8px 10px; background: var(--card-light); border-radius: 4px; margin-bottom: 6px; display: flex; justify-content: space-between; align-items: center; border: 1px solid var(--border-color);';
    const checkedAttr = isChecked ? 'checked' : '';
    const titleStyle = isChecked ? 'text-decoration: line-through; color: var(--signal-emerald);' : '';
    div.innerHTML =
      '<div style="display: flex; align-items: center; gap: 8px;">' +
        '<input type="checkbox" ' + checkedAttr + ' onchange="toggleDcaStep(' + idx + ')">' +
        '<div>' +
          '<div style="font-size: 12px; font-weight: 700; ' + titleStyle + '">' + s.title + '</div>' +
          '<div style="font-size: 10px; color: var(--text-muted);">' + s.action + ' - ' + s.date + '</div>' +
        '</div>' +
      '</div>' +
      '<div style="font-size: 11px; font-weight: 700; color: var(--gold-accent); font-family: monospace;">' + formatToman(stepAmt) + '</div>';
    cont.appendChild(div);
  });
}

function toggleDcaStep(idx) {
  if (completedSteps.has(idx)) completedSteps.delete(idx);
  else completedSteps.add(idx);
  const pct = Math.round((completedSteps.size / 4) * 100);
  document.getElementById('dcaProgressBadge').innerText = 'پیشرفت: ' + toPersianDigits(pct) + '٪';
  renderDca();
}

function convertShamsi() {
  document.getElementById('gregorianResult').innerText = 'معادل میلادی: 2026-10-20';
}

// Initial loads
fetchMarket();
setInterval(fetchMarket, 10000);
calculateJewelry();
renderDca();
`
