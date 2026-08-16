stay_roomがstay_listingに紐づいてない
$ docker exec a2a279d0b43d rails g migration AddStayListingIdToStayRoom

stay_listingsにaddress, amenitiesは不要

実装にstay_typeはstay_listingsにあり、個室・相部屋・一棟借り、など。
ERにはなく、room_kindが正しい？

capacityがstay_room_typesにあるが、stay_roomsにあるべきでは？
room_kindがstay_listingsにあるが、stay_room_typesにあるべきでは？


業務フロー 抽象
1. 施設名登録 => listing情報
2. 部屋の登録 => stay_rooms情報。stay_listingsに紐づき、stay_room_typeとは独立。
3. プラン、料金設定 => stay_room_type_ratesに料金をもたせ、条件を持つstay_rate_plans(食事、キャンセルポリシー)との組み合わせでプランを作る

具体
1. 山の上ホテルを登録。住所/説明/画像/タイムゾーン/チェックイン開始・チェックイン終了・チェックアウト/予約可能期間/予約確定方式(自動・承認)
2. 部屋を登録。101, 102, 201, 202を登録。　201, 202は相部屋で、ベットを01, 02, 03, 04の４台。また、別棟で一棟貸
3. プラン、料金を割り当てる。
    - 女性専用ドミトリー 朝食夕食付き 一泊6,000円
    - 女性専用ドミトリー 素泊まり 一泊3,000円
    - シングル(大人1名) 朝食夕食付き 一泊9,000円
    - シングル(大人1名) 素泊まり 一泊7,000円
    - ダブル(大人2名) 朝食夕食付き 一泊12,000円
    - ダブル(大人2名) 素泊まり 一泊9,000円
    - 一棟まるまるプラン  一泊60,000円

       Room Type             room_kind         capacity    Rate Plan                 料金単位
  ━━━━━━━━━━━━━━━━━━━━  ━━━━━━━━━━━━━━  ━━━━━━━━━━━━  ━━━━━━━━━━━━━━  ━━━━━━━━━━━━━━━━━━━━
   女性専用ドミトリー    shared_room              1    朝食夕食付き      6,000円／Bed・泊
  ────────────────────  ──────────────  ────────────  ──────────────  ────────────────────
   女性専用ドミトリー    shared_room              1    素泊まり          3,000円／Bed・泊
  ────────────────────  ──────────────  ────────────  ──────────────  ────────────────────
   シングル              private_room             1    朝食夕食付き     9,000円／Room・泊
  ────────────────────  ──────────────  ────────────  ──────────────  ────────────────────
   シングル              private_room             1    素泊まり         7,000円／Room・泊
  ────────────────────  ──────────────  ────────────  ──────────────  ────────────────────
   ダブル                private_room             2    朝食夕食付き    12,000円／Room・泊
  ────────────────────  ──────────────  ────────────  ──────────────  ────────────────────
   ダブル                private_room             2    素泊まり         9,000円／Room・泊
  ────────────────────  ──────────────  ────────────  ──────────────  ────────────────────
   一棟まるまる          entire_place    一棟の定員    素泊まり等      60,000円／Room・泊

room_types
	- name *スタンダードシングル など利用者が選ぶ名前
	- description
	- room_kind
	- capacity

stay_rate_plans
	- name *素泊まり、朝食・夕食付き、など販売条件名
	- description
	- meal_type
	- キャンセルポリシー

room_type_rates
	- FK: room_type_id
	- FK: rate_plan_id
	- price_per_night_amount
	- currency



    

**********

StayListingを作る。

listigテーブル
id
tenant_id : not null
created_by_tenant_member_id : 
updated_by_tenant_member_id
listing_type :not null => enum
title
description
status : => enum
published_at
last_published_at ＊欠如
closed_at
closed_reason *欠如
archived_at *欠如


# 仕様書との差分
listingテーブルは以下実装にない。
last_published_at ＊欠如
closed_reason *欠如
archived_at *欠如
