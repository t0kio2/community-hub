require "test_helper"

class Tenant::StayManagement::RatePlansControllerTest < ActionDispatch::IntegrationTest
  setup do
    @tenant = Tenant.create!(name: "料金プランテナント", kana: "リョウキンプランテナント", status: "active")
    @account = TenantAccount.create!(
      email: "rate-plans@example.com",
      password: "password",
      password_confirmation: "password"
    )
    TenantMember.create!(tenant: @tenant, account: @account, role: "owner", status: "active")
    @listing = @tenant.listings.create!(title: "料金プランホテル", listing_type: "stay", status: "draft")
    @stay_listing = StayListing.create!(listing: @listing)
    sign_in @account
  end

  test "料金プランがない場合は空状態を表示する" do
    get tenant_stay_rate_plans_path(@listing)

    assert_response :success
    assert_select "h1#tenant-page-title", text: "料金プラン"
    assert_includes response.body, "料金プランがまだ登録されていません"
    assert_select "a[href=?]", new_tenant_stay_rate_plan_path(@listing), text: "料金プランを登録"
  end

  test "施設の料金プランとRoom Type別基本料金を一覧表示する" do
    room_type = @stay_listing.stay_room_types.create!(
      name: "スタンダードツイン",
      room_kind: "private_room",
      capacity: 2
    )
    rate_plan = @stay_listing.stay_rate_plans.create!(
      name: "朝食付きプラン",
      description: "朝食を含む宿泊プランです",
      meal_type: "breakfast",
      cancellation_policy_type: "standard",
      status: "published"
    )
    StayRoomTypeRate.create!(
      stay_room_type: room_type,
      stay_rate_plan: rate_plan,
      price_per_night_amount: 15_000,
      currency: "JPY",
      active: true
    )

    get tenant_stay_rate_plans_path(@listing)

    assert_response :success
    assert_select "td", text: /朝食付きプラン/
    assert_select "td", text: I18n.t("activerecord.enums.stay_rate_plan.meal_type.breakfast")
    assert_select "td", text: I18n.t("activerecord.enums.stay_rate_plan.cancellation_policy_type.standard")
    assert_includes response.body, "スタンダードツイン"
    assert_includes response.body, "¥15,000"
    assert_select "a[href=?]", edit_tenant_stay_rate_plan_path(@listing, rate_plan), text: "編集"
  end

  test "別施設の料金プランを一覧へ表示しない" do
    other_listing = @tenant.listings.create!(title: "別ホテル", listing_type: "stay", status: "draft")
    other_stay_listing = StayListing.create!(listing: other_listing)
    other_stay_listing.stay_rate_plans.create!(name: "別施設限定プラン")

    get tenant_stay_rate_plans_path(@listing)

    assert_response :success
    assert_not_includes response.body, "別施設限定プラン"
  end

  test "料金プラン登録画面に基本情報とRoom Type別料金を表示する" do
    @stay_listing.stay_room_types.create!(name: "和室", room_kind: "private_room", capacity: 4)

    get new_tenant_stay_rate_plan_path(@listing)

    assert_response :success
    assert_select "h1#tenant-page-title", text: "料金プラン登録"
    assert_select "form[action=?]", tenant_stay_rate_plans_path(@listing)
    assert_select "input[name='stay_rate_plan[name]'][required]"
    assert_select "select[name='stay_rate_plan[meal_type]'][required]"
    assert_select "input[type='checkbox'][name$='[active]']"
    assert_select "input[type='number'][name$='[price_per_night_amount]']"
    assert_includes response.body, "和室"
    assert_select "[data-controller='cancellation-policy']"
    assert_includes response.body, "7日前（168時間前）以降"
    assert_includes response.body, "予約確定後に宿泊者がキャンセルした場合"
  end

  test "料金プランと選択したRoom Type別基本料金を登録する" do
    room_type = @stay_listing.stay_room_types.create!(name: "和室", room_kind: "private_room", capacity: 4)

    assert_difference "@stay_listing.stay_rate_plans.count", 1 do
      assert_difference "StayRoomTypeRate.count", 1 do
        post tenant_stay_rate_plans_path(@listing), params: {
          stay_rate_plan: {
            name: "夕食付きプラン",
            description: "季節の夕食付き",
            meal_type: "dinner",
            cancellation_policy_type: "standard",
            status: "draft",
            stay_room_type_rates_attributes: {
              "0" => {
                stay_room_type_id: room_type.id,
                active: "1",
                price_per_night_amount: "18000"
              }
            }
          }
        }
      end
    end

    rate_plan = @stay_listing.stay_rate_plans.order(:id).last
    assert_redirected_to tenant_stay_rate_plan_path(@listing, rate_plan)
    assert_equal "dinner", rate_plan.meal_type
    assert_equal 18_000, rate_plan.stay_room_type_rates.first.price_per_night_amount
  end

  test "未選択のRoom Type別料金は登録しない" do
    room_type = @stay_listing.stay_room_types.create!(name: "和室", room_kind: "private_room", capacity: 4)

    assert_no_difference "StayRoomTypeRate.count" do
      post tenant_stay_rate_plans_path(@listing), params: {
        stay_rate_plan: {
          name: "素泊まり",
          meal_type: "room_only",
          cancellation_policy_type: "standard",
          status: "draft",
          stay_room_type_rates_attributes: {
            "0" => {
              stay_room_type_id: room_type.id,
              active: "0",
              price_per_night_amount: ""
            }
          }
        }
      }
    end

    assert_response :redirect
  end

  test "販売中の基本料金が不正な場合は登録内容を保存しない" do
    room_type = @stay_listing.stay_room_types.create!(name: "和室", room_kind: "private_room", capacity: 4)

    assert_no_difference "StayRatePlan.count" do
      assert_no_difference "StayRoomTypeRate.count" do
        post tenant_stay_rate_plans_path(@listing), params: {
          stay_rate_plan: {
            name: "不正なプラン",
            meal_type: "room_only",
            cancellation_policy_type: "standard",
            status: "draft",
            stay_room_type_rates_attributes: {
              "0" => {
                stay_room_type_id: room_type.id,
                active: "1",
                price_per_night_amount: "0"
              }
            }
          }
        }
      end
    end

    assert_response :unprocessable_entity
    assert_select "[role='alert']"
    assert_includes response.body, "Room Type別基本料金 は0より大きい値にしてください"
    assert_not_includes response.body, "Translation missing"
    assert_select "input[type='number'][value='0']"
  end

  test "基本料金が空の場合は日本語の入力エラーを表示する" do
    room_type = @stay_listing.stay_room_types.create!(name: "和室", room_kind: "private_room", capacity: 4)

    post tenant_stay_rate_plans_path(@listing), params: {
      stay_rate_plan: {
        name: "基本料金未入力プラン",
        meal_type: "room_only",
        cancellation_policy_type: "standard",
        status: "draft",
        stay_room_type_rates_attributes: {
          "0" => {
            stay_room_type_id: room_type.id,
            active: "1",
            price_per_night_amount: ""
          }
        }
      }
    }

    assert_response :unprocessable_entity
    assert_includes response.body, "Room Type別基本料金 は数値で入力してください"
    assert_not_includes response.body, "Translation missing"
  end

  test "料金プラン詳細に販売条件と基本料金を表示する" do
    room_type = @stay_listing.stay_room_types.create!(name: "ドミトリー", room_kind: "shared_room", capacity: 1)
    rate_plan = @stay_listing.stay_rate_plans.create!(
      name: "返金不可プラン",
      meal_type: "room_only",
      cancellation_policy_type: "non_refundable",
      status: "published"
    )
    StayRoomTypeRate.create!(
      stay_room_type: room_type,
      stay_rate_plan: rate_plan,
      price_per_night_amount: 4_000
    )

    get tenant_stay_rate_plan_path(@listing, rate_plan)

    assert_response :success
    assert_select "h1#tenant-page-title", text: "返金不可プラン"
    assert_includes response.body, "返金不可"
    assert_includes response.body, "時期にかかわらず宿泊料金の100%"
    assert_includes response.body, "1 Bed・1泊"
    assert_includes response.body, "¥4,000"
    assert_select "a[href=?]", edit_tenant_stay_rate_plan_path(@listing, rate_plan), text: "編集"
  end

  test "料金プラン編集画面に保存済みの値を表示する" do
    room_type = @stay_listing.stay_room_types.create!(name: "ツイン", room_kind: "private_room", capacity: 2)
    rate_plan = @stay_listing.stay_rate_plans.create!(name: "朝食付き", meal_type: "breakfast")
    StayRoomTypeRate.create!(
      stay_room_type: room_type,
      stay_rate_plan: rate_plan,
      price_per_night_amount: 12_000
    )

    get edit_tenant_stay_rate_plan_path(@listing, rate_plan)

    assert_response :success
    assert_select "h1#tenant-page-title", text: "料金プラン編集"
    assert_select "form[action=?]", tenant_stay_rate_plan_path(@listing, rate_plan)
    assert_select "input[name='stay_rate_plan[name]'][value='朝食付き']"
    assert_select "input[type='number'][value='12000']"
  end

  test "料金プランと基本料金を更新する" do
    room_type = @stay_listing.stay_room_types.create!(name: "ツイン", room_kind: "private_room", capacity: 2)
    rate_plan = @stay_listing.stay_rate_plans.create!(name: "朝食付き", meal_type: "breakfast")
    room_type_rate = StayRoomTypeRate.create!(
      stay_room_type: room_type,
      stay_rate_plan: rate_plan,
      price_per_night_amount: 12_000
    )

    patch tenant_stay_rate_plan_path(@listing, rate_plan), params: {
      stay_rate_plan: {
        name: "朝夕食付き",
        meal_type: "breakfast_and_dinner",
        cancellation_policy_type: "standard",
        status: "published",
        stay_room_type_rates_attributes: {
          "0" => {
            id: room_type_rate.id,
            stay_room_type_id: room_type.id,
            active: "1",
            price_per_night_amount: "20000"
          }
        }
      }
    }

    assert_redirected_to tenant_stay_rate_plan_path(@listing, rate_plan)
    assert_equal "朝夕食付き", rate_plan.reload.name
    assert_equal "breakfast_and_dinner", rate_plan.meal_type
    assert_equal 20_000, room_type_rate.reload.price_per_night_amount
  end

  test "基本料金を停止しても保存済み価格を保持する" do
    room_type = @stay_listing.stay_room_types.create!(name: "ツイン", room_kind: "private_room", capacity: 2)
    rate_plan = @stay_listing.stay_rate_plans.create!(name: "素泊まり")
    room_type_rate = StayRoomTypeRate.create!(
      stay_room_type: room_type,
      stay_rate_plan: rate_plan,
      price_per_night_amount: 10_000
    )

    patch tenant_stay_rate_plan_path(@listing, rate_plan), params: {
      stay_rate_plan: {
        name: "素泊まり",
        meal_type: "room_only",
        cancellation_policy_type: "standard",
        status: "draft",
        stay_room_type_rates_attributes: {
          "0" => {
            id: room_type_rate.id,
            stay_room_type_id: room_type.id,
            active: "0",
            price_per_night_amount: "10000"
          }
        }
      }
    }

    assert_redirected_to tenant_stay_rate_plan_path(@listing, rate_plan)
    assert_not room_type_rate.reload.active?
    assert_equal 10_000, room_type_rate.price_per_night_amount
  end

  test "下書きかつ基本料金がない料金プランを削除する" do
    rate_plan = @stay_listing.stay_rate_plans.create!(name: "削除対象", status: "draft")

    assert_difference "@stay_listing.stay_rate_plans.count", -1 do
      delete tenant_stay_rate_plan_path(@listing, rate_plan)
    end

    assert_redirected_to tenant_stay_rate_plans_path(@listing)
  end

  test "公開中または基本料金がある料金プランは削除しない" do
    room_type = @stay_listing.stay_room_types.create!(name: "ツイン", room_kind: "private_room", capacity: 2)
    published_plan = @stay_listing.stay_rate_plans.create!(name: "公開中", status: "published")
    priced_plan = @stay_listing.stay_rate_plans.create!(name: "料金設定済み", status: "draft")
    StayRoomTypeRate.create!(
      stay_room_type: room_type,
      stay_rate_plan: priced_plan,
      price_per_night_amount: 10_000
    )

    assert_no_difference "StayRatePlan.count" do
      delete tenant_stay_rate_plan_path(@listing, published_plan)
    end
    assert_redirected_to tenant_stay_rate_plan_path(@listing, published_plan)

    sign_in @account
    assert_no_difference "StayRatePlan.count" do
      delete tenant_stay_rate_plan_path(@listing, priced_plan)
    end
    assert_redirected_to tenant_stay_rate_plan_path(@listing, priced_plan)
  end

  test "別施設の料金プランは表示・更新・削除できない" do
    other_listing = @tenant.listings.create!(title: "別ホテル", listing_type: "stay", status: "draft")
    other_stay_listing = StayListing.create!(listing: other_listing)
    other_rate_plan = other_stay_listing.stay_rate_plans.create!(name: "別施設限定プラン")

    get tenant_stay_rate_plan_path(@listing, other_rate_plan)
    assert_response :not_found

    sign_in @account
    patch tenant_stay_rate_plan_path(@listing, other_rate_plan), params: {
      stay_rate_plan: { name: "不正な更新" }
    }
    assert_response :not_found

    sign_in @account
    assert_no_difference "StayRatePlan.count" do
      delete tenant_stay_rate_plan_path(@listing, other_rate_plan)
    end
    assert_response :not_found
  end
end
