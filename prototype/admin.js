const STORAGE_KEY = "community-hub:admin-prototype:v1";
const titles = { dashboard:"ダッシュボード", tenants:"テナント管理", "tenant-detail":"テナント詳細", listings:"掲載管理", admins:"管理者管理", activity:"アクティビティ" };
const sections = { dashboard:"OVERVIEW", tenants:"PLATFORM", "tenant-detail":"PLATFORM", listings:"PLATFORM", admins:"SECURITY", activity:"SECURITY" };

let initialState;
let state;
let currentView = location.hash.slice(1) || "dashboard";
let selectedTenantId;
let tenantFilters = { query:"", status:"all" };
let listingFilters = { query:"", type:"all", status:"all" };
const content = document.querySelector("#admin-content");

async function initialize() {
  initialState = await fetch("./data/admin-workspace.json").then((response) => response.json());
  state = JSON.parse(localStorage.getItem(STORAGE_KEY) || "null") || structuredClone(initialState);
  bindEvents();
  render();
}

function bindEvents() {
  document.querySelector("#admin-navigation").addEventListener("click", (event) => {
    const button = event.target.closest("[data-view]");
    if (!button) return;
    currentView = button.dataset.view;
    location.hash = currentView;
    render();
  });
  window.addEventListener("hashchange", () => { currentView = location.hash.slice(1) || "dashboard"; render(); });
  content.addEventListener("input", handleInput);
  content.addEventListener("change", handleInput);
  content.addEventListener("click", handleClick);
  document.querySelector("#admin-reset").addEventListener("click", () => {
    if (!confirm("運営管理プロトタイプを初期状態へ戻しますか？")) return;
    state = structuredClone(initialState);
    localStorage.removeItem(STORAGE_KEY);
    currentView = "dashboard";
    location.hash = currentView;
    render();
    notice("初期状態へ戻しました");
  });
  document.querySelector("#admin-export").addEventListener("click", exportJson);
}

function render() {
  document.querySelector("#admin-title").textContent = titles[currentView] || titles.dashboard;
  document.querySelector("#admin-section").textContent = sections[currentView] || "OVERVIEW";
  document.querySelector("#admin-account-email").textContent = state.adminAccount.email;
  document.querySelector("#admin-account-role").textContent = `${adminRoleLabel(state.admin.role)}・${statusLabel(state.admin.status)}`;
  document.querySelector("#tenant-nav-count").textContent = state.tenants.length;
  document.querySelector("#review-nav-count").textContent = state.listings.filter((item) => item.status === "reviewing").length || "";
  document.querySelectorAll("[data-view]").forEach((button) => button.classList.toggle("active", button.dataset.view === currentView || (currentView === "tenant-detail" && button.dataset.view === "tenants")));
  const renderer = { dashboard:renderDashboard, tenants:renderTenants, "tenant-detail":renderTenantDetail, listings:renderListings, admins:renderAdmins, activity:renderActivity }[currentView] || renderDashboard;
  content.innerHTML = renderer();
}

function renderDashboard() {
  const activeTenants = state.tenants.filter((item) => item.status === "active").length;
  const published = state.listings.filter((item) => item.status === "published").length;
  const reviews = state.listings.filter((item) => item.status === "reviewing");
  return `<section class="admin-hero"><div><p class="eyebrow">PLATFORM OPERATIONS</p><h2>おはようございます、運営管理者さん</h2><p>プラットフォーム全体の状態と、今日対応が必要な項目を確認できます。</p></div><span class="admin-hero-date">2026.08.06<small>THURSDAY</small></span></section>
    <div class="admin-grid admin-grid-4">${metric("有効テナント",activeTenants,`${state.tenants.length}組織を登録`)}${metric("公開中の掲載",published,`宿泊・求人の合計`)}${metric("確認待ち",reviews.length,"掲載・テナント審査")}${metric("有効な管理者",state.admins.filter((item)=>item.status==="active").length,"運営アカウント")}</div>
    <div class="admin-grid admin-grid-main"><section class="admin-card"><div class="admin-card-header"><div><h3>対応が必要です</h3><p>審査・確認待ちの運営業務</p></div></div><div class="review-list">
      ${state.tenants.filter((item)=>item.status==="reviewing").map((tenant)=>`<article class="review-item"><span class="review-icon">T</span><div><strong>新規テナントの確認</strong><small>${escapeHtml(tenant.name)}・${escapeHtml(tenant.ownerAccount.email)}</small></div><button data-open-tenant="${tenant.id}">確認する →</button></article>`).join("")}
      ${reviews.map((listing)=>`<article class="review-item"><span class="review-icon">L</span><div><strong>掲載内容の確認</strong><small>${escapeHtml(listing.title)}・${escapeHtml(tenantName(listing.tenantId))}</small></div><button data-go-listings>確認する →</button></article>`).join("")}
    </div></section><section class="admin-card"><div class="admin-card-header"><div><h3>最近のアクティビティ</h3><p>運営管理者による操作</p></div><button class="admin-button small" data-go-activity>すべて表示</button></div>${activityRows(state.activities.slice(0,4))}</section></div>`;
}

function renderTenants() {
  const rows = state.tenants.filter((tenant) => (tenantFilters.status === "all" || tenant.status === tenantFilters.status) && `${tenant.name} ${tenant.ownerAccount.email}`.toLowerCase().includes(tenantFilters.query.toLowerCase()));
  return `<section class="page-heading"><div><h2>テナント</h2><p>組織とownerアカウントの状態を横断管理します。</p></div><button class="admin-button primary" disabled>＋ テナントを作成</button></section><div class="filter-bar"><input data-tenant-filter="query" value="${escapeHtml(tenantFilters.query)}" placeholder="組織名またはメールアドレスで検索"/><select data-tenant-filter="status"><option value="all">すべての状態</option>${["active","reviewing","suspended"].map((value)=>`<option value="${value}" ${tenantFilters.status===value?"selected":""}>${statusLabel(value)}</option>`).join("")}</select></div>
    <section class="admin-card admin-table-card"><table class="admin-table"><thead><tr><th>組織</th><th>ownerアカウント</th><th>掲載</th><th>状態</th><th>登録日</th><th></th></tr></thead><tbody>${rows.map((tenant)=>`<tr><td><div class="entity-cell"><span class="entity-logo">${escapeHtml(tenant.name.slice(0,1))}</span><div><strong>${escapeHtml(tenant.name)}</strong><small>${escapeHtml(tenant.address)}</small></div></div></td><td>${escapeHtml(tenant.ownerAccount.email)}</td><td><strong>${state.listings.filter((item)=>item.tenantId===tenant.id).length}</strong>件</td><td>${statusBadge(tenant.status)}</td><td>${formatDate(tenant.createdAt)}</td><td><button class="admin-button small" data-open-tenant="${tenant.id}">詳細</button></td></tr>`).join("")}</tbody></table>${rows.length?"":`<div class="empty-admin">条件に一致するテナントはありません</div>`}</section>`;
}

function renderTenantDetail() {
  const tenant = state.tenants.find((item)=>item.id===selectedTenantId) || state.tenants[0];
  selectedTenantId = tenant.id;
  const listings = state.listings.filter((item)=>item.tenantId===tenant.id);
  return `<button class="back-link" data-back-tenants>← テナント一覧へ戻る</button><section class="page-heading"><div><h2>${escapeHtml(tenant.name)}</h2><p>${escapeHtml(tenant.id)}</p></div><div><button class="admin-button ${tenant.status==="suspended"?"primary":"danger"}" data-toggle-tenant="${tenant.id}">${tenant.status==="suspended"?"利用を再開":"利用を停止"}</button></div></section><div class="admin-grid tenant-detail"><section class="admin-card"><div class="admin-card-header"><div><h3>組織・アカウント情報</h3><p>Tenant / Account / TenantMember</p></div>${statusBadge(tenant.status)}</div><div class="detail-kv"><div><span>組織名</span><strong>${escapeHtml(tenant.name)}</strong></div><div><span>フリガナ</span><strong>${escapeHtml(tenant.kana)}</strong></div><div><span>所在地</span><strong>${escapeHtml(tenant.address)}</strong></div><div><span>ownerアカウント</span><strong>${escapeHtml(tenant.ownerAccount.email)}</strong></div><div><span>TenantMember</span><strong>${tenant.ownerMember.role} / ${tenant.ownerMember.status}</strong></div></div></section><section class="admin-card"><div class="admin-card-header"><div><h3>掲載サマリー</h3><p>このテナントに属するListing</p></div></div><div class="admin-grid admin-grid-4">${metric("合計",listings.length,"件")}${metric("公開",listings.filter((item)=>item.status==="published").length,"件")}</div>${listings.map((item)=>`<article class="review-item"><span class="review-icon">${item.listingType==="stay"?"S":"J"}</span><div><strong>${escapeHtml(item.title)}</strong><small>${listingTypeLabel(item.listingType)}・${statusLabel(item.status)}</small></div></article>`).join("")||`<div class="empty-admin">掲載はありません</div>`}</section></div>`;
}

function renderListings() {
  const rows = state.listings.filter((listing)=>(listingFilters.type==="all"||listing.listingType===listingFilters.type)&&(listingFilters.status==="all"||listing.status===listingFilters.status)&&`${listing.title} ${tenantName(listing.tenantId)}`.toLowerCase().includes(listingFilters.query.toLowerCase()));
  return `<section class="page-heading"><div><h2>掲載情報</h2><p>すべてのテナントの宿泊・求人Listingを確認します。</p></div></section><div class="filter-bar"><input data-listing-filter="query" value="${escapeHtml(listingFilters.query)}" placeholder="タイトルまたはテナント名で検索"/><select data-listing-filter="type"><option value="all">すべての種別</option><option value="stay" ${listingFilters.type==="stay"?"selected":""}>宿泊</option><option value="job" ${listingFilters.type==="job"?"selected":""}>求人</option></select><select data-listing-filter="status"><option value="all">すべての状態</option>${["published","reviewing","draft","closed"].map((value)=>`<option value="${value}" ${listingFilters.status===value?"selected":""}>${statusLabel(value)}</option>`).join("")}</select></div><section class="admin-card admin-table-card"><table class="admin-table"><thead><tr><th>掲載</th><th>種別</th><th>テナント</th><th>状態</th><th>最終更新</th><th></th></tr></thead><tbody>${rows.map((listing)=>`<tr><td><div class="entity-cell"><span class="entity-logo">${listing.listingType==="stay"?"S":"J"}</span><div><strong>${escapeHtml(listing.title)}</strong><small>${escapeHtml(listing.id)}</small></div></div></td><td><span class="listing-type ${listing.listingType}">${listingTypeLabel(listing.listingType)}</span></td><td>${escapeHtml(tenantName(listing.tenantId))}</td><td>${statusBadge(listing.status)}</td><td>${formatDateTime(listing.updatedAt)}</td><td>${listing.status==="published"?`<button class="admin-button small danger" data-close-listing="${listing.id}">公開停止</button>`:"—"}</td></tr>`).join("")}</tbody></table>${rows.length?"":`<div class="empty-admin">条件に一致する掲載はありません</div>`}</section>`;
}

function renderAdmins() {
  return `<section class="page-heading"><div><h2>運営管理者</h2><p>Admin Accountとロール・利用状態を確認します。</p></div><button class="admin-button primary" disabled>＋ 管理者を招待</button></section><section class="admin-card admin-table-card"><table class="admin-table"><thead><tr><th>Admin Account</th><th>ロール</th><th>状態</th><th>最終ログイン</th></tr></thead><tbody>${state.admins.map((admin)=>`<tr><td><div class="entity-cell"><span class="entity-logo">${admin.role==="super_admin"?"SA":"OP"}</span><div><strong>${escapeHtml(admin.email)}${admin.id===state.admin.id?` <span class="admin-status status-active">ログイン中</span>`:""}</strong><small>${escapeHtml(admin.accountId)}</small></div></div></td><td>${adminRoleLabel(admin.role)}</td><td>${statusBadge(admin.status)}</td><td>${formatDateTime(admin.lastLoginAt)}</td></tr>`).join("")}</tbody></table></section>`;
}

function renderActivity() { return `<section class="page-heading"><div><h2>アクティビティ</h2><p>運営管理者による重要操作の表示用サンプルです。</p></div></section><section class="admin-card">${activityRows(state.activities)}</section>`; }

function handleInput(event) {
  const input=event.target;
  if(input.dataset.tenantFilter){tenantFilters[input.dataset.tenantFilter]=input.value;render();}
  if(input.dataset.listingFilter){listingFilters[input.dataset.listingFilter]=input.value;render();}
}

function handleClick(event) {
  const button=event.target.closest("button"); if(!button)return;
  if(button.dataset.openTenant){selectedTenantId=button.dataset.openTenant;currentView="tenant-detail";location.hash=currentView;render();}
  if(button.hasAttribute("data-back-tenants")){currentView="tenants";location.hash=currentView;render();}
  if(button.hasAttribute("data-go-listings")){currentView="listings";location.hash=currentView;render();}
  if(button.hasAttribute("data-go-activity")){currentView="activity";location.hash=currentView;render();}
  if(button.dataset.toggleTenant)toggleTenant(button.dataset.toggleTenant);
  if(button.dataset.closeListing)closeListing(button.dataset.closeListing);
}

function toggleTenant(id){const tenant=state.tenants.find((item)=>item.id===id);const next=tenant.status==="suspended"?"active":"suspended";if(next==="suspended"&&!confirm(`${tenant.name}の利用を停止しますか？`))return;tenant.status=next;tenant.ownerMember.status=next==="active"?"active":"inactive";persist(next==="active"?"テナントの利用を再開しました":"テナントの利用を停止しました");render();}
function closeListing(id){const listing=state.listings.find((item)=>item.id===id);if(!confirm(`${listing.title}を公開停止しますか？`))return;listing.status="closed";listing.updatedAt=new Date().toISOString();persist("掲載を公開停止しました");render();}
function persist(message){localStorage.setItem(STORAGE_KEY,JSON.stringify(state));if(message)notice(message);}
function notice(message){const element=document.querySelector("#admin-notice");element.textContent=message;element.hidden=false;setTimeout(()=>{element.hidden=true;},3000);}
function exportJson(){const blob=new Blob([JSON.stringify(state,null,2)],{type:"application/json"});const link=document.createElement("a");link.href=URL.createObjectURL(blob);link.download="community-hub-admin-workspace.json";link.click();URL.revokeObjectURL(link.href);}
function metric(label,value,note){return `<section class="admin-card admin-metric"><span>${label}</span><strong>${value}</strong><small>${note}</small></section>`;}
function activityRows(items){return `<div class="activity-list">${items.map((item)=>`<article class="activity-item"><span class="activity-icon">${item.tone==="alert"?"!":"↻"}</span><div><strong>${escapeHtml(item.action)} — ${escapeHtml(item.target)}</strong><small>${escapeHtml(item.actor)}</small></div><small>${formatDateTime(item.occurredAt)}</small></article>`).join("")}</div>`;}
function tenantName(id){return state.tenants.find((item)=>item.id===id)?.name||"削除済みテナント";}
function statusBadge(value){return `<span class="admin-status status-${value}">${statusLabel(value)}</span>`;}
function statusLabel(value){return {active:"有効",inactive:"無効",reviewing:"確認待ち",suspended:"利用停止",published:"公開中",draft:"下書き",closed:"公開終了"}[value]||value;}
function adminRoleLabel(value){return {super_admin:"super_admin",operator:"operator"}[value]||value;}
function listingTypeLabel(value){return {stay:"宿泊",job:"求人"}[value]||value;}
function formatDate(value){return new Intl.DateTimeFormat("ja-JP",{year:"numeric",month:"numeric",day:"numeric"}).format(new Date(value));}
function formatDateTime(value){return value?new Intl.DateTimeFormat("ja-JP",{month:"numeric",day:"numeric",hour:"2-digit",minute:"2-digit"}).format(new Date(value)):"—";}
function escapeHtml(value){return String(value??"").replace(/[&<>'"]/g,(character)=>({"&":"&amp;","<":"&lt;",">":"&gt;","'":"&#39;",'"':"&quot;"})[character]);}

initialize().catch((error)=>{content.innerHTML=`<section class="admin-card"><h2>読み込みに失敗しました</h2><p>HTTPサーバー経由で開いてください。</p><pre>${escapeHtml(error)}</pre></section>`;});
