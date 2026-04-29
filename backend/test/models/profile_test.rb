require "test_helper"

class ProfileTest < ActiveSupport::TestCase
  test "ユーザーに紐づくプロフィールは有効" do
    profile = Profile.new(
      user: users(:one),
      name: "山田 太郎",
      kana: "ヤマダ タロウ",
      birth_date: Date.new(1990, 1, 1),
      phone: "090-0000-0000",
      avatar_url: "https://example.com/avatar.png"
    )

    assert profile.valid?
  end

  test "ユーザーがないプロフィールは無効" do
    profile = Profile.new(name: "山田 太郎")

    assert_not profile.valid?
    assert_includes profile.errors[:user], "must exist"
  end

  test "名前がないプロフィールは無効" do
    profile = Profile.new(user: users(:one), name: nil)

    assert_not profile.valid?
    assert_includes profile.errors[:name], "can't be blank"
  end
end
