class StayRatePlan < ApplicationRecord
  MEAL_TYPES = %w[room_only breakfast dinner breakfast_and_dinner other].freeze
  CANCELLATION_POLICY_TYPES = %w[standard non_refundable].freeze
  STATUSES = %w[draft published inactive].freeze

  belongs_to :stay_listing

  has_many :stay_room_type_rates
  has_many :stay_room_types, through: :stay_room_type_rates

  accepts_nested_attributes_for :stay_room_type_rates,
                                reject_if: ->(attributes) {
                                  attributes["id"].blank? && attributes["active"] != "1"
                                }

  validates :name, presence: true, length: { maximum: 100 }, uniqueness: { scope: :stay_listing_id }
  validates :description, length: { maximum: 2_000 }, allow_blank: true
  validates :meal_type, inclusion: { in: MEAL_TYPES }
  validates :cancellation_policy_type, inclusion: { in: CANCELLATION_POLICY_TYPES }
  validates :status, inclusion: { in: STATUSES }

  enum :meal_type, MEAL_TYPES.index_with(&:itself)
  enum :cancellation_policy_type, CANCELLATION_POLICY_TYPES.index_with(&:itself)
  enum :status, STATUSES.index_with(&:itself)

  def destroyable?
    !published? && stay_room_type_rates.empty?
  end
end
