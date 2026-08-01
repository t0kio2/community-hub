import test from "node:test";
import assert from "node:assert/strict";
import {
  availableLastNightOn,
  buildStayPreview,
  canPublish,
  createBlankStayListing,
  inventoryForDate,
  normalizeWorkspace,
  physicalInventory,
  priceForDate,
  publicationChecks,
  stayAvailableEndsOn,
} from "../domain.js";

const privateRoomType = {
  id: "private",
  roomKind: "private_room",
  status: "published",
  rooms: [
    { active: true, beds: [] },
    { active: false, beds: [] },
  ],
  dailySalesControls: [],
};

const sharedRoomType = {
  id: "shared",
  roomKind: "shared_room",
  status: "published",
  rooms: [
    { active: true, beds: [{ active: true }, { active: false }, { active: true }] },
    { active: false, beds: [{ active: true }] },
  ],
  dailySalesControls: [],
};

test("個室の物理在庫は有効なRoom数から算出する", () => {
  assert.equal(physicalInventory(privateRoomType), 1);
});

test("相部屋の物理在庫は有効なRoomに属する有効なBed数から算出する", () => {
  assert.equal(physicalInventory(sharedRoomType), 2);
});

test("日別販売上限は物理在庫を超えて販売可能数を増やさない", () => {
  const roomType = structuredClone(sharedRoomType);
  roomType.dailySalesControls = [{ stayDate: "2026-08-15", salesLimit: 10 }];

  assert.equal(inventoryForDate(roomType, "2026-08-15"), 2);
});

test("日別販売上限0はその日の販売停止を表す", () => {
  const roomType = structuredClone(sharedRoomType);
  roomType.dailySalesControls = [{ stayDate: "2026-08-15", salesLimit: 0 }];

  assert.equal(inventoryForDate(roomType, "2026-08-15"), 0);
});

test("日別料金があれば基本料金より優先する", () => {
  const state = {
    roomTypeRates: [{ roomTypeId: "private", ratePlanId: "standard", active: true, pricePerNightAmount: 10_000, dailyPrices: [{ stayDate: "2026-08-15", priceAmount: 15_000 }] }],
  };

  assert.equal(priceForDate(state, "private", "standard", "2026-08-15"), 15_000);
  assert.equal(priceForDate(state, "private", "standard", "2026-08-16"), 10_000);
});

test("最後に宿泊できる日は内部の期間終了日の前日として表示する", () => {
  assert.equal(availableLastNightOn("2026-09-01"), "2026-08-31");
});

test("最後に宿泊できる日の翌日を内部の期間終了日として保存する", () => {
  assert.equal(stayAvailableEndsOn("2026-08-31"), "2026-09-01");
});

test("宿泊提供期間の終了日が未入力なら期間制限なしとして空値を維持する", () => {
  assert.equal(availableLastNightOn(""), "");
  assert.equal(stayAvailableEndsOn(""), "");
});

test("宿泊者プレビューは日別料金と必要Room数から連泊合計を算出する", () => {
  const state = previewState();
  const preview = buildStayPreview(state, { checkInDate: "2026-08-15", checkOutDate: "2026-08-17", guestCount: 2 });
  const room = preview.roomTypes[0];

  assert.equal(room.requiredQuantity, 1);
  assert.equal(room.availableUnits, 1);
  assert.deepEqual(room.rates[0].nights, [
    { stayDate: "2026-08-15", unitAmount: 15_000, quantity: 1, subtotalAmount: 15_000 },
    { stayDate: "2026-08-16", unitAmount: 10_000, quantity: 1, subtotalAmount: 10_000 },
  ]);
  assert.equal(room.rates[0].totalAmount, 25_000);
  assert.equal(room.rates[0].sellable, true);
});

test("宿泊期間中に販売上限0の日があれば宿泊者へ販売しない", () => {
  const state = previewState();
  state.roomTypes[0].dailySalesControls = [{ stayDate: "2026-08-16", salesLimit: 0 }];
  const preview = buildStayPreview(state, { checkInDate: "2026-08-15", checkOutDate: "2026-08-17", guestCount: 2 });

  assert.equal(preview.roomTypes[0].sellable, false);
  assert.ok(preview.roomTypes[0].reasons.includes("日程全体で必要な在庫を確保できません"));
});

test("非公開Rate Planは販売せず理由を点検情報へ返す", () => {
  const state = previewState();
  state.ratePlans[0].status = "draft";
  const preview = buildStayPreview(state, { checkInDate: "2026-08-15", checkOutDate: "2026-08-17", guestCount: 2 });

  assert.equal(preview.roomTypes[0].rates[0].sellable, false);
  assert.ok(preview.roomTypes[0].rates[0].reasons.includes("Rate Planが公開されていません"));
});

test("宿泊提供期間を超える日程は販売しない", () => {
  const state = previewState();
  const preview = buildStayPreview(state, { checkInDate: "2026-08-31", checkOutDate: "2026-09-02", guestCount: 2 });

  assert.ok(preview.listingReasons.includes("宿泊提供期間より後の日程です"));
  assert.equal(preview.roomTypes[0].sellable, false);
});

test("施設が下書きでも公開後の表示を点検できるが宿泊者には非表示とする", () => {
  const state = previewState();
  state.status = "draft";
  const preview = buildStayPreview(state, { checkInDate: "2026-08-15", checkOutDate: "2026-08-17", guestCount: 2 });

  assert.equal(preview.roomTypes[0].rates[0].sellable, true);
  assert.equal(preview.roomTypes[0].rates[0].visibleToGuests, false);
  assert.ok(preview.listingReasons.includes("施設が公開されていません"));
});

test("すべての公開条件を満たすと公開可能になる", () => {
  const state = completeState();

  assert.equal(canPublish(state), true);
  assert.equal(publicationChecks(state).every((check) => check.passed), true);
});

test("公開中Room Typeに物理在庫がなければ公開できない", () => {
  const state = completeState();
  state.roomTypes[0].rooms = [];

  assert.equal(canPublish(state), false);
  assert.equal(publicationChecks(state).find((check) => check.id === "room_type").passed, false);
});

test("旧版の単一Listingをテナントの複数施設形式へ変換する", () => {
  const workspace = normalizeWorkspace({
    id: "listing-1",
    title: "旧施設",
    amenities: [{ id: "wifi" }],
    roomTypes: [],
    ratePlans: [],
    roomTypeRates: [],
  });

  assert.equal(workspace.schemaVersion, 2);
  assert.equal(workspace.stayListings.length, 1);
  assert.equal(workspace.stayListings[0].title, "旧施設");
  assert.equal("amenities" in workspace.stayListings[0], false);
  assert.deepEqual(workspace.amenities, [{ id: "wifi" }]);
});

test("複数施設形式は施設を分離したまま読み込む", () => {
  const workspace = normalizeWorkspace({
    schemaVersion: 2,
    tenant: { id: "tenant-1", name: "テナント" },
    amenities: [],
    stayListings: [{ id: "listing-1", title: "施設A" }, { id: "listing-2", title: "施設B" }],
  });

  assert.deepEqual(workspace.stayListings.map((listing) => listing.title), ["施設A", "施設B"]);
});

test("追加した宿泊施設は独立した空のListingとして作成する", () => {
  const listing = createBlankStayListing("新しい宿");

  assert.equal(listing.title, "新しい宿");
  assert.equal(listing.status, "draft");
  assert.deepEqual(listing.roomTypes, []);
  assert.deepEqual(listing.ratePlans, []);
  assert.equal(listing.stay.timeZone, "Asia/Tokyo");
});

function completeState() {
  return {
    title: "テスト施設",
    description: "施設説明",
    images: [{ id: "image" }],
    location: { prefecture: "東京都", city: "渋谷区", addressLine1: "1-1", latitude: 35.6, longitude: 139.7 },
    stay: { checkInTime: "15:00", bookingOpenDaysBefore: 365, bookingCloseHoursBefore: 0 },
    roomTypes: [structuredClone(privateRoomType)],
    ratePlans: [{ id: "standard", status: "published" }],
    roomTypeRates: [{ roomTypeId: "private", ratePlanId: "standard", active: true, pricePerNightAmount: 10_000 }],
  };
}

function previewState() {
  return {
    status: "published",
    stay: { stayAvailableStartsOn: "2026-08-01", stayAvailableEndsOn: "2026-09-01" },
    roomTypes: [{
      id: "private",
      name: "個室",
      roomKind: "private_room",
      capacity: 2,
      status: "published",
      rooms: [{ active: true, beds: [] }],
      dailySalesControls: [],
    }],
    ratePlans: [{ id: "standard", status: "published" }],
    roomTypeRates: [{
      roomTypeId: "private",
      ratePlanId: "standard",
      active: true,
      pricePerNightAmount: 10_000,
      dailyPrices: [{ stayDate: "2026-08-15", priceAmount: 15_000 }],
    }],
  };
}
