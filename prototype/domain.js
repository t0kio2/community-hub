export function physicalInventory(roomType) {
  const activeRooms = roomType.rooms.filter((room) => room.active);
  if (roomType.roomKind !== "shared_room") return activeRooms.length;

  return activeRooms.reduce(
    (total, room) => total + room.beds.filter((bed) => bed.active).length,
    0,
  );
}

export function inventoryForDate(roomType, date) {
  const physical = physicalInventory(roomType);
  const control = roomType.dailySalesControls.find((item) => item.stayDate === date);
  const limit = control ? control.salesLimit : physical;
  return Math.max(0, Math.min(physical, limit));
}

export function priceForDate(state, roomTypeId, ratePlanId, date) {
  const rate = state.roomTypeRates.find(
    (item) => item.roomTypeId === roomTypeId && item.ratePlanId === ratePlanId && item.active,
  );
  if (!rate) return null;

  const dailyPrice = rate.dailyPrices.find((item) => item.stayDate === date);
  return dailyPrice?.priceAmount ?? rate.pricePerNightAmount;
}

export function addDays(date, days) {
  if (!date) return "";
  const value = new Date(`${date}T00:00:00Z`);
  if (Number.isNaN(value.getTime())) return "";
  value.setUTCDate(value.getUTCDate() + days);
  return value.toISOString().slice(0, 10);
}

export function arrivalTimeOptions(checkInTime, latestCheckInTime) {
  const toMinutes = (value) => {
    const match = /^(\d{2}):(\d{2})$/.exec(value || "");
    if (!match) return null;
    return Number(match[1]) * 60 + Number(match[2]);
  };
  const startsAt = toMinutes(checkInTime);
  const endsAt = toMinutes(latestCheckInTime);
  if (startsAt === null || endsAt === null || startsAt >= endsAt) return [];
  const format = (minutes) => `${String(Math.floor(minutes / 60)).padStart(2, "0")}:${String(minutes % 60).padStart(2, "0")}`;
  const options = [];
  for (let minutes = startsAt; minutes <= endsAt; minutes += 60) options.push(format(minutes));
  return options;
}

export function availableLastNightOn(stayAvailableEndsOn) {
  return addDays(stayAvailableEndsOn, -1);
}

export function stayAvailableEndsOn(lastNightOn) {
  return addDays(lastNightOn, 1);
}

export function stayDates(checkInDate, checkOutDate) {
  if (!checkInDate || !checkOutDate || checkInDate >= checkOutDate) return [];
  const dates = [];
  for (let date = checkInDate; date < checkOutDate; date = addDays(date, 1)) dates.push(date);
  return dates;
}

export function buildStayPreview(state, { checkInDate, checkOutDate, guestCount }) {
  const dates = stayDates(checkInDate, checkOutDate);
  const guests = Number(guestCount);
  const inputErrors = [];
  if (dates.length === 0) inputErrors.push("チェックアウト日はチェックイン日より後にしてください");
  if (!Number.isInteger(guests) || guests < 1) inputErrors.push("宿泊人数は1人以上にしてください");

  const listingReasons = [];
  if (state.status !== "published") listingReasons.push("施設が公開されていません");
  const scheduleReasons = [];
  if (dates.length > 0 && state.stay.stayAvailableStartsOn && checkInDate < state.stay.stayAvailableStartsOn) {
    scheduleReasons.push("宿泊提供期間より前の日程です");
  }
  if (dates.length > 0 && state.stay.stayAvailableEndsOn && checkOutDate > state.stay.stayAvailableEndsOn) {
    scheduleReasons.push("宿泊提供期間より後の日程です");
  }
  listingReasons.push(...scheduleReasons);

  const roomTypes = state.roomTypes.map((roomType) => {
    const requiredQuantity = roomType.roomKind === "shared_room"
      ? guests
      : Math.ceil(guests / Number(roomType.capacity || 0));
    const availableUnits = dates.length > 0
      ? Math.min(...dates.map((date) => inventoryForDate(roomType, date)))
      : 0;
    const roomReasons = [...scheduleReasons, ...inputErrors];
    if (roomType.status !== "published") roomReasons.push("Room Typeが公開されていません");
    if (!Number(roomType.capacity)) roomReasons.push("定員が設定されていません");
    if (dates.length > 0 && requiredQuantity > availableUnits) roomReasons.push("日程全体で必要な在庫を確保できません");

    const rates = state.roomTypeRates
      .filter((rate) => rate.roomTypeId === roomType.id)
      .map((rate) => {
        const plan = state.ratePlans.find((item) => item.id === rate.ratePlanId);
        const reasons = [...roomReasons];
        if (!plan) reasons.push("Rate Planが存在しません");
        else if (plan.status !== "published") reasons.push("Rate Planが公開されていません");
        if (!rate.active) reasons.push("Room Type別料金が販売停止中です");
        const nights = dates.map((stayDate) => {
          const unitAmount = priceForDate(state, roomType.id, rate.ratePlanId, stayDate) || 0;
          return { stayDate, unitAmount, quantity: requiredQuantity, subtotalAmount: unitAmount * requiredQuantity };
        });
        const totalAmount = nights.reduce((total, night) => total + night.subtotalAmount, 0);
        const sellable = reasons.length === 0;
        return { rate, plan, reasons: [...new Set(reasons)], nights, totalAmount, sellable, visibleToGuests: sellable && state.status === "published" };
      });

    if (rates.length === 0) roomReasons.push("Room Type別料金が設定されていません");
    return {
      roomType,
      requiredQuantity,
      availableUnits,
      rates,
      reasons: [...new Set(roomReasons)],
      sellable: rates.some((rate) => rate.sellable),
    };
  });

  return { dates, inputErrors, listingReasons, roomTypes };
}

export function normalizeWorkspace(data) {
  if (Array.isArray(data?.stayListings)) {
    const workspace = structuredClone(data);
    workspace.schemaVersion = 2;
    workspace.tenant ||= { id: "tenant-prototype", name: "Prototype Tenant" };
    workspace.amenities ||= workspace.stayListings[0]?.amenities || [];
    workspace.stayReservations ||= [];
    workspace.stayListings.forEach((listing) => {
      delete listing.amenities;
      listing.stay ||= {};
      listing.stay.latestCheckInTime ||= "22:00";
    });
    return workspace;
  }

  const listing = structuredClone(data);
  const amenities = listing.amenities || [];
  delete listing.amenities;
  listing.stay ||= {};
  listing.stay.latestCheckInTime ||= "22:00";
  return {
    schemaVersion: 2,
    tenant: { id: "tenant-prototype", name: "Prototype Tenant" },
    amenities,
    stayListings: [listing],
    stayReservations: [],
  };
}

export function reservationDashboard(workspace, listingId, businessDate) {
  const reservations = (workspace.stayReservations || []).filter((reservation) => reservation.listingId === listingId);
  const confirmed = reservations.filter((reservation) => reservation.status === "confirmed");
  const byCreatedAtDesc = (left, right) => String(right.createdAt || "").localeCompare(String(left.createdAt || ""));

  return {
    pending: reservations
      .filter((reservation) => reservation.status === "requested")
      .sort((left, right) => String(left.approvalExpiresAt || "9999").localeCompare(String(right.approvalExpiresAt || "9999"))),
    arrivals: confirmed.filter((reservation) => reservation.checkInDate === businessDate).sort((left, right) => {
      if (!left.expectedArrivalAt && !right.expectedArrivalAt) return byCreatedAtDesc(left, right);
      if (!left.expectedArrivalAt) return 1;
      if (!right.expectedArrivalAt) return -1;
      return left.expectedArrivalAt.localeCompare(right.expectedArrivalAt);
    }),
    departures: confirmed.filter((reservation) => reservation.checkOutDate === businessDate).sort(byCreatedAtDesc),
    staying: confirmed
      .filter((reservation) => reservation.checkInDate <= businessDate && businessDate < reservation.checkOutDate)
      .sort((left, right) => left.checkOutDate.localeCompare(right.checkOutDate)),
    recent: reservations.slice().sort(byCreatedAtDesc).slice(0, 8),
  };
}

export function transitionStayReservation(workspace, input, now = new Date()) {
  const reservation = (workspace.stayReservations || []).find((item) => item.id === input.reservationId);
  if (!reservation) throw new Error("対象の予約が見つかりません");

  const definitions = {
    approve: { from: ["requested"], to: "confirmed", eventType: "approved", reasonCodes: [] },
    reject: {
      from: ["requested"],
      to: "rejected",
      eventType: "rejected",
      reasonCodes: ["unable_to_accommodate", "request_not_acceptable", "facility_unavailable", "other"],
    },
    cancel: {
      from: ["requested", "confirmed"],
      to: "canceled",
      eventType: "canceled_by_tenant",
      reasonCodes: ["facility_unavailable", "maintenance", "overbooking", "safety", "other"],
    },
  };
  const definition = definitions[input.action];
  if (!definition || !definition.from.includes(reservation.status)) throw new Error("現在の予約状態ではこの操作を実行できません");

  const reasonCode = input.reasonCode || null;
  const reasonDetail = input.reasonDetail?.trim() || null;
  const internalNote = input.internalNote?.trim() || null;
  if (definition.reasonCodes.length && !definition.reasonCodes.includes(reasonCode)) throw new Error("操作理由を選択してください");
  if (reasonCode === "other" && !reasonDetail) throw new Error("その他の理由では利用者向け説明が必要です");

  const occurredAt = now.toISOString();
  const fromStatus = reservation.status;
  const event = {
    id: makeId("reservation-event"),
    stayReservationId: reservation.id,
    tenantMemberId: input.tenantMemberId || "tenant-member-prototype",
    eventType: definition.eventType,
    fromStatus,
    toStatus: definition.to,
    actorType: "tenant_member",
    reasonCode,
    reasonDetail,
    internalNote,
    cancellationPenaltyAmount: input.action === "cancel" ? 0 : null,
    occurredAt,
    createdAt: occurredAt,
  };

  const notifications = input.action === "cancel"
    ? tenantCancellationNotifications(reservation, event, now)
    : [];

  workspace.stayReservationEvents ||= [];
  workspace.stayReservationNotifications ||= [];
  reservation.status = definition.to;
  reservation.updatedAt = occurredAt;
  workspace.stayReservationEvents.push(event);
  workspace.stayReservationNotifications.push(...notifications);
  return { reservation, event, notifications };
}

export function availableAssignmentCandidates(workspace, reservationId, now = new Date()) {
  const reservation = (workspace.stayReservations || []).find((item) => item.id === reservationId);
  const listing = reservation && workspace.stayListings.find((item) => item.id === reservation.listingId);
  const roomType = listing?.roomTypes.find((item) => item.id === reservation.roomTypeId);
  if (!reservation || !roomType) return [];

  const overlapping = (workspace.stayReservations || []).filter((item) =>
    item.id !== reservation.id &&
    item.listingId === reservation.listingId &&
    ["requested", "confirmed"].includes(item.status) &&
    item.checkInDate < reservation.checkOutDate &&
    item.checkOutDate > reservation.checkInDate &&
    (item.status !== "requested" || !item.approvalExpiresAt || item.approvalExpiresAt > now.toISOString()),
  );
  const usedRoomIds = new Set(overlapping.flatMap((item) => (item.roomAssignments || []).map((assignment) => assignment.stayRoomId)));
  const usedBedIds = new Set(overlapping.flatMap((item) => (item.bedAssignments || []).map((assignment) => assignment.stayBedId)));
  const currentIds = new Set([
    ...(reservation.roomAssignments || []).map((item) => item.stayRoomId),
    ...(reservation.bedAssignments || []).map((item) => item.stayBedId),
  ]);

  if (roomType.roomKind === "shared_room") {
    return roomType.rooms.filter((room) => room.active).flatMap((room) => room.beds
      .filter((bed) => bed.active && !usedBedIds.has(bed.id) && !currentIds.has(bed.id))
      .map((bed) => ({ id: bed.id, name: `${room.name} / ${bed.name}`, kind: "bed" })));
  }
  return roomType.rooms
    .filter((room) => room.active && !usedRoomIds.has(room.id) && !currentIds.has(room.id))
    .map((room) => ({ id: room.id, name: room.name, kind: "room" }));
}

export function reassignReservationInventory(workspace, input, now = new Date()) {
  const reservation = (workspace.stayReservations || []).find((item) => item.id === input.reservationId);
  if (!reservation) throw new Error("対象の予約が見つかりません");
  if (reservation.status !== "confirmed") throw new Error("確定済み予約だけ割り当てを変更できます");

  const roomAssignment = (reservation.roomAssignments || []).find((item) => item.stayRoomId === input.currentInventoryId);
  const bedAssignment = (reservation.bedAssignments || []).find((item) => item.stayBedId === input.currentInventoryId);
  const assignment = roomAssignment || bedAssignment;
  if (!assignment) throw new Error("現在の割り当てが予約に含まれていません");

  const candidate = availableAssignmentCandidates(workspace, reservation.id, now).find((item) => item.id === input.newInventoryId);
  if (!candidate || (roomAssignment && candidate.kind !== "room") || (bedAssignment && candidate.kind !== "bed")) {
    throw new Error("変更先のRoomまたはBedを利用できません");
  }

  if (roomAssignment) assignment.stayRoomId = candidate.id;
  else assignment.stayBedId = candidate.id;
  assignment.assignedByTenantMemberId = input.tenantMemberId || "tenant-member-prototype";
  assignment.assignedAt = now.toISOString();
  reservation.updatedAt = now.toISOString();
  return assignment;
}

function tenantCancellationNotifications(reservation, event, now) {
  const primaryGuest = reservation.guests?.find((guest) => guest.guestRole === "primary");
  const createdAt = now.toISOString();
  const payloadSnapshot = {
    version: 1,
    reservation_number: reservation.reservationNumber || reservation.id,
    check_in_date: reservation.checkInDate,
    check_out_date: reservation.checkOutDate,
    room_type_name: reservation.priceSnapshot?.room_type?.name || null,
    rate_plan_name: reservation.priceSnapshot?.rate_plan?.name || null,
    reason_code: event.reasonCode,
    reason_detail: event.reasonDetail,
    cancellation_penalty_amount: 0,
  };
  const common = {
    stayReservationId: reservation.id,
    stayReservationEventId: event.id,
    notificationType: "canceled_by_tenant",
    status: "pending",
    attemptCount: 0,
    payloadSnapshot,
    createdAt,
    updatedAt: createdAt,
  };
  return [
    { ...common, id: makeId("notification"), channel: "in_app", recipientType: "booking_user", userId: reservation.userId, destination: null, status: "sent", sentAt: createdAt },
    { ...common, id: makeId("notification"), channel: "email", recipientType: "primary_guest", userId: null, destination: primaryGuest?.email || null, sentAt: null },
  ];
}

export function createStayReservation(workspace, input, now = new Date()) {
  const listing = workspace.stayListings.find((item) => item.id === input.listingId);
  const roomType = listing?.roomTypes.find((item) => item.id === input.roomTypeId);
  const rate = listing?.roomTypeRates.find((item) => item.id === input.rateId);
  const plan = rate && listing.ratePlans.find((item) => item.id === rate.ratePlanId);
  if (!listing || !roomType || !rate || !plan) throw new Error("選択した販売プランが見つかりません");
  if (!input.primaryGuest?.name || !input.primaryGuest?.email || !input.primaryGuest?.phone) throw new Error("代表宿泊者の氏名・メールアドレス・電話番号は必須です");
  if ((input.companionNames || []).filter(Boolean).length + 1 > Number(input.guestCount)) throw new Error("登録する宿泊者数が宿泊人数を超えています");

  const preview = buildStayPreview(listing, input);
  const previewRoom = preview.roomTypes.find((item) => item.roomType.id === roomType.id);
  const previewRate = previewRoom?.rates.find((item) => item.rate.id === rate.id);
  if (!previewRate?.sellable) throw new Error("選択した日程では予約できません");

  const reservations = workspace.stayReservations || [];
  const activeReservations = reservations.filter((reservation) =>
    reservation.listingId === listing.id &&
    reservation.roomTypeId === roomType.id &&
    ["requested", "confirmed"].includes(reservation.status) &&
    reservation.checkInDate < input.checkOutDate &&
    reservation.checkOutDate > input.checkInDate &&
    (reservation.status !== "requested" || !reservation.approvalExpiresAt || reservation.approvalExpiresAt > now.toISOString()),
  );
  const usedCount = activeReservations.reduce((total, reservation) => total + reservation.quantity, 0);
  const availableAcrossStay = Math.min(...preview.dates.map((date) => Math.max(inventoryForDate(roomType, date) - usedCount, 0)));
  if (availableAcrossStay < previewRoom.requiredQuantity) throw new Error("ほかの予約により在庫が不足しています");

  const usedRoomIds = new Set(activeReservations.flatMap((reservation) => (reservation.roomAssignments || []).map((item) => item.stayRoomId)));
  const usedBedIds = new Set(activeReservations.flatMap((reservation) => (reservation.bedAssignments || []).map((item) => item.stayBedId)));
  const assignedAt = now.toISOString();
  const roomAssignments = [];
  const bedAssignments = [];
  if (roomType.roomKind === "shared_room") {
    const beds = roomType.rooms.filter((room) => room.active).flatMap((room) => room.beds.filter((bed) => bed.active));
    beds.filter((bed) => !usedBedIds.has(bed.id)).slice(0, previewRoom.requiredQuantity).forEach((bed) => bedAssignments.push({ stayBedId: bed.id, assignedAt }));
  } else {
    roomType.rooms.filter((room) => room.active && !usedRoomIds.has(room.id)).slice(0, previewRoom.requiredQuantity).forEach((room) => roomAssignments.push({ stayRoomId: room.id, assignedAt }));
  }
  if (roomAssignments.length + bedAssignments.length !== previewRoom.requiredQuantity) throw new Error("割り当て可能な物理在庫がありません");

  const status = listing.stay.bookingConfirmationMode === "instant" ? "confirmed" : "requested";
  const approvalDeadline = now.getTime() + listing.stay.approvalDeadlineHours * 3_600_000;
  const checkInDeadline = new Date(`${input.checkInDate}T${listing.stay.checkInTime}:00Z`).getTime();
  const approvalExpiresAt = status === "requested"
    ? new Date(Math.min(approvalDeadline, checkInDeadline)).toISOString()
    : null;
  const checkInAt = `${input.checkInDate}T${listing.stay.checkInTime}:00`;
  const checkOutAt = `${input.checkOutDate}T${listing.stay.checkOutTime}:00`;
  const expectedArrivalAt = input.expectedArrivalAt
    ? `${input.expectedArrivalAt}${input.expectedArrivalAt.length === 16 ? ":00" : ""}`
    : null;
  const validArrivalTimes = arrivalTimeOptions(listing.stay.checkInTime, listing.stay.latestCheckInTime);
  if (expectedArrivalAt && (
    expectedArrivalAt.slice(0, 10) !== input.checkInDate ||
    !validArrivalTimes.includes(expectedArrivalAt.slice(11, 16))
  )) {
    throw new Error("到着予定時刻は施設が提示する選択肢から選んでください");
  }
  const activeAmenities = workspace.amenities.filter((amenity) => amenity.active);
  const amenitySnapshot = (ids) => activeAmenities.filter((amenity) => ids.includes(amenity.id)).map((amenity) => ({ id: amenity.id, name: amenity.name }));
  const nights = previewRate.nights.map((night) => ({ stay_date: night.stayDate, unit_amount: night.unitAmount, quantity: night.quantity, subtotal_amount: night.subtotalAmount }));
  const reservation = {
    id: makeId("reservation"),
    userId: "user-prototype",
    listingId: listing.id,
    roomTypeId: roomType.id,
    stayRoomTypeRateId: rate.id,
    status,
    checkInDate: input.checkInDate,
    checkOutDate: input.checkOutDate,
    checkInAt,
    checkOutAt,
    expectedArrivalAt,
    timeZone: listing.stay.timeZone,
    quantity: previewRoom.requiredQuantity,
    guestCount: Number(input.guestCount),
    approvalExpiresAt,
    currency: "JPY",
    accommodationSubtotalAmount: previewRate.totalAmount,
    additionalFeeTotalAmount: 0,
    discountTotalAmount: 0,
    totalAmount: previewRate.totalAmount,
    priceSnapshot: {
      version: 1,
      currency: "JPY",
      pricing_unit: roomType.roomKind === "shared_room" ? "bed" : "room",
      room_type: { id: roomType.id, name: roomType.name, room_kind: roomType.roomKind, capacity: roomType.capacity, amenities: amenitySnapshot(roomType.amenityIds) },
      facility_amenities: amenitySnapshot(listing.stay.facilityAmenityIds),
      rate_plan: { id: plan.id, name: plan.name, meal_type: plan.mealType },
      quantity: previewRoom.requiredQuantity,
      guest_count: Number(input.guestCount),
      nights,
      accommodation_subtotal_amount: previewRate.totalAmount,
      additional_fee_total_amount: 0,
      discount_total_amount: 0,
      total_amount: previewRate.totalAmount,
    },
    cancellationPolicySnapshot: cancellationPolicySnapshot(plan.cancellationPolicyType),
    message: input.message || "",
    guests: [
      { guestRole: "primary", ...input.primaryGuest },
      ...(input.companionNames || []).filter(Boolean).map((name) => ({ guestRole: "companion", name })),
    ],
    roomAssignments,
    bedAssignments,
    createdAt: assignedAt,
    updatedAt: assignedAt,
  };
  workspace.stayReservations ||= [];
  workspace.stayReservations.push(reservation);
  return reservation;
}

function cancellationPolicySnapshot(type) {
  if (type === "non_refundable") return { version: 1, type, basis: "accommodation_subtotal", penalty_rate: 100, no_show_penalty_rate: 100 };
  return {
    version: 1,
    type: "standard",
    basis: "accommodation_subtotal",
    rules: [
      { hours_before_check_in: 168, penalty_rate: 20 },
      { hours_before_check_in: 48, penalty_rate: 50 },
      { hours_before_check_in: 24, penalty_rate: 80 },
      { hours_before_check_in: 0, penalty_rate: 100 },
    ],
    no_show_penalty_rate: 100,
  };
}

export function createBlankStayListing(title) {
  return {
    schemaVersion: 1,
    id: makeId("listing"),
    listingType: "stay",
    status: "draft",
    title,
    description: "",
    images: [],
    location: { postalCode: "", prefecture: "", city: "", addressLine1: "", addressLine2: "", googlePlaceId: "", latitude: "", longitude: "" },
    stay: {
      bookingConfirmationMode: "approval_required",
      approvalDeadlineHours: 24,
      checkInTime: "15:00",
      latestCheckInTime: "22:00",
      checkOutTime: "10:00",
      timeZone: "Asia/Tokyo",
      stayAvailableStartsOn: "",
      stayAvailableEndsOn: "",
      bookingOpenDaysBefore: 365,
      bookingCloseHoursBefore: 0,
      houseRules: "",
      facilityAmenityIds: [],
    },
    roomTypes: [],
    ratePlans: [],
    roomTypeRates: [],
  };
}

export function publicationChecks(state) {
  const publishedRoomTypes = state.roomTypes.filter((roomType) => roomType.status === "published");
  const publishedPlans = state.ratePlans.filter((plan) => plan.status === "published");
  const hasSellableRate = state.roomTypeRates.some((rate) => {
    const roomType = publishedRoomTypes.find((item) => item.id === rate.roomTypeId);
    const plan = publishedPlans.find((item) => item.id === rate.ratePlanId);
    return roomType && plan && rate.active && rate.pricePerNightAmount > 0;
  });

  return [
    { id: "title", label: "施設名が入力されている", passed: Boolean(state.title.trim()) },
    { id: "description", label: "施設説明が入力されている", passed: Boolean(state.description.trim()) },
    { id: "image", label: "画像が1件以上登録されている", passed: state.images.length > 0 },
    {
      id: "location",
      label: "住所と座標が入力されている",
      passed: Boolean(
        state.location.prefecture &&
          state.location.city &&
          state.location.addressLine1 &&
          Number.isFinite(Number(state.location.latitude)) &&
          Number.isFinite(Number(state.location.longitude)),
      ),
    },
    { id: "check_in", label: "チェックイン受付時間が正しく設定されている", passed: arrivalTimeOptions(state.stay.checkInTime, state.stay.latestCheckInTime).length > 0 && Boolean(state.stay.checkOutTime) },
    {
      id: "booking_window",
      label: "予約受付期間が正しい",
      passed:
        state.stay.bookingOpenDaysBefore >= 1 &&
        state.stay.bookingOpenDaysBefore <= 365 &&
        state.stay.bookingCloseHoursBefore >= 0 &&
        state.stay.bookingCloseHoursBefore <= 720 &&
        state.stay.bookingOpenDaysBefore * 24 > state.stay.bookingCloseHoursBefore,
    },
    {
      id: "room_type",
      label: "公開中で物理在庫を持つRoom Typeがある",
      passed: publishedRoomTypes.some((roomType) => physicalInventory(roomType) > 0),
    },
    { id: "rate_plan", label: "公開中のRate Planがある", passed: publishedPlans.length > 0 },
    { id: "rate", label: "公開中の部屋とプランに有効な料金がある", passed: hasSellableRate },
  ];
}

export function canPublish(state) {
  return publicationChecks(state).every((check) => check.passed);
}

export function makeId(prefix) {
  return `${prefix}-${Date.now().toString(36)}-${Math.random().toString(36).slice(2, 7)}`;
}
