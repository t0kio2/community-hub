require "test_helper"

class Tenant::HomeControllerTest < ActionDispatch::IntegrationTest
  setup do
    @tenant = Tenant.create!(
      name: "Sample Lodge",
      kana: "サンプルロッジ",
      address: "Tokyo",
      status: "active"
    )
    @tenant_account = TenantAccount.create!(
      email: "tenant-home-owner@example.com",
      password: "password",
      password_confirmation: "password"
    )
    TenantMember.create!(
      tenant: @tenant,
      account: @tenant_account,
      role: "owner",
      status: "active"
    )
    sign_in @tenant_account
  end

  test "tenantホーム画面に組織情報と編集リンクを表示する" do
    get tenant_root_path

    assert_response :success
    assert_includes response.body, "テナント管理画面"
    assert_includes response.body, @tenant.name
    assert_includes response.body, @tenant_account.email
    assert_includes response.body, "ロール:"
    assert_includes response.body, "owner"
    assert_includes response.body, "組織情報を編集"
    assert_not_includes response.body, "次に実装する項目"
    assert_not_includes response.body, "運用メニュー"
  end

  test "staffのtenantホーム画面に組織情報編集リンクを表示しない" do
    @tenant_account.tenant_member.update!(role: "staff")

    get tenant_root_path

    assert_response :success
    assert_includes response.body, "staff"
    assert_not_includes response.body, "組織情報を編集"
  end

  test "無効なtenant memberはtenantホーム画面を表示できない" do
    @tenant_account.tenant_member.update!(status: "inactive")

    get tenant_root_path

    assert_response :forbidden
    assert_includes response.body, "このアカウントは利用できません"
  end
end
