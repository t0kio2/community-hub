require "test_helper"

class UserProfileTest < ActiveSupport::TestCase
  test "ユーザーに紐づくプロフィールは有効" do
    user_profile = UserProfile.new(
      user: users(:one),
      name: "山田 太郎",
      kana: "ヤマダ タロウ",
      birth_date: Date.new(1990, 1, 1),
      phone: "090-0000-0000",
      avatar_url: "https://example.com/avatar.png"
    )

    assert user_profile.valid?
  end

  test "ユーザーがないプロフィールは無効" do
    user_profile = UserProfile.new(name: "山田 太郎")

    assert_not user_profile.valid?
    assert_includes user_profile.errors[:user], "must exist"
  end

  test "名前がないプロフィールは無効" do
    user_profile = UserProfile.new(user: users(:one), name: nil)

    assert_not user_profile.valid?
    assert_includes user_profile.errors[:name], "can't be blank"
  end
end
