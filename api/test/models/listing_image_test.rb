require "test_helper"

class ListingImageTest < ActiveSupport::TestCase
  test "有効な掲載画像を保存できる" do
    image = ListingImage.new(
      listing: listings(:job),
      image_url: "https://example.com/job-2.jpg",
      position: 2
    )

    assert image.valid?
  end

  test "画像URLは必須" do
    image = listing_images(:one)
    image.image_url = nil

    assert_not image.valid?
    assert image.errors.of_kind?(:image_url, :blank)
  end

  test "表示順は1以上にする" do
    image = listing_images(:one)
    image.position = 0

    assert_not image.valid?
    assert image.errors.of_kind?(:position, :greater_than)
  end

  test "同じ掲載内で表示順を重複できない" do
    image = ListingImage.new(
      listing: listings(:job),
      image_url: "https://example.com/duplicate.jpg",
      position: 1
    )

    assert_not image.valid?
    assert image.errors.of_kind?(:position, :taken)
  end
end
