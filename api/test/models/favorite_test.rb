require "test_helper"

class FavoriteTest < ActiveSupport::TestCase
  test "有効なお気に入りを保存できる" do
    favorite = Favorite.new(user: users(:two), listing: listings(:stay))

    assert favorite.valid?
  end

  test "同じユーザが同じ掲載を重複してお気に入りできない" do
    favorite = Favorite.new(user: users(:one), listing: listings(:job))

    assert_not favorite.valid?
    assert favorite.errors.of_kind?(:user_id, :taken)
  end
end
