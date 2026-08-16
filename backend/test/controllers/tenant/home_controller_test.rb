require "test_helper"

class Tenant::HomeControllerTest < ActionDispatch::IntegrationTest
  setup do
    @tenant = Tenant.create!(
      name: "Sample Lodge",
      kana: "サンプルロッジ",
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
    assert_select 'link[rel="stylesheet"][href*="tenant"]', count: 1
    assert_select 'link[rel="stylesheet"][href*="form_components"]', count: 1
    assert_select ".tenant-shell", count: 1
    assert_select "h1#tenant-page-title", text: "ホーム"
    assert_select ".tenant-navigation .tenant-home-link.active", count: 1
    assert_select ".tenant-account-email", text: @tenant_account.email
    assert_select ".tenant-logout-button", text: "ログアウト"
    assert_select "head style", count: 0
    assert_includes response.body, "テナント管理画面"
    assert_includes response.body, @tenant.name
    assert_includes response.body, @tenant_account.email
    assert_includes response.body, "ロール:"
    assert_includes response.body, "owner"
    assert_includes response.body, "組織情報を編集"
    assert_includes response.body, ".tenant-content .tenant-edit-link"
    assert_not_includes response.body, "#2563eb"
    assert_not_includes response.body, "次に実装する項目"
    assert_not_includes response.body, "運用メニュー"
  end

  test "staffのtenantホーム画面に組織情報編集リンクを表示しない" do
    @tenant_account.tenant_member.update!(role: "staff")

    get tenant_root_path

    assert_response :success
    assert_includes response.body, "staff"
    assert_select ".tenant-menu-section a[href=?]", edit_tenant_organization_path, count: 0
    assert_not_includes response.body, "組織情報を編集"
  end

  test "未ログインのログイン画面をtenant用認証デザインで表示する" do
    sign_out @tenant_account

    get new_tenant_account_session_path

    assert_response :success
    assert_select "body.authentication-page--tenant", count: 1
    assert_select 'link[rel="stylesheet"][href*="authentication"]', count: 1
    assert_select ".authentication-role-label", text: /テナント管理画面/
    assert_select ".authentication-card h2", text: "テナントログイン"
    assert_select "form.authentication-form[action=?]", tenant_account_session_path
    assert_select "input#tenant_email[required][autocomplete='username']", count: 1
    assert_select "input#tenant_password[required][autocomplete='current-password']", count: 1
    assert_select ".authentication-submit[value='ログイン']", count: 1
    assert_select "style", count: 0
  end

  test "無効なtenant memberはtenantホーム画面を表示できない" do
    @tenant_account.tenant_member.update!(status: "inactive")

    get tenant_root_path

    assert_response :forbidden
    assert_includes response.body, "このアカウントは利用できません"
  end
end
