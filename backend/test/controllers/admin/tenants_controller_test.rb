require "test_helper"

class Admin::TenantsControllerTest < ActionDispatch::IntegrationTest
  setup do
    admin_account = AdminAccount.create!(
      email: "admin-tenants-controller@example.com",
      password: "password",
      password_confirmation: "password"
    )
    Admin.create!(account: admin_account, role: "super_admin", status: "active")
    sign_in admin_account
  end

  test "テナント詳細に組織、メンバー、掲載の情報を表示する" do
    tenant = tenants(:one)
    member = tenant_members(:one)
    listing = listings(:job)

    get admin_tenant_path(tenant)

    assert_response :success
    assert_select 'link[rel="stylesheet"][href*="admin"]', minimum: 2
    assert_select 'link[rel="stylesheet"][href*="tenants"]', count: 1
    assert_select "h1#admin-page-title", text: "テナント詳細"
    assert_select ".admin-topbar .admin-back-link[href=?]", admin_tenants_path, text: "← テナント一覧へ戻る"
    assert_select ".admin-content .admin-back-link", count: 0
    assert_select ".tenant-detail__identity h2", text: tenant.name
    assert_includes response.body, member.account.email
    assert_includes response.body, listing.title
    assert_includes response.body, "求人"
    assert_includes response.body, "公開中"
  end

  test "メンバーと掲載がないテナント詳細に空状態を表示する" do
    tenant = Tenant.create!(
      name: "空状態確認テナント",
      kana: "カラジョウタイカクニンテナント",
      status: "active"
    )

    get admin_tenant_path(tenant)

    assert_response :success
    assert_includes response.body, "メンバーが登録されていません"
    assert_includes response.body, "掲載がありません"
  end
end
