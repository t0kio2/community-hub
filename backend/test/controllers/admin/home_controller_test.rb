require "test_helper"

class Admin::HomeControllerTest < ActionDispatch::IntegrationTest
  setup do
    @account = AdminAccount.create!(
      email: "admin-home@example.com",
      password: "password",
      password_confirmation: "password"
    )
    Admin.create!(
      account: @account,
      role: "super_admin",
      status: "active"
    )
    sign_in @account
  end

  test "ホームにログイン中の管理者情報を表示する" do
    get admin_root_path

    assert_response :success
    assert_select "main dd", text: @account.email
    assert_select "main dd", text: "super_admin"
  end

  test "未ログインの場合はホームからログイン画面へ移動する" do
    sign_out @account

    get admin_root_path

    assert_redirected_to new_admin_account_session_path
  end

  test "無効な管理者はホームを閲覧できない" do
    @account.admin.update!(status: "inactive")

    get admin_root_path

    assert_response :forbidden
  end

  test "テナント管理にログイン中のメールアドレスとロールを表示する" do
    get admin_tenants_path

    assert_response :success
    assert_select ".admin-topbar .admin-breadcrumb", text: "ADMIN / COMMUNITY HUB"
    assert_select ".admin-topbar .admin-back-link", count: 0
    assert_includes response.body, "運営管理画面"
    assert_includes response.body, "ログイン中:"
    assert_includes response.body, @account.email
    assert_includes response.body, "ロール:"
    assert_includes response.body, "super_admin"
  end
end
