export type AuthResponse = {
  account?: {
    id: number;
    email: string;
  };
  refresh_token?: string;
  errors?: string[];
  error?: string;
};

export type SessionResponse = {
  account: AuthResponse["account"] | null;
  isAuthenticated: boolean;
};

type AuthParams = {
  email: string;
  password: string;
  passwordConfirmation?: string;
};

const ACCESS_TOKEN_KEY = "accessToken";
const REFRESH_TOKEN_KEY = "refreshToken";
const ACCOUNT_KEY = "account";

async function requestAuth(path: string, body: unknown) {
  const response = await fetch(path, {
    method: "POST",
    credentials: "same-origin",
    headers: {
      Accept: "application/json",
      "Content-Type": "application/json",
    },
    body: JSON.stringify(body),
  });

  const data = (await response.json().catch(() => ({}))) as AuthResponse;

  if (!response.ok) {
    throw new Error(data.errors?.join("\n") || data.error || "認証に失敗しました");
  }

  clearLegacyAuthStorage();

  return data;
}

export function login({ email, password }: AuthParams) {
  return requestAuth("/api/v1/auth/sign_in", {
    user_account: {
      email,
      password,
    },
  });
}

export function signUp({ email, password, passwordConfirmation }: AuthParams) {
  return requestAuth("/api/v1/auth", {
    user_account: {
      email,
      password,
      password_confirmation: passwordConfirmation,
    },
  });
}

export async function getCurrentSession() {
  const response = await fetch("/api/v1/auth/session", {
    credentials: "same-origin",
    headers: {
      Accept: "application/json",
    },
  });

  if (!response.ok) {
    return {
      account: null,
      isAuthenticated: false,
    };
  }

  return (await response.json().catch(() => ({
    account: null,
    isAuthenticated: false,
  }))) as SessionResponse;
}

export async function logout() {
  await fetch("/api/v1/auth/session", {
    method: "DELETE",
    credentials: "same-origin",
    headers: {
      Accept: "application/json",
    },
  }).catch(() => null);
  clearLegacyAuthStorage();
}

function clearLegacyAuthStorage() {
  window.localStorage.removeItem(ACCESS_TOKEN_KEY);
  window.localStorage.removeItem(REFRESH_TOKEN_KEY);
  window.localStorage.removeItem(ACCOUNT_KEY);
}
