"use client";

import Link from "next/link";
import { useRouter } from "next/navigation";
import { useEffect, useMemo, useState, useSyncExternalStore } from "react";
import { hasAccessToken, logout } from "@/lib/auth";

type ListingType = "all" | "job" | "stay";
type CategoryFilter = "all" | "remote" | "onsite" | "private-room" | "shared";

type Listing = {
  id: number;
  title: string;
  tenantName: string;
  listingType: Exclude<ListingType, "all">;
  category: Exclude<CategoryFilter, "all">;
  area: string;
  priceLabel: string;
  summary: string;
  publishedAt: string;
};

const sampleListings: Listing[] = [
  {
    id: 1,
    title: "地域イベント運営サポート",
    tenantName: "Community Works",
    listingType: "job",
    category: "onsite",
    area: "東京都 渋谷区",
    priceLabel: "時給 1,500円",
    summary: "受付、来場者案内、会場設営を担当する短期スタッフ募集です。",
    publishedAt: "2026-04-28",
  },
  {
    id: 2,
    title: "観光案内ページの翻訳",
    tenantName: "Local Guide Lab",
    listingType: "job",
    category: "remote",
    area: "リモート",
    priceLabel: "固定報酬 30,000円",
    summary: "日本語の観光案内文を英語へ翻訳し、公開前の確認まで行います。",
    publishedAt: "2026-04-27",
  },
  {
    id: 3,
    title: "駅近の個室ステイ",
    tenantName: "North Stay",
    listingType: "stay",
    category: "private-room",
    area: "北海道 札幌市",
    priceLabel: "1泊 6,800円",
    summary: "生活用品が揃った個室です。中長期の滞在にも対応しています。",
    publishedAt: "2026-04-26",
  },
  {
    id: 4,
    title: "交流スペース付きシェア滞在",
    tenantName: "Harbor House",
    listingType: "stay",
    category: "shared",
    area: "神奈川県 横浜市",
    priceLabel: "1泊 4,200円",
    summary: "共有ラウンジとワークスペースを利用できる滞在プランです。",
    publishedAt: "2026-04-25",
  },
];

const typeOptions: Array<{ label: string; value: ListingType }> = [
  { label: "すべて", value: "all" },
  { label: "仕事", value: "job" },
  { label: "滞在", value: "stay" },
];

const categoryOptions: Array<{ label: string; value: CategoryFilter }> = [
  { label: "すべて", value: "all" },
  { label: "リモート", value: "remote" },
  { label: "現地", value: "onsite" },
  { label: "個室", value: "private-room" },
  { label: "シェア", value: "shared" },
];

function subscribeAuthStore() {
  return () => {};
}

function getAuthSnapshot() {
  return String(hasAccessToken());
}

function getServerAuthSnapshot() {
  return "false";
}

function getTypeLabel(type: Listing["listingType"]) {
  return type === "job" ? "仕事" : "滞在";
}

export default function ListingsPage() {
  const router = useRouter();
  const isAuthenticated = useSyncExternalStore(
    subscribeAuthStore,
    getAuthSnapshot,
    getServerAuthSnapshot
  ) === "true";
  const [query, setQuery] = useState("");
  const [listingType, setListingType] = useState<ListingType>("all");
  const [category, setCategory] = useState<CategoryFilter>("all");

  useEffect(() => {
    if (!isAuthenticated) {
      router.replace("/auth/login");
    }
  }, [isAuthenticated, router]);

  const filteredListings = useMemo(() => {
    const normalizedQuery = query.trim().toLowerCase();

    return sampleListings.filter((listing) => {
      const matchesQuery =
        normalizedQuery.length === 0 ||
        [listing.title, listing.tenantName, listing.area, listing.summary]
          .join(" ")
          .toLowerCase()
          .includes(normalizedQuery);
      const matchesType = listingType === "all" || listing.listingType === listingType;
      const matchesCategory = category === "all" || listing.category === category;

      return matchesQuery && matchesType && matchesCategory;
    });
  }, [category, listingType, query]);

  function handleLogout() {
    logout();
    router.replace("/auth/login");
  }

  if (!isAuthenticated) {
    return (
      <main className="appShell">
        <p className="loadingText">読み込み中</p>
      </main>
    );
  }

  return (
    <main className="appShell">
      <header className="appHeader">
        <Link className="brandLink" href="/dashboard">
          Community Hub
        </Link>
        <nav className="headerNav" aria-label="メイン">
          <Link href="/dashboard">マイページ</Link>
          <Link aria-current="page" href="/listings">
            掲載を探す
          </Link>
        </nav>
        <button className="ghostButton" onClick={handleLogout} type="button">
          ログアウト
        </button>
      </header>

      <section className="listingsHero" aria-labelledby="listings-title">
        <div>
          <p className="eyebrow">Listings</p>
          <h1 id="listings-title">掲載を探す</h1>
          <p className="leadText">公開中 {filteredListings.length} 件</p>
        </div>
      </section>

      <section className="listingSearchPanel" aria-label="掲載検索">
        <label className="searchField">
          <span>キーワード</span>
          <input
            onChange={(event) => setQuery(event.target.value)}
            placeholder="タイトル、地域、団体名"
            type="search"
            value={query}
          />
        </label>

        <div className="filterGroup" aria-label="掲載種別">
          {typeOptions.map((option) => (
            <button
              aria-pressed={listingType === option.value}
              className="filterButton"
              key={option.value}
              onClick={() => setListingType(option.value)}
              type="button"
            >
              {option.label}
            </button>
          ))}
        </div>

        <div className="filterGroup" aria-label="カテゴリ">
          {categoryOptions.map((option) => (
            <button
              aria-pressed={category === option.value}
              className="filterButton"
              key={option.value}
              onClick={() => setCategory(option.value)}
              type="button"
            >
              {option.label}
            </button>
          ))}
        </div>
      </section>

      <section className="listingResults" aria-label="掲載一覧">
        {filteredListings.length > 0 ? (
          filteredListings.map((listing) => (
            <article className="listingCard" key={listing.id}>
              <div className="listingCardMain">
                <div className="listingMeta">
                  <span>{getTypeLabel(listing.listingType)}</span>
                  <span>{listing.area}</span>
                </div>
                <h2>{listing.title}</h2>
                <p>{listing.summary}</p>
                <div className="listingTenant">{listing.tenantName}</div>
              </div>
              <div className="listingCardSide">
                <div className="priceLabel">{listing.priceLabel}</div>
                <time dateTime={listing.publishedAt}>{listing.publishedAt}</time>
                <button className="secondaryButton" type="button">
                  詳細
                </button>
              </div>
            </article>
          ))
        ) : (
          <div className="emptyState">
            <h2>掲載がありません</h2>
            <p>条件を変更すると表示される場合があります。</p>
          </div>
        )}
      </section>
    </main>
  );
}
