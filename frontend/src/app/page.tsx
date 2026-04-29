import Link from "next/link";

export default function Home() {
  return (
    <main className="authShell">
      <section className="authPanel" aria-labelledby="home-title">
        <p className="eyebrow">Community Hub</p>
        <h1 id="home-title">アカウント</h1>
        <div className="homeActions">
          <Link className="primaryButton" href="/auth/login">
            ログイン
          </Link>
          <Link className="secondaryButton" href="/auth/sign-up">
            新規登録
          </Link>
        </div>
      </section>
    </main>
  );
}
