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

const ACCESS_TOKEN_KEY = "communityHubAccessToken";
const REFRESH_TOKEN_KEY = "communityHubRefreshToken";
const ACCOUNT_KEY = "communityHubAccount";
const DEVICE_ID_KEY = "communityHubDeviceId";
const API_ORIGIN = process.env.NEXT_PUBLIC_API_ORIGIN || "http://localhost:3001";

type StoredAuth = {
  accessToken: string;
  refreshToken?: string;
  account?: AuthResponse["account"];
};

function getApiUrl(path: string) {
  return `${API_ORIGIN}${path}`;
}

function getDeviceId() {
  const stored = window.localStorage.getItem(DEVICE_ID_KEY);
  if (stored) return stored;

  const nextDeviceId = crypto.randomUUID();
  window.localStorage.setItem(DEVICE_ID_KEY, nextDeviceId);
  return nextDeviceId;
}

function extractBearerToken(response: Response) {
  return response.headers.get("Authorization")?.replace(/^Bearer\s+/i, "") || "";
}

function storeAuth({ accessToken, refreshToken, account }: StoredAuth) {
  window.localStorage.setItem(ACCESS_TOKEN_KEY, accessToken);

  if (refreshToken) {
    window.localStorage.setItem(REFRESH_TOKEN_KEY, refreshToken);
  }

  if (account) {
    window.localStorage.setItem(ACCOUNT_KEY, JSON.stringify(account));
  }
}

function getStoredAccount() {
  const stored = window.localStorage.getItem(ACCOUNT_KEY);
  if (!stored) return null;

  try {
    return JSON.parse(stored) as NonNullable<AuthResponse["account"]>;
  } catch {
    window.localStorage.removeItem(ACCOUNT_KEY);
    return null;
  }
}

async function requestAuth(path: string, body: unknown) {
  const response = await fetch(getApiUrl(path), {
    method: "POST",
    headers: {
      Accept: "application/json",
      "Content-Type": "application/json",
      "X-Device-Id": getDeviceId(),
      "X-Device-Name": "browser",
    },
    body: JSON.stringify(body),
  });

  const data = (await response.json().catch(() => ({}))) as AuthResponse;

  if (!response.ok) {
    throw new Error(data.errors?.join("\n") || data.error || "認証に失敗しました");
  }

  const accessToken = extractBearerToken(response);
  if (!accessToken) {
    throw new Error("アクセストークンを取得できませんでした");
  }

  storeAuth({
    accessToken,
    refreshToken: data.refresh_token,
    account: data.account,
  });

  return { account: data.account };
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
  const accessToken = window.localStorage.getItem(ACCESS_TOKEN_KEY);
  const account = getStoredAccount();

  if (accessToken) {
    return {
      account,
      isAuthenticated: true,
    };
  }

  if (await refreshAuthSession()) {
    return {
      account: getStoredAccount(),
      isAuthenticated: true,
    };
  }

  return {
    account: null,
    isAuthenticated: false,
  };
}

export async function logout() {
  const refreshToken = window.localStorage.getItem(REFRESH_TOKEN_KEY);

  if (refreshToken) {
    await fetch(getApiUrl("/api/v1/auth/refresh"), {
      method: "DELETE",
      headers: {
        Accept: "application/json",
        "Content-Type": "application/json",
      },
      body: JSON.stringify({ refresh_token: refreshToken }),
    }).catch(() => null);
  }

  clearAuthStorage();
}

export async function authenticatedFetch(path: string, init: RequestInit = {}) {
  const response = await fetchWithAccessToken(path, init);

  if (response.status !== 401) {
    return response;
  }

  if (!(await refreshAuthSession())) {
    clearAuthStorage();
    return response;
  }

  return fetchWithAccessToken(path, init);
}

export function buildApiUrl(path: string) {
  return getApiUrl(path);
}

async function fetchWithAccessToken(path: string, init: RequestInit) {
  const accessToken = window.localStorage.getItem(ACCESS_TOKEN_KEY);
  const headers = new Headers(init.headers);
  headers.set("Accept", headers.get("Accept") || "application/json");

  if (accessToken) {
    headers.set("Authorization", `Bearer ${accessToken}`);
  }

  return fetch(getApiUrl(path), {
    ...init,
    headers,
  });
}

async function refreshAuthSession() {
  const refreshToken = window.localStorage.getItem(REFRESH_TOKEN_KEY);
  if (!refreshToken) return false;

  const response = await fetch(getApiUrl("/api/v1/auth/refresh"), {
    method: "POST",
    headers: {
      Accept: "application/json",
      "Content-Type": "application/json",
    },
    body: JSON.stringify({ refresh_token: refreshToken }),
  });

  const data = (await response.json().catch(() => ({}))) as AuthResponse;
  if (!response.ok) {
    clearAuthStorage();
    return false;
  }

  const accessToken = extractBearerToken(response);
  if (!accessToken) {
    clearAuthStorage();
    return false;
  }

  storeAuth({
    accessToken,
    refreshToken: data.refresh_token,
    account: data.account,
  });

  return true;
}

function clearAuthStorage() {
  window.localStorage.removeItem(ACCESS_TOKEN_KEY);
  window.localStorage.removeItem(REFRESH_TOKEN_KEY);
  window.localStorage.removeItem(ACCOUNT_KEY);
  window.localStorage.removeItem(DEVICE_ID_KEY);
}
