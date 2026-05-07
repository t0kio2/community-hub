require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "プロフィールを参照できる" do
    assert_equal user_profiles(:one), users(:one).user_profile
  end
end
