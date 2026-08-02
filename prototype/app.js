import {
  availableAssignmentCandidates,
  availableLastNightOn,
  buildStayPreview,
  canPublish,
  createBlankStayListing,
  inventoryForDate,
  makeId,
  normalizeWorkspace,
  physicalInventory,
  priceForDate,
  publicationChecks,
  reservationDashboard,
  reassignReservationInventory,
  transitionStayReservation,
  stayAvailableEndsOn,
} from "./domain.js";

const STORAGE_KEY = "community-hub:stay-listing-prototype:v1";
const viewTitles = {
  listings: "宿泊施設一覧",
  "reservation-dashboard": "予約ダッシュボード",
  reservations: "予約一覧",
  "reservation-detail": "予約詳細",
  overview: "概要",
  facility: "施設情報",
  rooms: "部屋と在庫",
  rates: "料金プラン",
  calendar: "日別設定",
  preview: "宿泊者プレビュー",
  publish: "公開確認",
};

let initialWorkspace;
let workspace;
let state;
let currentView = location.hash.slice(1) || "listings";
let selectedListingId;
let selectedRoomTypeId;
let selectedRatePlanId;
let selectedReservationId;
let reservationReturnView = "reservations";
let reservationFilters = { query: "", status: "all", checkInDate: "" };
let calendarDate = "2026-08-15";
let dashboardDate = "2026-08-15";
let previewConditions = { checkInDate: "2026-08-15", checkOutDate: "2026-08-17", guestCount: 2 };

const content = document.querySelector("#content");
const modal = document.querySelector("#modal");
const modalForm = document.querySelector("#modal-form");

async function initialize() {
  initialWorkspace = normalizeWorkspace(await fetch("./data/stay-listing.json").then((response) => response.json()));
  const stored = localStorage.getItem(STORAGE_KEY);
  workspace = stored ? normalizeWorkspace(JSON.parse(stored)) : structuredClone(initialWorkspace);
  activateListing(workspace.stayListings[0]?.id);
  bindGlobalEvents();
  render();
}

function bindGlobalEvents() {
  document.querySelector("#navigation").addEventListener("click", (event) => {
    const button = event.target.closest("[data-view]");
    if (!button) return;
    currentView = button.dataset.view;
    location.hash = currentView;
    render();
  });

  window.addEventListener("hashchange", () => {
    currentView = location.hash.slice(1) || "listings";
    render();
  });

  document.querySelector("#reset-button").addEventListener("click", () => {
    if (!confirm("入力内容を破棄して初期データへ戻しますか？")) return;
    workspace = structuredClone(initialWorkspace);
    activateListing(workspace.stayListings[0]?.id);
    currentView = "listings";
    location.hash = currentView;
    persist("初期データへ戻しました");
    render();
  });

  document.querySelector("#export-button").addEventListener("click", exportJson);
  document.querySelector("#publish-button").addEventListener("click", publish);
  content.addEventListener("input", handleInput);
  content.addEventListener("change", handleInput);
  content.addEventListener("click", handleClick);
}

function render() {
  if (currentView !== "listings" && !state) currentView = "listings";
  if (currentView === "reservation-detail" && !selectedReservation()) currentView = "reservations";
  document.querySelector("#listing-id").textContent = currentView === "listings" ? workspace.tenant.name : state.id;
  document.querySelector("#page-title").textContent = viewTitles[currentView] || viewTitles.listings;
  document.querySelector("#active-listing-name").textContent = state?.title || "施設未選択";
  document.querySelectorAll("[data-view]").forEach((button) => {
    button.classList.toggle("active", button.dataset.view === currentView);
  });
  document.querySelector("#publish-button").hidden = ["listings", "reservation-dashboard", "reservations", "reservation-detail"].includes(currentView);
  document.querySelector("#publish-button").textContent = state?.status === "published" ? "公開中" : "公開する";

  const renderView = {
    listings: renderListings,
    "reservation-dashboard": renderReservationDashboard,
    reservations: renderReservations,
    "reservation-detail": renderReservationDetail,
    overview: renderOverview,
    facility: renderFacility,
    rooms: renderRooms,
    rates: renderRates,
    calendar: renderCalendar,
    preview: renderPreview,
    publish: renderPublish,
  }[currentView] || renderListings;
  content.innerHTML = renderView();
}

function renderListings() {
  return `
    <section class="page-lead"><div><h2>宿泊施設</h2><p>${escapeHtml(workspace.tenant.name)}が管理する宿泊Listingです。</p></div><button class="button button-primary" data-modal="listing">宿泊施設を追加</button></section>
    <div class="facility-grid">${workspace.stayListings.map((listing) => {
      const checks = publicationChecks(listing);
      const passed = checks.filter((check) => check.passed).length;
      return `<article class="card facility-card"><div class="facility-card-image">${escapeHtml(listing.images[0]?.name || "画像未登録")}</div><div class="facility-card-body"><div class="card-header"><div><h3>${escapeHtml(listing.title)}</h3><p>${escapeHtml([listing.location.prefecture, listing.location.city].filter(Boolean).join(" ") || "所在地未設定")}</p></div><span class="status status-${listing.status}">${listing.status}</span></div><div class="facility-stats"><span>Room Type <strong>${listing.roomTypes.length}</strong></span><span>Rate Plan <strong>${listing.ratePlans.length}</strong></span><span>公開準備 <strong>${passed}/${checks.length}</strong></span></div><button class="button button-primary" data-select-listing="${listing.id}">この施設を管理</button></div></article>`;
    }).join("")}</div>
    ${workspace.stayListings.length ? "" : `<div class="empty">宿泊施設がありません。「宿泊施設を追加」から作成してください。</div>`}`;
}

function renderOverview() {
  const checks = publicationChecks(state);
  const passed = checks.filter((check) => check.passed).length;
  const physical = state.roomTypes.reduce((sum, roomType) => sum + physicalInventory(roomType), 0);
  return `
    <section class="page-lead"><div><h2>${escapeHtml(state.title)}</h2><p>設計上の関連を保ったまま、施設の販売準備状況を確認します。</p></div><span class="status status-${state.status}">${state.status}</span></section>
    <div class="grid grid-3">
      ${metric("Room Types", state.roomTypes.length, `${state.roomTypes.filter((item) => item.status === "published").length}件 公開中`)}
      ${metric("物理在庫", physical, "Room / Bedの有効数")}
      ${metric("Rate Plans", state.ratePlans.length, `${state.roomTypeRates.filter((item) => item.active).length}件の料金設定`)}
    </div>
    <div class="grid grid-main" style="margin-top:18px">
      <section class="card">
        <div class="card-header"><div><h3>販売構成</h3><p>Room Typeごとに在庫と料金プランを横断確認</p></div><button class="button button-small" data-go="rooms">編集する</button></div>
        <table class="table"><thead><tr><th>Room Type</th><th>販売単位</th><th>物理在庫</th><th>料金プラン</th><th>状態</th></tr></thead><tbody>
          ${state.roomTypes.map((roomType) => `<tr><td><strong>${escapeHtml(roomType.name)}</strong></td><td>${roomKindLabel(roomType.roomKind)}</td><td>${physicalInventory(roomType)}</td><td>${state.roomTypeRates.filter((rate) => rate.roomTypeId === roomType.id && rate.active).length}</td><td><span class="status status-${roomType.status}">${roomType.status}</span></td></tr>`).join("")}
        </tbody></table>
      </section>
      <section class="card">
        <div class="card-header"><div><h3>公開準備</h3><p>${passed} / ${checks.length} 項目が完了</p></div><strong>${Math.round((passed / checks.length) * 100)}%</strong></div>
        <div class="progress"><span style="width:${(passed / checks.length) * 100}%"></span></div>
        <ul class="check-list" style="margin-top:16px">${checks.slice(0, 6).map(checkRow).join("")}</ul>
        <button class="button button-primary" data-go="publish" style="width:100%;margin-top:16px">すべての条件を確認</button>
      </section>
    </div>`;
}

function renderReservationDashboard() {
  const dashboard = reservationDashboard(workspace, state.id, dashboardDate);
  const reservationIds = new Set((workspace.stayReservations || []).filter((item) => item.listingId === state.id).map((item) => item.id));
  const events = (workspace.stayReservationEvents || []).filter((event) => reservationIds.has(event.stayReservationId)).slice().sort((left, right) => right.occurredAt.localeCompare(left.occurredAt)).slice(0, 8);
  return `
    <section class="page-lead dashboard-lead"><div><p class="eyebrow">DAILY OPERATIONS</p><h2>${escapeHtml(state.title)}の予約業務</h2><p>承認待ちと当日の到着・出発を、施設単位で確認します。</p></div><div class="field dashboard-date"><label>業務日</label><input id="dashboard-date" type="date" value="${dashboardDate}" /></div></section>
    <div class="grid grid-4 dashboard-metrics">
      ${dashboardMetric("承認待ち", dashboard.pending.length, "回答が必要な予約申請", "attention")}
      ${dashboardMetric("本日の到着", dashboard.arrivals.length, `${dashboard.arrivals.reduce((sum, item) => sum + item.guestCount, 0)}名`, "arrival")}
      ${dashboardMetric("本日の出発", dashboard.departures.length, `${dashboard.departures.reduce((sum, item) => sum + item.guestCount, 0)}名`, "departure")}
      ${dashboardMetric("滞在中", dashboard.staying.length, `${dashboard.staying.reduce((sum, item) => sum + item.guestCount, 0)}名`, "staying")}
    </div>
    <div class="grid dashboard-layout">
      <section class="card"><div class="card-header"><div><h3>承認待ち</h3><p>承認期限が近い順</p></div><span class="dashboard-count">${dashboard.pending.length}件</span></div>${reservationTable(dashboard.pending, { deadline: true, actions: true })}</section>
      <section class="card"><div class="card-header"><div><h3>${formatStayDate(dashboardDate)}の到着</h3><p>確定済みのチェックイン予定</p></div><span class="dashboard-count">${dashboard.arrivals.length}件</span></div>${reservationList(dashboard.arrivals, "arrival")}</section>
      <section class="card"><div class="card-header"><div><h3>${formatStayDate(dashboardDate)}の出発</h3><p>確定済みのチェックアウト予定</p></div><span class="dashboard-count">${dashboard.departures.length}件</span></div>${reservationList(dashboard.departures, "departure")}</section>
      <section class="card"><div class="card-header"><div><h3>最近の予約</h3><p>状態を含む直近8件</p></div></div>${reservationTable(dashboard.recent, { actions: true })}</section>
      <section class="card dashboard-history"><div class="card-header"><div><h3>最近の操作履歴</h3><p>担当者、理由、変更前後の状態</p></div></div>${reservationEventList(events)}</section>
    </div>`;
}

function renderReservations() {
  const reservations = (workspace.stayReservations || [])
    .filter((reservation) => reservation.listingId === state.id)
    .filter((reservation) => reservationFilters.status === "all" || reservation.status === reservationFilters.status)
    .filter((reservation) => !reservationFilters.checkInDate || reservation.checkInDate === reservationFilters.checkInDate)
    .filter((reservation) => {
      const query = reservationFilters.query.trim().toLowerCase();
      if (!query) return true;
      const primaryGuest = reservation.guests?.find((guest) => guest.guestRole === "primary");
      return `${reservation.reservationNumber || reservation.id} ${primaryGuest?.name || ""}`.toLowerCase().includes(query);
    })
    .sort((left, right) => String(right.createdAt || "").localeCompare(String(left.createdAt || "")));
  return `
    <section class="page-lead"><div><p class="eyebrow">RESERVATIONS</p><h2>予約一覧</h2><p>${escapeHtml(state.title)}の予約を検索・確認します。</p></div><span class="dashboard-count">${reservations.length}件</span></section>
    <section class="card reservation-filter-card"><div class="reservation-filters">
      <div class="field"><label>予約番号・宿泊者</label><input data-reservation-filter="query" value="${escapeHtml(reservationFilters.query)}" placeholder="検索" /></div>
      <div class="field"><label>状態</label><select data-reservation-filter="status">${[["all", "すべて"], ["requested", "承認待ち"], ["confirmed", "予約確定"], ["rejected", "拒否"], ["canceled", "キャンセル"], ["expired", "期限切れ"], ["completed", "宿泊完了"], ["no_show", "無断不泊"]].map(([value, label]) => `<option value="${value}" ${reservationFilters.status === value ? "selected" : ""}>${label}</option>`).join("")}</select></div>
      <div class="field"><label>チェックイン日</label><input data-reservation-filter="checkInDate" type="date" value="${reservationFilters.checkInDate}" /></div>
      <button class="button" data-clear-reservation-filters>条件をクリア</button>
    </div></section>
    <section class="card reservation-list-card">${reservationListTable(reservations)}</section>`;
}

function reservationListTable(reservations) {
  if (!reservations.length) return `<div class="empty">条件に一致する予約はありません</div>`;
  return `<div class="table-scroll"><table class="table reservation-list-table"><thead><tr><th>予約・宿泊者</th><th>Room Type</th><th>宿泊日程</th><th>到着予定</th><th>人数</th><th>合計</th><th>状態</th><th></th></tr></thead><tbody>${reservations.map((reservation) => {
    const guest = reservation.guests?.find((item) => item.guestRole === "primary");
    return `<tr><td><strong>${escapeHtml(reservation.reservationNumber || reservation.id)}</strong><small>${escapeHtml(guest?.name || "宿泊者未登録")}</small></td><td>${escapeHtml(reservation.priceSnapshot?.room_type?.name || roomTypeName(reservation.roomTypeId))}</td><td>${reservation.checkInDate}<small>→ ${reservation.checkOutDate}</small></td><td>${reservation.expectedArrivalAt ? expectedArrivalLabel(reservation.expectedArrivalAt) : `<span class="deadline">未定</span>`}</td><td>${reservation.guestCount}名</td><td class="price">${yen(reservation.totalAmount)}</td><td><span class="status status-${reservation.status}">${statusLabel(reservation.status)}</span></td><td><button class="button button-small" data-open-reservation="${reservation.id}" data-return-view="reservations">詳細</button></td></tr>`;
  }).join("")}</tbody></table></div>`;
}

function renderReservationDetail() {
  const reservation = selectedReservation();
  const primaryGuest = reservation.guests?.find((guest) => guest.guestRole === "primary");
  const companions = reservation.guests?.filter((guest) => guest.guestRole === "companion") || [];
  const events = (workspace.stayReservationEvents || []).filter((event) => event.stayReservationId === reservation.id).slice().sort((left, right) => right.occurredAt.localeCompare(left.occurredAt));
  const nights = reservation.priceSnapshot?.nights || [];
  return `
    <section class="detail-head"><div><button class="button button-small" data-back-reservations>← ${reservationReturnView === "reservation-dashboard" ? "ダッシュボード" : "予約一覧"}</button><p class="eyebrow">${escapeHtml(reservation.reservationNumber || reservation.id)}</p><div class="detail-title"><h2>${escapeHtml(primaryGuest?.name || "宿泊者未登録")}</h2><span class="status status-${reservation.status}">${statusLabel(reservation.status)}</span></div><p>${reservation.checkInDate} → ${reservation.checkOutDate}・${reservation.guestCount}名</p></div><div class="detail-actions">${reservationActionButtons(reservation)}</div></section>
    <div class="grid detail-layout">
      <div class="grid">
        <section class="card"><div class="card-header"><div><h3>宿泊内容</h3><p>予約時点の販売条件</p></div><strong class="detail-total">${yen(reservation.totalAmount)}</strong></div><dl class="definition-grid"><div><dt>Room Type</dt><dd>${escapeHtml(reservation.priceSnapshot?.room_type?.name || roomTypeName(reservation.roomTypeId))}</dd></div><div><dt>Rate Plan</dt><dd>${escapeHtml(reservation.priceSnapshot?.rate_plan?.name || "—")}</dd></div><div><dt>到着予定</dt><dd>${reservation.expectedArrivalAt ? formatDateTime(reservation.expectedArrivalAt) : "未定"}</dd></div><div><dt>数量</dt><dd>${reservation.quantity}${reservation.priceSnapshot?.pricing_unit === "bed" ? "ベッド" : "室"}</dd></div></dl>${nights.length ? `<div class="nightly-breakdown">${nights.map((night) => `<div><span>${night.stay_date}</span><span>${yen(night.unit_amount)} × ${night.quantity}</span><strong>${yen(night.subtotal_amount)}</strong></div>`).join("")}</div>` : ""}</section>
        <section class="card"><div class="card-header"><div><h3>物理Room／Bed割り当て</h3><p>同じRoom Typeの空き在庫へ変更できます</p></div></div>${assignmentEditor(reservation)}</section>
        <section class="card"><div class="card-header"><div><h3>操作履歴</h3><p>追記専用の状態変更履歴</p></div></div>${reservationEventList(events)}</section>
      </div>
      <aside class="grid detail-side">
        <section class="card"><div class="card-header"><div><h3>宿泊者</h3><p>代表宿泊者と同行者</p></div></div><dl class="stacked-definition"><div><dt>代表宿泊者</dt><dd>${escapeHtml(primaryGuest?.name || "—")}</dd></div><div><dt>メール</dt><dd>${escapeHtml(primaryGuest?.email || "—")}</dd></div><div><dt>電話番号</dt><dd>${escapeHtml(primaryGuest?.phone || "—")}</dd></div><div><dt>同行者</dt><dd>${companions.length ? companions.map((guest) => escapeHtml(guest.name)).join("、") : "未登録"}</dd></div></dl></section>
        <section class="card"><div class="card-header"><div><h3>キャンセル条件</h3><p>予約時スナップショット</p></div></div>${cancellationPolicyView(reservation.cancellationPolicySnapshot)}</section>
        <section class="card"><div class="card-header"><div><h3>利用者メッセージ</h3></div></div><p class="detail-message">${escapeHtml(reservation.message || "メッセージはありません")}</p></section>
      </aside>
    </div>`;
}

function assignmentEditor(reservation) {
  const assignments = [
    ...(reservation.roomAssignments || []).map((item) => ({ ...item, id: item.stayRoomId, kind: "room" })),
    ...(reservation.bedAssignments || []).map((item) => ({ ...item, id: item.stayBedId, kind: "bed" })),
  ];
  if (!assignments.length) return `<div class="empty">物理在庫は割り当てられていません</div>`;
  const candidates = reservation.status === "confirmed" ? availableAssignmentCandidates(workspace, reservation.id) : [];
  return `<div class="assignment-list">${assignments.map((assignment) => `<div class="assignment-row"><div><span class="assignment-kind">${assignment.kind === "bed" ? "BED" : "ROOM"}</span><strong>${escapeHtml(inventoryName(assignment.id))}</strong><small>${assignment.assignedAt ? `更新 ${formatDateTime(assignment.assignedAt)}` : ""}</small></div>${reservation.status === "confirmed" ? `<select aria-label="変更先"><option value="">変更先を選択</option>${candidates.filter((candidate) => candidate.kind === assignment.kind).map((candidate) => `<option value="${candidate.id}">${escapeHtml(candidate.name)}</option>`).join("")}</select><button class="button button-small" data-reassign-inventory="${assignment.id}">変更</button>` : `<span class="muted">確定予約のみ変更可能</span>`}</div>`).join("")}</div>`;
}

function cancellationPolicyView(snapshot) {
  if (!snapshot) return `<p class="muted">スナップショットがありません</p>`;
  if (snapshot.type === "non_refundable") return `<div class="policy-callout"><strong>返金不可</strong><span>予約確定後 ${snapshot.penalty_rate}%</span></div>`;
  return `<div class="policy-rules">${(snapshot.rules || []).map((rule) => `<div><span>${rule.hours_before_check_in}時間前から</span><strong>${rule.penalty_rate}%</strong></div>`).join("") || `<p class="muted">標準キャンセル条件</p>`}<div><span>無断不泊</span><strong>${snapshot.no_show_penalty_rate ?? 100}%</strong></div></div>`;
}

function reservationEventList(events) {
  if (!events.length) return `<div class="empty dashboard-empty">操作履歴はまだありません</div>`;
  return `<div class="event-list">${events.map((event) => {
    const reservation = workspace.stayReservations.find((item) => item.id === event.stayReservationId);
    return `<article class="event-item"><div><strong>${eventLabel(event.eventType)}</strong><small>${escapeHtml(reservation?.reservationNumber || event.stayReservationId)}・${formatDateTime(event.occurredAt)}</small></div><div><span>${statusLabel(event.fromStatus)} → ${statusLabel(event.toStatus)}</span><small>${event.reasonCode ? reasonLabel(event.reasonCode) : "理由入力なし"}・${escapeHtml(event.tenantMemberId || "システム")}</small></div></article>`;
  }).join("")}</div>`;
}

function reservationTable(reservations, options = {}) {
  if (!reservations.length) return `<div class="empty dashboard-empty">該当する予約はありません</div>`;
  return `<div class="table-scroll"><table class="table reservation-table"><thead><tr><th>予約・宿泊者</th><th>宿泊内容</th><th>${options.deadline ? "承認期限" : "状態"}</th><th>金額</th>${options.actions ? "<th>操作</th>" : ""}</tr></thead><tbody>${reservations.map((reservation) => {
    const guest = reservation.guests?.find((item) => item.guestRole === "primary");
    return `<tr><td><button class="table-link" data-open-reservation="${reservation.id}" data-return-view="reservation-dashboard"><strong>${escapeHtml(guest?.name || "宿泊者未登録")}</strong><small>${escapeHtml(reservation.reservationNumber || reservation.id)}</small></button></td><td><strong>${escapeHtml(reservation.priceSnapshot?.room_type?.name || roomTypeName(reservation.roomTypeId))}</strong><small>${reservation.checkInDate} → ${reservation.checkOutDate}・${reservation.guestCount}名</small></td><td>${options.deadline ? `<strong class="deadline">${formatDateTime(reservation.approvalExpiresAt)}</strong>` : `<span class="status status-${reservation.status}">${statusLabel(reservation.status)}</span>`}</td><td class="price">${yen(reservation.totalAmount)}</td>${options.actions ? `<td>${reservationActionButtons(reservation)}</td>` : ""}</tr>`;
  }).join("")}</tbody></table></div>`;
}

function reservationList(reservations, type) {
  if (!reservations.length) return `<div class="empty dashboard-empty">予定はありません</div>`;
  return `<div class="operation-list">${reservations.map((reservation) => {
    const guest = reservation.guests?.find((item) => item.guestRole === "primary");
    const time = type === "arrival" ? expectedArrivalLabel(reservation.expectedArrivalAt) : state.stay.checkOutTime;
    return `<article class="operation-item"><time class="${type === "arrival" && !reservation.expectedArrivalAt ? "time-undecided" : ""}">${escapeHtml(time)}</time><div><strong>${escapeHtml(guest?.name || "宿泊者未登録")}</strong><small>${escapeHtml(reservation.priceSnapshot?.room_type?.name || roomTypeName(reservation.roomTypeId))}・${reservation.guestCount}名</small></div><span>${escapeHtml(assignmentLabel(reservation))}</span></article>`;
  }).join("")}</div>`;
}

function renderFacility() {
  const facilityAmenities = workspace.amenities.filter((item) => ["facility", "both"].includes(item.scope) && item.active);
  return `
    <section class="page-lead"><div><h2>施設情報</h2><p>Listing共通情報とStay固有の予約受付設定を編集します。</p></div></section>
    <div class="grid grid-main">
      <div class="grid">
        <section class="card"><div class="card-header"><div><h3>基本情報</h3><p>一般ユーザーへ表示される内容</p></div></div>
          <div class="field-grid">
            ${field("施設名", "title", state.title, "text", "field-wide")}
            ${textarea("施設説明", "description", state.description, "field-wide")}
            ${field("画像件数（疑似）", "images.length", state.images.length, "number")}
            ${field("タイムゾーン", "stay.timeZone", state.stay.timeZone)}
          </div>
        </section>
        <section class="card"><div class="card-header"><div><h3>住所・位置情報</h3><p>プロトタイプではGeocodingを行わず直接入力</p></div></div>
          <div class="field-grid">
            ${field("郵便番号", "location.postalCode", state.location.postalCode)}
            ${field("都道府県", "location.prefecture", state.location.prefecture)}
            ${field("市区町村", "location.city", state.location.city)}
            ${field("町名・番地", "location.addressLine1", state.location.addressLine1)}
            ${field("建物名", "location.addressLine2", state.location.addressLine2, "text", "field-wide")}
            ${field("緯度", "location.latitude", state.location.latitude, "number")}
            ${field("経度", "location.longitude", state.location.longitude, "number")}
          </div>
        </section>
      </div>
      <div class="grid">
        <section class="card"><div class="card-header"><div><h3>予約受付</h3><p>施設単位の設定</p></div></div>
          <div class="field-grid">
            ${selectField("確定方式", "stay.bookingConfirmationMode", state.stay.bookingConfirmationMode, [["approval_required", "承認制"], ["instant", "即時確定"]], "field-wide")}
            ${field("承認期限（時間）", "stay.approvalDeadlineHours", state.stay.approvalDeadlineHours, "number")}
            ${field("受付開始（日前）", "stay.bookingOpenDaysBefore", state.stay.bookingOpenDaysBefore, "number")}
            ${field("チェックイン", "stay.checkInTime", state.stay.checkInTime, "time")}
            ${field("最終チェックイン", "stay.latestCheckInTime", state.stay.latestCheckInTime, "time")}
            ${field("チェックアウト", "stay.checkOutTime", state.stay.checkOutTime, "time")}
            <div class="field field-wide"><label>宿泊提供期間</label><small class="muted">空欄の場合、その方向の期間を制限しません</small></div>
            ${field("最初に宿泊できる日", "stay.stayAvailableStartsOn", state.stay.stayAvailableStartsOn, "date")}
            ${field("最後に宿泊できる日", "stay.availableLastNightOn", availableLastNightOn(state.stay.stayAvailableEndsOn), "date")}
          </div>
        </section>
        <section class="card"><div class="card-header"><div><h3>施設Amenities</h3><p>公開条件には含まれません</p></div></div>
          <div class="amenities">${facilityAmenities.map((amenity) => amenityButton(amenity, state.stay.facilityAmenityIds.includes(amenity.id), "facility-amenity")).join("")}</div>
        </section>
      </div>
    </div>`;
}

function renderRooms() {
  const selected = state.roomTypes.find((item) => item.id === selectedRoomTypeId) || state.roomTypes[0];
  if (selected) selectedRoomTypeId = selected.id;
  return `
    <section class="page-lead"><div><h2>部屋と物理在庫</h2><p>利用者が選ぶRoom Typeと、運営が管理するRoom / Bedを分けて確認します。</p></div><button class="button button-primary" data-modal="room-type">Room Typeを追加</button></section>
    <div class="grid grid-main">
      <section class="card"><div class="card-header"><div><h3>Room Types</h3><p>施設固有の販売分類</p></div></div>
        <div class="entity-list">${state.roomTypes.map((roomType) => `<button class="entity-row ${roomType.id === selected?.id ? "selected" : ""}" data-select-room-type="${roomType.id}"><span><strong>${escapeHtml(roomType.name)}</strong><small>${roomKindLabel(roomType.roomKind)} · 在庫 ${physicalInventory(roomType)}</small></span><span class="status status-${roomType.status}">${roomType.status}</span></button>`).join("")}</div>
      </section>
      ${selected ? renderRoomTypeEditor(selected) : `<section class="card empty">Room Typeを追加してください</section>`}
    </div>`;
}

function renderRoomTypeEditor(roomType) {
  const roomAmenities = workspace.amenities.filter((item) => ["room_type", "both"].includes(item.scope) && item.active);
  return `<div class="grid">
    <section class="card"><div class="card-header"><div><h3>${escapeHtml(roomType.name)}</h3><p>販売単位: ${roomKindLabel(roomType.roomKind)}</p></div><span class="status status-${roomType.status}">${roomType.status}</span></div>
      <div class="field-grid">
        ${field("名称", `roomType.${roomType.id}.name`, roomType.name)}
        ${selectField("状態", `roomType.${roomType.id}.status`, roomType.status, [["draft", "draft"], ["published", "published"], ["inactive", "inactive"]])}
        ${selectField("販売形態", `roomType.${roomType.id}.roomKind`, roomType.roomKind, [["entire_place", "一棟貸し"], ["private_room", "個室"], ["shared_room", "相部屋"]])}
        ${field("1販売単位の定員", `roomType.${roomType.id}.capacity`, roomType.capacity, "number")}
        ${textarea("説明", `roomType.${roomType.id}.description`, roomType.description, "field-wide")}
      </div>
      <div class="amenities" style="margin-top:16px">${roomAmenities.map((amenity) => amenityButton(amenity, roomType.amenityIds.includes(amenity.id), `room-amenity:${roomType.id}`)).join("")}</div>
    </section>
    <section class="card"><div class="card-header"><div><h3>物理Room / Bed</h3><p>有効な${roomType.roomKind === "shared_room" ? "Bed" : "Room"}が基本在庫になります</p></div><button class="button button-small" data-modal="room">Roomを追加</button></div>
      ${roomType.rooms.length ? `<table class="table"><thead><tr><th>Room</th><th>管理メモ / Beds</th><th>有効</th><th></th></tr></thead><tbody>${roomType.rooms.map((room) => `<tr><td><strong>${escapeHtml(room.name)}</strong></td><td>${roomType.roomKind === "shared_room" ? room.beds.map((bed) => `<button class="amenity ${bed.active ? "selected" : ""}" data-toggle-bed="${room.id}:${bed.id}">${escapeHtml(bed.name)}</button>`).join(" ") || "Bedなし" : escapeHtml(room.notes || "—")}</td><td><button class="toggle ${room.active ? "on" : ""}" data-toggle-room="${room.id}" aria-label="Roomの有効状態"></button></td><td>${roomType.roomKind === "shared_room" ? `<button class="button button-small" data-modal="bed" data-room-id="${room.id}">Bed追加</button>` : ""}</td></tr>`).join("")}</tbody></table>` : `<div class="empty">物理Roomがありません</div>`}
    </section>
  </div>`;
}

function renderRates() {
  const selected = state.ratePlans.find((item) => item.id === selectedRatePlanId) || state.ratePlans[0];
  if (selected) selectedRatePlanId = selected.id;
  return `
    <section class="page-lead"><div><h2>料金プラン</h2><p>Rate Planは販売条件、金額はRoom Typeとの組み合わせに設定します。</p></div><button class="button button-primary" data-modal="rate-plan">Rate Planを追加</button></section>
    <div class="grid grid-main">
      <section class="card"><div class="card-header"><div><h3>Rate Plans</h3><p>施設固有の販売条件</p></div></div><div class="entity-list">${state.ratePlans.map((plan) => `<button class="entity-row ${plan.id === selected?.id ? "selected" : ""}" data-select-rate-plan="${plan.id}"><span><strong>${escapeHtml(plan.name)}</strong><small>${mealLabel(plan.mealType)} · ${policyLabel(plan.cancellationPolicyType)}</small></span><span class="status status-${plan.status}">${plan.status}</span></button>`).join("")}</div></section>
      ${selected ? `<div class="grid"><section class="card"><div class="card-header"><div><h3>${escapeHtml(selected.name)}</h3><p>プラン設定</p></div></div><div class="field-grid">${field("名称", `ratePlan.${selected.id}.name`, selected.name)}${selectField("状態", `ratePlan.${selected.id}.status`, selected.status, [["draft", "draft"], ["published", "published"], ["inactive", "inactive"]])}${selectField("食事", `ratePlan.${selected.id}.mealType`, selected.mealType, [["room_only", "素泊まり"], ["breakfast", "朝食"], ["dinner", "夕食"], ["breakfast_and_dinner", "朝夕食"]])}${selectField("キャンセル", `ratePlan.${selected.id}.cancellationPolicyType`, selected.cancellationPolicyType, [["standard", "標準"], ["non_refundable", "返金不可"]])}${textarea("説明", `ratePlan.${selected.id}.description`, selected.description, "field-wide")}</div></section>
      <section class="card"><div class="card-header"><div><h3>Room Type別の基本料金</h3><p>JPY / 1販売単位 / 1泊</p></div></div><table class="table"><thead><tr><th>Room Type</th><th>金額</th><th>販売</th></tr></thead><tbody>${state.roomTypes.map((roomType) => rateEditorRow(roomType, selected)).join("")}</tbody></table></section></div>` : ""}
    </div>`;
}

function rateEditorRow(roomType, plan) {
  const rate = state.roomTypeRates.find((item) => item.roomTypeId === roomType.id && item.ratePlanId === plan.id);
  return `<tr><td><strong>${escapeHtml(roomType.name)}</strong></td><td><input data-rate-amount="${roomType.id}:${plan.id}" type="number" min="1" value="${rate?.pricePerNightAmount ?? ""}" placeholder="未設定" /></td><td><button class="toggle ${rate?.active ? "on" : ""}" data-toggle-rate="${roomType.id}:${plan.id}" aria-label="料金の有効状態"></button></td></tr>`;
}

function renderCalendar() {
  return `
    <section class="page-lead"><div><h2>日別料金・販売上限</h2><p>日付ごとの例外だけを保存し、未設定日は基本料金と物理在庫へフォールバックします。</p></div></section>
    <section class="card"><div class="calendar-controls"><div class="field"><label>宿泊日</label><input id="calendar-date" type="date" value="${calendarDate}" /></div><div class="muted">選択日の料金と販売可能数を比較します</div></div></section>
    <section class="card" style="margin-top:18px"><table class="table"><thead><tr><th>Room Type</th><th>物理在庫</th><th>販売上限</th><th>販売可能数</th><th>Rate Plan</th><th>基本料金</th><th>日別料金</th></tr></thead><tbody>
      ${state.roomTypes.flatMap((roomType) => {
        const rates = state.roomTypeRates.filter((rate) => rate.roomTypeId === roomType.id && rate.active);
        return (rates.length ? rates : [null]).map((rate, index) => {
          const control = roomType.dailySalesControls.find((item) => item.stayDate === calendarDate);
          const plan = rate && state.ratePlans.find((item) => item.id === rate.ratePlanId);
          const daily = rate?.dailyPrices.find((item) => item.stayDate === calendarDate);
          return `<tr>${index === 0 ? `<td rowspan="${rates.length || 1}"><strong>${escapeHtml(roomType.name)}</strong></td><td rowspan="${rates.length || 1}">${physicalInventory(roomType)}</td><td rowspan="${rates.length || 1}"><input data-sales-limit="${roomType.id}" type="number" min="0" value="${control?.salesLimit ?? ""}" placeholder="制限なし" /></td><td rowspan="${rates.length || 1}"><strong>${inventoryForDate(roomType, calendarDate)}</strong></td>` : ""}<td>${plan ? escapeHtml(plan.name) : "料金なし"}</td><td class="price">${rate ? yen(rate.pricePerNightAmount) : "—"}</td><td>${rate ? `<input data-daily-price="${rate.id}" type="number" min="1" value="${daily?.priceAmount ?? ""}" placeholder="${priceForDate(state, roomType.id, plan.id, calendarDate)}" />` : "—"}</td></tr>`;
        });
      }).join("")}
    </tbody></table></section>`;
}

function renderPreview() {
  const preview = buildStayPreview(state, previewConditions);
  const sellableRooms = preview.roomTypes.filter((item) => item.sellable);
  const facilityAmenities = workspace.amenities.filter((item) => state.stay.facilityAmenityIds.includes(item.id) && item.active);
  return `
    <section class="page-lead"><div><h2>宿泊者プレビュー</h2><p>現在の設定が指定日程で宿泊者にどう販売されるか確認します。</p></div><span class="preview-badge">プレビュー</span></section>
    <section class="card preview-search"><div class="field-grid">
      ${previewField("チェックイン", "checkInDate", previewConditions.checkInDate, "date")}
      ${previewField("チェックアウト", "checkOutDate", previewConditions.checkOutDate, "date")}
      ${previewField("宿泊人数", "guestCount", previewConditions.guestCount, "number")}
    </div></section>
    <section class="preview-hero">
      <div><span class="eyebrow">STAY</span><h2>${escapeHtml(state.title)}</h2><p>${escapeHtml(state.description)}</p><div class="amenities">${facilityAmenities.map((item) => `<span class="amenity selected">${escapeHtml(item.name)}</span>`).join("")}</div></div>
      <div class="preview-image"><span>${escapeHtml(state.images[0]?.name || "施設画像なし")}</span></div>
    </section>
    <div class="preview-section-title"><div><h2>選択できる客室</h2><p>${preview.dates.length}泊・${previewConditions.guestCount}名</p></div><strong>${sellableRooms.length}件</strong></div>
    <div class="grid preview-results">
      ${sellableRooms.length ? sellableRooms.map(renderPreviewRoom).join("") : `<section class="card empty"><strong>この日程で予約できる客室はありません</strong><p>日程または宿泊人数を変更してお試しください。</p></section>`}
    </div>`;
}

function renderPreviewRoom(item) {
  const amenities = workspace.amenities.filter((amenity) => item.roomType.amenityIds.includes(amenity.id) && amenity.active);
  return `<article class="card preview-room"><div class="preview-room-image">ROOM TYPE</div><div><div class="card-header"><div><h3>${escapeHtml(item.roomType.name)}</h3><p>${escapeHtml(item.roomType.description)}</p></div><span class="remaining">残り${item.availableUnits}${item.roomType.roomKind === "shared_room" ? "ベッド" : "室"}</span></div>
    <div class="amenities">${amenities.map((amenity) => `<span class="amenity">${escapeHtml(amenity.name)}</span>`).join("")}</div>
    <div class="preview-rates">${item.rates.filter((rate) => rate.sellable).map((rate) => `<section class="preview-rate"><div class="preview-rate-header"><div><strong>${escapeHtml(rate.plan.name)}</strong><small>${escapeHtml(rate.plan.description || "")} · ${mealLabel(rate.plan.mealType)} · ${policyLabel(rate.plan.cancellationPolicyType)}</small></div><div class="preview-price"><strong>${yen(rate.totalAmount)}</strong><small>${previewConditions.guestCount}名・${rate.nights.length}泊の宿泊料金合計</small></div></div><div class="nightly-breakdown">${rate.nights.map((night) => `<div><span>${formatStayDate(night.stayDate)}</span><span>${yen(night.unitAmount)} × ${night.quantity}${item.roomType.roomKind === "shared_room" ? "ベッド" : "室"}</span><strong>${yen(night.subtotalAmount)}</strong></div>`).join("")}</div><button class="button button-primary preview-select" type="button">このプランを選ぶ</button></section>`).join("")}</div>
  </div></article>`;
}

function renderPublish() {
  const checks = publicationChecks(state);
  return `<section class="page-lead"><div><h2>公開確認</h2><p>Listing・施設・Room Type・Rate Plan・料金の境界を横断して検証します。</p></div><button class="button button-primary" data-publish>${state.status === "published" ? "公開済み" : "条件を確認して公開"}</button></section>
    <div class="grid grid-main"><section class="card"><div class="card-header"><div><h3>公開必須条件</h3><p>${checks.filter((item) => item.passed).length} / ${checks.length} 完了</p></div></div><ul class="check-list">${checks.map(checkRow).join("")}</ul></section>
    <section class="card"><div class="card-header"><div><h3>保存されるJSON</h3><p>ERへ変換可能な集約形式</p></div></div><pre class="json-preview">${escapeHtml(JSON.stringify(state, null, 2))}</pre></section></div>`;
}

function handleInput(event) {
  const input = event.target;
  if (input.dataset.reservationFilter) {
    reservationFilters[input.dataset.reservationFilter] = input.value;
    if (event.type === "change") render();
    return;
  }
  if (input.id === "dashboard-date") {
    dashboardDate = input.value;
    render();
    return;
  }
  if (input.id === "calendar-date") {
    calendarDate = input.value;
    render();
    return;
  }
  if (input.dataset.preview) {
    previewConditions[input.dataset.preview] = input.type === "number" ? Number(input.value) : input.value;
    if (event.type === "change") render();
    return;
  }
  if (input.dataset.path) {
    setPath(input.dataset.path, input.type === "number" ? Number(input.value) : input.value);
  } else if (input.dataset.rateAmount) {
    const [roomTypeId, ratePlanId] = input.dataset.rateAmount.split(":");
    upsertRate(roomTypeId, ratePlanId, Number(input.value), true);
  } else if (input.dataset.salesLimit) {
    upsertDailyControl(input.dataset.salesLimit, input.value === "" ? null : Number(input.value));
  } else if (input.dataset.dailyPrice) {
    upsertDailyPrice(input.dataset.dailyPrice, input.value === "" ? null : Number(input.value));
  } else return;
  persist();
  if (event.type === "change") render();
}

function handleClick(event) {
  const target = event.target.closest("button");
  if (!target) return;
  if (target.dataset.go) { currentView = target.dataset.go; location.hash = currentView; render(); }
  if (target.dataset.selectListing) { activateListing(target.dataset.selectListing); currentView = "reservation-dashboard"; location.hash = currentView; render(); }
  if (target.dataset.selectRoomType) { selectedRoomTypeId = target.dataset.selectRoomType; render(); }
  if (target.dataset.selectRatePlan) { selectedRatePlanId = target.dataset.selectRatePlan; render(); }
  if (target.dataset.modal) openModal(target.dataset.modal, target.dataset.roomId);
  if (target.dataset.toggleRoom) toggleRoom(target.dataset.toggleRoom);
  if (target.dataset.toggleBed) toggleBed(target.dataset.toggleBed);
  if (target.dataset.toggleRate) toggleRate(target.dataset.toggleRate);
  if (target.dataset.amenity) toggleAmenity(target.dataset.amenity, target.dataset.target);
  if (target.dataset.openReservation) {
    selectedReservationId = target.dataset.openReservation;
    reservationReturnView = target.dataset.returnView || currentView;
    currentView = "reservation-detail";
    location.hash = currentView;
    render();
  }
  if (target.hasAttribute("data-back-reservations")) { currentView = reservationReturnView; location.hash = currentView; render(); }
  if (target.hasAttribute("data-clear-reservation-filters")) { reservationFilters = { query: "", status: "all", checkInDate: "" }; render(); }
  if (target.dataset.reassignInventory) applyInventoryReassignment(target, target.dataset.reassignInventory);
  if (target.dataset.reservationAction) openReservationAction(target.dataset.reservationAction, target.dataset.reservationId);
  if (target.hasAttribute("data-publish")) publish();
}

function openModal(type, roomId) {
  const definitions = {
    listing: ["宿泊施設を追加", field("施設名", "modal.name", "")],
    "room-type": ["Room Typeを追加", `${field("名称", "modal.name", "")}${selectField("販売形態", "modal.kind", "private_room", [["private_room", "個室"], ["shared_room", "相部屋"], ["entire_place", "一棟貸し"]])}${field("定員", "modal.capacity", 2, "number")}`],
    room: ["物理Roomを追加", field("管理名", "modal.name", "")],
    bed: ["Bedを追加", field("管理名", "modal.name", "")],
    "rate-plan": ["Rate Planを追加", `${field("名称", "modal.name", "")}${selectField("食事", "modal.meal", "room_only", [["room_only", "素泊まり"], ["breakfast", "朝食"], ["dinner", "夕食"], ["breakfast_and_dinner", "朝夕食"]])}${selectField("キャンセル", "modal.policy", "standard", [["standard", "標準"], ["non_refundable", "返金不可"]])}`],
  };
  const [title, body] = definitions[type];
  document.querySelector("#modal-title").textContent = title;
  document.querySelector("#modal-submit").textContent = "追加する";
  document.querySelector("#modal-body").innerHTML = `<div class="field-grid">${body}</div>`;
  modalForm.dataset.type = type;
  modalForm.dataset.roomId = roomId || "";
  modalForm.onsubmit = submitModal;
  modal.showModal();
}

function openReservationAction(action, reservationId) {
  const reservation = workspace.stayReservations.find((item) => item.id === reservationId);
  if (!reservation) return;
  if (action === "approve") {
    if (!confirm(`${reservation.reservationNumber || reservation.id}を承認して予約を確定しますか？`)) return;
    applyReservationTransition({ reservationId, action });
    return;
  }
  const isReject = action === "reject";
  const reasonOptions = isReject
    ? [["", "選択してください"], ["unable_to_accommodate", "受け入れ困難"], ["request_not_acceptable", "要望に対応できない"], ["facility_unavailable", "施設を提供できない"], ["other", "その他"]]
    : [["", "選択してください"], ["facility_unavailable", "施設を提供できない"], ["maintenance", "設備メンテナンス"], ["overbooking", "オーバーブッキング"], ["safety", "安全上の理由"], ["other", "その他"]];
  document.querySelector("#modal-title").textContent = isReject ? "予約申請を拒否" : "予約を取り消す";
  document.querySelector("#modal-body").innerHTML = `<div class="reservation-action-summary"><strong>${escapeHtml(reservation.reservationNumber || reservation.id)}</strong><span>${escapeHtml(reservation.guests?.find((guest) => guest.guestRole === "primary")?.name || "宿泊者未登録")}・${reservation.checkInDate} → ${reservation.checkOutDate}</span></div><div class="field-grid">${selectField("理由", "reasonCode", "", reasonOptions, "field-wide")}${textarea("利用者向け説明", "reasonDetail", "", "field-wide")}${textarea("内部メモ（利用者には表示されません）", "internalNote", "", "field-wide")}</div>`;
  document.querySelector("#modal-submit").textContent = isReject ? "拒否する" : "予約を取り消す";
  modalForm.dataset.type = `reservation-${action}`;
  modalForm.dataset.reservationId = reservationId;
  modalForm.onsubmit = submitModal;
  modal.showModal();
}

function submitModal(event) {
  event.preventDefault();
  if (event.submitter?.value === "cancel") {
    modal.close();
    return;
  }
  const values = Object.fromEntries(new FormData(modalForm).entries());
  const type = modalForm.dataset.type;
  if (type.startsWith("reservation-")) {
    applyReservationTransition({
      reservationId: modalForm.dataset.reservationId,
      action: type.replace("reservation-", ""),
      reasonCode: values.reasonCode,
      reasonDetail: values.reasonDetail,
      internalNote: values.internalNote,
    });
    return;
  }
  const name = values["modal.name"]?.trim();
  if (!name) return;
  if (type === "listing") {
    const listing = createBlankStayListing(name);
    workspace.stayListings.push(listing);
    activateListing(listing.id);
    currentView = "facility";
    location.hash = currentView;
  } else if (type === "room-type") {
    const id = makeId("room-type");
    state.roomTypes.push({ id, name, description: "", roomKind: values["modal.kind"], capacity: values["modal.kind"] === "shared_room" ? 1 : Number(values["modal.capacity"]), status: "draft", amenityIds: [], rooms: [], dailySalesControls: [] });
    selectedRoomTypeId = id;
  } else if (type === "room") {
    selectedRoomType().rooms.push({ id: makeId("room"), name, active: true, notes: "", beds: [] });
  } else if (type === "bed") {
    selectedRoomType().rooms.find((room) => room.id === modalForm.dataset.roomId).beds.push({ id: makeId("bed"), name, active: true });
  } else if (type === "rate-plan") {
    const id = makeId("plan");
    state.ratePlans.push({ id, name, description: "", mealType: values["modal.meal"], cancellationPolicyType: values["modal.policy"], status: "draft" });
    selectedRatePlanId = id;
  }
  modal.close();
  persist(`${name}を追加しました`);
  render();
}

function applyReservationTransition(input) {
  try {
    const result = transitionStayReservation(workspace, input);
    if (modal.open) modal.close();
    document.querySelector("#modal-submit").textContent = "追加する";
    persist(`${result.reservation.reservationNumber || result.reservation.id}を${statusLabel(result.reservation.status)}に更新しました`);
    render();
  } catch (error) {
    showNotice(error.message, true);
  }
}

function applyInventoryReassignment(button, currentInventoryId) {
  const newInventoryId = button.closest(".assignment-row")?.querySelector("select")?.value;
  if (!newInventoryId) { showNotice("変更先を選択してください。", true); return; }
  try {
    reassignReservationInventory(workspace, { reservationId: selectedReservationId, currentInventoryId, newInventoryId });
    persist(`${inventoryName(currentInventoryId)}から${inventoryName(newInventoryId)}へ割り当てを変更しました`);
    render();
  } catch (error) {
    showNotice(error.message, true);
  }
}

function setPath(path, value) {
  if (path === "images.length") {
    state.images = Array.from({ length: Math.max(0, value) }, (_, index) => state.images[index] || { id: makeId("image"), name: `sample-${index + 1}.jpg`, position: index + 1, altText: "" });
    return;
  }
  if (path === "stay.availableLastNightOn") {
    state.stay.stayAvailableEndsOn = stayAvailableEndsOn(value);
    return;
  }
  const parts = path.split(".");
  if (parts[0] === "roomType") {
    const item = state.roomTypes.find((roomType) => roomType.id === parts[1]);
    item[parts[2]] = value;
    if (parts[2] === "roomKind" && value === "shared_room") item.capacity = 1;
    return;
  }
  if (parts[0] === "ratePlan") {
    state.ratePlans.find((plan) => plan.id === parts[1])[parts[2]] = value;
    return;
  }
  let object = state;
  parts.slice(0, -1).forEach((part) => { object = object[part]; });
  object[parts.at(-1)] = value;
}

function toggleRoom(roomId) { const room = selectedRoomType().rooms.find((item) => item.id === roomId); room.active = !room.active; persist(); render(); }
function toggleBed(key) { const [roomId, bedId] = key.split(":"); const bed = selectedRoomType().rooms.find((room) => room.id === roomId).beds.find((item) => item.id === bedId); bed.active = !bed.active; persist(); render(); }
function toggleRate(key) { const [roomTypeId, ratePlanId] = key.split(":"); const rate = upsertRate(roomTypeId, ratePlanId, 1, false); rate.active = !rate.active; persist(); render(); }
function toggleAmenity(amenityId, target) { const ids = target === "facility-amenity" ? state.stay.facilityAmenityIds : state.roomTypes.find((item) => item.id === target.split(":")[1]).amenityIds; const index = ids.indexOf(amenityId); index >= 0 ? ids.splice(index, 1) : ids.push(amenityId); persist(); render(); }

function upsertRate(roomTypeId, ratePlanId, amount, updateAmount) {
  let rate = state.roomTypeRates.find((item) => item.roomTypeId === roomTypeId && item.ratePlanId === ratePlanId);
  if (!rate) { rate = { id: makeId("rate"), roomTypeId, ratePlanId, pricePerNightAmount: Math.max(1, amount || 1), currency: "JPY", active: true, dailyPrices: [] }; state.roomTypeRates.push(rate); }
  if (updateAmount && amount > 0) rate.pricePerNightAmount = amount;
  return rate;
}

function upsertDailyControl(roomTypeId, amount) {
  const controls = state.roomTypes.find((item) => item.id === roomTypeId).dailySalesControls;
  const index = controls.findIndex((item) => item.stayDate === calendarDate);
  if (amount === null) { if (index >= 0) controls.splice(index, 1); }
  else if (index >= 0) controls[index].salesLimit = amount;
  else controls.push({ stayDate: calendarDate, salesLimit: amount });
}

function upsertDailyPrice(rateId, amount) {
  const prices = state.roomTypeRates.find((item) => item.id === rateId).dailyPrices;
  const index = prices.findIndex((item) => item.stayDate === calendarDate);
  if (amount === null) { if (index >= 0) prices.splice(index, 1); }
  else if (index >= 0) prices[index].priceAmount = amount;
  else prices.push({ stayDate: calendarDate, priceAmount: amount });
}

function publish() {
  currentView = "publish";
  location.hash = currentView;
  if (!canPublish(state)) { showNotice("公開条件を満たしていません。未完了項目を確認してください。", true); render(); return; }
  state.status = "published";
  persist("Listingを疑似公開しました");
  render();
}

function exportJson() {
  const blob = new Blob([JSON.stringify(workspace, null, 2)], { type: "application/json" });
  const link = document.createElement("a");
  link.href = URL.createObjectURL(blob);
  link.download = `${workspace.tenant.id}-stay-listings.json`;
  link.click();
  URL.revokeObjectURL(link.href);
}

function persist(message) {
  localStorage.setItem(STORAGE_KEY, JSON.stringify(workspace));
  const saveState = document.querySelector("#save-state");
  saveState.textContent = "保存中…";
  setTimeout(() => { saveState.textContent = "このブラウザに保存済み"; }, 250);
  if (message) showNotice(message);
}

function showNotice(message, error = false) {
  const notice = document.querySelector("#notice");
  notice.textContent = message;
  notice.style.color = error ? "var(--red)" : "var(--green)";
  notice.style.background = error ? "#fae9e7" : "var(--green-soft)";
  notice.hidden = false;
  setTimeout(() => { notice.hidden = true; }, 3500);
}

function selectedRoomType() { return state.roomTypes.find((item) => item.id === selectedRoomTypeId); }
function selectedReservation() { return (workspace.stayReservations || []).find((item) => item.id === selectedReservationId && item.listingId === state?.id); }
function activateListing(listingId) {
  selectedListingId = listingId;
  state = workspace.stayListings.find((listing) => listing.id === selectedListingId);
  selectedRoomTypeId = state?.roomTypes[0]?.id;
  selectedRatePlanId = state?.ratePlans[0]?.id;
}
function metric(label, value, note) { return `<section class="card metric"><span class="metric-label">${label}</span><strong>${value}</strong><small>${note}</small></section>`; }
function dashboardMetric(label, value, note, tone) { return `<section class="card dashboard-metric dashboard-metric-${tone}"><span>${label}</span><strong>${value}</strong><small>${note}</small></section>`; }
function reservationActionButtons(reservation) {
  if (reservation.status === "requested") return `<div class="reservation-actions"><button class="button button-small button-primary" data-reservation-action="approve" data-reservation-id="${reservation.id}">承認</button><button class="button button-small" data-reservation-action="reject" data-reservation-id="${reservation.id}">拒否</button><button class="button button-small danger" data-reservation-action="cancel" data-reservation-id="${reservation.id}">取消</button></div>`;
  if (reservation.status === "confirmed") return `<div class="reservation-actions"><button class="button button-small danger" data-reservation-action="cancel" data-reservation-id="${reservation.id}">取消</button></div>`;
  return `<span class="muted">操作なし</span>`;
}
function checkRow(check) { return `<li class="check-item ${check.passed ? "" : "failed"}"><span class="check-icon">${check.passed ? "✓" : "!"}</span>${escapeHtml(check.label)}</li>`; }
function field(label, path, value, type = "text", className = "") { return `<div class="field ${className}"><label>${label}</label><input name="${path}" data-path="${path}" type="${type}" value="${escapeHtml(String(value ?? ""))}" /></div>`; }
function previewField(label, key, value, type) { return `<div class="field"><label>${label}</label><input data-preview="${key}" type="${type}" min="${type === "number" ? "1" : ""}" value="${escapeHtml(String(value ?? ""))}" /></div>`; }
function textarea(label, path, value, className = "") { return `<div class="field ${className}"><label>${label}</label><textarea name="${path}" data-path="${path}">${escapeHtml(value || "")}</textarea></div>`; }
function selectField(label, path, value, options, className = "") { return `<div class="field ${className}"><label>${label}</label><select name="${path}" data-path="${path}">${options.map(([optionValue, optionLabel]) => `<option value="${optionValue}" ${optionValue === value ? "selected" : ""}>${optionLabel}</option>`).join("")}</select></div>`; }
function amenityButton(amenity, selected, target) { return `<button class="amenity ${selected ? "selected" : ""}" data-amenity="${amenity.id}" data-target="${target}">${selected ? "✓ " : "+ "}${escapeHtml(amenity.name)}</button>`; }
function roomKindLabel(value) { return { entire_place: "一棟貸し / Room", private_room: "個室 / Room", shared_room: "相部屋 / Bed" }[value] || value; }
function mealLabel(value) { return { room_only: "素泊まり", breakfast: "朝食", dinner: "夕食", breakfast_and_dinner: "朝夕食" }[value] || value; }
function policyLabel(value) { return value === "non_refundable" ? "返金不可" : "キャンセル可"; }
function statusLabel(value) { return { requested: "承認待ち", confirmed: "予約確定", rejected: "拒否", canceled: "キャンセル", expired: "期限切れ", completed: "宿泊完了", no_show: "無断不泊" }[value] || value; }
function eventLabel(value) { return { approved: "予約を承認", rejected: "予約申請を拒否", canceled_by_tenant: "テナント都合で取消" }[value] || value; }
function reasonLabel(value) { return { unable_to_accommodate: "受け入れ困難", request_not_acceptable: "要望に対応できない", facility_unavailable: "施設を提供できない", maintenance: "設備メンテナンス", overbooking: "オーバーブッキング", safety: "安全上の理由", other: "その他" }[value] || value; }
function roomTypeName(id) { return state.roomTypes.find((item) => item.id === id)?.name || "Room Type未設定"; }
function inventoryName(id) {
  for (const roomType of state.roomTypes) {
    const room = roomType.rooms.find((item) => item.id === id);
    if (room) return room.name;
    for (const parentRoom of roomType.rooms) {
      const bed = parentRoom.beds.find((item) => item.id === id);
      if (bed) return `${parentRoom.name} / ${bed.name}`;
    }
  }
  return id;
}
function assignmentLabel(reservation) { const ids = [...(reservation.roomAssignments || []).map((item) => item.stayRoomId), ...(reservation.bedAssignments || []).map((item) => item.stayBedId)]; return ids.length ? ids.join(" / ") : "未割当"; }
function yen(value) { return new Intl.NumberFormat("ja-JP", { style: "currency", currency: "JPY" }).format(value); }
function formatDateTime(value) { return value ? new Intl.DateTimeFormat("ja-JP", { month: "numeric", day: "numeric", hour: "2-digit", minute: "2-digit" }).format(new Date(value)) : "—"; }
function expectedArrivalLabel(value) { return value ? value.slice(11, 16) : "未定"; }
function formatStayDate(value) { return new Intl.DateTimeFormat("ja-JP", { month: "numeric", day: "numeric", weekday: "short", timeZone: "UTC" }).format(new Date(`${value}T00:00:00Z`)); }
function escapeHtml(value) { return value.replace(/[&<>'"]/g, (character) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", "'": "&#39;", '"': "&quot;" })[character]); }

initialize().catch((error) => {
  content.innerHTML = `<section class="card"><h2>読み込みに失敗しました</h2><p class="muted">HTTPサーバー経由で開いてください。</p><pre>${escapeHtml(String(error))}</pre></section>`;
});
