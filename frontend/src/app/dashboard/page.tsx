"use client";

import Link from "next/link";
import { useRouter } from "next/navigation";
import { useEffect } from "react";
import { logout } from "@/lib/auth";
import { useAuthSnapshot } from "@/lib/useAuthSnapshot";

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

export default function DashboardPage() {
  const router = useRouter();
  const auth = useAuthSnapshot();

  useEffect(() => {
    if (!auth.isCheckingAuth && !auth.isAuthenticated) {
      router.replace("/auth/login");
    }
  }, [auth.isAuthenticated, auth.isCheckingAuth, router]);

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
