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
