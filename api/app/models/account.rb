class Account < ApplicationRecord
  # 共通の関連と検証のみを持つ（Deviseは各派生モデルに定義）
  has_many :user_refresh_tokens, dependent: :destroy

  has_one :profile, dependent: :destroy
  has_one :user, dependent: :destroy
  has_one :tenant_user, dependent: :destroy
  has_one :admin, dependent: :destroy

  validates :account_type, presence: true, inclusion: { in: %w[user tenant admin] }
  validates :email, presence: true, uniqueness: true
end
