module Auth
  class TokenService
    class << self
      # アクセスJWTの発行（devise-jwtと同一経路）
      # 戻り値: [access_token, expires_in]
      def issue_access_for(user, scope: :user, aud: nil)
        encoder = Warden::JWTAuth::UserEncoder.new
        token, _payload = encoder.call(user, scope, aud)
        [token, Warden::JWTAuth.config.expiration_time]
      end

      # リフレッシュトークンの発行（DBはハッシュ保存）
      # 戻り値: refresh_raw
      def issue_refresh_for(user, device_id: nil, device_name: nil, ttl: 90.days)
        _rec, raw = UserRefreshToken.issue!(
          user: user,
          device_id: device_id,
          device_name: device_name,
          ttl: ttl
        )
        raw
      end

      # リフレッシュでローテーションしつつ新しいアクセスJWTも返す
      # 戻り値: [user, access_token, expires_in, refresh_raw]
      def refresh_with(raw_token, ttl: 90.days)
        user, refresh_raw = UserRefreshToken.verify_and_rotate!(raw_token: raw_token, ttl: ttl)
        access_token, expires_in = issue_access_for(user)
        [user, access_token, expires_in, refresh_raw]
      end
    end
  end
end
