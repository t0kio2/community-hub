require "test_helper"

class AccountTest < ActiveSupport::TestCase
  test "プロフィールを直接参照しない" do
    assert_not_respond_to accounts(:one), :profile
  end
end
