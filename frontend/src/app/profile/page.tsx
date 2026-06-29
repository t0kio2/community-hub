"use client";

import Link from "next/link";
import { useRouter } from "next/navigation";
import type React from "react";
import { useEffect, useMemo, useState } from "react";
import { logout } from "@/lib/auth";
import {
  emptyProfileFormValues,
  fetchUserProfile,
  getProfileCompletion,
  ProfileApiError,
  profileToFormValues,
  saveUserProfile,
  validateProfileForm,
  type ProfileFormValues,
} from "@/lib/profile";
import { useAuthSnapshot } from "@/lib/useAuthSnapshot";

export default function ProfilePage() {
  const router = useRouter();
  const auth = useAuthSnapshot();
  const [values, setValues] = useState<ProfileFormValues>(emptyProfileFormValues);
  const [isLoadingProfile, setIsLoadingProfile] = useState(false);
  const [isSaving, setIsSaving] = useState(false);
  const [loadError, setLoadError] = useState("");
  const [formError, setFormError] = useState("");
  const [successMessage, setSuccessMessage] = useState("");

  useEffect(() => {
    if (!auth.isCheckingAuth && !auth.isAuthenticated) {
      router.replace("/auth/login");
    }
  }, [auth.isAuthenticated, auth.isCheckingAuth, router]);

  useEffect(() => {
    if (!auth.isAuthenticated) return;

    let ignore = false;

    async function loadProfile() {
      setIsLoadingProfile(true);
      setLoadError("");

      try {
        const profile = await fetchUserProfile();
        if (!ignore) {
          setValues(profileToFormValues(profile));
        }
      } catch (caught) {
        if (ignore) return;
        if (caught instanceof ProfileApiError && caught.status === 401) {
          router.replace("/auth/login");
          return;
        }
        setLoadError(caught instanceof Error ? caught.message : "プロフィールを取得できませんでした");
      } finally {
        if (!ignore) {
          setIsLoadingProfile(false);
        }
      }
    }

    void loadProfile();

    return () => {
      ignore = true;
    };
  }, [auth.isAuthenticated, router]);

  const completion = useMemo(() => getProfileCompletion(values), [values]);
  const completionPercent = Math.round((completion.completed / completion.total) * 100);

  function updateField(field: keyof ProfileFormValues, value: string) {
    setValues((current) => ({
      ...current,
      [field]: value,
    }));
    setFormError("");
    setSuccessMessage("");
  }

  async function handleLogout() {
    await logout();
    router.replace("/auth/login");
  }

  async function handleSubmit(event: React.FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setFormError("");
    setSuccessMessage("");

    const validationError = validateProfileForm(values);
    if (validationError) {
      setFormError(validationError);
      return;
    }

    setIsSaving(true);

    try {
      const profile = await saveUserProfile(values);
      setValues(profileToFormValues(profile));
      setSuccessMessage("プロフィールを保存しました");
    } catch (caught) {
      if (caught instanceof ProfileApiError && caught.status === 401) {
        router.replace("/auth/login");
        return;
      }
      setFormError(caught instanceof Error ? caught.message : "プロフィールを保存できませんでした");
    } finally {
      setIsSaving(false);
    }
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
          <Link href="/listings">掲載を探す</Link>
          <Link aria-current="page" href="/profile">
            プロフィール
          </Link>
        </nav>
        <button className="ghostButton" onClick={handleLogout} type="button">
          ログアウト
        </button>
      </header>

      <section className="profileHero" aria-labelledby="profile-title">
        <div>
          <p className="eyebrow">Profile</p>
          <h1 id="profile-title">プロフィール</h1>
          <p className="leadText">応募や問い合わせに使う基本情報を管理します。</p>
        </div>
        <div className="profileCompletion" aria-label="プロフィール完成度">
          <span>{completionPercent}%</span>
          <p>
            {completion.completed} / {completion.total} 項目
          </p>
        </div>
      </section>

      {loadError ? (
        <section className="emptyState" role="alert">
          <h2>プロフィールを取得できませんでした</h2>
          <p>{loadError}</p>
          <button className="secondaryButton" onClick={() => window.location.reload()} type="button">
            再読み込み
          </button>
        </section>
      ) : (
        <section className="profileLayout" aria-label="プロフィール編集">
          <form className="profileForm" onSubmit={handleSubmit}>
            {isLoadingProfile ? (
              <div className="formNotice">プロフィールを読み込み中</div>
            ) : null}
            {successMessage ? <div className="formSuccess">{successMessage}</div> : null}
            {formError ? (
              <p className="formError" role="alert">
                {formError}
              </p>
            ) : null}

            <label className="field">
              <span>
                氏名 <b>必須</b>
              </span>
              <input
                autoComplete="name"
                disabled={isLoadingProfile || isSaving}
                onChange={(event) => updateField("name", event.target.value)}
                required
                type="text"
                value={values.name}
              />
            </label>

            <label className="field">
              <span>フリガナ</span>
              <input
                disabled={isLoadingProfile || isSaving}
                onChange={(event) => updateField("kana", event.target.value)}
                type="text"
                value={values.kana}
              />
            </label>

            <label className="field">
              <span>生年月日</span>
              <input
                disabled={isLoadingProfile || isSaving}
                onChange={(event) => updateField("birthDate", event.target.value)}
                type="date"
                value={values.birthDate}
              />
            </label>

            <label className="field">
              <span>電話番号</span>
              <input
                autoComplete="tel"
                disabled={isLoadingProfile || isSaving}
                onChange={(event) => updateField("phone", event.target.value)}
                type="tel"
                value={values.phone}
              />
            </label>

            <label className="field">
              <span>アバター URL</span>
              <input
                disabled={isLoadingProfile || isSaving}
                onChange={(event) => updateField("avatarUrl", event.target.value)}
                type="url"
                value={values.avatarUrl}
              />
            </label>

            <div className="profileActions">
              <button className="primaryButton" disabled={isLoadingProfile || isSaving} type="submit">
                {isSaving ? "保存中" : "プロフィールを保存"}
              </button>
            </div>
          </form>

          <aside className="profilePreview" aria-label="プロフィールプレビュー">
            <div className="avatarPreview">
              {values.avatarUrl ? (
                // eslint-disable-next-line @next/next/no-img-element
                <img alt="" src={values.avatarUrl} />
              ) : (
                <span>{values.name.trim().slice(0, 1) || "?"}</span>
              )}
            </div>
            <h2>{values.name.trim() || "氏名未入力"}</h2>
            <dl>
              <div>
                <dt>フリガナ</dt>
                <dd>{values.kana.trim() || "未設定"}</dd>
              </div>
              <div>
                <dt>生年月日</dt>
                <dd>{values.birthDate || "未設定"}</dd>
              </div>
              <div>
                <dt>電話番号</dt>
                <dd>{values.phone.trim() || "未設定"}</dd>
              </div>
            </dl>
          </aside>
        </section>
      )}
    </main>
  );
}
