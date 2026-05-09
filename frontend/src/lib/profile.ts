import { authenticatedFetch } from "@/lib/auth";

export type UserProfile = {
  id: number;
  name: string;
  kana: string | null;
  birth_date: string | null;
  phone: string | null;
  avatar_url: string | null;
};

export type ProfileFormValues = {
  name: string;
  kana: string;
  birthDate: string;
  phone: string;
  avatarUrl: string;
};

type ProfileResponse = {
  user_profile?: UserProfile | null;
  errors?: string[];
  error?: string;
};

export const emptyProfileFormValues: ProfileFormValues = {
  name: "",
  kana: "",
  birthDate: "",
  phone: "",
  avatarUrl: "",
};

export class ProfileApiError extends Error {
  status: number;

  constructor(message: string, status: number) {
    super(message);
    this.name = "ProfileApiError";
    this.status = status;
  }
}

export async function fetchUserProfile() {
  const response = await authenticatedFetch("/api/v1/user/profile");
  const data = (await response.json().catch(() => ({}))) as ProfileResponse;

  if (!response.ok) {
    throw buildProfileApiError(response.status, data, "プロフィールを取得できませんでした");
  }

  return data.user_profile ?? null;
}

export async function saveUserProfile(values: ProfileFormValues) {
  const validationError = validateProfileForm(values);
  if (validationError) {
    throw new ProfileApiError(validationError, 0);
  }

  const response = await authenticatedFetch("/api/v1/user/profile", {
    method: "PUT",
    headers: {
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      user_profile: formValuesToPayload(values),
    }),
  });
  const data = (await response.json().catch(() => ({}))) as ProfileResponse;

  if (!response.ok) {
    throw buildProfileApiError(response.status, data, "プロフィールを保存できませんでした");
  }

  return data.user_profile ?? null;
}

export function profileToFormValues(profile: UserProfile | null): ProfileFormValues {
  if (!profile) return { ...emptyProfileFormValues };

  return {
    name: profile.name,
    kana: profile.kana ?? "",
    birthDate: profile.birth_date ?? "",
    phone: profile.phone ?? "",
    avatarUrl: profile.avatar_url ?? "",
  };
}

export function validateProfileForm(values: ProfileFormValues) {
  if (!values.name.trim()) {
    return "氏名を入力してください";
  }

  return "";
}

export function getProfileCompletion(values: ProfileFormValues) {
  const requiredItems = [values.name.trim()];
  const optionalItems = [
    values.kana.trim(),
    values.birthDate.trim(),
    values.phone.trim(),
    values.avatarUrl.trim(),
  ];
  const completed = [...requiredItems, ...optionalItems].filter(Boolean).length;

  return {
    completed,
    total: requiredItems.length + optionalItems.length,
  };
}

function formValuesToPayload(values: ProfileFormValues) {
  return {
    name: values.name.trim(),
    kana: optionalString(values.kana),
    birth_date: optionalString(values.birthDate),
    phone: optionalString(values.phone),
    avatar_url: optionalString(values.avatarUrl),
  };
}

function optionalString(value: string) {
  const normalized = value.trim();
  return normalized.length > 0 ? normalized : null;
}

function buildProfileApiError(status: number, data: ProfileResponse, fallback: string) {
  return new ProfileApiError(data.errors?.join("\n") || data.error || fallback, status);
}
