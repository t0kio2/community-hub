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
    workspace.stayListings.forEach((listing) => { delete listing.amenities; });
    return workspace;
  }

  const listing = structuredClone(data);
  const amenities = listing.amenities || [];
  delete listing.amenities;
  return {
    schemaVersion: 2,
    tenant: { id: "tenant-prototype", name: "Prototype Tenant" },
    amenities,
    stayListings: [listing],
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
    { id: "check_in", label: "チェックイン時刻が設定されている", passed: Boolean(state.stay.checkInTime) },
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
