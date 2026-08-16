require "test_helper"

class Admin::HomeControllerTest < ActionDispatch::IntegrationTest
  test "管理画面にログイン中のメールアドレスとロールを表示する" do
    account = AdminAccount.create!(
      email: "admin-home@example.com",
      password: "password",
      password_confirmation: "password"
    )
    Admin.create!(
      account: account,
      role: "super_admin",
      status: "active"
    )
    sign_in account

    get admin_root_path

    assert_response :success
    assert_select ".admin-topbar .admin-breadcrumb", text: "ADMIN / COMMUNITY HUB"
    assert_select ".admin-topbar .admin-back-link", count: 0
    assert_includes response.body, "運営管理画面"
    assert_includes response.body, "ログイン中:"
    assert_includes response.body, account.email
    assert_includes response.body, "ロール:"
    assert_includes response.body, "super_admin"
  end
end
