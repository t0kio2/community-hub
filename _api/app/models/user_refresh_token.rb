class UserRefreshToken < ApplicationRecord
  belongs_to :user
  belongs_to :replaced_by_token, class_name: "UserRefreshToken", optional: true

  validates :token_digest, presence: true, uniqueness: true
  validates :expired_at, presence: true

  scope :active, -> { where(revoked_at: nil).where("expired_at > ?", Time.current) }

  # 発行（既存デバイスがあれば置き換え）
  # 戻り値: [refresh_record, refresh_raw]
  # - refresh_record: DBに保存されるレコード。token_digest には refresh_raw のSHA-256が入る。
  #                    生のトークン値はDBに保存しない（復元不可能）。
  # - refresh_raw    : クライアントへ一度だけ返す生のリフレッシュトークン文字列。
  def self.issue!(user:, device_id: nil, device_name: nil, ttl: 90.days)
    refresh_raw = SecureRandom.hex(32)
    digest = digest_for(refresh_raw)

    ActiveRecord::Base.transaction do
      # 同一デバイスは常に1つに保つ
      if device_id.present?
        prev = find_by(user_id: user.id, device_id: device_id)
        if prev
          prev.update!(revoked_at: Time.current)
        end
      end

      refresh_record = create!(
        user: user,
        token_digest: digest,
        device_id: device_id,
        device_name: device_name,
        expired_at: ttl.from_now
      )
      [refresh_record, refresh_raw]
    end
  end

  def self.verify_and_rotate!(raw_token:, device_id: nil, ttl: 90.days)
    current_record = find_by(token_digest: digest_for(raw_token))
    raise ActiveRecord::RecordNotFound, "refresh token not found" unless current_record

    raise StandardError, "refresh token expired" if current_record.expired_at <= Time.current
    raise StandardError, "refresh token revoked" if current_record.revoked_at.present?

    # ローテーション: 旧トークン失効 + 新規発行（同デバイスに縛る）
    # refresh_raw: クライアントに返す生のトークン文字列。サーバ側では保持しない。
    refresh_raw = nil
    ActiveRecord::Base.transaction do
      current_record.update!(revoked_at: Time.current, last_used_at: Time.current)
      new_record, refresh_raw = issue!(
        user: current_record.user,
        device_id: current_record.device_id || device_id,
        device_name: current_record.device_name,
        ttl: ttl
      )
      current_record.update!(replaced_by_token_id: new_record.id)
    end

    [current_record.user, refresh_raw]
  end

  def active?
    revoked_at.nil? && expired_at > Time.current
  end

  def self.digest_for(raw)
    OpenSSL::Digest::SHA256.hexdigest(raw)
  end
end
