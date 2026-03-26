class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
          :recoverable, :rememberable, :validatable,
          :jwt_authenticatable, jwt_revocation_strategy: JwtDenylist
  validates :email, presence: true, uniqueness: true
  validates :role, inclusion: { in: %w[user tenant admin] }
  validates :status, inclusion: { in: %w[active suspended] }

  has_many :user_refresh_tokens, dependent: :delete_all
end
