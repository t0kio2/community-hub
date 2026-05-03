require "test_helper"

class Admin::TenantAccountsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin_account = AdminAccount.create!(
      email: "admin-controller-test@example.com",
      password: "password",
      password_confirmation: "password"
    )
    sign_in @admin_account
  end

  test "creates tenant account organization and owner tenant member" do
    assert_difference -> { TenantAccount.count }, 1 do
      assert_difference -> { Tenant.count }, 1 do
        assert_difference -> { TenantMember.count }, 1 do
          post admin_tenant_accounts_path, params: valid_params
        end
      end
    end

    assert_redirected_to admin_tenant_accounts_path

    tenant_account = TenantAccount.find_by!(email: "owner@example.com")
    tenant_member = tenant_account.tenant_member

    assert_equal "owner", tenant_member.role
    assert_equal "active", tenant_member.status
    assert_equal "Sample Inn", tenant_member.tenant.name
    assert_equal "サンプルイン", tenant_member.tenant.kana
    assert_equal "Tokyo", tenant_member.tenant.address
    assert_equal "active", tenant_member.tenant.status
  end

  test "rolls back tenant account when organization is invalid" do
    invalid_params = valid_params.deep_merge(
      tenant_account: { email: "rollback-owner@example.com" },
      tenant: { name: "" }
    )

    assert_no_difference -> { TenantAccount.count } do
      assert_no_difference -> { Tenant.count } do
        assert_no_difference -> { TenantMember.count } do
          post admin_tenant_accounts_path, params: invalid_params
        end
      end
    end

    assert_response :unprocessable_entity
    assert_nil TenantAccount.find_by(email: "rollback-owner@example.com")
  end

  test "削除フォームのmethod overrideでテナントアカウントを削除できる" do
    tenant_account = TenantAccount.create!(
      email: "delete-owner@example.com",
      password: "password",
      password_confirmation: "password"
    )

    assert_difference -> { TenantAccount.count }, -1 do
      post admin_tenant_account_path(tenant_account), params: { _method: "delete" }
    end

    assert_redirected_to admin_tenant_accounts_path
    assert_nil TenantAccount.find_by(email: "delete-owner@example.com")
  end

  test "一覧画面にdelete method override付きの削除フォームを表示する" do
    TenantAccount.create!(
      email: "index-delete-owner@example.com",
      password: "password",
      password_confirmation: "password"
    )

    get admin_tenant_accounts_path

    assert_response :success
    assert_includes response.body, 'name="_method"'
    assert_includes response.body, 'value="delete"'
    assert_includes response.body, "削除"
  end

  test "テナント別掲載画面で対象テナントの掲載だけを表示する" do
    tenant_account = create_tenant_account_with_organization(
      email: "listing-owner@example.com",
      tenant_name: "掲載確認テナント"
    )
    other_tenant_account = create_tenant_account_with_organization(
      email: "other-listing-owner@example.com",
      tenant_name: "別テナント"
    )
    target_listing = create_listing_for(tenant_account.tenant_member.tenant, title: "対象テナントの掲載")
    other_listing = create_listing_for(other_tenant_account.tenant_member.tenant, title: "別テナントの掲載")

    get admin_tenant_account_path(tenant_account)

    assert_response :success
    assert_includes response.body, tenant_account.email
    assert_includes response.body, "掲載確認テナント"
    assert_includes response.body, target_listing.title
    assert_not_includes response.body, other_listing.title
  end

  test "テナント一覧に掲載画面へのリンクを表示する" do
    tenant_account = create_tenant_account_with_organization(
      email: "index-listing-owner@example.com",
      tenant_name: "一覧リンク確認テナント"
    )

    get admin_tenant_accounts_path

    assert_response :success
    assert_includes response.body, admin_tenant_account_path(tenant_account)
    assert_includes response.body, "掲載"
  end

  test "組織が未作成のテナントアカウントでも掲載画面を表示できる" do
    tenant_account = TenantAccount.create!(
      email: "no-organization-owner@example.com",
      password: "password",
      password_confirmation: "password"
    )

    get admin_tenant_account_path(tenant_account)

    assert_response :success
    assert_includes response.body, "組織情報がありません"
  end

  private

  def valid_params
    {
      tenant_account: {
        email: "owner@example.com",
        password: "password",
        password_confirmation: "password"
      },
      tenant: {
        name: "Sample Inn",
        kana: "サンプルイン",
        address: "Tokyo"
      }
    }
  end

  def create_tenant_account_with_organization(email:, tenant_name:)
    tenant_account = TenantAccount.create!(
      email: email,
      password: "password",
      password_confirmation: "password"
    )
    tenant = Tenant.create!(
      name: tenant_name,
      kana: "テナント",
      address: "Tokyo",
      status: "active"
    )
    TenantMember.create!(
      account: tenant_account,
      tenant: tenant,
      role: "owner",
      status: "active"
    )

    tenant_account
  end

  def create_listing_for(tenant, title:)
    tenant.listings.create!(
      listing_type: "job",
      title: title,
      description: "#{title}の説明",
      status: "published",
      published_at: Time.current
    )
  end
end
