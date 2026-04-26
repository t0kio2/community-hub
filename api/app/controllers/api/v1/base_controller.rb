class Api::V1::BaseController < ActionController::API
  # JWT認証（user_account スコープ）
  before_action :authenticate_user_account!

  # 呼び出し側で current_account を使いたい場合の簡易エイリアス
  def current_account
    current_user_account
  end
end
