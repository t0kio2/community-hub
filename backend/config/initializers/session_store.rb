# 管理画面(MVC)でDBセッションを使う
Rails.application.config.session_store :active_record_store,
  key: '_community_hub_session',
  secure: Rails.env.production?,
  httponly: true,
  same_site: :lax

