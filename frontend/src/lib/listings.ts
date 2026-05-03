export type ListingType = "all" | "job" | "stay";
export type CategoryFilter = "all" | "remote" | "onsite" | "private-room" | "shared";

export type Listing = {
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

export type ApiListing = {
  id: number;
  listing_type: "job" | "stay";
  title: string;
  description: string | null;
  tenant: {
    id: number;
    name: string;
  };
  published_at: string | null;
  detail: {
    employment_type?: string | null;
    job_category?: string | null;
    work_area?: string | null;
    salary_type?: string | null;
    salary_min?: number | null;
    salary_max?: number | null;
    working_hours?: string | null;
    work_days?: string | null;
    stay_type?: string | null;
    address?: string | null;
    capacity?: number | null;
    price_per_night?: number | null;
    available_from?: string | null;
    available_until?: string | null;
  };
};

type ListingsResponse = {
  listings?: ApiListing[];
};

export async function fetchPublicListings() {
  const response = await fetch("/api/v1/public/listings", {
    headers: {
      Accept: "application/json",
    },
  });

  if (!response.ok) {
    throw new Error("掲載一覧を取得できませんでした");
  }

  const data = (await response.json().catch(() => ({}))) as ListingsResponse;
  return (data.listings ?? []).map(mapApiListingToListing);
}

export function mapApiListingToListing(listing: ApiListing): Listing {
  const isJob = listing.listing_type === "job";
  const detail = listing.detail ?? {};

  return {
    id: listing.id,
    title: listing.title,
    tenantName: listing.tenant.name,
    listingType: listing.listing_type,
    category: isJob ? mapJobCategory(detail.work_area) : mapStayCategory(detail.stay_type),
    area: isJob ? detail.work_area || "地域未設定" : detail.address || "住所未設定",
    priceLabel: isJob
      ? formatSalary(detail.salary_type, detail.salary_min, detail.salary_max)
      : formatNightlyPrice(detail.price_per_night),
    summary: listing.description || "説明はまだ登録されていません。",
    publishedAt: formatDate(listing.published_at),
  };
}

export function filterListings(
  listings: Listing[],
  query: string,
  listingType: ListingType,
  category: CategoryFilter
) {
  const normalizedQuery = query.trim().toLowerCase();

  return listings.filter((listing) => {
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
}

function mapJobCategory(workArea?: string | null): "remote" | "onsite" {
  const normalizedArea = (workArea ?? "").toLowerCase();
  return normalizedArea.includes("remote") || normalizedArea.includes("リモート")
    ? "remote"
    : "onsite";
}

function mapStayCategory(stayType?: string | null): "private-room" | "shared" {
  return stayType === "private_room" ? "private-room" : "shared";
}

function formatSalary(
  salaryType?: string | null,
  salaryMin?: number | null,
  salaryMax?: number | null
) {
  const prefix = salaryType === "hourly" ? "時給" : "報酬";
  return formatPriceRange(prefix, salaryMin, salaryMax);
}

function formatNightlyPrice(pricePerNight?: number | null) {
  if (!pricePerNight) return "料金未設定";

  return `1泊 ${pricePerNight.toLocaleString("ja-JP")}円`;
}

function formatPriceRange(prefix: string, min?: number | null, max?: number | null) {
  if (min && max) {
    return `${prefix} ${min.toLocaleString("ja-JP")}〜${max.toLocaleString("ja-JP")}円`;
  }
  if (min) return `${prefix} ${min.toLocaleString("ja-JP")}円〜`;
  if (max) return `${prefix} 〜${max.toLocaleString("ja-JP")}円`;

  return `${prefix} 未設定`;
}

function formatDate(value?: string | null) {
  if (!value) return "";

  return value.slice(0, 10);
}
