require "test_helper"

class AdminAccounts::CreateServiceTest < ActiveSupport::TestCase
  test "AdminAccountとAdminを同じトランザクションで作成する" do
    result = nil

    assert_difference -> { AdminAccount.count }, 1 do
      assert_difference -> { Admin.count }, 1 do
        result = AdminAccounts::CreateService.new(
          account_attributes: {
            email: "created-admin@example.com",
            password: "password",
            password_confirmation: "password"
          },
          role: "operator"
        ).call
      end
    end

    assert_predicate result.account, :persisted?
    assert_predicate result.admin, :persisted?
    assert_equal result.account, result.admin.account
    assert_equal "operator", result.admin.role
    assert_equal "active", result.admin.status
  end

  test "Adminの保存に失敗した場合はAdminAccountもロールバックする" do
    service = AdminAccounts::CreateService.new(
      account_attributes: {
        email: "rollback-admin@example.com",
        password: "password",
        password_confirmation: "password"
      },
      role: "unknown"
    )

    assert_no_difference -> { AdminAccount.count } do
      assert_no_difference -> { Admin.count } do
        assert_raises(ActiveRecord::RecordInvalid) { service.call }
      end
    end

    assert_not_predicate service.account, :persisted?
    assert_not_predicate service.admin, :persisted?
  end
end
