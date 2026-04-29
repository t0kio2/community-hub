require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "プロフィールを参照できる" do
    assert_equal profiles(:one), users(:one).profile
  end
end
