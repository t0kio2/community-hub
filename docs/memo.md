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
listingテーブルは如何実装にない。
last_published_at ＊欠如
closed_reason *欠如
archived_at *欠如
