class User < ApplicationRecord
  belongs_to :account

  has_one :profile, dependent: :destroy
  has_many :favorites, dependent: :destroy
  has_many :favorite_listings, through: :favorites, source: :listing
end
