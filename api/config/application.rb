require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module App
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.1

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # アプリのタイムゾーンをJSTへ
    config.time_zone = 'Tokyo'
    # DBへ保存する時刻もローカル時間（JST）で保存
    # 既存データはUTCで保存されている可能性があるため、必要ならセッション等をクリアしてください。
    config.active_record.default_timezone = :local
    # config.eager_load_paths << Rails.root.join("extras")

    # Only loads a smaller set of middleware suitable for API only apps.
    # Middleware like session, flash, cookies can be added back manually.
    # Skip views, helpers and assets when generating a new resource.
    config.api_only = true

    # 管理画面(MVC)のHTMLフォームで _method=delete/patch を解釈する
    config.middleware.use Rack::MethodOverride
    # 管理画面(MVC)でセッション/クッキーを使うためのミドルウェアを追加
    config.middleware.use ActionDispatch::Cookies
    # セッションはActiveRecordストア（初期化子でstore指定）
    config.middleware.use ActionDispatch::Session::ActiveRecordStore
    # Deviseのフラッシュ等
    config.middleware.use ActionDispatch::Flash
  end
end
