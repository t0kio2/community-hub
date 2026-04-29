"use client";

import Link from "next/link";
import { useRouter } from "next/navigation";
import type React from "react";
import { useState } from "react";
import { login, signUp } from "@/lib/auth";

type AuthFormProps = {
  mode: "login" | "sign-up";
};

export function AuthForm({ mode }: AuthFormProps) {
  const router = useRouter();
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [passwordConfirmation, setPasswordConfirmation] = useState("");
  const [error, setError] = useState("");
  const [isSubmitting, setIsSubmitting] = useState(false);

  const isLogin = mode === "login";

  async function handleSubmit(event: React.FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setError("");
    setIsSubmitting(true);

    try {
      if (isLogin) {
        await login({ email, password });
      } else {
        await signUp({ email, password, passwordConfirmation });
      }
      router.push("/");
    } catch (caught) {
      setError(caught instanceof Error ? caught.message : "認証に失敗しました");
    } finally {
      setIsSubmitting(false);
    }
  }

  return (
    <main className="authShell">
      <section className="authPanel" aria-labelledby="auth-title">
        <p className="eyebrow">Community Hub</p>
        <h1 id="auth-title">{isLogin ? "ログイン" : "新規登録"}</h1>

        <form className="authForm" onSubmit={handleSubmit}>
          <label className="field">
            <span>メールアドレス</span>
            <input
              autoComplete="email"
              name="email"
              onChange={(event) => setEmail(event.target.value)}
              required
              type="email"
              value={email}
            />
          </label>

          <label className="field">
            <span>パスワード</span>
            <input
              autoComplete={isLogin ? "current-password" : "new-password"}
              name="password"
              onChange={(event) => setPassword(event.target.value)}
              required
              type="password"
              value={password}
            />
          </label>

          {!isLogin && (
            <label className="field">
              <span>パスワード確認</span>
              <input
                autoComplete="new-password"
                name="passwordConfirmation"
                onChange={(event) => setPasswordConfirmation(event.target.value)}
                required
                type="password"
                value={passwordConfirmation}
              />
            </label>
          )}

          {error && <p className="formError">{error}</p>}

          <button className="primaryButton" disabled={isSubmitting} type="submit">
            {isLogin ? "ログイン" : "登録"}
          </button>
        </form>

        <div className="authSwitch">
          {isLogin ? (
            <Link href="/auth/sign-up">新規登録</Link>
          ) : (
            <Link href="/auth/login">ログイン</Link>
          )}
        </div>
      </section>
    </main>
  );
}
