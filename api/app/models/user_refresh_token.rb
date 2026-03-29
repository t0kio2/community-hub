class UserRefreshToken < ApplicationRecord
  belongs_to :account

  validates :token_digest, presence: true, uniqueness: true
  validates :expired_at, presence: true

  # 有効なトークンのみを取得するスコープ
  scope :active, -> { where(revoked_at: nil).where('expired_at > ?', Time.current) }

  def self.issue!(account:, device_id: nil, device_name: nil, ttl: 90.days)
    refresh_raw = SecureRandom.hex(32)
    # ランダム値をハッシュ化(SHA-256)
    digest = digest_for(refresh_raw)

    ActiveRecord::Base.transaction do
      # 同一デバイスの古いトークンを全て無効化
      if device_id.present?
        where(account_id: account.id, device_id: device_id)
          .where(revoked_at: nil)
          .update_all(revoked_at: Time.current)
      end

      refresh_record = create!(
        account: account,
        token_digest: digest,
        device_id: device_id,
        device_name: device_name,
        expired_at: ttl.from_now # 今から90日後の日時を生成
      )
      [refresh_record, refresh_raw]
    end
  end

  # 検証とローテーション
  def self.verify_and_rotate!(raw_token:, ttl: 90.days)
    # 1.ダイジェストで検索
    current_record = find_by(token_digest: digest_for(raw_token))
    raise ActiveRecord::RecordNotFound, "refresh token not found" unless current_record

    # 2.状態チェック
    raise StandardError, "refresh token expired" if current_record.expired_at <= Time.current
    raise StandardError, "refresh token revoked" if current_record.revoked_at.present?

    # 3. ローテーション
    refresh_raw = nil
    ActiveRecord::Base.transaction do
      # 旧トークン無効化
      current_record.update!(revoked_at: Time.current, last_used_at: Time.current)

      # 新規発行
      _, refresh_raw = issue!(
        account: current_record.account,
        device_id: current_record.device_id,
        device_name: current_record.device_name,
        ttl: ttl
      )
    end

    [current_record.account, refresh_raw]

  end

  def active?
    revoked_at.nil? && expired_at > Time.current
  end

  def self.digest_for(raw)
    OpenSSL::Digest::SHA256.hexdigest(raw)
  end

end
