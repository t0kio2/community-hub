module Auth
  class TokenService
    class << self
      # アクセストークン発行
      def issue_access_for(account, scope: :user_account, aud: nil)
        encoder = Warden::JWTAuth::UserEncoder.new
        token, _payload = encoder.call(account, scope, aud)

        [token, Warden::JWTAuth.config.expiration_time]
      end

      # リフレッシュトークン発行
      def issue_refresh_for(account, device_id: nil, device_name: nil, ttl: 90.days)
        _rec, raw = UserRefreshToken.issue!(
          account: account,
          device_id: device_id,
          device_name: device_name,
          ttl: ttl
        )
        raw
      end

      # アクセストークンをリフレッシュ
      def refresh_with(raw_token, ttl: 90.days)
        account, refresh_raw = UserRefreshToken.verify_and_rotate!(
          raw_token: raw_token,
          ttl: ttl
        )

        # 新しいアクセストークン発行
        access_token, expires_in = issue_access_for(account)
        [account, access_token, expires_in, refresh_raw]
      end
    end
  end
end
