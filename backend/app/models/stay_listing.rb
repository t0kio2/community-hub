class StayListing < ApplicationRecord
  BOOKING_CONFIRMATION_MODES = %w[instant approval_required].freeze

  belongs_to :listing

  validates :listing_id, uniqueness: true
  validates :booking_confirmation_mode, inclusion: { in: BOOKING_CONFIRMATION_MODES }
  validates :approval_deadline_hours,
            numericality: { only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: 72 }
  validates :booking_open_days_before,
            numericality: { only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: 365 }
  validates :booking_close_hours_before,
            numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 720 }
  validate :time_zone_is_valid
  validate :listing_type_is_stay
  validate :check_in_period_is_valid
  validate :stay_available_period_is_valid
  validate :booking_reception_period_is_valid

  private

  def listing_type_is_stay
    return if listing.blank? || listing.listing_type == "stay"

    errors.add(:listing, "は宿泊である必要があります")
  end

  def time_zone_is_valid
    return if time_zone.present? && TZInfo::Timezone.all_identifiers.include?(time_zone)

    errors.add(:time_zone, "は有効なIANAタイムゾーンにしてください")
  end

  def check_in_period_is_valid
    return if check_in_time.blank? || latest_check_in_time.blank? || check_in_time < latest_check_in_time

    errors.add(:latest_check_in_time, "はチェックイン開始時刻より後にしてください")
  end

  def stay_available_period_is_valid
    return if stay_available_starts_on.blank? || stay_available_ends_on.blank? ||
              stay_available_starts_on < stay_available_ends_on

    errors.add(:stay_available_ends_on, "は宿泊可能期間の開始日より後にしてください")
  end

  def booking_reception_period_is_valid
    return if booking_open_days_before.blank? || booking_close_hours_before.blank? ||
              booking_open_days_before * 24 > booking_close_hours_before

    errors.add(:booking_close_hours_before, "は予約受付開始より前に受付が終了する値にしてください")
  end
end
