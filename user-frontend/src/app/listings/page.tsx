"use client";

import Link from "next/link";
import { useRouter } from "next/navigation";
import { useEffect, useMemo, useState } from "react";
import { logout } from "@/lib/auth";
import {
  fetchPublicListings,
  filterListings,
  type CategoryFilter,
  type Listing,
  type ListingType,
} from "@/lib/listings";
import { useAuthSnapshot } from "@/lib/useAuthSnapshot";

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

function getTypeLabel(type: Listing["listingType"]) {
  return type === "job" ? "仕事" : "滞在";
}

export default function ListingsPage() {
  const router = useRouter();
  const auth = useAuthSnapshot();
  const [query, setQuery] = useState("");
  const [listingType, setListingType] = useState<ListingType>("all");
  const [category, setCategory] = useState<CategoryFilter>("all");
  const [listings, setListings] = useState<Listing[]>([]);
  const [isLoadingListings, setIsLoadingListings] = useState(false);
  const [loadError, setLoadError] = useState("");

  useEffect(() => {
    if (!auth.isCheckingAuth && !auth.isAuthenticated) {
      router.replace("/auth/login");
    }
  }, [auth.isAuthenticated, auth.isCheckingAuth, router]);

  useEffect(() => {
    if (!auth.isAuthenticated) return;

    let ignore = false;

    async function loadListings() {
      setIsLoadingListings(true);
      setLoadError("");

      try {
        const nextListings = await fetchPublicListings();
        if (!ignore) {
          setListings(nextListings);
        }
      } catch (caught) {
        if (!ignore) {
          setLoadError(
            caught instanceof Error ? caught.message : "掲載一覧を取得できませんでした"
          );
        }
      } finally {
        if (!ignore) {
          setIsLoadingListings(false);
        }
      }
    }

    void loadListings();

    return () => {
      ignore = true;
    };
  }, [auth.isAuthenticated]);

  const filteredListings = useMemo(
    () => filterListings(listings, query, listingType, category),
    [category, listingType, listings, query]
  );

  async function handleLogout() {
    await logout();
    router.replace("/auth/login");
  }

  if (auth.isCheckingAuth || !auth.isAuthenticated) {
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
          <p className="leadText">
            {isLoadingListings ? "掲載を読み込み中" : `公開中 ${filteredListings.length} 件`}
          </p>
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
        {loadError ? (
          <div className="emptyState" role="alert">
            <h2>掲載を取得できませんでした</h2>
            <p>{loadError}</p>
            <button
              className="secondaryButton"
              onClick={() => window.location.reload()}
              type="button"
            >
              再読み込み
            </button>
          </div>
        ) : isLoadingListings ? (
          <div className="emptyState">
            <h2>読み込み中</h2>
            <p>公開中の掲載を取得しています。</p>
          </div>
        ) : filteredListings.length > 0 ? (
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
                {listing.publishedAt ? (
                  <time dateTime={listing.publishedAt}>{listing.publishedAt}</time>
                ) : (
                  <span className="listingDateFallback">公開日未設定</span>
                )}
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
