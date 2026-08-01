import { buildStayPreview, createStayReservation, normalizeWorkspace } from "./domain.js";

const STORAGE_KEY = "community-hub:stay-listing-prototype:v1";
const content = document.querySelector("#guest-content");
let workspace;
let currentListing;
let selectedOffer;
let completedReservation;
let conditions = { checkInDate: "2026-08-15", checkOutDate: "2026-08-17", guestCount: 2 };

async function initialize() {
  const initial = await fetch("./data/stay-listing.json").then((response) => response.json());
  workspace = normalizeWorkspace(JSON.parse(localStorage.getItem(STORAGE_KEY) || JSON.stringify(initial)));
  bindEvents();
  renderHome();
}

function bindEvents() {
  document.body.addEventListener("click", (event) => {
    const target = event.target.closest("button");
    if (!target) return;
    if (target.hasAttribute("data-home")) renderHome();
    if (target.hasAttribute("data-reservations")) renderReservations();
    if (target.dataset.listing) {
      currentListing = workspace.stayListings.find((listing) => listing.id === target.dataset.listing);
      renderListing();
    }
    if (target.dataset.offer) {
      const [roomTypeId, rateId] = target.dataset.offer.split(":");
      selectedOffer = { roomTypeId, rateId };
      renderCheckout();
    }
  });
  document.body.addEventListener("change", (event) => {
    if (!event.target.dataset.condition) return;
    conditions[event.target.dataset.condition] = event.target.type === "number" ? Number(event.target.value) : event.target.value;
    if (currentListing) renderListing();
  });
  document.body.addEventListener("submit", submitReservation);
}

function renderHome() {
  currentListing = null;
  selectedOffer = null;
  const listings = workspace.stayListings.filter((listing) => listing.status === "published");
  content.innerHTML = `
    <section class="guest-hero"><p>COMMUNITY STAY</p><h1>暮らすように泊まれる場所を見つけよう</h1><p>日程と人数を選び、あなたに合う客室と宿泊プランを探せます。</p>${searchForm()}</section>
    <section class="guest-section"><h2>泊まれる施設</h2><div class="guest-facilities">${listings.map((listing) => `<article class="card guest-facility"><div class="guest-photo">${escapeHtml(listing.images[0]?.name || "施設画像")}</div><div><h3>${escapeHtml(listing.title)}</h3><p>${escapeHtml(listing.description)}</p><button class="button button-primary" data-listing="${listing.id}">空室と料金を見る</button></div></article>`).join("")}</div>${listings.length ? "" : `<div class="empty">現在公開中の宿泊施設はありません</div>`}</section>`;
}

function renderListing() {
  const preview = buildStayPreview(currentListing, conditions);
  const rooms = preview.roomTypes.filter((room) => room.sellable);
  content.innerHTML = `
    <button class="button" data-home>← 施設一覧</button>
    <section class="guest-detail-head guest-section"><p>${escapeHtml([currentListing.location.prefecture, currentListing.location.city].filter(Boolean).join(" "))}</p><h1>${escapeHtml(currentListing.title)}</h1><p>${escapeHtml(currentListing.description)}</p></section>
    <section class="guest-section"><div class="card">${searchForm()}</div><h2>客室と宿泊プラン</h2><p>${conditions.checkInDate}から${conditions.checkOutDate}・${conditions.guestCount}名</p>
      ${rooms.map(renderRoom).join("") || `<div class="card empty">この日程で予約できる客室はありません。日程または人数を変更してください。</div>`}
    </section>`;
}

function renderRoom(item) {
  return `<article class="card guest-room"><div class="guest-photo">ROOM TYPE</div><div class="guest-room-body"><h2>${escapeHtml(item.roomType.name)}</h2><p>${escapeHtml(item.roomType.description)}</p><span class="remaining">残り${item.availableUnits}${item.roomType.roomKind === "shared_room" ? "ベッド" : "室"}</span>${item.rates.filter((rate) => rate.sellable).map((rate) => `<div class="guest-plan"><div><strong>${escapeHtml(rate.plan.name)}</strong><small>${mealLabel(rate.plan.mealType)}・${policyLabel(rate.plan.cancellationPolicyType)}・${rate.nights.length}泊</small></div><div class="guest-price">${yen(rate.totalAmount)}<small>宿泊料金合計</small></div><button class="button button-primary" data-offer="${item.roomType.id}:${rate.rate.id}">選択する</button></div>`).join("")}</div></article>`;
}

function renderCheckout(error = "") {
  const offer = selectedPreviewOffer();
  if (!offer) return renderListing();
  content.innerHTML = `<button class="button" data-listing="${currentListing.id}">← プラン選択</button><section class="guest-section"><h1>予約情報の入力</h1><div class="guest-checkout"><form id="reservation-form" class="card guest-form">${error ? `<div class="guest-error">${escapeHtml(error)}</div>` : ""}<h2>代表宿泊者</h2><label>氏名<input name="name" required /></label><label>メールアドレス<input name="email" type="email" required /></label><label>電話番号<input name="phone" type="tel" required /></label><label>同行者名（任意・カンマ区切り）<input name="companions" /></label><label>施設へのメッセージ（任意）<textarea name="message"></textarea></label><button class="button button-primary" type="submit">${currentListing.stay.bookingConfirmationMode === "instant" ? "予約を確定する" : "予約を申請する"}</button></form>${summary(offer)}</div></section>`;
}

function submitReservation(event) {
  if (event.target.id !== "reservation-form") return;
  event.preventDefault();
  const values = Object.fromEntries(new FormData(event.target).entries());
  try {
    completedReservation = createStayReservation(workspace, {
      listingId: currentListing.id,
      roomTypeId: selectedOffer.roomTypeId,
      rateId: selectedOffer.rateId,
      ...conditions,
      primaryGuest: { name: values.name.trim(), email: values.email.trim(), phone: values.phone.trim() },
      companionNames: values.companions.split(",").map((name) => name.trim()).filter(Boolean),
      message: values.message.trim(),
    });
    localStorage.setItem(STORAGE_KEY, JSON.stringify(workspace));
    renderComplete();
  } catch (error) {
    renderCheckout(error.message);
  }
}

function renderComplete() {
  const requested = completedReservation.status === "requested";
  content.innerHTML = `<section class="card guest-complete"><div class="guest-complete-mark">✓</div><p>${requested ? "予約申請を受け付けました" : "予約が確定しました"}</p><h1>${requested ? "施設からの回答をお待ちください" : "ご予約ありがとうございます"}</h1><p>予約番号: ${escapeHtml(completedReservation.id)}</p><p>${escapeHtml(currentListing.title)}<br>${completedReservation.checkInDate} — ${completedReservation.checkOutDate}</p><div class="guest-total">${yen(completedReservation.totalAmount)}</div>${requested ? `<p>回答期限: ${formatDateTime(completedReservation.approvalExpiresAt)}</p>` : ""}<button class="button button-primary" data-reservations>予約履歴を見る</button></section>`;
}

function renderReservations() {
  const reservations = (workspace.stayReservations || []).filter((reservation) => reservation.userId === "user-prototype").slice().reverse();
  content.innerHTML = `<section><h1>予約履歴</h1><div class="grid guest-section">${reservations.map((reservation) => { const listing = workspace.stayListings.find((item) => item.id === reservation.listingId); return `<article class="card"><div class="card-header"><div><h3>${escapeHtml(listing?.title || "施設")}</h3><p>${reservation.checkInDate} — ${reservation.checkOutDate}</p></div><span class="status status-${reservation.status}">${statusLabel(reservation.status)}</span></div><div class="guest-summary-row"><span>宿泊人数</span><strong>${reservation.guestCount}名</strong></div><div class="guest-summary-row"><span>合計</span><strong>${yen(reservation.totalAmount)}</strong></div><small>予約番号 ${escapeHtml(reservation.id)}</small></article>`; }).join("") || `<div class="empty">予約履歴はありません</div>`}</div></section>`;
}

function selectedPreviewOffer() {
  const preview = buildStayPreview(currentListing, conditions);
  const room = preview.roomTypes.find((item) => item.roomType.id === selectedOffer?.roomTypeId);
  const rate = room?.rates.find((item) => item.rate.id === selectedOffer?.rateId && item.sellable);
  return room && rate ? { room, rate } : null;
}

function summary({ room, rate }) {
  return `<aside class="card guest-summary"><h3>${escapeHtml(currentListing.title)}</h3><p>${escapeHtml(room.roomType.name)}<br>${escapeHtml(rate.plan.name)}</p><div class="guest-summary-row"><span>日程</span><strong>${conditions.checkInDate}<br>${conditions.checkOutDate}</strong></div><div class="guest-summary-row"><span>人数・数量</span><strong>${conditions.guestCount}名・${room.requiredQuantity}${room.roomType.roomKind === "shared_room" ? "ベッド" : "室"}</strong></div>${rate.nights.map((night) => `<div class="guest-summary-row"><span>${night.stayDate}</span><strong>${yen(night.subtotalAmount)}</strong></div>`).join("")}<div class="guest-summary-row guest-total"><span>合計</span><strong>${yen(rate.totalAmount)}</strong></div><small>${policyLabel(rate.plan.cancellationPolicyType)}</small></aside>`;
}

function searchForm() { return `<div class="guest-search"><label>チェックイン<input data-condition="checkInDate" type="date" value="${conditions.checkInDate}" /></label><label>チェックアウト<input data-condition="checkOutDate" type="date" value="${conditions.checkOutDate}" /></label><label>宿泊人数<input data-condition="guestCount" type="number" min="1" value="${conditions.guestCount}" /></label>${currentListing ? "" : `<span></span>`}</div>`; }
function mealLabel(value) { return { room_only: "食事なし", breakfast: "朝食付き", dinner: "夕食付き", breakfast_and_dinner: "朝夕食付き" }[value] || value; }
function policyLabel(value) { return value === "non_refundable" ? "返金不可" : "キャンセル条件あり"; }
function statusLabel(value) { return { requested: "承認待ち", confirmed: "予約確定", canceled: "キャンセル" }[value] || value; }
function yen(value) { return new Intl.NumberFormat("ja-JP", { style: "currency", currency: "JPY" }).format(value); }
function formatDateTime(value) { return value ? new Intl.DateTimeFormat("ja-JP", { dateStyle: "medium", timeStyle: "short" }).format(new Date(value)) : ""; }
function escapeHtml(value) { return String(value ?? "").replace(/[&<>'"]/g, (character) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", "'": "&#39;", '"': "&quot;" })[character]); }

initialize().catch((error) => { content.innerHTML = `<div class="guest-error">${escapeHtml(error.message)}</div>`; });
