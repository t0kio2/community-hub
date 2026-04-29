class JobListing < ApplicationRecord
  EMPLOYMENT_TYPES = %w[full_time part_time contract temporary other].freeze
  SALARY_TYPES = %w[hourly daily monthly yearly other].freeze

  belongs_to :listing

  validates :listing_id, uniqueness: true
  validates :employment_type, inclusion: { in: EMPLOYMENT_TYPES }, allow_blank: true
  validates :salary_type, inclusion: { in: SALARY_TYPES }, allow_blank: true
  validates :salary_min, :salary_max, :application_limit,
            numericality: { only_integer: true, greater_than_or_equal_to: 0 },
            allow_nil: true
  validate :listing_type_is_job
  validate :salary_range_is_valid

  private

  def listing_type_is_job
    return if listing.blank? || listing.listing_type == "job"

    errors.add(:listing, "は求人である必要があります")
  end

  def salary_range_is_valid
    return if salary_min.blank? || salary_max.blank? || salary_min <= salary_max

    errors.add(:salary_max, "は最低給与以上にしてください")
  end
end
