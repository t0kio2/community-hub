"use client";

import Link from "next/link";
import { useRouter } from "next/navigation";
import { useEffect, useMemo, useSyncExternalStore } from "react";
import { getCurrentAccount, hasAccessToken, logout } from "@/lib/auth";

type Account = {
  id: number;
  email: string;
};

const nextActions = [
  {
    href: "/listings",
    label: "掲載を探す",
    value: "公開中の掲載を一覧で確認する",
  },
  {
    href: "/dashboard",
    label: "お気に入り",
    value: "気になる掲載を後で見返す",
  },
  {
    href: "/dashboard",
    label: "プロフィール",
    value: "応募や問い合わせに使う情報を整える",
  },
];

function subscribeAuthStore() {
  return () => {};
}

function getAuthSnapshot() {
  return JSON.stringify({
    account: getCurrentAccount(),
    isAuthenticated: hasAccessToken(),
  });
}

function getServerAuthSnapshot() {
  return JSON.stringify({
    account: null,
    isAuthenticated: false,
  });
}

export default function DashboardPage() {
  const router = useRouter();
  const authSnapshot = useSyncExternalStore(
    subscribeAuthStore,
    getAuthSnapshot,
    getServerAuthSnapshot
  );
  const auth = useMemo(
    () => JSON.parse(authSnapshot) as { account: Account | null; isAuthenticated: boolean },
    [authSnapshot]
  );

  useEffect(() => {
    if (!auth.isAuthenticated) {
      router.replace("/auth/login");
    }
  }, [auth.isAuthenticated, router]);

  function handleLogout() {
    logout();
    router.replace("/auth/login");
  }

  if (!auth.isAuthenticated) {
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
        <button className="ghostButton" onClick={handleLogout} type="button">
          ログアウト
        </button>
      </header>

      <section className="dashboardHero" aria-labelledby="dashboard-title">
        <div>
          <p className="eyebrow">User dashboard</p>
          <h1 id="dashboard-title">マイページ</h1>
          <p className="leadText">
            {auth.account?.email ?? "ログイン中のアカウント"} として利用中です。
          </p>
        </div>
      </section>

      <section className="dashboardSection" aria-labelledby="next-actions-title">
        <div className="sectionHeader">
          <h2 id="next-actions-title">次の操作</h2>
        </div>

        <div className="actionGrid">
          {nextActions.map((action) => (
            <Link className="actionCard" href={action.href} key={action.label}>
              <h3>{action.label}</h3>
              <p>{action.value}</p>
            </Link>
          ))}
        </div>
      </section>
    </main>
  );
}
