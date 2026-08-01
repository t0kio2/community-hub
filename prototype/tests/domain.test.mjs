import test from "node:test";
import assert from "node:assert/strict";
import { canPublish, inventoryForDate, physicalInventory, priceForDate, publicationChecks } from "../domain.js";

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
