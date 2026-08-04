import test from "node:test";
import assert from "node:assert/strict";
import {
  addInventoryBlock,
  assignRoomType,
  availableAssignmentCandidates,
  arrivalTimeOptions,
  availableLastNightOn,
  buildStayPreview,
  canPublish,
  createBlankStayListing,
  createStayReservation,
  inventoryForDate,
  normalizeWorkspace,
  physicalInventory,
  priceForDate,
  publicationChecks,
  reservationDashboard,
  reassignReservationInventory,
  removeInventoryBlock,
  stayAvailableEndsOn,
  transitionStayReservation,
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
  assert.deepEqual(listing.rooms, []);
  assert.equal(listing.stay.timeZone, "Asia/Tokyo");
});

test("旧形式のRoom Type配下Roomを施設直下へ変換する", () => {
  const workspace = normalizeWorkspace({
    id: "listing-1",
    title: "旧施設",
    roomTypes: [{ id: "room-type-1", rooms: [{ id: "room-1", name: "101", active: true, beds: [] }] }],
    ratePlans: [],
    roomTypeRates: [],
  });

  assert.equal(workspace.stayListings[0].rooms[0].roomTypeId, "room-type-1");
  assert.equal("rooms" in workspace.stayListings[0].roomTypes[0], false);
});

test("未分類RoomはRoom Typeの物理在庫へ含めない", () => {
  const listing = {
    rooms: [
      { id: "classified", roomTypeId: "room-type-1", active: true, beds: [] },
      { id: "unclassified", roomTypeId: null, active: true, beds: [] },
    ],
  };
  const roomType = { id: "room-type-1", roomKind: "private_room" };

  assert.equal(physicalInventory(roomType, listing), 1);
});

test("承認制の予約申請は料金を固定してRoomを仮確保する", () => {
  const workspace = reservationWorkspace("approval_required", "private_room");
  const reservation = createStayReservation(workspace, reservationInput(), new Date("2026-08-01T00:00:00Z"));

  assert.equal(reservation.status, "requested");
  assert.equal(reservation.totalAmount, 25_000);
  assert.equal(reservation.priceSnapshot.nights.length, 2);
  assert.equal(reservation.cancellationPolicySnapshot.version, 1);
  assert.equal(reservation.checkOutAt, "2026-08-17T10:00:00");
  assert.deepEqual(reservation.roomAssignments.map((item) => item.stayRoomId), ["room-1"]);
  assert.deepEqual(reservation.bedAssignments, []);
  assert.equal(workspace.stayReservations.length, 1);
});

test("即時確定の相部屋予約は人数分のBedを割り当てる", () => {
  const workspace = reservationWorkspace("instant", "shared_room");
  const reservation = createStayReservation(workspace, reservationInput(), new Date("2026-08-01T00:00:00Z"));

  assert.equal(reservation.status, "confirmed");
  assert.equal(reservation.approvalExpiresAt, null);
  assert.equal(reservation.quantity, 2);
  assert.deepEqual(reservation.bedAssignments.map((item) => item.stayBedId), ["bed-1", "bed-2"]);
});

test("同じ期間の後続予約で物理在庫が不足する場合は保存しない", () => {
  const workspace = reservationWorkspace("instant", "private_room");
  createStayReservation(workspace, reservationInput(), new Date("2026-08-01T00:00:00Z"));

  assert.throws(
    () => createStayReservation(workspace, reservationInput(), new Date("2026-08-01T01:00:00Z")),
    /在庫が不足/,
  );
  assert.equal(workspace.stayReservations.length, 1);
});

test("登録する宿泊者数が予約人数を超える場合は予約を保存しない", () => {
  const workspace = reservationWorkspace("instant", "private_room");
  const input = reservationInput();
  input.guestCount = 1;

  assert.throws(() => createStayReservation(workspace, input), /宿泊人数を超えています/);
  assert.equal(workspace.stayReservations.length, 0);
});

test("予約者が選択した到着予定時刻をチェックイン開始日時とは別に保存する", () => {
  const workspace = reservationWorkspace("instant", "private_room");
  const input = reservationInput();
  input.expectedArrivalAt = "2026-08-15T18:00";
  const reservation = createStayReservation(workspace, input, new Date("2026-08-01T00:00:00Z"));

  assert.equal(reservation.checkInAt, "2026-08-15T15:00:00");
  assert.equal(reservation.expectedArrivalAt, "2026-08-15T18:00:00");
});

test("到着予定日時は未入力でも予約できる", () => {
  const workspace = reservationWorkspace("instant", "private_room");
  const reservation = createStayReservation(workspace, reservationInput(), new Date("2026-08-01T00:00:00Z"));

  assert.equal(reservation.expectedArrivalAt, null);
});

test("施設が提示していない到着予定時刻は保存しない", () => {
  const workspace = reservationWorkspace("instant", "private_room");
  const input = reservationInput();
  input.expectedArrivalAt = "2026-08-15T18:30";

  assert.throws(() => createStayReservation(workspace, input), /選択肢/);
  assert.equal(workspace.stayReservations.length, 0);
});

test("到着予定時刻はチェックイン開始から最終時刻まで1時間間隔で生成する", () => {
  assert.deepEqual(arrivalTimeOptions("15:00", "18:00"), ["15:00", "16:00", "17:00", "18:00"]);
  assert.deepEqual(arrivalTimeOptions("15:30", "18:00"), ["15:30", "16:30", "17:30"]);
});

test("最終チェックインが開始以前なら到着予定時刻を生成しない", () => {
  assert.deepEqual(arrivalTimeOptions("15:00", "15:00"), []);
  assert.deepEqual(arrivalTimeOptions("18:00", "17:00"), []);
});

test("予約ダッシュボードは選択した施設の予約だけを集計する", () => {
  const workspace = dashboardWorkspace();
  const dashboard = reservationDashboard(workspace, "listing-1", "2026-08-15");

  assert.deepEqual(dashboard.recent.map((item) => item.id), ["requested", "arrival", "departure", "canceled"]);
  assert.equal(dashboard.recent.some((item) => item.id === "other-listing"), false);
});

test("滞在中予約はチェックアウト日を含まない半開区間で判定する", () => {
  const dashboard = reservationDashboard(dashboardWorkspace(), "listing-1", "2026-08-15");

  assert.deepEqual(dashboard.arrivals.map((item) => item.id), ["arrival"]);
  assert.deepEqual(dashboard.departures.map((item) => item.id), ["departure"]);
  assert.deepEqual(dashboard.staying.map((item) => item.id), ["arrival"]);
});

test("承認待ちは承認期限順に並び終端状態を当日業務から除外する", () => {
  const workspace = dashboardWorkspace();
  workspace.stayReservations.push({ ...workspace.stayReservations[0], id: "requested-urgent", approvalExpiresAt: "2026-08-14T22:00:00Z", createdAt: "2026-08-13T00:00:00Z" });
  const dashboard = reservationDashboard(workspace, "listing-1", "2026-08-15");

  assert.deepEqual(dashboard.pending.map((item) => item.id), ["requested-urgent", "requested"]);
  assert.equal(dashboard.arrivals.some((item) => item.id === "canceled"), false);
  assert.equal(dashboard.staying.some((item) => item.id === "canceled"), false);
});

test("本日の到着は申告した到着予定時刻順とし未定を末尾にする", () => {
  const workspace = dashboardWorkspace();
  workspace.stayReservations.push(
    { id: "arrival-early", listingId: "listing-1", status: "confirmed", checkInDate: "2026-08-15", checkOutDate: "2026-08-16", expectedArrivalAt: "2026-08-15T16:00:00", createdAt: "2026-08-13T00:00:00Z" },
    { id: "arrival-undecided", listingId: "listing-1", status: "confirmed", checkInDate: "2026-08-15", checkOutDate: "2026-08-16", expectedArrivalAt: null, createdAt: "2026-08-14T00:00:00Z" },
  );
  workspace.stayReservations.find((item) => item.id === "arrival").expectedArrivalAt = "2026-08-15T18:00:00";
  const dashboard = reservationDashboard(workspace, "listing-1", "2026-08-15");

  assert.deepEqual(dashboard.arrivals.map((item) => item.id), ["arrival-early", "arrival", "arrival-undecided"]);
});

test("申請中予約を承認すると確定状態と追記履歴を同時に保存する", () => {
  const workspace = transitionWorkspace("requested");
  const result = transitionStayReservation(workspace, { reservationId: "reservation-1", action: "approve", tenantMemberId: "member-1" }, new Date("2026-08-14T01:00:00Z"));

  assert.equal(result.reservation.status, "confirmed");
  assert.equal(result.event.eventType, "approved");
  assert.equal(result.event.fromStatus, "requested");
  assert.equal(result.event.toStatus, "confirmed");
  assert.equal(result.event.tenantMemberId, "member-1");
  assert.equal(result.event.reasonCode, null);
  assert.equal(workspace.stayReservationEvents.length, 1);
});

test("拒否理由が未選択なら状態と履歴を変更しない", () => {
  const workspace = transitionWorkspace("requested");

  assert.throws(() => transitionStayReservation(workspace, { reservationId: "reservation-1", action: "reject" }), /操作理由/);
  assert.equal(workspace.stayReservations[0].status, "requested");
  assert.equal(workspace.stayReservationEvents.length, 0);
});

test("その他の理由では利用者向け説明を必須とする", () => {
  const workspace = transitionWorkspace("requested");

  assert.throws(() => transitionStayReservation(workspace, { reservationId: "reservation-1", action: "reject", reasonCode: "other" }), /利用者向け説明/);
  assert.equal(workspace.stayReservations[0].status, "requested");
});

test("テナント都合取消は取消料0円の履歴と二経路の通知を保存する", () => {
  const workspace = transitionWorkspace("confirmed");
  const result = transitionStayReservation(workspace, {
    reservationId: "reservation-1",
    action: "cancel",
    reasonCode: "maintenance",
    reasonDetail: "給湯設備の故障のため",
    internalNote: "修理依頼済み",
  }, new Date("2026-08-14T02:00:00Z"));

  assert.equal(result.reservation.status, "canceled");
  assert.equal(result.event.eventType, "canceled_by_tenant");
  assert.equal(result.event.cancellationPenaltyAmount, 0);
  assert.equal(result.notifications.length, 2);
  assert.deepEqual(result.notifications.map((item) => item.channel), ["in_app", "email"]);
  assert.equal(result.notifications[1].destination, "guest@example.com");
  assert.equal(result.notifications[0].payloadSnapshot.version, 1);
  assert.equal("internalNote" in result.notifications[0].payloadSnapshot, false);
});

test("終端状態の予約は承認・拒否・取消できない", () => {
  const workspace = transitionWorkspace("canceled");

  assert.throws(() => transitionStayReservation(workspace, { reservationId: "reservation-1", action: "cancel", reasonCode: "maintenance" }), /現在の予約状態/);
  assert.equal(workspace.stayReservationEvents.length, 0);
  assert.equal(workspace.stayReservationNotifications.length, 0);
});

test("再割り当て候補は同じRoom Typeの有効かつ予約期間中に空いているRoomだけ返す", () => {
  const workspace = assignmentWorkspace();
  const candidates = availableAssignmentCandidates(workspace, "reservation-current", new Date("2026-08-01T00:00:00Z"));

  assert.deepEqual(candidates, [{ id: "room-3", name: "103", kind: "room" }]);
});

test("確定予約のRoomを空きRoomへ再割り当てする", () => {
  const workspace = assignmentWorkspace();
  const assignment = reassignReservationInventory(workspace, {
    reservationId: "reservation-current",
    currentInventoryId: "room-1",
    newInventoryId: "room-3",
    tenantMemberId: "member-1",
  }, new Date("2026-08-10T01:00:00Z"));

  assert.equal(assignment.stayRoomId, "room-3");
  assert.equal(assignment.assignedByTenantMemberId, "member-1");
  assert.equal(assignment.assignedAt, "2026-08-10T01:00:00.000Z");
});

test("他予約が使用中のRoomへの変更失敗時は元の割り当てを維持する", () => {
  const workspace = assignmentWorkspace();

  assert.throws(() => reassignReservationInventory(workspace, {
    reservationId: "reservation-current",
    currentInventoryId: "room-1",
    newInventoryId: "room-2",
  }), /利用できません/);
  assert.equal(workspace.stayReservations[0].roomAssignments[0].stayRoomId, "room-1");
});

test("確定前または終端状態の予約は割り当てを変更できない", () => {
  const workspace = assignmentWorkspace();
  workspace.stayReservations[0].status = "requested";

  assert.throws(() => reassignReservationInventory(workspace, {
    reservationId: "reservation-current",
    currentInventoryId: "room-1",
    newInventoryId: "room-3",
  }), /確定済み予約/);
  assert.equal(workspace.stayReservations[0].roomAssignments[0].stayRoomId, "room-1");
});

test("相部屋予約は有効な親Roomに属する空きBedへ再割り当てする", () => {
  const workspace = bedAssignmentWorkspace();
  assert.deepEqual(availableAssignmentCandidates(workspace, "reservation-bed"), [{ id: "bed-3", name: "201 / C", kind: "bed" }]);

  const assignment = reassignReservationInventory(workspace, {
    reservationId: "reservation-bed",
    currentInventoryId: "bed-1",
    newInventoryId: "bed-3",
  });
  assert.equal(assignment.stayBedId, "bed-3");
});

test("予約割り当てと重なるRoom停止期間は登録しない", () => {
  const workspace = assignmentWorkspace();

  assert.throws(() => addInventoryBlock(workspace, { listingId: "listing-1", inventoryId: "room-1", startsOn: "2026-08-16", endsOn: "2026-08-18", reason: "maintenance" }), /予約割り当て/);
  assert.deepEqual(workspace.stayListings[0].rooms[0].blocks || [], []);
});

test("予約と重ならない停止期間を追加して解除できる", () => {
  const workspace = assignmentWorkspace();
  const block = addInventoryBlock(workspace, { listingId: "listing-1", inventoryId: "room-3", startsOn: "2026-08-20", endsOn: "2026-08-22", reason: "cleaning" });

  assert.equal(workspace.stayListings[0].rooms[2].blocks.length, 1);
  assert.equal(removeInventoryBlock(workspace, { listingId: "listing-1", blockId: block.id }).reason, "cleaning");
  assert.equal(workspace.stayListings[0].rooms[2].blocks.length, 0);
});

test("停止期間と重なるRoomを再割り当て候補から除外する", () => {
  const workspace = assignmentWorkspace();
  workspace.stayListings[0].rooms[2].blocks = [{ id: "block-1", startsOn: "2026-08-15", endsOn: "2026-08-17", reason: "maintenance" }];

  assert.deepEqual(availableAssignmentCandidates(workspace, "reservation-current"), []);
});

test("停止期間中の物理Roomには新規予約を割り当てない", () => {
  const workspace = reservationWorkspace("instant", "private_room");
  workspace.stayListings[0].rooms[0].blocks = [{ id: "block-1", startsOn: "2026-08-15", endsOn: "2026-08-17", reason: "maintenance" }];

  assert.throws(() => createStayReservation(workspace, reservationInput()), /割り当て可能な物理在庫/);
  assert.equal(workspace.stayReservations.length, 0);
});

test("予約割り当てがないRoomはRoom Typeへ分類し未分類へ戻せる", () => {
  const workspace = assignmentWorkspace();
  workspace.stayListings[0].rooms.push({ id: "room-unclassified", roomTypeId: null, name: "105", active: true, beds: [] });

  assert.equal(assignRoomType(workspace, { listingId: "listing-1", roomId: "room-unclassified", roomTypeId: "room-type-1" }).roomTypeId, "room-type-1");
  assert.equal(assignRoomType(workspace, { listingId: "listing-1", roomId: "room-unclassified", roomTypeId: null }).roomTypeId, null);
});

test("有効な予約割り当てを持つRoomはRoom Type変更や未分類化ができない", () => {
  const workspace = assignmentWorkspace();

  assert.throws(() => assignRoomType(workspace, { listingId: "listing-1", roomId: "room-1", roomTypeId: null }), /予約割り当て/);
  assert.equal(workspace.stayListings[0].rooms[0].roomTypeId, "room-type-1");
});

test("Bedを持つRoomは個室Room Typeへ分類できない", () => {
  const workspace = bedAssignmentWorkspace();
  workspace.stayListings[0].roomTypes.push({ id: "private-type", roomKind: "private_room" });
  workspace.stayReservations = [];

  assert.throws(() => assignRoomType(workspace, { listingId: "listing-1", roomId: "room-201", roomTypeId: "private-type" }), /相部屋/);
  assert.equal(workspace.stayListings[0].rooms[0].roomTypeId, "room-type-bed");
});

function assignmentWorkspace() {
  return {
    stayListings: [{
      id: "listing-1",
      roomTypes: [{
        id: "room-type-1",
        roomKind: "private_room",
      }],
      rooms: [
        { id: "room-1", roomTypeId: "room-type-1", name: "101", active: true, beds: [] },
        { id: "room-2", roomTypeId: "room-type-1", name: "102", active: true, beds: [] },
        { id: "room-3", roomTypeId: "room-type-1", name: "103", active: true, beds: [] },
        { id: "room-4", roomTypeId: "room-type-1", name: "104", active: false, beds: [] },
      ],
    }],
    stayReservations: [
      { id: "reservation-current", listingId: "listing-1", roomTypeId: "room-type-1", status: "confirmed", checkInDate: "2026-08-15", checkOutDate: "2026-08-17", roomAssignments: [{ stayRoomId: "room-1" }], bedAssignments: [] },
      { id: "reservation-overlap", listingId: "listing-1", roomTypeId: "room-type-1", status: "confirmed", checkInDate: "2026-08-16", checkOutDate: "2026-08-18", roomAssignments: [{ stayRoomId: "room-2" }], bedAssignments: [] },
    ],
  };
}

function bedAssignmentWorkspace() {
  return {
    stayListings: [{
      id: "listing-1",
      roomTypes: [{
        id: "room-type-bed",
        roomKind: "shared_room",
      }],
      rooms: [{
          id: "room-201",
          roomTypeId: "room-type-bed",
          name: "201",
          active: true,
          beds: [
            { id: "bed-1", name: "A", active: true },
            { id: "bed-2", name: "B", active: false },
            { id: "bed-3", name: "C", active: true },
          ],
        }],
    }],
    stayReservations: [{
      id: "reservation-bed",
      listingId: "listing-1",
      roomTypeId: "room-type-bed",
      status: "confirmed",
      checkInDate: "2026-08-15",
      checkOutDate: "2026-08-17",
      roomAssignments: [],
      bedAssignments: [{ stayBedId: "bed-1" }],
    }],
  };
}

function transitionWorkspace(status) {
  return {
    stayReservations: [{
      id: "reservation-1",
      reservationNumber: "ST-TEST-0000-0001",
      userId: "user-1",
      listingId: "listing-1",
      status,
      checkInDate: "2026-08-20",
      checkOutDate: "2026-08-22",
      totalAmount: 20_000,
      priceSnapshot: { version: 1, room_type: { name: "個室" }, rate_plan: { name: "素泊まり" } },
      guests: [{ guestRole: "primary", name: "宿泊者", email: "guest@example.com" }],
    }],
    stayReservationEvents: [],
    stayReservationNotifications: [],
  };
}

function dashboardWorkspace() {
  return {
    stayReservations: [
      { id: "requested", listingId: "listing-1", status: "requested", checkInDate: "2026-08-20", checkOutDate: "2026-08-22", approvalExpiresAt: "2026-08-15T00:00:00Z", createdAt: "2026-08-14T00:00:00Z" },
      { id: "arrival", listingId: "listing-1", status: "confirmed", checkInDate: "2026-08-15", checkOutDate: "2026-08-17", createdAt: "2026-08-12T00:00:00Z" },
      { id: "departure", listingId: "listing-1", status: "confirmed", checkInDate: "2026-08-13", checkOutDate: "2026-08-15", createdAt: "2026-08-11T00:00:00Z" },
      { id: "canceled", listingId: "listing-1", status: "canceled", checkInDate: "2026-08-15", checkOutDate: "2026-08-16", createdAt: "2026-08-10T00:00:00Z" },
      { id: "other-listing", listingId: "listing-2", status: "confirmed", checkInDate: "2026-08-15", checkOutDate: "2026-08-16", createdAt: "2026-08-15T00:00:00Z" },
    ],
  };
}

function completeState() {
  return {
    title: "テスト施設",
    description: "施設説明",
    images: [{ id: "image" }],
    location: { prefecture: "東京都", city: "渋谷区", addressLine1: "1-1", latitude: 35.6, longitude: 139.7 },
    stay: { checkInTime: "15:00", latestCheckInTime: "22:00", checkOutTime: "10:00", bookingOpenDaysBefore: 365, bookingCloseHoursBefore: 0 },
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

function reservationWorkspace(mode, roomKind) {
  const roomType = {
    id: "private",
    name: roomKind === "shared_room" ? "ドミトリー" : "個室",
    roomKind,
    capacity: roomKind === "shared_room" ? 1 : 2,
    status: "published",
    amenityIds: ["wifi"],
    dailySalesControls: [],
  };
  return {
    schemaVersion: 2,
    tenant: { id: "tenant", name: "テナント" },
    amenities: [{ id: "wifi", name: "Wi-Fi", active: true }],
    stayListings: [{
      id: "listing",
      status: "published",
      stay: { bookingConfirmationMode: mode, approvalDeadlineHours: 24, checkInTime: "15:00", latestCheckInTime: "22:00", checkOutTime: "10:00", timeZone: "Asia/Tokyo", stayAvailableStartsOn: "2026-08-01", stayAvailableEndsOn: "2026-09-01", facilityAmenityIds: ["wifi"] },
      roomTypes: [roomType],
      rooms: roomKind === "shared_room"
        ? [{ id: "room-1", roomTypeId: "private", active: true, beds: [{ id: "bed-1", active: true }, { id: "bed-2", active: true }] }]
        : [{ id: "room-1", roomTypeId: "private", active: true, beds: [] }],
      ratePlans: [{ id: "standard", name: "素泊まり", description: "", mealType: "room_only", cancellationPolicyType: "standard", status: "published" }],
      roomTypeRates: [{ id: "rate", roomTypeId: "private", ratePlanId: "standard", active: true, pricePerNightAmount: 10_000, dailyPrices: [{ stayDate: "2026-08-15", priceAmount: 15_000 }] }],
    }],
    stayReservations: [],
  };
}

function reservationInput() {
  return {
    listingId: "listing",
    roomTypeId: "private",
    rateId: "rate",
    checkInDate: "2026-08-15",
    checkOutDate: "2026-08-17",
    guestCount: 2,
    primaryGuest: { name: "田中太郎", email: "taro@example.com", phone: "090-0000-0000" },
    companionNames: ["田中花子"],
    message: "よろしくお願いします",
  };
}
