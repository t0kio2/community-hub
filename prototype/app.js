import {
  canPublish,
  inventoryForDate,
  makeId,
  physicalInventory,
  priceForDate,
  publicationChecks,
} from "./domain.js";

const STORAGE_KEY = "community-hub:stay-listing-prototype:v1";
const viewTitles = {
  overview: "概要",
  facility: "施設情報",
  rooms: "部屋と在庫",
  rates: "料金プラン",
  calendar: "日別設定",
  publish: "公開確認",
};

let initialState;
let state;
let currentView = location.hash.slice(1) || "overview";
let selectedRoomTypeId;
let selectedRatePlanId;
let calendarDate = "2026-08-15";

const content = document.querySelector("#content");
const modal = document.querySelector("#modal");
const modalForm = document.querySelector("#modal-form");

async function initialize() {
  initialState = await fetch("./data/stay-listing.json").then((response) => response.json());
  const stored = localStorage.getItem(STORAGE_KEY);
  state = stored ? JSON.parse(stored) : structuredClone(initialState);
  selectedRoomTypeId = state.roomTypes[0]?.id;
  selectedRatePlanId = state.ratePlans[0]?.id;
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
    currentView = location.hash.slice(1) || "overview";
    render();
  });

  document.querySelector("#reset-button").addEventListener("click", () => {
    if (!confirm("入力内容を破棄して初期データへ戻しますか？")) return;
    state = structuredClone(initialState);
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
  document.querySelector("#listing-id").textContent = state.id;
  document.querySelector("#page-title").textContent = viewTitles[currentView] || viewTitles.overview;
  document.querySelectorAll("[data-view]").forEach((button) => {
    button.classList.toggle("active", button.dataset.view === currentView);
  });
  document.querySelector("#publish-button").textContent = state.status === "published" ? "公開中" : "公開する";

  const renderView = {
    overview: renderOverview,
    facility: renderFacility,
    rooms: renderRooms,
    rates: renderRates,
    calendar: renderCalendar,
    publish: renderPublish,
  }[currentView] || renderOverview;
  content.innerHTML = renderView();
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

function renderFacility() {
  const facilityAmenities = state.amenities.filter((item) => ["facility", "both"].includes(item.scope) && item.active);
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
            ${field("チェックアウト", "stay.checkOutTime", state.stay.checkOutTime, "time")}
            ${field("宿泊開始日", "stay.stayAvailableStartsOn", state.stay.stayAvailableStartsOn, "date")}
            ${field("最遅チェックアウト日", "stay.stayAvailableEndsOn", state.stay.stayAvailableEndsOn, "date")}
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
  const roomAmenities = state.amenities.filter((item) => ["room_type", "both"].includes(item.scope) && item.active);
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

function renderPublish() {
  const checks = publicationChecks(state);
  return `<section class="page-lead"><div><h2>公開確認</h2><p>Listing・施設・Room Type・Rate Plan・料金の境界を横断して検証します。</p></div><button class="button button-primary" data-publish>${state.status === "published" ? "公開済み" : "条件を確認して公開"}</button></section>
    <div class="grid grid-main"><section class="card"><div class="card-header"><div><h3>公開必須条件</h3><p>${checks.filter((item) => item.passed).length} / ${checks.length} 完了</p></div></div><ul class="check-list">${checks.map(checkRow).join("")}</ul></section>
    <section class="card"><div class="card-header"><div><h3>保存されるJSON</h3><p>ERへ変換可能な集約形式</p></div></div><pre class="json-preview">${escapeHtml(JSON.stringify(state, null, 2))}</pre></section></div>`;
}

function handleInput(event) {
  const input = event.target;
  if (input.id === "calendar-date") {
    calendarDate = input.value;
    render();
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
  if (target.dataset.selectRoomType) { selectedRoomTypeId = target.dataset.selectRoomType; render(); }
  if (target.dataset.selectRatePlan) { selectedRatePlanId = target.dataset.selectRatePlan; render(); }
  if (target.dataset.modal) openModal(target.dataset.modal, target.dataset.roomId);
  if (target.dataset.toggleRoom) toggleRoom(target.dataset.toggleRoom);
  if (target.dataset.toggleBed) toggleBed(target.dataset.toggleBed);
  if (target.dataset.toggleRate) toggleRate(target.dataset.toggleRate);
  if (target.dataset.amenity) toggleAmenity(target.dataset.amenity, target.dataset.target);
  if (target.hasAttribute("data-publish")) publish();
}

function openModal(type, roomId) {
  const definitions = {
    "room-type": ["Room Typeを追加", `${field("名称", "modal.name", "")}${selectField("販売形態", "modal.kind", "private_room", [["private_room", "個室"], ["shared_room", "相部屋"], ["entire_place", "一棟貸し"]])}${field("定員", "modal.capacity", 2, "number")}`],
    room: ["物理Roomを追加", field("管理名", "modal.name", "")],
    bed: ["Bedを追加", field("管理名", "modal.name", "")],
    "rate-plan": ["Rate Planを追加", `${field("名称", "modal.name", "")}${selectField("食事", "modal.meal", "room_only", [["room_only", "素泊まり"], ["breakfast", "朝食"], ["dinner", "夕食"], ["breakfast_and_dinner", "朝夕食"]])}${selectField("キャンセル", "modal.policy", "standard", [["standard", "標準"], ["non_refundable", "返金不可"]])}`],
  };
  const [title, body] = definitions[type];
  document.querySelector("#modal-title").textContent = title;
  document.querySelector("#modal-body").innerHTML = `<div class="field-grid">${body}</div>`;
  modalForm.dataset.type = type;
  modalForm.dataset.roomId = roomId || "";
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
  const name = values["modal.name"]?.trim();
  if (!name) return;
  if (type === "room-type") {
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

function setPath(path, value) {
  if (path === "images.length") {
    state.images = Array.from({ length: Math.max(0, value) }, (_, index) => state.images[index] || { id: makeId("image"), name: `sample-${index + 1}.jpg`, position: index + 1, altText: "" });
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
  const blob = new Blob([JSON.stringify(state, null, 2)], { type: "application/json" });
  const link = document.createElement("a");
  link.href = URL.createObjectURL(blob);
  link.download = `${state.id}.json`;
  link.click();
  URL.revokeObjectURL(link.href);
}

function persist(message) {
  localStorage.setItem(STORAGE_KEY, JSON.stringify(state));
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
function metric(label, value, note) { return `<section class="card metric"><span class="metric-label">${label}</span><strong>${value}</strong><small>${note}</small></section>`; }
function checkRow(check) { return `<li class="check-item ${check.passed ? "" : "failed"}"><span class="check-icon">${check.passed ? "✓" : "!"}</span>${escapeHtml(check.label)}</li>`; }
function field(label, path, value, type = "text", className = "") { return `<div class="field ${className}"><label>${label}</label><input name="${path}" data-path="${path}" type="${type}" value="${escapeHtml(String(value ?? ""))}" /></div>`; }
function textarea(label, path, value, className = "") { return `<div class="field ${className}"><label>${label}</label><textarea name="${path}" data-path="${path}">${escapeHtml(value || "")}</textarea></div>`; }
function selectField(label, path, value, options, className = "") { return `<div class="field ${className}"><label>${label}</label><select name="${path}" data-path="${path}">${options.map(([optionValue, optionLabel]) => `<option value="${optionValue}" ${optionValue === value ? "selected" : ""}>${optionLabel}</option>`).join("")}</select></div>`; }
function amenityButton(amenity, selected, target) { return `<button class="amenity ${selected ? "selected" : ""}" data-amenity="${amenity.id}" data-target="${target}">${selected ? "✓ " : "+ "}${escapeHtml(amenity.name)}</button>`; }
function roomKindLabel(value) { return { entire_place: "一棟貸し / Room", private_room: "個室 / Room", shared_room: "相部屋 / Bed" }[value] || value; }
function mealLabel(value) { return { room_only: "素泊まり", breakfast: "朝食", dinner: "夕食", breakfast_and_dinner: "朝夕食" }[value] || value; }
function policyLabel(value) { return value === "non_refundable" ? "返金不可" : "キャンセル可"; }
function yen(value) { return new Intl.NumberFormat("ja-JP", { style: "currency", currency: "JPY" }).format(value); }
function escapeHtml(value) { return value.replace(/[&<>'"]/g, (character) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", "'": "&#39;", '"': "&quot;" })[character]); }

initialize().catch((error) => {
  content.innerHTML = `<section class="card"><h2>読み込みに失敗しました</h2><p class="muted">HTTPサーバー経由で開いてください。</p><pre>${escapeHtml(String(error))}</pre></section>`;
});
