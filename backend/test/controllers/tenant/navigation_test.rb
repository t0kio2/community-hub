require "test_helper"

class Tenant::NavigationTest < ActionDispatch::IntegrationTest
  setup do
    tenant = Tenant.create!(name: "ナビゲーション確認テナント", kana: "ナビゲーションカクニンテナント", status: "active")
    account = TenantAccount.create!(
      email: "tenant-navigation@example.com",
      password: "password",
      password_confirmation: "password"
    )
    TenantMember.create!(tenant: tenant, account: account, role: "owner", status: "active")
    sign_in account
  end

  test "求人一覧では求人管理だけをアクティブ表示する" do
    get tenant_jobs_path

    assert_response :success
    assert_select ".tenant-menu-section.has-active", count: 1
    assert_select ".tenant-menu-section.has-active .tenant-menu-heading strong", text: "求人管理"
    assert_select ".tenant-menu-items a.active[href=?]", tenant_jobs_path, text: "求人一覧"
    assert_select ".tenant-menu-items a[href=?]:not(.active)", tenant_stays_path, text: "宿泊一覧"
  end

  test "宿泊一覧では宿泊管理だけをアクティブ表示する" do
    get tenant_stays_path

    assert_response :success
    assert_select ".tenant-menu-section.has-active", count: 1
    assert_select ".tenant-menu-section.has-active .tenant-menu-heading strong", text: "宿泊管理"
    assert_select ".tenant-menu-items a.active[href=?]", tenant_stays_path, text: "宿泊一覧"
    assert_select ".tenant-menu-items a[href=?]:not(.active)", tenant_jobs_path, text: "求人一覧"
  end
end
